# --- lib/servo_control.py ---
# Classe para controlar múltiplos servos com PWM (MicroPython)
# Focada em movimento suave (easing) para cargas sensíveis (como um ovo).

from machine import Pin, PWM
from time import sleep, sleep_ms
try:
    # Tenta importar umath (nativo do MicroPython)
    import umath as math
except ImportError:
    # Fallback para o math padrão (CPython, etc.)
    import math

class ServoControl:
    """Controla múltiplos servos (base, cotovelo, pulso, cos).
       Armazena a última posição conhecida para permitir movimentos suaves
       e sincronizados (easing).
    """

    def __init__(self, pin_base, pin_cotovelo, pin_pulso, pin_cos, freq=50,
                 min_ns=500_000, max_ns=2_500_000):
        
        # Configuração básica
        self.freq = int(freq)
        self.MIN_NS = int(min_ns)
        self.MAX_NS = int(max_ns)
        self.RANGE_NS = self.MAX_NS - self.MIN_NS
        
        # --- API Refatorada ---
        # Armazena os objetos PWM em um dicionário para acesso por nome
        self.pwms = {
            "base": PWM(Pin(pin_base), freq=self.freq),
            "cotovelo": PWM(Pin(pin_cotovelo), freq=self.freq),
            "pulso": PWM(Pin(pin_pulso), freq=self.freq),
            "cos": PWM(Pin(pin_cos), freq=self.freq),
        }
        
        # Armazena a última posição COMANDADA (0-180) de cada servo.
        # Começa como 'None' para forçar uma posição inicial.
        self.posicao = {
            "base": None, "cotovelo": None, "pulso": None, "cos": None
        }

        # Armazena a calibração (offset em graus, se o movimento é invertido)
        self.calib = {
            "base": {"offset": 0, "invert": False},
            "cotovelo": {"offset": 0, "invert": False},
            "pulso": {"offset": 0, "invert": False},
            "cos": {"offset": 0, "invert": False},
        }
        
        # Define a cadência de atualização para movimentos suaves (50Hz = 20ms)
        self.PASSO_MS = 20 

        print(f"Controlador de Servos inicializado (freq {self.freq} Hz).")
        print("IMPORTANTE: Chame 'posicionar_inicial()' para definir um estado conhecido.")

    # ---------------- Métodos Privados (Core) ----------------
    
    def _clamp_angle(self, angle):
        """Garante que o ângulo esteja entre 0 e 180."""
        if angle < 0: return 0
        if angle > 180: return 180
        return int(angle)

    def _angle_to_ns(self, angle):
        """Converte ângulo (0-180) para nanosegundos de pulso."""
        # Mapeamento linear
        ns = self.MIN_NS + int((angle / 180.0) * self.RANGE_NS)
        return ns

    def _write_pwm(self, pwm_obj, ns):
        """Tenta usar duty_ns; se não disponível, converte para duty_u16."""
        try:
            # Tenta o método mais preciso (ESP32)
            pwm_obj.duty_ns(int(ns))
        except TypeError:
            # Fallback para duty_u16 (outras placas)
            period_ns = 1_000_000_000 // self.freq
            duty_u16 = int((ns / period_ns) * 65535)
            try:
                pwm_obj.duty_u16(duty_u16)
            except Exception as e:
                print(f"Erro fatal no PWM: {e}")
                # (O fallback para duty() foi removido por ser muito inconsistente)
        except ValueError:
            # Pulso pode estar fora do range suportado pelo hardware
            pass 

    def _apply_calib(self, servo_name, angle):
        """Aplica o offset e a inversão de calibração."""
        a = self._clamp_angle(angle)
        conf = self.calib.get(servo_name) # Já definido no init, seguro
        
        a_cal = a + int(conf["offset"])
        if conf["invert"]:
            a_cal = 180 - a_cal
            
        return self._clamp_angle(a_cal)

    # ---------------- Métodos Públicos (Controle) ----------------

    def set_calibration(self, servo_name, offset=0, invert=False):
        """Configura offset (graus) e invert (True/False) para um servo."""
        if servo_name not in self.calib:
            raise ValueError(f"Servo '{servo_name}' inválido.")
        self.calib[servo_name]["offset"] = int(offset)
        self.calib[servo_name]["invert"] = bool(invert)
        print(f"Calibração de '{servo_name}': offset={offset}, invert={invert}")

    def mover(self, servo_name, angle):
        """Move um servo específico para o ângulo (0-180) instantaneamente."""
        if servo_name not in self.pwms:
            raise ValueError(f"Servo '{servo_name}' não existe.")
        
        # 1. Salva a posição *desejada* (antes da calibração)
        target_angle = self._clamp_angle(angle)
        self.posicao[servo_name] = target_angle
        
        # 2. Aplica calibração
        calib_angle = self._apply_calib(servo_name, target_angle)
        
        # 3. Converte para pulso
        ns = self._angle_to_ns(calib_angle)
        
        # 4. Envia comando
        self._write_pwm(self.pwms[servo_name], ns)

    def mover_pose(self, pose_dict):
        """Move múltiplos servos para uma pose instantaneamente.
           Ex: braco.mover_pose({'base': 90, 'pulso': 45})
        """
        for servo_name, angle in pose_dict.items():
            self.mover(servo_name, angle)

    def posicionar_inicial(self, pose_dict, espera_ms=500):
        """Move todos os servos para uma posição inicial conhecida (sem suavização).
           NECESSÁRIO para usar os movimentos suaves.
        """
        print(f"Definindo posição inicial... {pose_dict}")
        self.mover_pose(pose_dict)
        sleep_ms(espera_ms) # Dá tempo para os servos chegarem na posição
        print("Braço posicionado.")

    def _check_estado_conhecido(self):
        """Verifica se todos os servos têm uma posição inicial definida."""
        for servo_name, pos in self.posicao.items():
            if pos is None:
                raise RuntimeError(
                    f"Posição inicial do servo '{servo_name}' é desconhecida. "
                    "Chame 'posicionar_inicial()' primeiro."
                )
    
    def get_posicao(self, servo_name):
        """Retorna a última posição COMANDADA (0-180) para um servo."""
        return self.posicao.get(servo_name)

    # ---------------- Movimento Suave (Egg-Safe) ----------------
    
    def _ease_in_out_sine(self, t):
        """Fórmula de easing (0 <= t <= 1)."""
        return 0.5 * (1 - math.cos(t * math.pi))

    def mover_suave_para(self, servo_name, angulo_final, duracao_ms=1000):
        """Move UM servo para um novo ângulo com aceleração/desaceleração suave.
           Perfeito para o movimento delicado da GARRA.
        """
        self._check_estado_conhecido()
        
        # 1. Define início e fim
        ang_inicio = self.posicao[servo_name]
        ang_final = self._clamp_angle(angulo_final)
        delta_total = ang_final - ang_inicio
        
        if delta_total == 0:
            return # Já está no lugar

        num_passos = max(1, duracao_ms // self.PASSO_MS)
        ms_por_passo = duracao_ms // num_passos
        
        # 2. Loop de movimento
        for i in range(num_passos):
            frac_tempo = (i + 1) / num_passos
            frac_movimento = self._ease_in_out_sine(frac_tempo)
            
            angulo_atual = ang_inicio + (delta_total * frac_movimento)
            self.mover(servo_name, angulo_atual) # Mover já aplica calibração
            sleep_ms(ms_por_passo)
            
        # 3. Garante a posição final exata
        self.mover(servo_name, ang_final)

    def mover_pose_suave(self, pose_dict, duracao_ms=1000):
        """Move MÚLTIPLOS servos para uma nova pose, de forma SINCRONIZADA
           e SUAVE (easing). Todos começam e terminam ao mesmo tempo.
           Esta é a função principal para mover o braço com o ovo.
        """
        self._check_estado_conhecido()

        # 1. Define início e fim para todos os servos na pose
        ang_inicio = {}
        delta_total = {}
        for servo_name, ang_final in pose_dict.items():
            ang_inicio[servo_name] = self.posicao[servo_name]
            delta_total[servo_name] = self._clamp_angle(ang_final) - ang_inicio[servo_name]
            
        num_passos = max(1, duracao_ms // self.PASSO_MS)
        ms_por_passo = duracao_ms // num_passos
        
        # 2. Loop de movimento sincronizado
        for i in range(num_passos):
            # Calcula a fração de movimento (easing)
            frac_tempo = (i + 1) / num_passos
            frac_movimento = self._ease_in_out_sine(frac_tempo)
            
            # Aplica o movimento para CADA servo
            pose_atual = {}
            for servo_name in pose_dict.keys():
                angulo_atual = ang_inicio[servo_name] + (delta_total[servo_name] * frac_movimento)
                pose_atual[servo_name] = angulo_atual
            
            self.mover_pose(pose_atual) # Manda todos os comandos de uma vez
            sleep_ms(ms_por_passo)
            
        # 3. Garante a pose final exata
        self.mover_pose(pose_dict)

    def parar_todos(self):
        """Desliga PWM de todos os servos (para de enviar sinal)."""
        print("Desligando servos.")
        for pwm_obj in self.pwms.values():
            try:
                pwm_obj.deinit()
            except Exception:
                pass # Ignora erros se já estiver desligado

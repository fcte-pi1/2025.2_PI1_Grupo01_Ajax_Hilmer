# --- lib/servo_control.py ---
# Classe para controlar múltiplos Servos com PWM

from machine import Pin, PWM
from time import sleep

class ServoControl:
    
    def __init__(self, pin_base, pin_cotovelo, pin_pulso, pin_cos):
        # Frequência padrão para servos
        FREQ = 50 
        
        # Mapeamento de ângulo (0-180) para nanosegundos (500k-2500k)
        # Esses valores podem precisar de ajuste fino para seus servos
        self.MIN_NS = 500000  # 0.5 ms
        self.MAX_NS = 2500000 # 2.5 ms
        
        # Inicializa um objeto PWM para cada servo
        self.base = PWM(Pin(pin_base), freq=FREQ)
        self.cotovelo = PWM(Pin(pin_cotovelo), freq=FREQ)
        self.pulso = PWM(Pin(pin_pulso), freq=FREQ)
        self.cos = PWM(Pin(pin_cos), freq=FREQ)
        
        print("Controlador de Servos inicializado.")
        # Começa movendo todos para a posição central (90 graus)
        self.mover_todos(90)
        sleep(1) # Dá tempo para os servos chegarem na posição

    def _angle_to_ns(self, angle):
        """Converte um ângulo (0-180) para o valor em nanosegundos."""
        if angle < 0: angle = 0
        if angle > 180: angle = 180
        
        # Mapeamento linear
        # (angulo / 180) * (range_total_ns) + min_ns
        range_ns = self.MAX_NS - self.MIN_NS
        ns = self.MIN_NS + int((angle / 180.0) * range_ns)
        return ns

    def mover(self, servo_obj, angle):
        """Move um servo específico para um ângulo."""
        ns = self._angle_to_ns(angle)
        servo_obj.duty_ns(ns)
        
    def mover_todos(self, angle):
        """Move todos os servos para o mesmo ângulo."""
        print(f"Movendo todos os servos para {angle} graus.")
        ns = self._angle_to_ns(angle)
        self.base.duty_ns(ns)
        self.cotovelo.duty_ns(ns)
        self.pulso.duty_ns(ns)
        self.cos.duty_ns(ns)

    def parar_todos(self):
        """Desliga o PWM de todos os servos (para parar de "zunir")."""
        print("Desligando servos.")
        self.base.deinit()
        self.cotovelo.deinit()
        self.pulso.deinit()
        self.cos.deinit()
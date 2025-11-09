# --- lib/hcsr04.py ---
# Biblioteca para o sensor ultrassônico HC-SR04
# Baseado na implementação de: https://github.com/micropython-IMU/micropython-hcsr04

from machine import Pin, time_pulse_us
import time

class HCSR04:
    def __init__(self, trigger_pin, echo_pin, echo_timeout_us=30000):
        """
        trigger_pin: Pino de saída para enviar o pulso.
        echo_pin: Pino de entrada para ler o eco.
        echo_timeout_us: Timeout em microsegundos. 30000us = 30ms.
        """
        self.echo_timeout_us = echo_timeout_us
        
        # Inicializa os pinos
        self.trigger = Pin(trigger_pin, Pin.OUT)
        self.echo = Pin(echo_pin, Pin.IN)
        
        # Garante que o trigger comece em nível baixo
        self.trigger.off()

    def _send_pulse(self):
        """
        Envia um pulso de 10 microsegundos no pino Trigger.
        """
        self.trigger.on()
        time.sleep_us(10)
        self.trigger.off()

    def distance_cm(self):
        """
        Mede a distância em centímetros.
        Retorna -1 em caso de timeout (sem eco).
        """
        self._send_pulse() # Envia o pulso
        
        try:
            # Mede o tempo (em microsegundos) que o pino Echo
            # fica em nível ALTO.
            pulse_time = time_pulse_us(self.echo, 1, self.echo_timeout_us)

            # --- INÍCIO DA CORREÇÃO ---
            # Checagem crítica: 
            # Se o tempo for negativo, é um timeout
            if pulse_time < 0:
                # print("Erro: time_pulse_us retornou negativo")
                return -1
            # --- FIM DA CORREÇÃO ---

        except OSError as e:
            # Timeout ou outro erro (OSError: [Errno 110] ETIMEDOUT)
            # print("Erro: OSErrorm", e)
            return -1

        # Se chegamos aqui, pulse_time é positivo
        dist_cm = pulse_time / 58.0
        
        return dist_cm
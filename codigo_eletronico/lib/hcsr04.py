# --- lib/hcsr04.py ---
# Biblioteca para o sensor ultrassônico HC-SR04
# Adaptada para ESP32 (com divisor de tensão no pino ECHO)
# Baseado em: https://github.com/micropython-IMU/micropython-hcsr04

from machine import Pin, time_pulse_us
import time

class HCSR04:
    def __init__(self, trigger_pin, echo_pin, echo_timeout_us=30000):
        """
        trigger_pin: Pino de saída para enviar o pulso (GPIO)
        echo_pin: Pino de entrada para ler o eco (⚠️ precisa de divisor de tensão no ESP32!)
        echo_timeout_us: Tempo máximo de espera (30.000 µs = 30 ms)
        """
        self.echo_timeout_us = echo_timeout_us

        # Inicializa os pinos
        self.trigger = Pin(trigger_pin, Pin.OUT)
        self.echo = Pin(echo_pin, Pin.IN)

        # Garante que o trigger comece em nível baixo
        self.trigger.off()

    def _send_pulse(self):
        """Envia um pulso de 10 µs no TRIG."""
        self.trigger.off()
        time.sleep_us(2)    # estabiliza
        self.trigger.on()
        time.sleep_us(10)   # pulso de 10 µs
        self.trigger.off()

    def distance_cm(self):
        """
        Mede a distância em centímetros.
        Retorna:
          - Valor em cm (float) se sucesso
          - -1 em caso de timeout ou erro
        """
        self._send_pulse()

        try:
            # Mede o tempo que o ECHO ficou em nível ALTO (em microsegundos)
            pulse_time = time_pulse_us(self.echo, 1, self.echo_timeout_us)

            if pulse_time < 0:
                return -1  # Timeout

        except OSError:
            return -1  # Falha de leitura ou timeout

        # Converte tempo em distância (velocidade do som ≈ 343 m/s)
        distance = (pulse_time / 2) / 29.1  # em cm
        return distance


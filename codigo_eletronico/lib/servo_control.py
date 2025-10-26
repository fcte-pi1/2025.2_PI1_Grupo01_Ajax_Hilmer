# --- lib/servo_control.py Uma classe para controlar qualquer servo motor---
from machine import Pin, PWM

class ServoControl:
    def __init__(self, pin_num, freq=50):
        self.pwm = PWM(Pin(pin_num), freq=freq)

    def _angle_to_duty(self, angle):
        # Converte ângulo (0-180) para ciclo de trabalho (duty cycle)
        # Este range (20-120) é comum para 50Hz, mas PODE PRECISAR DE AJUSTE.
        min_duty = 20
        max_duty = 120
        return int(min_duty + (angle / 180) * (max_duty - min_duty))

    def set_angle(self, angle):
        if 0 <= angle <= 180:
            duty = self._angle_to_duty(angle)
            self.pwm.duty(duty)
        else:
            print(f"Ângulo inválido: {angle}")
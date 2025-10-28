# --- lib/servo_control.py Uma classe para controlar qualquer servo motor---
from machine import Pin, PWM
import uasyncio

class ServoControl:
    def __init__(self, pin_num, freq=50):
        self.pwm = PWM(Pin(pin_num), freq=freq)
        self.current_angle = -1

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
            self.current_angle = angle
        else:
            print(f"Ângulo inválido: {angle}")

    async def move_to_angle(self, target_angle, speed_delay_ms=20): # O delay pode ser mudado
        if not (0 <= target_angle <=180):
            print(f"Ângulo alvo inválido: {target_angle}")
            return
            
        if self.current_angle == -1:
             self.set_angle(target_angle)
             return

        # Determina a direção (incremento)
        step = 1 if target_angle > self.current_angle else -1
        
        # Loop de interpolação (adaptado do Arduino)
        for angle in range(self.current_angle, target_angle + step, step):
            duty = self._angle_to_duty(angle)
            self.pwm.duty(duty)
            await uasyncio.sleep_ms(speed_delay_ms) # Pausa
            
        self.current_angle = target_angle
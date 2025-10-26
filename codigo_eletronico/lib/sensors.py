# --- lib/sensors.py Um arquivo para agrupar as classes dos sensores mais simples (HC-SR04 e LM393).---
from machine import Pin
import time

class HCSRO4:
    def __init__(self, pin_trig, pin_echo):
        self.trig = Pin(pin_trig, Pin.OUT)
        self.echo = Pin(pin_echo, Pin.IN)

    def get_distance_cm(self):
        self.trig.off()
        time.sleep_us(2)
        self.trig.on()
        time.sleep_us(10)
        self.trig.off()

        try:
            pulse_time = machine.time_pulse_us(self.echo, 1, 30000) # Timeout de 30ms
            distance = (pulse_time * 0.0343) / 2
            return distance
        except OSError:
            return -1 # Erro (timeout)

class LineFollower:
    def __init__(self, pin_left, pin_right):
        self.left = Pin(pin_left, Pin.IN)
        self.right = Pin(pin_right, Pin.IN)

    def read(self):
        # Assumindo 0 = linha preta, 1 = superfície branca
        return self.left.value(), self.right.value()
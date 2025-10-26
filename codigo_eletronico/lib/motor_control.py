# --- lib/motor_control.py  Uma classe dedicada a controlar os motores L298N.--- 
from machine import Pin


class MotorControl:
    def __init__(self, pin_re_avante, pin_re_re, pin_rd_avante, pin_rd_re):
        # Configura os pinos como saída
        self.re_avante = Pin(pin_re_avante, Pin.OUT)
        self.re_re = Pin(pin_re_re, Pin.OUT)
        self.rd_avante = Pin(pin_rd_avante, Pin.OUT)
        self.rd_re = Pin(pin_rd_re, Pin.OUT)
        self.parar()

    def frente(self):
        self.re_avante.on()
        self.re_re.off()
        self.rd_avante.on()
        self.rd_re.off()
        print("Motores: Frente")

    def tras(self):
        self.re_avante.off()
        self.re_re.on()
        self.rd_avante.off()
        self.rd_re.on()
        print("Motores: Trás")

    def esquerda(self):
        self.re_avante.off()
        self.re_re.on()
        self.rd_avante.on()
        self.rd_re.off()
        print("Motores: Virar Esquerda")

    def direita(self):
        self.re_avante.on()
        self.re_re.off()
        self.rd_avante.off()
        self.rd_re.on()
        print("Motores: Virar Direita")

    def parar(self):
        self.re_avante.off()
        self.re_re.off()
        self.rd_avante.off()
        self.rd_re.off()
        print("Motores: Parar")
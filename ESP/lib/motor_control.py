from machine import Pin
from time import sleep

class MotorControl:
    def __init__(self, pin_re_avante, pin_re_re, pin_rd_avante, pin_rd_re):
        self.re_avante = Pin(pin_re_avante, Pin.OUT)
        self.re_re = Pin(pin_re_re, Pin.OUT)
        self.rd_avante = Pin(pin_rd_avante, Pin.OUT)
        self.rd_re = Pin(pin_rd_re, Pin.OUT)
        self.parar()

    def frente(self, compensar=0):
        """
        Move para frente. 
        compensar > 0 -> motor direito mais rápido
        compensar < 0 -> motor esquerdo mais rápido
        """
        if compensar >= 0:
            self.re_avante.on()
            self.re_re.off()
            self.rd_avante.on()
            self.rd_re.off()
            sleep(compensar)  # deixa motor direito ligado mais tempo
        else:
            self.re_avante.on()
            self.re_re.off()
            self.rd_avante.on()
            self.rd_re.off()
            sleep(-compensar)  # deixa motor esquerdo ligado mais tempo
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

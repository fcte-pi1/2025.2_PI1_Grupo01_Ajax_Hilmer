# --- testes/test_distancia.py ---
# Script para testar o sensor HC-SR04

import sys
sys.path.append('..')  # Para achar 'config' e 'lib'

from time import sleep
from lib.hcsr04 import HCSR04
import config

print("Iniciando o teste do sensor de distância HC-SR04...")
print(f"Trigger: GPIO{config.PIN_TRIG} | Echo: GPIO{config.PIN_ECHO}")
print("⚠️ Certifique-se de usar divisor de tensão no pino ECHO (5V → 3.3V)!\n")

# Inicializa o sensor
try:
    sensor = HCSR04(trigger_pin=config.PIN_TRIG, echo_pin=config.PIN_ECHO)

    while True:
        distancia = sensor.distance_cm()

        if distancia == -1:
            print("⛔ Erro: Fora de alcance ou timeout.")
        else:
            print(f"📏 Distância: {distancia:.2f} cm")

        sleep(0.5)

except KeyboardInterrupt:
    print("\n🛑 Teste interrompido pelo usuário.")

except Exception as e:
    print(f"\n❌ Erro ao iniciar o sensor: {e}")
    print("Verifique os pinos e o divisor de tensão no ECHO!")


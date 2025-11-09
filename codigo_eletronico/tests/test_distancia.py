# --- testes/test_distancia.py ---
# Script para testar o sensor HC-SR04

import sys
sys.path.append('..') # Para achar 'config' e 'lib'

from time import sleep
from lib.hcsr04 import HCSR04 # Importa nossa nova biblioteca
import config

print("Iniciando o teste do sensor de distância HC-SR04...")
print(f"Pino Trigger: {config.PIN_TRIG}")
print(f"Pino Echo: {config.PIN_ECHO}")

# Inicializa o sensor
try:
    sensor = HCSR04(
        trigger_pin=config.PIN_TRIG,
        echo_pin=config.PIN_ECHO
    )

    # Loop principal
    while True:
        distancia = sensor.distance_cm()
        
        if distancia == -1:
            print("Erro: Fora de alcance ou timeout.")
        else:
            # O f:.2f formata o número para 2 casas decimais
            print(f"Distância: {distancia:.2f} cm")
        
        sleep(0.5) # Pausa de meio segundo entre as medições

except KeyboardInterrupt:
    print("\nTeste interrompido pelo usuário.")
except Exception as e:
    print(f"\nErro fatal ao inicializar o sensor: {e}")
    print("Verifique os pinos no config.py e as conexões!")
teste_braco
# --- test_servos.py ---
# Script para testar a classe ServoControl

from time import sleep
from lib.servo_control import ServoControl # Importa nossa nova classe
import config # Importa as configurações

print("Iniciando o teste do braço robótico...")

try:
    # 1. Instancia a classe
    braco = ServoControl(
        pin_base=config.PIN_SERVO_BASE,
        pin_cotovelo=config.PIN_SERVO_COTOVELO,
        pin_pulso=config.PIN_SERVO_PULSO,
        pin_cos=config.PIN_SERVO_COS
    )

    # 2. Executa uma sequência de testes
    # (Todos já começam em 90 graus, definido no __init__)

    print("Testando Base (0 a 180)...")
    braco.mover(braco.base, 0)
    sleep(2)
    braco.mover(braco.base, 180)
    sleep(2)
    braco.mover(braco.base, 90) # Volta ao centro
    sleep(1)

    print("Testando Cotovelo (45 a 135)...")
    braco.mover(braco.cotovelo, 45)
    sleep(2)
    braco.mover(braco.cotovelo, 135)
    sleep(2)
    braco.mover(braco.cotovelo, 90) # Volta ao centro
    sleep(1)
    
    print("Testando Pulso...")
    braco.mover(braco.pulso, 0)
    sleep(2)
    braco.mover(braco.pulso, 180)
    sleep(2)
    braco.mover(braco.pulso, 90) # Volta ao centro
    sleep(1)
    
    print("Testando 'Cos'...")
    braco.mover(braco.cos, 45)
    sleep(2)
    braco.mover(braco.cos, 135)
    sleep(2)
    braco.mover(braco.cos, 90) # Volta ao centro
    sleep(1)
    
    print("Teste concluído!")

except KeyboardInterrupt:
    print("\nTeste interrompido.")

finally:
    # 3. Bloco de segurança:
    # Garante que os servos parem de tentar se mover
    if 'braco' in locals():
        braco.parar_todos()
    print("Script finalizado.")
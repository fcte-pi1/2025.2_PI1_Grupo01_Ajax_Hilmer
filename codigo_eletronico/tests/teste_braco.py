# --- trim_servo.py (Atualizado) ---
# Coloca os servos em posições iniciais para trimar/montar.

from time import sleep
from lib.servo_control import ServoControl
import config

print("Iniciando ferramenta de trimagem de servos...")

try:
    # 1. Inicializa o controlador
    braco = ServoControl(
        pin_base=config.PIN_SERVO_BASE,
        pin_cotovelo=config.PIN_SERVO_COTOVELO,
        pin_pulso=config.PIN_SERVO_PULSO,
        pin_cos=config.PIN_SERVO_COS
    )

    # 2. Define a posição inicial conhecida (sem suavização)
    #    Isso é crucial para que os movimentos suaves saibam de onde partir.
    #    90 graus é o "centro" padrão para a maioria dos servos.
    pose_inicial = {
        "base": 90,
        "cotovelo": 80,
        "pulso": 180,
        "cos": 70  # Ajuste 'cos' (garra) para uma posição aberta
    }
    braco.posicionar_inicial(pose_inicial, espera_ms=1000)

    print("\nBraço posicionado no centro (90°).")
    print("Agora você pode montar fisicamente os 'horns' dos servos.")
    print("---------------------------------------------------------")
    print("Pressione Ctrl+C quando terminar a montagem.")

    # Mantém a posição
    while True:
        sleep(1)

except KeyboardInterrupt:
    print("\nTrimagem finalizada.")

finally:
    # Garante que os servos sejam desligados ao sair
    if 'braco' in locals():
        braco.parar_todos()
    print("Servos desligados com segurança.")

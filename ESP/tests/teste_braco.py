# --- teste_braco.py ---
# Rotina coreografada para pegar o ovo com movimentos suaves
# e retornar à posição inicial.

from time import sleep
from lib.servo_control import ServoControl
import config

# --- 1. Definição das Poses e Ângulos (AJUSTE AQUI) ---

# Posição inicial (estacionado, garra aberta)
# (base: 90, cotovelo: 90, pulso: 180, cos: 70)
POS_INICIAL = {'base': 90, 'cotovelo': 80, 'pulso': 180, 'cos': 60}

# Posição 2: Desce o braço (base e cotovelo)
ANGULO_BASE_DESCIDA = 45
ANGULO_COTOVELO_DESCIDA = 60
DURACAO_DESCIDA_MS = 2500    # 2.5 segundos

# Posição 3: Gira o pulso
ANGULO_PULSO_CENTRO = 40
DURACAO_PULSO_MS = 1500

# Posição 4: Fecha a garra (cos)
ANGULO_GARRA_FECHADA = 70
DURACAO_GARRA_MS = 2000

# --- Fim dos Ajustes ---


# Define as poses completas com base nos ângulos
POS_DESCER = {
    'base': ANGULO_BASE_DESCIDA,
    'cotovelo': ANGULO_COTOVELO_DESCIDA,
    'pulso': POS_INICIAL['pulso'], # Mantém o pulso
    'cos': POS_INICIAL['cos']      # Mantém a garra
}

braco = None
try:
    # Inicializa o controlador
    braco = ServoControl(
        pin_base=config.PIN_SERVO_BASE,
        pin_cotovelo=config.PIN_SERVO_COTOVELO,
        pin_pulso=config.PIN_SERVO_PULSO,
        pin_cos=config.PIN_SERVO_COS
    )
    
    # --- 2. Execução da Rotina ---

    # PASSO 1: Define a posição inicial conhecida (obrigatório)
    braco.posicionar_inicial(POS_INICIAL, espera_ms=1000)
    print("Braço em posição inicial. Pressione Ctrl+C para parar.")
    sleep(0.5)

    print("\n--- ROTINA CONCLUÍDA ---")


except KeyboardInterrupt:
    print("\nRotina interrompida pelo usuário.")
except Exception as e:
    print(f"\nErro fatal na rotina: {e}")

finally:
    if braco:
        print("Desligando servos...")
        #braco.parar_todos()
    print("Fim.")

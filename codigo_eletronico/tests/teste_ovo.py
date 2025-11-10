# --- rotina_pegar_ovo.py ---
# Rotina coreografada para pegar o ovo com movimentos suaves
# e retornar à posição inicial.

from time import sleep
from lib.servo_control import ServoControl
import config

print("Iniciando rotina 'Pegar Ovo'...")

# --- 1. Definição das Poses e Ângulos (AJUSTE AQUI) ---

# Posição inicial (estacionado, garra aberta)
# (base: 90, cotovelo: 90, pulso: 180, cos: 70)
POS_INICIAL = {'base': 90, 'cotovelo': 80, 'pulso': 180, 'cos': 70}

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
    sleep(2)

    # PASSO 2: "descer um pouco a base e o cotovelo se manter correlato"
    print(f"Movendo para: Base={ANGULO_BASE_DESCIDA}, Cotovelo={ANGULO_COTOVELO_DESCIDA}")
    braco.mover_pose_suave(POS_DESCER, duracao_ms=DURACAO_DESCIDA_MS)
    sleep(1.5)

    # PASSO 3: "depois o pulso fica 90"
    print(f"Movendo Pulso para: {ANGULO_PULSO_CENTRO}")
    braco.mover_suave_para("pulso", ANGULO_PULSO_CENTRO, duracao_ms=DURACAO_PULSO_MS)
    sleep(1.5)

    # PASSO 4: "e o cos desce" (fecha a garra)
    print(f"Fechando Garra (Cos) para: {ANGULO_GARRA_FECHADA}")
    braco.mover_suave_para("cos", ANGULO_GARRA_FECHADA, duracao_ms=DURACAO_GARRA_MS)
    sleep(1.0)
    
    print("\n--- OVO CAPTURADO ---")
    print("Segurando por 3 segundos...")
    sleep(3.0) # Espera 3 segundos segurando o ovo

    # PASSO 5: Retorna à posição inicial
    print("Retornando para a posição inicial (segurando o ovo)...")
    # Nota: A garra (cos) ainda está fechada. A POS_INICIAL manda abrir.
    braco.mover_pose_suave(POS_INICIAL, duracao_ms=DURACAO_DESCIDA_MS)
    sleep(1.0)

    print("\n--- ROTINA CONCLUÍDA ---")


except KeyboardInterrupt:
    print("\nRotina interrompida pelo usuário.")
except Exception as e:
    print(f"\nErro fatal na rotina: {e}")

finally:
    if braco:
        print("Desligando servos...")
        braco.parar_todos()
    print("Fim.")

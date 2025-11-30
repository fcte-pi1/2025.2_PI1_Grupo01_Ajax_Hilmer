# --- controle_braco.py ---
# Módulo que define poses e rotinas de movimento para o braço robótico.

from time import sleep
from lib.servo_control import ServoControl
import config

# --- 1. Definição das Poses e Ângulos (AJUSTE AQUI) ---

# Posição inicial (estacionado, garra aberta)
POS_INICIAL = {'base': 90, 'cotovelo': 80, 'pulso': 180, 'cos': 60}

# Posição 2: Desce o braço (base e cotovelo)
ANGULO_BASE_DESCIDA = 45
ANGULO_COTOVELO_DESCIDA = 70
DURACAO_DESCIDA_MS = 2500

# Posição 3: Gira o pulso para pegar o ovo
ANGULO_PULSO_CENTRO = 40
DURACAO_PULSO_MS = 1500

# Posição 4: Fecha a garra (cos)
ANGULO_GARRA_FECHADA = 70
DURACAO_GARRA_MS = 2000

# Define a pose de descida
POS_DESCER = {
    'base': ANGULO_BASE_DESCIDA,
    'cotovelo': ANGULO_COTOVELO_DESCIDA,
    'pulso': POS_INICIAL['pulso'], 
    'cos': POS_INICIAL['cos']      
}

# --- 2. Funções de Setup e Controle ---

def setup_e_posicao_inicial():
    """
    Inicializa o controlador de servo e move o braço para a Posição Inicial.

    Retorna o objeto ServoControl (braco) se a inicialização for bem-sucedida, 
    ou None em caso de erro.
    """
    try:
        # Inicializa o controlador
        braco = ServoControl(
            pin_base=config.PIN_SERVO_BASE,
            pin_cotovelo=config.PIN_SERVO_COTOVELO,
            pin_pulso=config.PIN_SERVO_PULSO,
            pin_cos=config.PIN_SERVO_COS
        )
        
        # Define a posição inicial conhecida
        braco.posicionar_inicial(POS_INICIAL, espera_ms=1000)
        print("✅ Braço em posição inicial.")
        sleep(1)
        
        return braco
    
    except Exception as e:
        print(f"❌ Erro ao inicializar ou posicionar o braço: {e}")
        return None

def desligar_servos(braco):
    """Desliga todos os servos e finaliza o objeto ServoControl."""
    if braco:
        print("Desligando servos do braço...")
        braco.parar_todos()

# --- 3. Rotinas Coreografadas do Braço ---

def rotina_pegar_ovo(braco):
    """
    Executa a sequência de movimentos para descer, fechar a garra e subir com o objeto.
    """
    print("\n--- INICIANDO ROTINA: PEGAR OVO ---")
    
    # PASSO 1: Descer Base e Cotovelo
    print(f"Movendo para: Base={ANGULO_BASE_DESCIDA}, Cotovelo={ANGULO_COTOVELO_DESCIDA}")
    braco.mover_pose_suave(POS_DESCER, duracao_ms=DURACAO_DESCIDA_MS)
    sleep(DURACAO_DESCIDA_MS / 1000.0)

    # PASSO 2: Girar o Pulso
    print(f"Movendo Pulso para: {ANGULO_PULSO_CENTRO}")
    braco.mover_suave_para("pulso", ANGULO_PULSO_CENTRO, duracao_ms=DURACAO_PULSO_MS)
    sleep(DURACAO_PULSO_MS / 1000.0)

    # PASSO 3: Fechar a garra (Cos)
    print(f"Fechando Garra (Cos) para: {ANGULO_GARRA_FECHADA}")
    braco.mover_suave_para("cos", ANGULO_GARRA_FECHADA, duracao_ms=DURACAO_GARRA_MS)
    sleep(DURACAO_GARRA_MS / 1000.0)
    
    # PASSO 4: Retorna para a posição alta (segurando o ovo)
    POS_SUBIR = POS_INICIAL.copy()
    POS_SUBIR['cos'] = ANGULO_GARRA_FECHADA # Garante que a garra permaneça fechada
    print("Retornando para a posição alta (segurando o ovo)...")
    braco.mover_pose_suave(POS_SUBIR, duracao_ms=DURACAO_DESCIDA_MS)
    sleep(DURACAO_DESCIDA_MS / 1000.0)
    
    print("--- OVO CAPTURADO e Braço Elevado ---")


def rotina_entregar_ovo(braco):
    """
    Abre a garra para liberar o ovo.
    """
    print("\n--- INICIANDO ROTINA: ENTREGAR OVO ---")

    # Move a garra (cos) para o ângulo aberto inicial
    DURACAO_ENTREGA_MS = 1000
    ANGULO_GARRA_ABERTA = POS_INICIAL['cos'] # Usa o ângulo inicial (aberto)
    
    print(f"Abrindo Garra (Cos) para liberar o ovo: {ANGULO_GARRA_ABERTA}")
    braco.mover_suave_para("cos", ANGULO_GARRA_ABERTA, duracao_ms=DURACAO_ENTREGA_MS)
    sleep(DURACAO_ENTREGA_MS / 1000.0)
    
    print("Ovo entregue.")
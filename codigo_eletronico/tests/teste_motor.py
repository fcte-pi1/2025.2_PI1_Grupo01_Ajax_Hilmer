# --- main.py ---
# Script para testar a classe MotorControl

from time import sleep
from lib.motor_control import MotorControl # Importa sua classe
import config # Importa suas configurações

# Tempo de pausa entre os movimentos (em segundos)
TEMPO_PAUSA = 1.5
TEMPO_GIRO = 0.87 # TEMPO DE ROTAÇÃO ESTIMADO EM 90 GRAUS
TEMPO_ADICIONAL = 0.193 # TEMPO DE GIRO ADICIONAL (o carrinho quando vira para a direita, faz uma curva a mais, esse tempo ajuda ele a se permanecer reto)
print("Iniciando o teste dos motores...")

try:
    # 1. Instancia a classe de controle dos motores
    # Passa os pinos definidos no arquivo config.py
    motores = MotorControl(
        pin_re_avante=config.PIN_RE_AVANTE,
        pin_re_re=config.PIN_RE_RE,
        pin_rd_avante=config.PIN_RD_AVANTE,
        pin_rd_re=config.PIN_RD_RE
    )

    # 2. Executa a sequência de testes
    
    print(f"Virando à ESQUERDA por {TEMPO_GIRO}s...")
    motores.esquerda()
    sleep(TEMPO_GIRO)
    motores.parar()
    sleep(2)

    print(f"Movendo para FRENTE por {TEMPO_PAUSA}s...")
    motores.frente()
    sleep(TEMPO_PAUSA)
    motores.parar()
    sleep(2)
    
    print(f"Virando à ESQUERDA por {TEMPO_GIRO}s...")
    motores.esquerda()
    sleep(TEMPO_GIRO)
    motores.parar()
    sleep(2)

    print(f"Movendo para FRENTE por {TEMPO_PAUSA}s...")
    motores.frente()
    sleep(TEMPO_PAUSA)
    motores.parar()
    sleep(2)
    
    print(f"Virando à DIREITA por {TEMPO_GIRO + TEMPO_ADICIONAL}s...")
    motores.direita()
    sleep(TEMPO_GIRO + TEMPO_ADICIONAL)
    motores.parar()
    sleep(2)
    
    print(f"Virando à ESQUERDA por {TEMPO_ADICIONAL}s...")
    motores.esquerda()
    sleep(TEMPO_ADICIONAL)
    motores.parar()
    sleep(2)
    
    print(f"Movendo para FRENTE por {TEMPO_PAUSA}s...")
    motores.frente()
    sleep(TEMPO_PAUSA)
    motores.parar()
    sleep(2)

    print("Teste concluído com sucesso!")

except KeyboardInterrupt:
    # Caso o usuário interrompa o script
    print("\nTeste interrompido pelo usuário.")

finally:
    # 3. Bloco de segurança:
    # Garante que os motores parem
    # independentemente do que aconteça.
    print("Parando todos os motores.")
    # Precisamos instanciar de novo caso o erro tenha sido no __init__
    # Mas para este teste simples, podemos apenas chamar o parar
    # Se 'motores' foi definido antes do erro:
    if 'motores' in locals():
        motores.parar()
    else:
        # Se falhou antes de criar o objeto, apenas informa
        print("Objeto 'motores' não foi inicializado.") 


# Adicione esta função ao seu arquivo principal (app_principal.py)

def executar_percurso_carrinho():
    """
    Inicializa o MotorControl e executa o percurso do carrinho.
    """
    print("\n--- INICIANDO ROTINA DO CARRINHO ---")
    
    # Inicializa motores (MotorControl deve estar importado)
    motores = MotorControl(
        pin_re_avante=config.PIN_RE_AVANTE,
        pin_re_re=config.PIN_RE_RE,
        pin_rd_avante=config.PIN_RD_AVANTE,
        pin_rd_re=config.PIN_RD_RE
    )
    
    # Parâmetros de Movimento
    compensar = -0.29  # Compensação
    tempo_movimento = 3 # Duração do movimento (segundos)
    
    try:
        print(f"Movendo para frente com compensação de {compensar} por {tempo_movimento} segundos...")
        motores.frente(compensar=compensar)
        sleep(tempo_movimento)
        
    except KeyboardInterrupt:
        print("\nPercurso do carrinho interrompido pelo usuário.")
    except Exception as e:
        print(f"\nErro no percurso do carrinho: {e}")
        
    finally:
        print("Parando motores.")
        motores.parar()
    
    print("--- ROTINA DO CARRINHO CONCLUÍDA ---")
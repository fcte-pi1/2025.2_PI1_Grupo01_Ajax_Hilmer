# --- teste_corrente.py ---
# Teste para o sensor INA219 usando o config.py

from machine import Pin, I2C
from time import sleep

# 1. IMPORTA AS CONFIGURAÇÕES
#    Isso traz todas as variáveis do seu config.py (PIN_I2C_SCL, INA219_ADDR, etc.)
from config import * # 2. IMPORTA A BIBLIOTECA
#    Isso assume que 'ina219.py' está na mesma pasta (raiz)
from ina219 import INA219

# Opcional: Define o ID do barramento I2C
I2C_BUS_ID = 0 

def init_ina219():
    """Inicializa o barramento I2C e o sensor INA219 usando config.py."""
    
    # 1. Inicializa o I2C com os pinos do config.py
    try:
        # Usa as variáveis importadas diretamente
        i2c = I2C(I2C_BUS_ID, scl=Pin(PIN_I2C_SCL), sda=Pin(PIN_I2C_SDA))
        
        # 2. Inicializa o objeto INA219
        #    Não precisamos mais do i2c.scan() aqui, pois já confirmamos que funciona.
        ina = INA219(i2c, addr=INA219_ADDR)  
        
        # A biblioteca que você está usando chama set_calibration_32V_2A() por padrão.
        # Isso é perfeito para sua bateria de 7.4V.
        print("✅ INA219 inicializado com sucesso.")
        return ina
    
    except Exception as e:
        print(f"❌ Erro ao inicializar I2C/INA219: {e}")
        return None

# --- Loop Principal ---
ina = init_ina219()

if ina:
    print("\n--- INICIANDO LEITURAS DA BATERIA ---")
    
    try:
        while True:
            # Lê todos os valores
            bus_voltage = ina.bus_voltage # Tensão (V)
            current_mA = ina.current      # Corrente (mA)
            power_mW = ina.power          # Potência (mW)

            # Imprime os valores formatados
            print(f"Tensão: {bus_voltage:6.3f} V | Corrente: {current_mA:6.3f} mA | Potência: {power_mW:6.3f} mW")
            sleep(1)

    except KeyboardInterrupt:
        print("\nLeitura interrompida pelo usuário.")
    
    except Exception as e:
        print(f"Ocorreu um erro durante a leitura: {e}")

else:
    print("Não foi possível iniciar as leituras. Verifique o sensor.")

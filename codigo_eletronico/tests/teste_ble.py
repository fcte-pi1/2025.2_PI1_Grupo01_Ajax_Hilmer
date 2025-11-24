# --- teste_ble.py ---
# Script para testar a classe BLEManager

import ubluetooth
import time
import config # Importa seu config.py

# Tenta importar a biblioteca
try:
    from lib.ble_manager import BLEManager
except ImportError:
    print("ERRO: Não encontrou o arquivo 'lib/ble_manager.py'")
    raise

print("--- Iniciando Teste BLE ---")

# --- 1. AVISO IMPORTANTE SOBRE UUIDs ---
if "gerar" in config.BLE_SERVICE_UUID:
    print("="*40)
    print("⚠️ ATENÇÃO: Seus UUIDs em 'config.py' não foram gerados!")
    print("   Use um site como 'uuidgenerator.net' para criar UUIDs reais.")
    print("   O teste pode falhar com UUIDs inválidos.")
    print("="*40)
    time.sleep(3)

# --- 2. Função de Callback ---
def on_command_received(command):
    """Esta função é chamada pela BLEManager quando um comando chega."""
    print(f"\n*** COMANDO RECEBIDO: '{command}' ***")
    
    # Lógica de comando simples
    if command.upper() == "LED_ON":
        print("Simulando: Ligar LED")
        # (Aqui você colocaria o código real, ex: led_pin.on())
    elif command.upper() == "LED_OFF":
        print("Simulando: Desligar LED")
        # (ex: led_pin.off())
    elif command.upper() == "PING":
        print("Enviando resposta: PONG")
        ble_manager.send_data({"resposta": "PONG"})
    else:
        print("Comando desconhecido.")

# --- 3. Inicialização e Loop Principal ---
ble_manager = None
try:
    ble_hw = ubluetooth.BLE()
    
    ble_manager = BLEManager(
        ble_hw,
        name=config.BLE_NAME,
        service_uuid=config.BLE_SERVICE_UUID,
        cmd_uuid=config.BLE_CMD_UUID,
        data_uuid=config.BLE_DATA_UUID
    )
    
    # Registra a função de callback
    ble_manager.command_handler_callback = on_command_received
    
    print("\nBLE Manager inicializado. Aguardando conexões...")
    print("Use um app (como 'nRF Connect' ou 'LightBlue') para se conectar.")

    # Loop principal - simula o envio de dados (Notify)
    counter = 0
    while True:
        # Simula o envio de dados de sensores a cada 5 segundos
        dados_para_enviar = {
            "bat": 7.4, # (Aqui você chamaria o ina219.voltage())
            "count": counter
        }
        
        print(f"Enviando dados (via Notify): {dados_para_enviar}")
        ble_manager.send_data(dados_para_enviar)
        
        counter += 1
        time.sleep(5)

except KeyboardInterrupt:
    print("Teste interrompido.")
    if ble_manager:
        ble_manager._ble.gap_advertise(None) # Para de anunciar
except Exception as e:
    print(f"Erro fatal: {e}")

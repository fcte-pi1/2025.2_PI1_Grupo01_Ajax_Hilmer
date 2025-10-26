# --- config.py ---
# Arquivo central de configuração de pinos e IDs do projeto.

# L298N (Motores)
PIN_RE_AVANTE = 12 # Roda Esquerda - Avante
PIN_RE_RE = 13     # Roda Esquerda - Ré
PIN_RD_AVANTE = 14 # Roda Direita - Avante
PIN_RD_RE = 15     # Roda Direita - Ré

# Servos (Braço Robótico)
PIN_SERVO_A_BASE = 2
PIN_SERVO_B_ELBOW = 4
PIN_SERVO_C_CESTO = 5
PIN_SERVO_D_CESTO = 18
PIN_SERVO_E_CESTO = 19

# I2C (Para o INA219)
I2C_BUS_ID = 0
PIN_I2C_SCL = 22
PIN_I2C_SDA = 21
INA219_ADDR = 0x40 # Endereço I2C do INA219

# HC-SR04 (Sensor de Distância)
PIN_TRIG = 26
PIN_ECHO = 25

# LM393 (Sensores de Linha)
PIN_LM393_L = 34 # Sensor Esquerdo
PIN_LM393_R = 35 # Sensor Direito

# Configurações do Bluetooth (BLE)
BLE_NAME = "ESP32-Carrinho"
# UUIDs (Use um gerador de UUID online para criar os seus)
BLE_SERVICE_UUID = "gerar"
BLE_CMD_UUID = "gerar" # Característica de "Comando" (Write)
BLE_DATA_UUID = "gerar" # Característica de "Dados" (Notify)
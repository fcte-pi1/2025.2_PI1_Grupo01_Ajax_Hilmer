# --- config.py ---
# Arquivo central de configuração de pinos e IDs do projeto.

# L298N (Motores)
PIN_RE_AVANTE = 14 # Roda Esquerda - Avante
PIN_RE_RE = 27     # Roda Esquerda - Ré
PIN_RD_AVANTE = 17 # Roda Direita - Avante
PIN_RD_RE = 16     # Roda Direita - Ré

# Servos (Braço Robótico)
PIN_SERVO_BASE     = 4
PIN_SERVO_COTOVELO = 5
PIN_SERVO_PULSO    = 23
PIN_SERVO_COS      = 13

# I2C (Para o INA219)
PIN_I2C_SCL = 22
PIN_I2C_SDA = 21
INA219_ADDR = 0x40 # Endereço I2C do INA219

# HC-SR04 (Sensor de Distância)
PIN_TRIG = 25
PIN_ECHO = 26

# LM393 (Sensores de Linha)
PIN_LM393_L = 34 # Sensor Esquerdo
PIN_LM393_R = 35 # Sensor Direito

# Configurações do Bluetooth (BLE)
BLE_NAME = "ESP32-Carrinho"
# UUIDs atualizados
BLE_SERVICE_UUID = "bbe292b4-7f84-4b15-a6c3-3595809838bd"
BLE_CMD_UUID = "58d79e09-6c87-4790-8ca5-54842887f8e2" # Característica de "Comando" (Write)
BLE_DATA_UUID = "9b3832d6-fc81-4c6a-ac26-9ec7bf3d2814" # Característica de "Dados" (Notify)

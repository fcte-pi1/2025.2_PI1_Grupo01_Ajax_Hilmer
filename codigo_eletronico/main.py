# --- main.py ---
# Orquestra todos os módulos de hardware e a lógica de controle.

import uasyncio
import ubluetooth
from machine import Pin, I2C

# Importa todas as nossas configurações e classes
import config
from lib.motor_control import MotorControl
from lib.servo_control import ServoControl
from lib.sensors import HCSRO4, LineFollower
from lib.ina219 import INA219 # Lembre-se de usar a biblioteca real
from lib.ble_manager import BLEManager

# Fila global de comandos (preenchida pela interrupção do BLE)
command_queue = []

def handle_ble_command(command):
    """ Callback chamada pelo BLEManager quando um comando chega. """
    print(f"Comando recebido: {command}")
    command_queue.append(command)

async def main_control_loop(ble_manager, motors, hardware):
    """ Loop principal assíncrono para controle e leitura de sensores. """
    print("Loop de controle iniciado. Aguardando conexão BLE...")
    
    while True:
        # --- 1. Processar Comandos da Fila ---
        if command_queue:
            cmd = command_queue.pop(0).upper()
            
            if cmd == 'FRENTE':
                motors.frente()
            elif cmd == 'TRAS':
                motors.tras()
            elif cmd == 'ESQUERDA':
                motors.esquerda()
            elif cmd == 'DIREITA':
                motors.direita()
            elif cmd == 'PARAR':
                motors.parar()
            elif cmd.startswith('SERVO_'): # Comando: "SERVO_A:90"
                try:
                    parts = cmd.split(':')
                    servo_id = parts[0] 
                    angle = int(parts[1]) 

                    if servo_id == 'SERVO_A':
                        await hardware['servo_a'].move_to_angle(angle)
                    elif servo_id == 'SERVO_B':
                        await hardware['servo_b'].move_to_angle(angle)
                    elif servo_id == 'SERVO_C':
                        await hardware['servo_c'].move_to_angle(angle)
                    elif servo_id == 'SERVO_D':
                        await hardware['servo_d'].move_to_angle(angle)
                    elif servo_id == 'SERVO_E':
                        await hardware['servo_e'].move_to_angle(angle)
                except Exception:
                    print("Comando servo inválido")                    

        # --- 2. Ler Todos os Sensores ---
        distance = hardware['hc_sr04'].get_distance_cm()
        voltage = hardware['ina219'].get_voltage()
        current = hardware['ina219'].get_current_ma()
        line_l, line_r = hardware['line'].read()

        # --- 3. Lógica Autônoma (Exemplo) ---
        if distance != -1 and distance < 10: # A 10cm de um obstáculo
            motors.parar()
            print(f"Obstáculo detectado! {distance} cm. Parando.")

        # --- 4. Enviar Dados de Volta via BLE ---
        data_to_send = {
            'dist': round(distance, 1),
            'volt': round(voltage, 2),
            'curr': round(current, 0),
            'line_l': line_l,
            'line_r': line_r
        }
        ble_manager.send_data(data_to_send)

        # Pausa assíncrona para permitir que outras tarefas (como o BLE) rodem
        await uasyncio.sleep_ms(100) # Loop roda ~10x por segundo

async def main():
    """ Função principal de inicialização do hardware. """
    print("Inicializando hardware...")
    
    # 1. Inicializar I2C
    i2c = I2C(config.I2C_BUS_ID, scl=Pin(config.PIN_I2C_SCL), sda=Pin(config.PIN_I2C_SDA))

    # 2. Inicializar Motores
    motors = MotorControl(config.PIN_RE_AVANTE, 
                          config.PIN_RE_RE, 
                          config.PIN_RD_AVANTE, 
                          config.PIN_RD_RE)

    # 3. Inicializar outros hardwares (sensores, servos)
    hardware = {
        'servo_a': ServoControl(config.PIN_SERVO_A_BASE),
        'servo_b': ServoControl(config.PIN_SERVO_B_ELBOW),
        'servo_c': ServoControl(config.PIN_SERVO_C_CESTO),
        'servo_d': ServoControl(config.PIN_SERVO_D_CESTO),
        'servo_e': ServoControl(config.PIN_SERVO_E_CESTO),
        'ina219': INA219(i2c, config.INA219_ADDR),
        'hc_sr04': HCSRO4(config.PIN_TRIG, config.PIN_ECHO),
        'line': LineFollower(config.PIN_LM393_L, config.PIN_LM393_R)
    }
    
    # (Opcional) Tentar configurar o INA219 (se a biblioteca real tiver)
    try:
        hardware['ina219'].configure()
    except AttributeError:
        pass # Ignora se for a biblioteca simulada
    
    # Posição inicial dos servos
    hardware['servo_a'].set_angle(90)
    hardware['servo_b'].set_angle(90)
    hardware['servo_c'].set_angle(90)
    hardware['servo_d'].set_angle(90)
    hardware['servo_e'].set_angle(90)

    # 4. Inicializar BLE
    ble = ubluetooth.BLE()
    ble_manager = BLEManager(ble, 
                             config.BLE_NAME, 
                             config.BLE_SERVICE_UUID, 
                             config.BLE_CMD_UUID, 
                             config.BLE_DATA_UUID)
    
    ble_manager.command_handler_callback = handle_ble_command # Conecta a callback

    # 5. Iniciar o loop principal
    try:
        await main_control_loop(ble_manager, motors, hardware)
    except Exception as e:
        print(f"Erro fatal no loop principal: {e}")
    finally:
        motors.parar()
        ble.active(False)

# Ponto de entrada do programa
if __name__ == "__main__":
    try:
        uasyncio.run(main())
    except KeyboardInterrupt:
        print("Programa interrompido")
# --- lib/ble_manager.py ---
# Classe dedicada para gerenciar toda a lógica de conexão e comunicação Bluetooth.
# (Versão corrigida para compatibilidade com firmware mais antigo - usa binascii)

import ubluetooth
import binascii # <-- ADICIONADO: Módulo para converter Hex para Bytes

_IRQ_CENTRAL_CONNECT = 1
_IRQ_CENTRAL_DISCONNECT = 2
_IRQ_GATTS_WRITE = 3

class BLEManager:
    def __init__(self, ble, name, service_uuid, cmd_uuid, data_uuid):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)

        # Guarda as strings de UUID (do config.py)
        self._service_uuid_str = service_uuid
        
        # Cria os objetos UUID para o GATT Server
        self._service_uuid = ubluetooth.UUID(self._service_uuid_str)
        self._char_cmd_uuid = ubluetooth.UUID(cmd_uuid)
        self._char_data_uuid = ubluetooth.UUID(data_uuid)
        
        # Define o serviço e as características
        ((self._handle_cmd, self._handle_data),) = self._ble.gatts_register_services(
            (
                (
                    self._service_uuid,
                    (
                        (self._char_cmd_uuid, ubluetooth.FLAG_WRITE),
                        (self._char_data_uuid, ubluetooth.FLAG_READ | ubluetooth.FLAG_NOTIFY),
                    ),
                ),
            )
        )
        
        self._connections = set()
        self._name = name
        
        # --- CORREÇÃO DEFINITIVA (Manual Payload com binascii) ---
        
        # 1. Cria o pacote de anúncio (Flags + Service UUID)
        adv_flags = b'\x02\x01\x06'
        
        # Converte a string UUID "bbe292b4-..." em 16 bytes brutos
        # a) Remove os hífens "-" da string
        uuid_string_no_dashes = self._service_uuid_str.replace('-', '')
        # b) Converte a string hexadecimal em bytes
        uuid_bytes = binascii.unhexlify(uuid_string_no_dashes)
        
        # Pacote 2: Service UUID (128-bit)
        adv_uuid = b'\x11\x07' + uuid_bytes
        
        self._adv_payload = adv_flags + adv_uuid
        
        # 2. Cria o pacote de resposta (Nome)
        name_bytes = name.encode('utf-8')
        self._resp_payload = bytes([len(name_bytes) + 1, 0x09]) + name_bytes
        # --- FIM DA CORREÇÃO ---
        
        self._advertise()
        self.command_handler_callback = None

    def _irq(self, event, data):
        # Gerencia conexões e comandos recebidos
        
        if event == _IRQ_CENTRAL_CONNECT:
            conn_handle, _, _ = data
            self._connections.add(conn_handle)
            print("BLE Conectado (Handle:", conn_handle, ")")
            self._ble.gap_advertise(None) # Para de anunciar

        elif event == _IRQ_CENTRAL_DISCONNECT:
            conn_handle, _, _ = data
            if conn_handle in self._connections:
                self._connections.discard(conn_handle)
            print("BLE Desconectado")
            self._advertise() # Volta a anunciar

        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            # Verifica se a escrita foi na característica de COMANDO
            if value_handle == self._handle_cmd:
                try:
                    command = self._ble.gatts_read(self._handle_cmd).decode('utf-8')
                    if self.command_handler_callback:
                        self.command_handler_callback(command) # Chama a função externa
                except Exception as e:
                    print(f"Erro ao ler comando: {e}")

    def _advertise(self, interval_us=500000):
        print(f"Iniciando anúncio BLE como '{self._name}'...")
        # Usa os dois pacotes (anúncio e resposta)
        self._ble.gap_advertise(interval_us, adv_data=self._adv_payload, resp_data=self._resp_payload)

    def send_data(self, data_dict):
        """Envia um dicionário de dados para todos os clientes conectados
           via Notificação BLE."""
        
        # Converte o dicionário em uma string (ex: "bat:7.4,temp:25")
        data_str = ",".join([f"{k}:{v}" for k, v in data_dict.items()])
        data_bytes = data_str.encode('utf-8')
        
        try:
            # 1. Escreve o valor localmente no GATT server
            self._ble.gatts_write(self._handle_data, data_bytes)
            
            # 2. Notifica todos os clientes conectados
            for conn_handle in self._connections:
                try:
                    self._ble.gatts_notify(conn_handle, self._handle_data)
                except OSError as e:
                    # Cliente pode ter desconectado de forma abrupta
                    pass 
        except OSError as e:
            # Buffer pode estar cheio ou sem conexões
            pass

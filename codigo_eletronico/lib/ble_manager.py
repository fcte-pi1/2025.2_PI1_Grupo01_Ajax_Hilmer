# --- lib/ble_manager.py A classe dedicada para gerenciar toda a lógica de conexão e comunicação Bluetooth.---
import ubluetooth
import struct

class BLEManager:
    def __init__(self, ble, name, service_uuid, cmd_uuid, data_uuid):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)

        # UUIDs
        self._service_uuid = ubluetooth.UUID(service_uuid)
        self._char_cmd_uuid = ubluetooth.UUID(cmd_uuid)
        self._char_data_uuid = ubluetooth.UUID(data_uuid)
        
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
        self._payload = ubluetooth.advertising_adv_data(
            name=name, services=[self._service_uuid]
        )
        self._advertise()
        self.command_handler_callback = None

    def _irq(self, event, data):
        if event == 1: # _IRQ_CENTRAL_CONNECT
            conn_handle, _, _ = data
            self._connections.add(conn_handle)
            print("BLE Conectado")
            self._ble.gap_advertise(None) # Parar de anunciar
        elif event == 2: # _IRQ_CENTRAL_DISCONNECT
            conn_handle, _, _ = data
            if conn_handle in self._connections:
                self._connections.remove(conn_handle)
            print("BLE Desconectado")
            self._advertise()
        elif event == 3: # _IRQ_GATTS_WRITE
            conn_handle, value_handle = data
            if value_handle == self._handle_cmd:
                command = self._ble.gatts_read(self._handle_cmd).decode('utf-8')
                if self.command_handler_callback:
                    self.command_handler_callback(command)

    def _advertise(self, interval_us=500000):
        print("Iniciando anúncio BLE...")
        self._ble.gap_advertise(interval_us, adv_data=self._payload)

    def send_data(self, data_dict):
        # Serializa dados. Ex: "dist:10.5,volt:5.1,curr:150"
        data_str = ",".join([f"{k}:{v}" for k, v in data_dict.items()])
        
        self._ble.gatts_write(self._handle_data, data_str.encode('utf-8'))
        for conn_handle in self._connections:
            self._ble.gatts_notify(conn_handle, self._handle_data)
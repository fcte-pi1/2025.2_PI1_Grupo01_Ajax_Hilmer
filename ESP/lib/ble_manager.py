# =============================================================================
# BLE MANAGER - VERSÃO 3 ULTRA OTIMIZADA
# =============================================================================
# Esta versão é AINDA MAIS otimizada para responder rapidamente às
# requisições de descoberta de serviços do app

import ubluetooth
import time

_IRQ_CENTRAL_CONNECT = 1
_IRQ_CENTRAL_DISCONNECT = 2
_IRQ_GATTS_WRITE = 3

# FLAGS para características BLE
_FLAG_READ = 0x0002
_FLAG_WRITE_NO_RESPONSE = 0x0004
_FLAG_WRITE = 0x0008
_FLAG_NOTIFY = 0x0010

class BLEManager:
    def __init__(self, ble, name, service_uuid, cmd_uuid, data_uuid):
        print("\n" + "="*60)
        print("🔧 BLE MANAGER V3 - ULTRA OTIMIZADO")
        print("="*60)
        
        self._ble = ble
        self._ble.active(False)  # Garante que está desligado
        time.sleep_ms(100)
        self._ble.active(True)   # Liga do zero
        time.sleep_ms(100)       # Aguarda estabilizar
        
        # Configura parâmetros de conexão para resposta rápida
        # mtu = Maximum Transmission Unit (maior = mais dados por vez)
        self._ble.config(mtu=247)  # Tamanho máximo suportado
        
        self._ble.irq(self._irq)
        
        # Guarda UUIDs
        self._service_uuid_str = service_uuid
        self._cmd_uuid_str = cmd_uuid
        self._data_uuid_str = data_uuid
        
        print(f"📋 UUIDs:")
        print(f"   Service: {service_uuid}")
        print(f"   CMD:     {cmd_uuid}")
        print(f"   DATA:    {data_uuid}")
        
        # Cria objetos UUID
        self._service_uuid = ubluetooth.UUID(service_uuid)
        self._char_cmd_uuid = ubluetooth.UUID(cmd_uuid)
        self._char_data_uuid = ubluetooth.UUID(data_uuid)
        
        print("\n🔨 Registrando serviços GATT...")
        
        # IMPORTANTE: Registra com FLAGS corretas
        # CMD: FLAG_WRITE + FLAG_WRITE_NO_RESPONSE (app pode escrever de ambas formas)
        # DATA: FLAG_READ | FLAG_NOTIFY (app lê e recebe notificações)
        try:
            ((self._handle_cmd, self._handle_data),) = self._ble.gatts_register_services((
                (
                    self._service_uuid,
                    (
                        # Característica de COMANDO (escrita COM e SEM resposta)
                        (self._char_cmd_uuid, _FLAG_WRITE | _FLAG_WRITE_NO_RESPONSE),
                        # Característica de DADOS (leitura + notificação)
                        (self._char_data_uuid, _FLAG_READ | _FLAG_NOTIFY),
                    ),
                ),
            ))
            
            print(f"✅ Serviços registrados!")
            print(f"   CMD Handle:  {self._handle_cmd}")
            print(f"   DATA Handle: {self._handle_data}")
            
        except Exception as e:
            print(f"❌ ERRO ao registrar serviços: {e}")
            raise
        
        self._connections = set()
        self._name = name
        
        # =========================================================================
        # ADVERTISEMENT PAYLOAD SUPER OTIMIZADO
        # =========================================================================
        print("\n📡 Criando advertisement payload...")
        
        # Limita nome rigorosamente
        name_bytes = name.encode('utf-8')[:15]
        
        # FLAGS + NOME
        adv_flags = b'\x02\x01\x06'
        adv_name = bytes([len(name_bytes) + 1, 0x09]) + name_bytes
        
        # UUID DO SERVIÇO (128-bit) no scan response
        uuid_hex = service_uuid.replace('-', '')
        uuid_bytes = bytes.fromhex(uuid_hex)
        uuid_bytes_le = bytes(reversed(uuid_bytes))
        adv_service_uuid = bytes([0x11, 0x07]) + uuid_bytes_le
        
        self._adv_payload = adv_flags + adv_name
        self._resp_payload = adv_service_uuid
        
        print(f"   ADV:  {len(self._adv_payload)} bytes")
        print(f"   RESP: {len(self._resp_payload)} bytes")
        
        self.command_handler_callback = None
        
        # LED
        try:
            from machine import Pin
            self.led = Pin(2, Pin.OUT)
            self.led.value(1)
        except:
            self.led = None
        
        print("\n✅ BLE MANAGER PRONTO!\n")
        self._advertise()

    def _irq(self, event, data):
        """Handler de eventos BLE - OTIMIZADO"""
        
        if event == _IRQ_CENTRAL_CONNECT:
            conn_handle, _, _ = data
            self._connections.add(conn_handle)
            
            print("\n" + "="*60)
            print(f"✅ CONECTADO! Handle: {conn_handle}")
            print("="*60 + "\n")
            
            # LED feedback
            if self.led:
                for _ in range(3):
                    self.led.value(0)
                    time.sleep_ms(100)
                    self.led.value(1)
                    time.sleep_ms(100)
            
            # Para advertisement
            self._ble.gap_advertise(None)

        elif event == _IRQ_CENTRAL_DISCONNECT:
            conn_handle, _, _ = data
            self._connections.discard(conn_handle)
            
            print("\n" + "="*60)
            print(f"❌ DESCONECTADO! Handle: {conn_handle}")
            print("="*60 + "\n")
            
            # Volta a anunciar
            self._advertise()

        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            
            if value_handle == self._handle_cmd:
                try:
                    # Lê comando imediatamente
                    command = self._ble.gatts_read(self._handle_cmd).decode('utf-8')
                    
                    print("\n" + "="*60)
                    print("📥 COMANDO RECEBIDO:")
                    print(f"   {command}")
                    print("="*60 + "\n")
                    
                    # Processa comando
                    if self.command_handler_callback:
                        self.command_handler_callback(command)
                    else:
                        print("⚠️ Sem callback registrado!")
                        
                except Exception as e:
                    print(f"❌ Erro ao processar: {e}")

    def _advertise(self, interval_us=500000):
        """Inicia advertisement BLE"""
        print(f"📡 Advertisement BLE ativo ('{self._name}')...")
        
        try:
            self._ble.gap_advertise(
                interval_us,
                adv_data=self._adv_payload,
                resp_data=self._resp_payload,
                connectable=True
            )
            print("✅ Dispositivo visível!\n")
        except Exception as e:
            print(f"❌ Erro: {e}")

    def send_data(self, data_dict):
        """Envia telemetria via notificação BLE"""
        
        if not self._connections:
            print("⚠️ Nenhum cliente conectado")
            return False
        
        try:
            import ujson
            data_json = ujson.dumps(data_dict)
            data_bytes = data_json.encode('utf-8')
            
            print(f"📤 Enviando: {data_json}")
            
            # Escreve no GATT
            self._ble.gatts_write(self._handle_data, data_bytes)
            
            # Notifica clientes
            success = 0
            for conn_handle in list(self._connections):
                try:
                    self._ble.gatts_notify(conn_handle, self._handle_data)
                    success += 1
                except OSError:
                    self._connections.discard(conn_handle)
            
            print(f"✅ Enviado para {success} cliente(s)\n")
            return success > 0
            
        except Exception as e:
            print(f"❌ Erro: {e}")
            return False
    
    def is_connected(self):
        """Retorna True se conectado"""
        return len(self._connections) > 0
    
    def stop(self):
        """Para BLE"""
        print("\n🛑 Parando BLE...")
        self._ble.gap_advertise(None)
        self._connections.clear()
        if self.led:
            self.led.value(0)
        print("✅ BLE parado\n")


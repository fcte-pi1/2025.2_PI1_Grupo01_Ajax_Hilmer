# =============================================================================
# WIFI MANAGER - ESP32 MICROPYTHON
# =============================================================================
# Servidor HTTP para comunicação WiFi com o app Flutter
# O ESP32 cria um Access Point (AP) e o celular conecta nele

import network
import socket
import json
import time
try:
    from machine import Pin
except:
    Pin = None


class WifiManager:
    """
    Gerenciador WiFi para ESP32
    Cria um Access Point e servidor HTTP para receber comandos do app
    """
    
    def __init__(self, ssid="Ajax_Carrinho", password="ajax1234", ip="192.168.4.1"):
        """
        Inicializa o WiFi Manager
        
        Args:
            ssid: Nome da rede WiFi (Access Point)
            password: Senha da rede (mínimo 8 caracteres)
            ip: IP fixo do ESP32
        """
        print("\n" + "="*60)
        print("📶 WIFI MANAGER - ESP32")
        print("="*60)
        
        self.ssid = ssid
        self.password = password
        self.ip = ip
        self.port = 80
        
        # Estado
        self.clients = set()
        self.is_running = False
        self.command_handler_callback = None
        self.last_telemetry = {}
        
        # LED de status
        self.led = None
        if Pin:
            try:
                self.led = Pin(2, Pin.OUT)
            except:
                pass
        
        # Configura o Access Point
        self._setup_ap()
        
    def _setup_ap(self):
        """Configura o Access Point WiFi"""
        print(f"\n📡 Configurando Access Point...")
        print(f"   SSID:     {self.ssid}")
        print(f"   Senha:    {self.password}")
        print(f"   IP:       {self.ip}")
        
        # Desativa modo station se ativo
        sta = network.WLAN(network.STA_IF)
        sta.active(False)
        
        # Configura Access Point
        self.ap = network.WLAN(network.AP_IF)
        self.ap.active(True)
        
        # Configura IP fixo
        self.ap.ifconfig((self.ip, '255.255.255.0', self.ip, '8.8.8.8'))
        
        # Configura SSID e senha
        self.ap.config(essid=self.ssid, password=self.password, authmode=network.AUTH_WPA2_PSK)
        
        # Aguarda ativar
        timeout = 10
        while not self.ap.active() and timeout > 0:
            time.sleep(0.5)
            timeout -= 1
        
        if self.ap.active():
            print(f"\n✅ Access Point ATIVO!")
            print(f"   IP: {self.ap.ifconfig()[0]}")
            if self.led:
                self.led.value(1)
        else:
            print("❌ Falha ao ativar Access Point!")
            raise RuntimeError("Falha ao iniciar WiFi AP")
    
    def start_server(self):
        """Inicia o servidor HTTP"""
        print(f"\n🌐 Iniciando servidor HTTP na porta {self.port}...")
        
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind(('', self.port))
        self.server_socket.listen(5)
        self.server_socket.setblocking(False)
        
        self.is_running = True
        
        print(f"✅ Servidor HTTP rodando!")
        print(f"\n" + "="*60)
        print("📱 INSTRUÇÕES PARA CONECTAR:")
        print("="*60)
        print(f"1. No celular, conecte à rede WiFi: {self.ssid}")
        print(f"2. Senha: {self.password}")
        print(f"3. Abra o app e selecione conexão WiFi")
        print(f"4. O app conectará automaticamente em {self.ip}")
        print("="*60 + "\n")
        
    def handle_requests(self):
        """
        Processa requisições HTTP pendentes
        Deve ser chamado em loop no programa principal
        """
        if not self.is_running:
            return
            
        try:
            # Aceita novas conexões
            try:
                client_socket, addr = self.server_socket.accept()
                client_socket.setblocking(False)
                self._handle_client(client_socket, addr)
            except OSError:
                pass  # Nenhuma conexão pendente
                
        except Exception as e:
            print(f"❌ Erro ao processar requisição: {e}")
    
    def _handle_client(self, client_socket, addr):
        """Processa uma requisição de cliente"""
        try:
            # Lê a requisição
            request = b""
            while True:
                try:
                    chunk = client_socket.recv(1024)
                    if not chunk:
                        break
                    request += chunk
                    if b"\r\n\r\n" in request:
                        break
                except OSError:
                    break
            
            if not request:
                client_socket.close()
                return
                
            request_str = request.decode('utf-8')
            
            # Parse da requisição
            lines = request_str.split('\r\n')
            method, path, _ = lines[0].split(' ', 2)
            
            print(f"\n📥 {method} {path} de {addr[0]}")
            
            # Extrai body se for POST
            body = ""
            if method == "POST":
                body_start = request_str.find('\r\n\r\n')
                if body_start != -1:
                    body = request_str[body_start + 4:]
            
            # Roteia para o handler correto
            response = self._route_request(method, path, body)
            
            # Envia resposta
            http_response = self._build_response(response)
            client_socket.send(http_response.encode('utf-8'))
            
        except Exception as e:
            print(f"❌ Erro ao processar cliente: {e}")
        finally:
            client_socket.close()
    
    def _route_request(self, method, path, body):
        """Roteia a requisição para o handler correto"""
        
        # GET /ping - Verifica conexão
        if path == "/ping" and method == "GET":
            return {
                "status": "ok",
                "name": "Ajax Carrinho",
                "version": "1.0",
                "uptime": time.ticks_ms() // 1000
            }
        
        # GET /telemetry - Retorna última telemetria
        if path == "/telemetry" and method == "GET":
            return self.last_telemetry if self.last_telemetry else {"status": "idle"}
        
        # POST /command - Recebe comandos
        if path == "/command" and method == "POST":
            return self._handle_command(body)
        
        # GET /status - Status geral
        if path == "/status" and method == "GET":
            return {
                "status": "ok",
                "wifi": {
                    "ssid": self.ssid,
                    "ip": self.ip,
                    "clients": len(self.ap.status('stations')) if hasattr(self.ap, 'status') else 0
                },
                "telemetry": self.last_telemetry
            }
        
        # 404 para rotas não encontradas
        return {"status": "error", "message": "Rota não encontrada"}
    
    def _handle_command(self, body):
        """Processa comando recebido do app"""
        try:
            data = json.loads(body) if body else {}
            command = data.get('command', '')
            
            if not command:
                return {"status": "error", "message": "Comando vazio"}
            
            print("\n" + "="*60)
            print("📥 COMANDO RECEBIDO:")
            print(f"   {command}")
            print("="*60)
            
            # LED feedback
            if self.led:
                for _ in range(3):
                    self.led.value(0)
                    time.sleep_ms(100)
                    self.led.value(1)
                    time.sleep_ms(100)
            
            # Chama callback se registrado
            if self.command_handler_callback:
                result = self.command_handler_callback(command)
                
                # Atualiza última telemetria se o callback retornou algo
                if isinstance(result, dict):
                    self.last_telemetry = result
                    return {"status": "ok", "telemetry": result}
            
            return {"status": "ok", "message": "Comando recebido"}
            
        except json.JSONDecodeError:
            return {"status": "error", "message": "JSON inválido"}
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def _build_response(self, data):
        """Constrói resposta HTTP"""
        body = json.dumps(data)
        return (
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: application/json\r\n"
            "Access-Control-Allow-Origin: *\r\n"
            "Connection: close\r\n"
            f"Content-Length: {len(body)}\r\n"
            "\r\n"
            f"{body}"
        )
    
    def send_telemetry(self, telemetry_dict):
        """
        Armazena telemetria para ser enviada na próxima requisição
        
        Args:
            telemetry_dict: Dicionário com dados de telemetria
        """
        self.last_telemetry = telemetry_dict
        self.last_telemetry['timestamp'] = time.ticks_ms()
        print(f"📊 Telemetria atualizada: {telemetry_dict}")
    
    def is_client_connected(self):
        """Verifica se há clientes conectados ao AP"""
        try:
            stations = self.ap.status('stations')
            return len(stations) > 0
        except:
            return False
    
    def stop(self):
        """Para o servidor e desativa o AP"""
        print("\n🛑 Parando servidor WiFi...")
        self.is_running = False
        
        try:
            self.server_socket.close()
        except:
            pass
        
        self.ap.active(False)
        
        if self.led:
            self.led.value(0)
            
        print("✅ Servidor WiFi parado")


# =============================================================================
# EXEMPLO DE USO
# =============================================================================
if __name__ == "__main__":
    def processar_comando(comando):
        """Callback para processar comandos"""
        print(f"Processando: {comando}")
        
        # Simula execução e retorna telemetria
        return {
            "status": "success",
            "message": "Comando executado!",
            "time": 5.0,
            "distance": 100
        }
    
    # Cria e inicia o servidor
    wifi = WifiManager(ssid="Ajax_Carrinho", password="ajax1234")
    wifi.command_handler_callback = processar_comando
    wifi.start_server()
    
    print("Servidor rodando... Pressione Ctrl+C para parar")
    
    try:
        while True:
            wifi.handle_requests()
            time.sleep_ms(10)
    except KeyboardInterrupt:
        wifi.stop()

# =============================================================================
# MAIN_STATION.PY - ESP32 CONECTA EM REDE WIFI EXISTENTE
# =============================================================================
# Modo alternativo: ESP32 conecta na rede WiFi do laboratório/casa
# Tanto o celular quanto o ESP32 ficam na mesma rede com internet
# 
# VANTAGEM: O celular mantém acesso à internet (pode sincronizar com API)
# DESVANTAGEM: Precisa configurar SSID e senha da rede local

import time
import sys
import network
sys.path.append('/lib')

print("\n\n" + "="*70)
print(" 🚗 CARRINHO AJAX - MODO STATION (REDE LOCAL)")
print("="*70)

# =============================================================================
# CONFIGURAÇÃO DA REDE WIFI LOCAL
# =============================================================================
# ALTERE AQUI para sua rede WiFi
WIFI_SSID = "LB"       # Nome da rede WiFi local
WIFI_PASSWORD = "Python54321"   # Senha da rede

print(f"\n📋 Configuração:")
print(f"   Rede: {WIFI_SSID}")

# =============================================================================
# IMPORTAÇÕES
# =============================================================================
from config import (
    PIN_RE_AVANTE, PIN_RE_RE, PIN_RD_AVANTE, PIN_RD_RE,
    PIN_I2C_SCL, PIN_I2C_SDA, INA219_ADDR
)

from lib.motor_control import MotorControl

# Tenta importar INA219
ina_sensor = None
try:
    from machine import I2C, Pin
    from lib.ina219 import INA219
    
    i2c = I2C(0, scl=Pin(PIN_I2C_SCL), sda=Pin(PIN_I2C_SDA))
    ina_sensor = INA219(i2c, INA219_ADDR)
    print("✅ Sensor INA219 inicializado!")
except Exception as e:
    print(f"⚠️ INA219 não disponível: {e}")

# Inicializa motores
try:
    motors = MotorControl(PIN_RE_AVANTE, PIN_RE_RE, PIN_RD_AVANTE, PIN_RD_RE)
    print("✅ Motores inicializados!")
except Exception as e:
    print(f"⚠️ Motores não disponíveis: {e}")
    motors = None

# Tenta importar e inicializar o braço robótico
braco = None
try:
    from lib.controle_braco import setup_e_posicao_inicial, rotina_entregar_ovo
    braco = setup_e_posicao_inicial()
    if braco:
        print("✅ Braço robótico inicializado!")
    else:
        print("⚠️ Braço robótico não pôde ser inicializado")
except Exception as e:
    print(f"⚠️ Braço robótico não disponível: {e}")

# Velocidade do carrinho
VELOCIDADE_CM_POR_SEGUNDO = 44.0
TEMPO_GIRO_90_GRAUS = 0.5

# =============================================================================
# CONEXÃO WIFI (MODO STATION)
# =============================================================================
def conectar_wifi():
    """Conecta na rede WiFi local"""
    print(f"\n📡 Conectando à rede {WIFI_SSID}...")
    
    # Desativa AP se estiver ativo
    ap = network.WLAN(network.AP_IF)
    ap.active(False)
    
    # Ativa Station
    sta = network.WLAN(network.STA_IF)
    sta.active(True)
    
    # Conecta
    sta.connect(WIFI_SSID, WIFI_PASSWORD)
    
    # Aguarda conexão
    timeout = 20
    while not sta.isconnected() and timeout > 0:
        print(".", end="")
        time.sleep(1)
        timeout -= 1
    
    if sta.isconnected():
        ip = sta.ifconfig()[0]
        print(f"\n✅ Conectado!")
        print(f"   IP: {ip}")
        return ip
    else:
        print(f"\n❌ Falha ao conectar na rede {WIFI_SSID}")
        return None

# =============================================================================
# FUNÇÕES (mesmas do main.py normal)
# =============================================================================
def ler_telemetria():
    if ina_sensor:
        try:
            return {
                "voltage": round(ina_sensor.bus_voltage, 2),
                "current": round(ina_sensor.current, 2),
                "power": round(ina_sensor.power, 2)
            }
        except:
            pass
    return {"voltage": 7.4, "current": 500.0, "power": 3700.0}

def parse_comandos(comando_str):
    comandos = []
    partes = comando_str.upper().split(',')
    
    for parte in partes:
        parte = parte.strip()
        if not parte:
            continue
        
        tokens = parte.split()
        
        if len(tokens) >= 3 and tokens[0] == "ANDAR":
            try:
                comandos.append(("ANDAR", int(tokens[1])))
            except:
                pass
                
        elif len(tokens) >= 4 and tokens[0] == "GIRAR":
            try:
                angulo = int(tokens[1])
                direcao = tokens[3] if len(tokens) > 3 else "DIREITA"
                if "ESQUERDA" in direcao:
                    comandos.append(("GIRAR_ESQUERDA", angulo))
                else:
                    comandos.append(("GIRAR_DIREITA", angulo))
            except:
                pass
                
        elif len(tokens) >= 2 and tokens[0] == "RE":
            try:
                comandos.append(("RE", int(tokens[1])))
            except:
                pass
    
    return comandos

def executar_comandos(comandos):
    print("\n🚗 EXECUTANDO ROTA")
    
    tempo_inicio = time.ticks_ms()
    distancia_total = 0
    amostras = []
    
    for acao, valor in comandos:
        tel = ler_telemetria()
        amostras.append(tel)
        
        if acao == "ANDAR":
            tempo = valor / VELOCIDADE_CM_POR_SEGUNDO
            if motors:
                motors.frente()
                time.sleep(tempo)
                motors.parar()
            else:
                time.sleep(tempo)
            distancia_total += valor
            
        elif acao == "RE":
            tempo = valor / VELOCIDADE_CM_POR_SEGUNDO
            if motors:
                motors.tras()
                time.sleep(tempo)
                motors.parar()
            else:
                time.sleep(tempo)
            distancia_total += valor
            
        elif acao == "GIRAR_DIREITA":
            tempo = (valor / 90.0) * TEMPO_GIRO_90_GRAUS
            if motors:
                motors.direita()
                time.sleep(tempo)
                motors.parar()
            else:
                time.sleep(tempo)
                
        elif acao == "GIRAR_ESQUERDA":
            tempo = (valor / 90.0) * TEMPO_GIRO_90_GRAUS
            if motors:
                motors.esquerda()
                time.sleep(tempo)
                motors.parar()
            else:
                time.sleep(tempo)
    
    if motors:
        motors.parar()
    
    tempo_total = time.ticks_diff(time.ticks_ms(), tempo_inicio) / 1000.0
    
    avg_v = sum(a["voltage"] for a in amostras) / len(amostras) if amostras else 0
    avg_c = sum(a["current"] for a in amostras) / len(amostras) if amostras else 0
    avg_p = sum(a["power"] for a in amostras) / len(amostras) if amostras else 0
    
    return {
        "status": "success",
        "message": "Rota executada!",
        "time": round(tempo_total, 2),
        "distance": distancia_total,
        "average_speed": round(distancia_total / tempo_total if tempo_total > 0 else 0, 2),
        "average_voltage": round(avg_v, 2),
        "average_current": round(avg_c, 2),
        "average_power": round(avg_p, 2),
        "commands_executed": len(comandos)
    }

def executar_entrega_ovo():
    """Executa a rotina de entrega do ovo usando o braço robótico"""
    print("\n🥚 EXECUTANDO ENTREGA DO OVO")
    
    if braco is None:
        print("⚠️ Braço robótico não disponível - simulando entrega")
        time.sleep(2)  # Simula tempo de entrega
        return {
            "status": "simulated",
            "message": "Entrega simulada (braço não disponível)"
        }
    
    try:
        rotina_entregar_ovo(braco)
        print("✅ Ovo entregue com sucesso!")
        return {
            "status": "success",
            "message": "Ovo entregue com sucesso!"
        }
    except Exception as e:
        print(f"❌ Erro na entrega: {e}")
        return {
            "status": "error",
            "message": f"Erro na entrega: {str(e)}"
        }

def processar_comando(comando):
    print(f"\n📥 Comando: {comando}")
    
    try:
        # FASE 1: Parsear e executar comandos de movimento
        comandos = parse_comandos(comando)
        if not comandos:
            return {"status": "error", "message": "Nenhum comando válido"}
        
        resultado_rota = executar_comandos(comandos)
        
        # FASE 2: Executar entrega do ovo
        resultado_entrega = executar_entrega_ovo()
        
        # FASE 3: Combinar resultados
        resultado_final = resultado_rota.copy()
        resultado_final["phase"] = "mission_complete"
        resultado_final["message"] = "Missão completa!"
        resultado_final["egg_delivery_status"] = resultado_entrega["status"]
        resultado_final["egg_delivery_message"] = resultado_entrega["message"]
        
        # Calcular energia consumida (Wh) = Potência média (W) * tempo (h)
        tempo_horas = resultado_rota["time"] / 3600.0
        energia_wh = resultado_rota.get("average_power", 0) * tempo_horas
        resultado_final["energy_consumed"] = round(energia_wh, 4)
        
        print("\n✅ MISSÃO COMPLETA!")
        return resultado_final
        
    except Exception as e:
        if motors:
            motors.parar()
        return {"status": "error", "message": str(e)}

# =============================================================================
# SERVIDOR HTTP SIMPLES
# =============================================================================
import socket
import json

def iniciar_servidor(ip):
    """Inicia servidor HTTP no IP obtido"""
    print(f"\n🌐 Iniciando servidor em {ip}:80...")
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('', 80))
    server.listen(5)
    server.setblocking(False)
    
    print(f"✅ Servidor rodando!")
    print(f"\n📱 No app Flutter, conecte usando o IP: {ip}")
    
    return server

def handle_request(client):
    """Processa requisição HTTP"""
    try:
        # Configura socket para blocking com timeout longo
        client.setblocking(True)
        client.settimeout(300)  # 5 minutos de timeout
        
        # Lê headers primeiro
        request = b""
        while b"\r\n\r\n" not in request:
            try:
                chunk = client.recv(1024)
                if not chunk:
                    break
                request += chunk
            except Exception as e:
                print(f"⚠️ Erro ao ler headers: {e}")
                break
        
        if not request:
            return
        
        req_str = request.decode('utf-8')
        
        # Parse da primeira linha
        first_line_end = req_str.find('\r\n')
        if first_line_end == -1:
            return
        first_line = req_str[:first_line_end]
        parts = first_line.split(' ')
        if len(parts) < 2:
            return
        method, path = parts[0], parts[1]
        
        print(f"📥 {method} {path}")
        
        # Extrai Content-Length dos headers
        content_length = 0
        for line in req_str.split('\r\n'):
            if line.lower().startswith('content-length:'):
                try:
                    content_length = int(line.split(':')[1].strip())
                except:
                    pass
                break
        
        # Extrai body já recebido
        body = ""
        header_end = req_str.find('\r\n\r\n')
        if header_end != -1:
            body = req_str[header_end + 4:]
        
        # Se precisamos ler mais body
        if method == "POST" and content_length > 0:
            bytes_to_read = content_length - len(body.encode('utf-8'))
            while bytes_to_read > 0:
                try:
                    chunk = client.recv(min(1024, bytes_to_read))
                    if not chunk:
                        break
                    body += chunk.decode('utf-8')
                    bytes_to_read -= len(chunk)
                except Exception as e:
                    print(f"⚠️ Erro ao ler body: {e}")
                    break
        
        # Rotas
        response = None
        if path == "/ping":
            response = {"status": "ok", "name": "Ajax Carrinho", "mode": "station"}
        elif path == "/telemetry":
            tel = ler_telemetria()
            response = {"status": "ok", "telemetry": tel}
        elif path == "/command" and method == "POST":
            try:
                data = json.loads(body) if body.strip() else {}
                cmd = data.get('command', '')
                if cmd:
                    print(f"🚀 Iniciando execução do comando...")
                    result = processar_comando(cmd)
                    print(f"✅ Comando executado, preparando resposta...")
                    response = {"status": "ok", "telemetry": result}
                else:
                    response = {"status": "error", "message": "Comando vazio"}
            except json.JSONDecodeError as e:
                print(f"❌ Erro JSON: {e}, body: '{body}'")
                response = {"status": "error", "message": f"JSON inválido: {str(e)}"}
        else:
            response = {"status": "error", "message": "Rota não encontrada"}
        
        # Prepara resposta HTTP
        body_json = json.dumps(response)
        
        # GARANTIA: Verifica se o JSON é válido antes de enviar
        try:
            test_parse = json.loads(body_json)
            print(f"✅ JSON válido: {len(body_json)} bytes")
        except Exception as json_err:
            print(f"❌ JSON INVÁLIDO antes de enviar: {json_err}")
            print(f"❌ JSON raw: {body_json}")
        
        print(f"📤 Enviando resposta: {response}")
        print(f"📤 JSON: {body_json}")
        
        # Monta resposta HTTP completa
        http_response = (
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: application/json\r\n"
            "Access-Control-Allow-Origin: *\r\n"
            "Cache-Control: no-cache\r\n"
            "Connection: close\r\n"
            f"Content-Length: {len(body_json)}\r\n"
            "\r\n"
            f"{body_json}"
        )
 
        response_bytes = http_response.encode('utf-8')
        
        # Envia tudo de uma vez
        try:
            client.sendall(response_bytes)
            print(f"📤 Resposta enviada ({len(response_bytes)} bytes)")
        except Exception as e:
            print(f"❌ Erro ao enviar resposta: {e}")
        
    except Exception as e:
        print(f"❌ Erro handle_request: {e}")
        try:
            error_resp = json.dumps({"status": "error", "message": str(e)})
            error_http = f"HTTP/1.1 500 Error\r\nContent-Type: application/json\r\nContent-Length: {len(error_resp)}\r\n\r\n{error_resp}"
            client.sendall(error_http.encode('utf-8'))
        except:
            pass
    finally:
        try:
            time.sleep_ms(50)  # Pequeno delay antes de fechar
            client.close()
        except:
            pass

# =============================================================================
# MAIN
# =============================================================================
ip = conectar_wifi()

if not ip:
    print("\n❌ Não foi possível conectar ao WiFi")
    print("   Verifique SSID e senha no início do arquivo")
    sys.exit(1)

server = iniciar_servidor(ip)

print("\n" + "="*70)
print("✅ SISTEMA PRONTO (MODO STATION)")
print("="*70)
print(f"📱 Configure o app para conectar em: {ip}")
print("🌐 O celular e o carrinho estão na mesma rede")
print("☁️ O celular mantém acesso à internet!")
print("="*70 + "\n")

try:
    while True:
        try:
            client, addr = server.accept()
            handle_request(client)
        except:
            pass
        time.sleep_ms(10)
        
except KeyboardInterrupt:
    print("\n🛑 Programa interrompido")
    if motors:
        motors.parar()
    if braco:
        try:
            from lib.controle_braco import desligar_servos
            desligar_servos(braco)
        except:
            pass
    server.close()


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
WIFI_SSID = "SuaRedeWiFi"       # Nome da rede WiFi local
WIFI_PASSWORD = "SuaSenha123"   # Senha da rede

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

def processar_comando(comando):
    print(f"\n📥 Comando: {comando}")
    
    try:
        comandos = parse_comandos(comando)
        if not comandos:
            return {"status": "error", "message": "Nenhum comando válido"}
        
        return executar_comandos(comandos)
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
        request = b""
        while True:
            try:
                chunk = client.recv(1024)
                if not chunk:
                    break
                request += chunk
                if b"\r\n\r\n" in request:
                    break
            except:
                break
        
        if not request:
            return
        
        req_str = request.decode('utf-8')
        lines = req_str.split('\r\n')
        method, path, _ = lines[0].split(' ', 2)
        
        print(f"📥 {method} {path}")
        
        # Extrai body
        body = ""
        if method == "POST":
            idx = req_str.find('\r\n\r\n')
            if idx != -1:
                body = req_str[idx + 4:]
        
        # Rotas
        if path == "/ping":
            response = {"status": "ok", "name": "Ajax Carrinho", "mode": "station"}
        elif path == "/command" and method == "POST":
            data = json.loads(body) if body else {}
            cmd = data.get('command', '')
            result = processar_comando(cmd)
            response = {"status": "ok", "telemetry": result}
        else:
            response = {"status": "error", "message": "Rota não encontrada"}
        
        # Envia resposta
        body_json = json.dumps(response)
        http_response = (
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: application/json\r\n"
            "Access-Control-Allow-Origin: *\r\n"
            f"Content-Length: {len(body_json)}\r\n"
            "\r\n"
            f"{body_json}"
        )
        client.send(http_response.encode())
        
    except Exception as e:
        print(f"❌ Erro: {e}")
    finally:
        client.close()

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
    server.close()

# =============================================================================
# TESTE WIFI - TESTA A CONEXÃO WIFI E COMANDOS
# =============================================================================
# Execute este arquivo para testar o servidor WiFi do carrinho
# Ele simula os comandos sem mover os motores

import sys
sys.path.append('/lib')
sys.path.append('..')

import time

print("\n" + "="*70)
print(" 🧪 TESTE DO SERVIDOR WIFI")
print("="*70)

# =============================================================================
# IMPORTAÇÃO
# =============================================================================
try:
    from lib.wifi_manager import WifiManager
    print("✅ WifiManager importado")
except Exception as e:
    print(f"❌ Erro ao importar WifiManager: {e}")
    sys.exit(1)

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================
WIFI_SSID = "Ajax_Teste"
WIFI_PASSWORD = "teste123"
ESP_IP = "192.168.4.1"

# =============================================================================
# FUNÇÃO DE TESTE DE PARSE
# =============================================================================
def parse_comandos(comando_str):
    """Testa o parsing de comandos"""
    comandos = []
    partes = comando_str.upper().split(',')
    
    for parte in partes:
        parte = parte.strip()
        if not parte:
            continue
        
        tokens = parte.split()
        
        if len(tokens) >= 3 and tokens[0] == "ANDAR":
            try:
                distancia = int(tokens[1])
                comandos.append(("ANDAR", distancia))
            except ValueError:
                print(f"⚠️ Distância inválida: {tokens[1]}")
                
        elif len(tokens) >= 4 and tokens[0] == "GIRAR":
            try:
                angulo = int(tokens[1])
                direcao = tokens[3] if len(tokens) > 3 else "DIREITA"
                
                if "ESQUERDA" in direcao or "ESQ" in direcao:
                    comandos.append(("GIRAR_ESQUERDA", angulo))
                else:
                    comandos.append(("GIRAR_DIREITA", angulo))
            except ValueError:
                print(f"⚠️ Ângulo inválido: {tokens[1]}")
                
        elif len(tokens) >= 2 and tokens[0] == "RE":
            try:
                distancia = int(tokens[1])
                comandos.append(("RE", distancia))
            except ValueError:
                print(f"⚠️ Distância inválida: {tokens[1]}")
    
    return comandos

# =============================================================================
# TESTE DE PARSE DE COMANDOS
# =============================================================================
print("\n📋 TESTE DE PARSE DE COMANDOS")
print("-"*50)

comandos_teste = [
    "ANDAR 100 CM",
    "ANDAR 50 CM, GIRAR 90 GRAUS DIREITA",
    "ANDAR 100 CM, GIRAR 90 GRAUS DIREITA, ANDAR 50 CM",
    "GIRAR 45 GRAUS ESQUERDA, ANDAR 200 CM",
    "RE 30 CM, GIRAR 180 GRAUS DIREITA",
]

for cmd in comandos_teste:
    print(f"\n📝 Entrada: {cmd}")
    resultado = parse_comandos(cmd)
    print(f"   Resultado: {resultado}")
    
print("\n✅ Parse de comandos funcionando!")

# =============================================================================
# CALLBACK DE TESTE
# =============================================================================
def processar_comando_teste(comando):
    """Callback que simula execução"""
    print(f"\n📥 Comando recebido: {comando}")
    
    comandos = parse_comandos(comando)
    
    if not comandos:
        return {"status": "error", "message": "Nenhum comando válido"}
    
    distancia = sum(v for a, v in comandos if a in ["ANDAR", "RE"])
    tempo = distancia / 44.0  # 44 cm/s
    
    telemetria = {
        "status": "success",
        "message": "Simulação executada!",
        "time": round(tempo, 2),
        "distance": distancia,
        "average_speed": 44.0,
        "average_voltage": 7.4,
        "average_current": 500.0,
        "average_power": 3700.0,
        "energy_consumed": round((3700.0 / 1000.0) * (tempo / 3600.0), 4),
        "commands_executed": len(comandos)
    }
    
    print(f"   Telemetria: {telemetria}")
    return telemetria

# =============================================================================
# TESTE DO SERVIDOR WIFI
# =============================================================================
print("\n" + "="*70)
print("📶 INICIANDO SERVIDOR WIFI DE TESTE")
print("="*70)

try:
    wifi = WifiManager(ssid=WIFI_SSID, password=WIFI_PASSWORD, ip=ESP_IP)
    wifi.command_handler_callback = processar_comando_teste
    wifi.start_server()
    
    print("\n✅ Servidor iniciado!")
    print(f"   Conecte na rede: {WIFI_SSID}")
    print(f"   Senha: {WIFI_PASSWORD}")
    print("\n🔧 Teste endpoints:")
    print(f"   GET  http://{ESP_IP}/ping")
    print(f"   POST http://{ESP_IP}/command")
    print(f"   GET  http://{ESP_IP}/telemetry")
    print("\n⌨️ Pressione Ctrl+C para sair\n")
    
    while True:
        wifi.handle_requests()
        time.sleep_ms(10)
        
except KeyboardInterrupt:
    print("\n\n🛑 Teste encerrado")
    wifi.stop()
except Exception as e:
    print(f"\n❌ Erro: {e}")

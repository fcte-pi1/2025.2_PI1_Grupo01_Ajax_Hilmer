import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'debug_logger.dart';

/// Gerenciador de conexão WiFi com o carrinho ESP32
/// O carrinho cria um Access Point WiFi e o celular conecta nele
class WifiManager {
  static const String _tag = 'WifiManager';
  WifiManager();

  // Configuração padrão do ESP32
  static const String DEFAULT_ESP_IP = "192.168.4.1";
  static const int DEFAULT_PORT = 80;

  // Estado da conexão
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<String> connectionStatus = ValueNotifier('Desconectado');
  final ValueNotifier<String?> connectedIp = ValueNotifier(null);

  // Stream controller para telemetria
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;

  String _espIp = DEFAULT_ESP_IP;
  int _port = DEFAULT_PORT;
  Timer? _heartbeatTimer;

  // Flag para pausar heartbeat durante execução de rota
  bool _isExecutingRoute = false;

  /// Tenta conectar ao carrinho via WiFi
  /// O celular deve estar conectado à rede WiFi do ESP32 (ex: "Ajax_Carrinho")
  Future<bool> connect({String? ip, int? port}) async {
    _espIp = ip ?? DEFAULT_ESP_IP;
    _port = port ?? DEFAULT_PORT;

    logger.info(_tag, "Tentando conectar a $_espIp:$_port...");
    connectionStatus.value = 'Conectando...';

    try {
      // Testa a conexão com um ping
      final response = await http
          .get(Uri.parse('http://$_espIp:$_port/ping'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.success(_tag, "Conectado! Resposta: $data");

        isConnected.value = true;
        connectedIp.value = _espIp;
        connectionStatus.value = 'Conectado a ${data['name'] ?? 'Carrinho'}';

        // Inicia heartbeat para manter conexão viva (a cada 10 segundos, não 5)
        _startHeartbeat();

        return true;
      } else {
        logger.error(_tag, "Resposta inválida: ${response.statusCode}");
        connectionStatus.value = 'Erro: Resposta ${response.statusCode}';
        return false;
      }
    } on SocketException catch (e) {
      logger.error(_tag, "Erro de socket: $e");
      connectionStatus.value = 'Erro: Não foi possível conectar';
      return false;
    } on TimeoutException {
      logger.error(_tag, "Timeout ao conectar");
      connectionStatus.value = 'Erro: Timeout';
      return false;
    } catch (e) {
      logger.error(_tag, "Erro desconhecido: $e");
      connectionStatus.value = 'Erro: $e';
      return false;
    }
  }

  /// Desconecta do carrinho
  void disconnect() {
    logger.info(_tag, "Desconectando...");
    _heartbeatTimer?.cancel();
    isConnected.value = false;
    connectedIp.value = null;
    connectionStatus.value = 'Desconectado';
  }

  /// Envia comandos de trajetória para o carrinho e aguarda conclusão
  /// Formato: "ANDAR 50 CM, GIRAR 90 GRAUS DIREITA"
  /// O carrinho executa a rota completa, entrega o ovo e retorna telemetria
  Future<Map<String, dynamic>?> sendTrajectoryAndWait(
    String commandString,
  ) async {
    if (!isConnected.value) {
      logger.error(_tag, "Não conectado!");
      return null;
    }

    logger.info(_tag, "════════════════════════════════════════");
    logger.info(_tag, "📤 ENVIANDO ROTA PARA EXECUÇÃO");
    logger.info(_tag, "📤 Comando: $commandString");
    logger.info(_tag, "📤 URL: http://$_espIp:$_port/command");
    logger.info(_tag, "════════════════════════════════════════");

    // Pausa heartbeat COMPLETAMENTE durante execução
    _isExecutingRoute = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    try {
      logger.info(_tag, "📤 Criando requisição HTTP...");

      // Usa http.post simples com timeout longo
      final response = await http
          .post(
        Uri.parse('http://$_espIp:$_port/command'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode({'command': commandString}),
      )
          .timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          logger.error(_tag, "⏱️ TIMEOUT após 10 minutos!");
          throw TimeoutException('Timeout ao aguardar resposta do carrinho');
        },
      );

      logger.success(_tag, "════════════════════════════════════════");
      logger.success(_tag, "📥 RESPOSTA RECEBIDA!");
      logger.info(_tag, "📥 Status HTTP: ${response.statusCode}");
      logger.info(_tag, "📥 Body length: ${response.body.length} bytes");
      logger.info(_tag, "📥 Body: ${response.body}");
      logger.success(_tag, "════════════════════════════════════════");

      _isExecutingRoute = false;

      if (response.statusCode == 200) {
        try {
          // Tenta parsear diretamente
          var bodyStr = response.body;
          dynamic data;

          try {
            data = jsonDecode(bodyStr);
          } catch (parseError) {
            // JSON pode estar truncado - tenta corrigir
            logger.warning(_tag, "JSON truncado, tentando corrigir...");
            logger.warning(_tag, "Erro original: $parseError");

            // Conta chaves abertas e fechadas
            int openBraces = 0;
            int closeBraces = 0;
            for (var char in bodyStr.runes) {
              if (char == '{'.codeUnitAt(0)) openBraces++;
              if (char == '}'.codeUnitAt(0)) closeBraces++;
            }

            // Adiciona chaves faltantes
            int missing = openBraces - closeBraces;
            if (missing > 0) {
              bodyStr = bodyStr + ('}' * missing);
              logger.info(_tag, "Adicionadas $missing chaves faltantes");
              logger.info(_tag, "JSON corrigido: $bodyStr");

              try {
                data = jsonDecode(bodyStr);
                logger.success(_tag, "JSON corrigido parseado com sucesso!");
              } catch (e2) {
                logger.error(_tag, "Ainda não conseguiu parsear: $e2");
                rethrow;
              }
            } else {
              rethrow;
            }
          }

          logger.success(_tag, "JSON parseado com sucesso");

          // Reinicia heartbeat
          _startHeartbeat();

          // Se veio telemetria na resposta, extrai e retorna
          if (data['telemetry'] != null) {
            final telemetry = Map<String, dynamic>.from(data['telemetry']);
            logger.success(_tag, "📊 Telemetria extraída: $telemetry");
            _telemetryController.add(telemetry);
            return telemetry;
          }

          // Se a resposta tem status ok/success, retorna ela mesma
          if (data['status'] == 'ok' || data['status'] == 'success') {
            logger.success(_tag, "Status OK - retornando dados");
            return Map<String, dynamic>.from(data);
          }

          logger.warning(_tag, "Resposta sem telemetria válida");
          return data is Map ? Map<String, dynamic>.from(data) : null;
        } catch (e) {
          logger.error(_tag, "Erro ao parsear JSON: $e");
          logger.error(_tag, "Body raw: ${response.body}");
          return null;
        }
      } else {
        logger.error(_tag, "Erro HTTP: ${response.statusCode}");
        return null;
      }
    } on TimeoutException catch (e) {
      _isExecutingRoute = false;
      logger.error(_tag, "Timeout exception: $e");
      _startHeartbeat();
      return null;
    } on SocketException catch (e) {
      _isExecutingRoute = false;
      logger.error(_tag, "Socket exception: $e");
      _startHeartbeat();
      return null;
    } on http.ClientException catch (e) {
      _isExecutingRoute = false;
      logger.error(_tag, "Client exception: $e");
      _startHeartbeat();
      return null;
    } catch (e, stack) {
      _isExecutingRoute = false;
      logger.error(_tag, "Erro genérico: $e");
      logger.error(_tag, "Tipo: ${e.runtimeType}");
      logger.error(_tag, "Stack: $stack");
      _startHeartbeat();
      return null;
    }
  }

  /// Envia comandos de trajetória para o carrinho (compatibilidade)
  /// Formato: "ANDAR 50 CM, GIRAR 90 GRAUS DIREITA"
  Future<bool> sendTrajectory(String commandString) async {
    final result = await sendTrajectoryAndWait(commandString);
    return result != null;
  }

  /// Inicia heartbeat para verificar se ainda está conectado
  /// Usa intervalo de 10 segundos e pausa durante execução de rota
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      // Não faz heartbeat se estiver executando rota
      if (_isExecutingRoute) {
        return;
      }

      try {
        final response = await http
            .get(Uri.parse('http://$_espIp:$_port/ping'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode != 200) {
          logger.warning(_tag, "Heartbeat falhou");
          _handleDisconnect();
        }
      } catch (e) {
        logger.warning(_tag, "Heartbeat erro: $e");
        _handleDisconnect();
      }
    });
  }

  void _handleDisconnect() {
    if (isConnected.value) {
      isConnected.value = false;
      connectedIp.value = null;
      connectionStatus.value = 'Conexão perdida';
      _heartbeatTimer?.cancel();
    }
  }

  /// Getter para compatibilidade com BleManager
  bool get isReadyToSend => isConnected.value;

  void dispose() {
    _heartbeatTimer?.cancel();
    _telemetryController.close();
    isConnected.dispose();
    connectionStatus.dispose();
    connectedIp.dispose();
  }
}

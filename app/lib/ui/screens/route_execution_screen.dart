import 'package:flutter/material.dart';
import 'route_results_screen.dart';
import 'route_editor_screen.dart';
import '../../models/trajectory_command.dart';
import '../../services/ble_manager.dart';
import '../../services/wifi_manager.dart';
import '../../services/api_service.dart';
import '../../services/debug_logger.dart';
import '../../service_locator.dart';
import 'dart:async';

/// Modo de conexão com o carrinho
enum ConnectionMode { ble, wifi, test }

class RouteExecutionScreen extends StatefulWidget {
  final List<TrajectoryCommand> commands;
  final ConnectionMode connectionMode;

  /// String de comandos pré-formatada para enviar ao carrinho
  final String? commandString;

  const RouteExecutionScreen({
    super.key,
    required this.commands,
    this.connectionMode = ConnectionMode.test,
    this.commandString,
  });

  @override
  State<RouteExecutionScreen> createState() => _RouteExecutionScreenState();
}

class _RouteExecutionScreenState extends State<RouteExecutionScreen> {
  static const String _tag = 'RouteExecution';

  late final BleManager _bleManager = locator<BleManager>();
  late final WifiManager _wifiManager = locator<WifiManager>();
  late final ApiService _apiService = locator<ApiService>();

  StreamSubscription<Map<String, dynamic>>? _telemetrySubscription;
  String _statusMessage = "Preparando execução...";
  bool _isExecuting = false;
  bool _hasNavigated = false; // Evita navegação dupla

  @override
  void initState() {
    super.initState();
    // Inicia execução após o build completar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpa logs anteriores para ter logs limpos desta execução
      logger.clear();
      logger.info(_tag, "🚀 Iniciando nova execução de rota");
      _startExecution();
    });
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    super.dispose();
  }

  // Inicia a execução baseado no modo de conexão
  void _startExecution() {
    switch (widget.connectionMode) {
      case ConnectionMode.test:
        _simulateExecution();
        break;
      case ConnectionMode.ble:
        _executeBle();
        break;
      case ConnectionMode.wifi:
        _executeWifi();
        break;
    }
  }

  // Executa via WiFi - envia comando e aguarda resposta
  Future<void> _executeWifi() async {
    if (_isExecuting) return;
    _isExecuting = true;

    logger.info(_tag, "════════════════════════════════════════");
    logger.info(_tag, " INICIANDO EXECUÇÃO VIA WIFI");
    logger.info(_tag, "════════════════════════════════════════");

    setState(() => _statusMessage = "Enviando rota para o carrinho...");

    // Monta string de comandos se não foi fornecida
    final commandString = widget.commandString ?? _buildCommandString();

    logger.info(_tag, "📤 Comando: $commandString");

    try {
      // Envia comando e aguarda resposta (o ESP32 executa e retorna telemetria)
      setState(() => _statusMessage = "Executando rota...");

      final result = await _wifiManager.sendTrajectoryAndWait(commandString);

      logger.info(_tag, "📥 Resultado bruto: $result");

      if (!mounted) {
        logger.warning(_tag, "Widget desmontado, cancelando...");
        return;
      }

      if (result != null) {
        logger.success(_tag, "Resposta recebida!");
        logger.info(_tag, "📊 Tipo: ${result.runtimeType}");
        logger.info(_tag, "📊 Keys: ${result.keys.toList()}");

        // Verifica se a resposta indica sucesso
        final status = result['status'];
        logger.info(_tag, "📊 Status: $status");

        if (status == 'success' || status == 'ok') {
          _handleTelemetryData(result, commandString);
        } else if (status == 'error') {
          final message = result['message'] ?? 'Erro desconhecido';
          _handleError("Erro do carrinho: $message");
        } else {
          // Tenta processar mesmo assim
          _handleTelemetryData(result, commandString);
        }
      } else {
        logger.error(_tag, "Resultado é null!");
        _handleError("Falha ao executar rota - sem resposta do carrinho");
      }
    } catch (e, stackTrace) {
      logger.error(_tag, "Exceção: $e");
      logger.error(_tag, "Stack: $stackTrace");
      if (mounted) {
        _handleError("Erro na comunicação: $e");
      }
    }
  }

  // Executa via BLE - escuta stream de telemetria
  void _executeBle() {
    if (_isExecuting) return;
    _isExecuting = true;

    logger.info(_tag, "📡 Executando via BLE...");
    setState(() => _statusMessage = "Enviando rota via Bluetooth...");

    // Monta e envia comando
    final commandString = widget.commandString ?? _buildCommandString();
    _bleManager.sendTrajectory(commandString);

    // Escuta resposta
    _telemetrySubscription = _bleManager.telemetryStream.listen(
      (data) {
        logger.info(_tag, "Telemetria BLE: $data");
        if (!mounted) return;
        _handleTelemetryData(data, commandString);
      },
      onError: (error) {
        logger.error(_tag, "Erro BLE: $error");
        if (mounted) {
          _handleError("Erro na comunicação Bluetooth");
        }
      },
    );

    // Timeout de segurança
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted && _isExecuting) {
        _handleError("Timeout: Carrinho não respondeu");
      }
    });
  }

  /// Processa dados de telemetria recebidos (BLE ou WiFi)
  Future<void> _handleTelemetryData(
      Map<String, dynamic> data, String commandString) async {
    logger.info(_tag, "════════════════════════════════════════");
    logger.info(_tag, "📊 PROCESSANDO TELEMETRIA");
    logger.info(_tag, "📊 Data: $data");
    logger.info(_tag, "════════════════════════════════════════");

    final status = data['status'] as String?;
    final phase = data['phase'] as String?;

    logger.info(_tag, "Status: $status, Phase: $phase");

    // Considera sucesso se tiver time e distance OU status ok/success
    final hasTimeAndDistance =
        data.containsKey('time') && data.containsKey('distance');
    final isSuccess = status == 'success' ||
        status == 'ok' ||
        status == 'completed' ||
        status == 'done';
    final isMissionComplete =
        phase == 'mission_complete' || phase == 'route_completed';

    logger.info(_tag,
        "hasTimeAndDistance: $hasTimeAndDistance, isSuccess: $isSuccess, isMissionComplete: $isMissionComplete");

    // Se temos dados de telemetria válidos, navega para resultados
    if (hasTimeAndDistance || isSuccess || isMissionComplete) {
      _isExecuting = false;

      // Extrai dados de telemetria
      final double time =
          _extractDouble(data, ['time', 'execution_time']) ?? 0.0;
      final double distance =
          _extractDouble(data, ['distance', 'distance_traveled']) ?? 0.0;
      final double? avgSpeed = _extractDouble(data, ['average_speed']);
      final double? avgCurrent = _extractDouble(data, ['average_current']);
      final double? voltage = _extractDouble(
          data, ['average_voltage', 'voltage', 'operatingVoltage']);
      final double? energy =
          _extractDouble(data, ['energy_consumed', 'energy']);

      logger.success(_tag, "📊 Valores extraídos:");
      logger.info(_tag, "   - time: $time");
      logger.info(_tag, "   - distance: $distance");
      logger.info(_tag, "   - avgSpeed: $avgSpeed");
      logger.info(_tag, "   - avgCurrent: $avgCurrent");
      logger.info(_tag, "   - voltage: $voltage");
      logger.info(_tag, "   - energy: $energy");

      // Info da entrega do ovo (opcional)
      final String? eggStatus = data['egg_delivery_status'] as String?;
      final String? eggMessage = data['egg_delivery_message'] as String?;

      if (eggStatus != null) {
        logger.success(_tag, "🥚 Entrega: $eggStatus - $eggMessage");
      }

      // Salva telemetria diretamente na API (aguarda completar)
      await _saveTelemetryToApi(
          commandString, data, distance, avgSpeed, avgCurrent, energy);

      // Navega para resultados
      _navigateToResults(time, distance, avgSpeed, avgCurrent, voltage, energy);
      return;
    }

    // Se é um erro explícito
    if (status == 'error' || status == 'failed') {
      _isExecuting = false;
      final message = data['message'] as String? ?? 'Erro desconhecido';
      _handleError(message);
      return;
    }

    // Atualização intermediária (fase != mission_complete)
    setState(() {
      _statusMessage = data['message'] as String? ?? 'Executando...';
    });
  }

  // Salva telemetria diretamente na API
  Future<void> _saveTelemetryToApi(
    String commands,
    Map<String, dynamic> rawData,
    double distance,
    double? avgSpeed,
    double? avgCurrent,
    double? energy,
  ) async {
    try {
      // Primeiro cria/obtém a rota
      final routeResult = await _apiService.createRoute(commands);
      if (routeResult == null) {
        logger.warning(_tag, "Não foi possível criar/obter rota na API");
        return;
      }

      final routeId = routeResult['id'] as int;
      logger.info(_tag, "💾 Rota obtida (ID: $routeId)");

      // Monta payload da telemetria
      final telemetryData = {
        'average_speed': avgSpeed ?? 0.0,
        'distance_traveled': distance,
        'energy_consumed': energy ?? 0.0,
        'average_current': avgCurrent ?? 0.0,
        'status': 'success',
      };

      // Envia telemetria
      final success = await _apiService.createTelemetry(routeId, telemetryData);
      if (success) {
        logger.success(_tag, "✅ Telemetria salva na API!");
      } else {
        logger.warning(_tag, "⚠️ Falha ao salvar telemetria na API");
      }
    } catch (e) {
      logger.error(_tag, "Erro ao salvar na API: $e");
    }
  }

  /// Extrai um double de várias chaves possíveis
  double? _extractDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value);
      }
    }
    return null;
  }

  /// Constrói string de comandos no formato esperado pelo ESP32
  String _buildCommandString() {
    final parts = <String>[];

    for (final cmd in widget.commands) {
      switch (cmd.type) {
        case CommandType.andar:
          parts.add('ANDAR ${cmd.value?.abs() ?? 0} CM');
          break;
        case CommandType.girar:
          final angle = cmd.value ?? 0;
          final direction = angle >= 0 ? 'DIREITA' : 'ESQUERDA';
          parts.add('GIRAR ${angle.abs()} GRAUS $direction');
          break;
      }
    }

    return parts.join(', ');
  }

  /// Navega para tela de resultados
  void _navigateToResults(
    double time,
    double distance,
    double? avgSpeed,
    double? avgCurrent,
    double? voltage,
    double? energy,
  ) {
    logger.info(_tag, "════════════════════════════════════════");
    logger.info(_tag, "   NAVEGANDO PARA RESULTADOS");
    logger.info(_tag, "mounted: $mounted, hasNavigated: $_hasNavigated");
    logger.info(_tag, "════════════════════════════════════════");

    if (!mounted) {
      logger.warning(_tag, "Widget não montado, cancelando navegação");
      return;
    }

    if (_hasNavigated) {
      logger.warning(_tag, "Já navegou, cancelando duplicata");
      return;
    }

    _hasNavigated = true;

    logger.success(_tag, "Iniciando navegação para RouteResultsScreen");
    logger.info(_tag, "- Tempo: ${time}s");
    logger.info(_tag, "- Distância: ${distance}cm");
    logger.info(_tag, "- Velocidade média: $avgSpeed");
    logger.info(_tag, "- Corrente média: $avgCurrent");
    logger.info(_tag, "- Tensão: $voltage");
    logger.info(_tag, "- Energia: $energy");

    // Usa WidgetsBinding para garantir que navegação ocorra após o frame atual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        logger.warning(_tag, "Widget desmontado durante callback");
        return;
      }

      try {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RouteResultsScreen(
              totalTime: time,
              totalDistance: distance,
              commands: widget.commands,
              averageSpeed: avgSpeed,
              averageCurrent: avgCurrent,
              operatingVoltage: voltage,
              energyConsumed: energy,
            ),
          ),
        );
        logger.success(_tag, "Navegação concluída!");
      } catch (e, stackTrace) {
        logger.error(_tag, "Erro na navegação: $e");
        logger.error(_tag, "Stack: $stackTrace");
      }
    });
  }

  /// Trata erros e volta para o editor
  void _handleError(String message) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _isExecuting = false;

    logger.error(_tag, "ERRO: $message");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RouteEditorScreen(
              connectionType:
                  widget.connectionMode == ConnectionMode.wifi ? 'wifi' : 'ble',
            ),
          ),
        );
      }
    });
  }

  /// Simula execução (modo teste)
  Future<void> _simulateExecution() async {
    _isExecuting = true;
    logger.info(_tag, "🧪 MODO TESTE - Simulando execução...");

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _statusMessage = "Executando rota...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _statusMessage = "Entregando ovo...");
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // Calcula distância total
    double totalDist = 0;
    for (var cmd in widget.commands) {
      if (cmd.type == CommandType.andar) {
        totalDist += (cmd.value ?? 0).abs();
      }
    }

    // Simula resposta do ESP32
    final simulatedResponse = {
      'status': 'success',
      'phase': 'mission_complete',
      'message': 'Missão completa! Rota executada e ovo entregue.',
      'time': totalDist / 44.0, // 44 cm/s
      'distance': totalDist,
      'average_speed': 44.0,
      'average_current': 500.0,
      'average_voltage': 7.4,
      'average_power': 3700.0,
      'energy_consumed': 0.01,
      'egg_delivery_status': 'success',
      'egg_delivery_message': 'Ovo entregue com sucesso!',
    };

    _handleTelemetryData(simulatedResponse, _buildCommandString());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Título
                Text(
                  'Executando percurso...',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),

                const SizedBox(height: 20),

                // Subtítulo com modo de conexão
                Text(
                  _getSubtitle(),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 60),

                // Loading Spinner
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF33DDFF)),
                  ),
                ),

                const SizedBox(height: 50),

                // Indicador de status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191C23),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF33DDFF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF33DDFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Badge de modo de conexão
                _buildConnectionBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (widget.connectionMode) {
      case ConnectionMode.wifi:
        return 'Conectado via WiFi\nExecutando rota e entregando ovo';
      case ConnectionMode.ble:
        return 'Conectado via Bluetooth\nExecutando rota e entregando ovo';
      case ConnectionMode.test:
        return 'Modo de teste\nSimulando execução';
    }
  }

  Widget _buildConnectionBadge() {
    IconData icon;
    String label;
    Color color;

    switch (widget.connectionMode) {
      case ConnectionMode.wifi:
        icon = Icons.wifi;
        label = 'WiFi';
        color = Colors.green;
        break;
      case ConnectionMode.ble:
        icon = Icons.bluetooth;
        label = 'Bluetooth';
        color = Colors.blue;
        break;
      case ConnectionMode.test:
        icon = Icons.science;
        label = 'Teste';
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

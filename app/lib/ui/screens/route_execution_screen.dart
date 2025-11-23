import 'package:flutter/material.dart';
import 'route_results_screen.dart';
import 'route_editor_screen.dart';
import '../../models/trajectory_command.dart';
import '../../services/ble_manager.dart';
import '../../service_locator.dart';
import 'dart:async';

class RouteExecutionScreen extends StatefulWidget {
  final List<TrajectoryCommand> commands;
  final bool testMode; // true = simula resposta, false = aguarda BLE real

  const RouteExecutionScreen({
    super.key,
    required this.commands,
    this.testMode = true, // Padrão modo teste
  });

  @override
  State<RouteExecutionScreen> createState() => _RouteExecutionScreenState();
}

class _RouteExecutionScreenState extends State<RouteExecutionScreen> {
  late final BleManager _bleManager = locator<BleManager>();
  StreamSubscription<Map<String, dynamic>>? _telemetrySubscription;
  String _statusMessage = "Aguardando execução do carrinho...";

  @override
  void initState() {
    super.initState();
    if (widget.testMode) {
      _simulateExecution(); // Modo teste
    } else {
      _listenToCarrinh(); // Modo produção
    }
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    super.dispose();
  }

  /// Escuta dados de telemetria vindos do carrinho via BLE
  void _listenToCarrinh() {
    print("[RouteExecution] Escutando telemetria do carrinho...");

    _telemetrySubscription = _bleManager.telemetryStream.listen(
      (data) {
        print("[RouteExecution] Telemetria recebida: $data");

        if (!mounted) return;

        // Verifica o status enviado pelo carrinho ou API
        final status = data['status'] as String?;

        if (status == 'success' || status == 'completed' || status == 'done') {
          // Carrinho concluiu com sucesso
          // Tenta pegar dados do formato BLE
          double time = (data['time'] as num?)?.toDouble() ?? 0.0;
          double distance = (data['distance'] as num?)?.toDouble() ?? 0.0;

          // Dados adicionais de telemetria
          double? avgSpeed;
          double? avgCurrent;
          double? voltage;
          double? energy;

          // Se não encontrou, tenta formato da API
          if (time == 0.0 && distance == 0.0) {
            // Calcula tempo baseado na velocidade média (se disponível)
            avgSpeed = (data['average_speed'] as num?)?.toDouble();
            distance = (data['distance_traveled'] as num?)?.toDouble() ?? 0.0;
            avgCurrent = (data['average_current'] as num?)?.toDouble();
            energy = (data['energy_consumed'] as num?)?.toDouble();

            // Estima tempo: distance / speed (converte cm/s para segundos)
            if (avgSpeed != null && avgSpeed > 0) {
              time = distance / avgSpeed;
            } else {
              // Fallback: estima ~0.5s por 10cm
              time = distance / 20;
            }
          } else {
            // Formato BLE - tenta extrair dados adicionais se existirem
            avgSpeed = (data['average_speed'] as num?)?.toDouble();
            avgCurrent = (data['average_current'] as num?)?.toDouble();
            voltage = (data['voltage'] as num?)?.toDouble();
            energy = (data['energy'] as num?)?.toDouble();
          }

          _navigateToResults(
              time, distance, avgSpeed, avgCurrent, voltage, energy);
        } else if (status == 'error' || status == 'failed') {
          // Houve um erro na execução
          final message = data['message'] as String? ?? 'Erro desconhecido';
          _handleError(message);
        } else {
          // Atualiza status intermediário (opcional)
          setState(() {
            _statusMessage = data['message'] as String? ??
                data['raw'] as String? ??
                'Executando...';
          });
        }
      },
      onError: (error) {
        print("[RouteExecution] Erro no stream: $error");
        if (mounted) {
          _handleError("Erro na comunicação com o carrinho");
        }
      },
    );

    // Timeout de segurança (ex: 2 minutos)
    Future.delayed(const Duration(minutes: 2), () {
      if (mounted && _telemetrySubscription != null) {
        _handleError("Timeout: Carrinho não respondeu");
      }
    });
  }

  /// Navega para tela de resultados em caso de sucesso
  void _navigateToResults(
    double time,
    double distance,
    double? avgSpeed,
    double? avgCurrent,
    double? voltage,
    double? energy,
  ) {
    if (!mounted) return;

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
  }

  /// Volta para tela de criação em caso de erro
  void _handleError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );

    // Aguarda um pouco e volta para o editor
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RouteEditorScreen(),
          ),
        );
      }
    });
  }

  /// Simula a execução do percurso (APENAS PARA TESTES)
  Future<void> _simulateExecution() async {
    print("[RouteExecution] MODO TESTE - Simulando resposta do carrinho...");

    // Simula tempo de execução
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    setState(() => _statusMessage = "Simulando execução...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Calcula valores simulados
    double totalDist = 0;
    for (var cmd in widget.commands) {
      if (cmd.type == CommandType.andar) {
        totalDist += (cmd.value ?? 0).abs();
      }
    }

    // Simula sucesso (80% do tempo) ou erro (20%)
    final random = DateTime.now().millisecond;
    if (random % 5 != 0) {
      // Sucesso - simula dados de telemetria
      final simulatedSpeed = 4.3; // cm/s
      final simulatedCurrent = 2.0; // mAh
      final simulatedVoltage = 16.0; // V
      final simulatedEnergy = 21.0; // J
      final simulatedTime = totalDist / (simulatedSpeed * 10); // tempo estimado

      _navigateToResults(
        simulatedTime,
        totalDist,
        simulatedSpeed,
        simulatedCurrent,
        simulatedVoltage,
        simulatedEnergy,
      );
    } else {
      // Erro simulado
      _handleError("Obstáculo detectado (simulação)");
    }
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

                // Subtítulo
                Text(
                  'O carrinho está seguindo para a\nrota programada',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

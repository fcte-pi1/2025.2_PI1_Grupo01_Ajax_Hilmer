import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/api_service.dart';

// Modelo de dados simulado para a trajetória
class TrajectoryData {
  final double averageSpeed;
  final double averageCurrent;
  final double energyConsumed;
  final double distance;
  final Duration timeInUse;
  final String operationStatus;

  TrajectoryData({
    required this.averageSpeed,
    required this.averageCurrent,
    required this.energyConsumed,
    required this.distance,
    required this.timeInUse,
    required this.operationStatus,
  });
}

class TrajectoryDataScreen extends StatefulWidget {
  const TrajectoryDataScreen({super.key});

  @override
  State<TrajectoryDataScreen> createState() => _TrajectoryDataScreenState();
}

class _TrajectoryDataScreenState extends State<TrajectoryDataScreen> {
    final ApiService _apiService = GetIt.I<ApiService>();
  TrajectoryData? _data;
  bool _isLoading = true;

  // Função para buscar dados reais do backend
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final telemetryData = await _apiService.getLatestTelemetry();

      if (telemetryData != null) {
        // O campo 'time_in_use' não está no schema do backend, então vou simular
        // ou assumir que ele será calculado no frontend por enquanto.
        // O status no backend é um enum, mas aqui vou tratar como String.
        final statusString = telemetryData['status'].toString().split('.').last;

        _data = TrajectoryData(
          averageSpeed: telemetryData['average_speed'] as double,
          averageCurrent: telemetryData['average_current'] as double,
          energyConsumed: telemetryData['energy_consumed'] as double,
          distance: telemetryData['distance_traveled'] as double,
          // Simulação de tempo de uso, pois não está no backend
          timeInUse: const Duration(hours: 0, minutes: 25, seconds: 15),
          operationStatus: statusString,
        );
      } else {
        _data = null; // Nenhum dado encontrado
      }
    } catch (e) {
      print('Erro ao buscar dados de telemetria: $e');
      _data = null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  

  @override
  void initState() {
    super.initState();
    // Inicia a busca de dados ao carregar a tela
    _fetchData();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados da Trajetória'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData, // Implementa o refresh manual
          ),
        ],
      ),
      body: RefreshIndicator(
        // Implementa a atualização via pull-to-refresh
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? Center(
                    child: Text(
                      'Nenhum dado de telemetria encontrado.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status de Operação em destaque
                        _buildMetricCard(
                          'Status de Operação',
                          _data!.operationStatus,
                          Icons.info_outline,
                          _data!.operationStatus == 'COMPLETED'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(height: 16),

              // Grid para as métricas principais
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildMetricCard(
                    'Velocidade Média',
                    '${_data!.averageSpeed.toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Distância',
                    '${_data!.distance.toStringAsFixed(2)} km',
                    Icons.route,
                    Colors.purple,
                  ),
                  _buildMetricCard(
                    'Tempo de Uso',
                    _formatDuration(_data!.timeInUse),
                    Icons.timer,
                    Colors.teal,
                  ),
                  _buildMetricCard(
                    'Energia Consumida',
                    '${_data!.energyConsumed.toStringAsFixed(1)} Wh',
                    Icons.bolt,
                    Colors.red,
                  ),
                  _buildMetricCard(
                    'Corrente Média',
                    '${_data!.averageCurrent.toStringAsFixed(1)} A',
                    Icons.flash_on,
                    Colors.orange,
                  ),
                  // Espaço reservado para métricas futuras ou para manter o layout
                  const Card(elevation: 0, color: Colors.transparent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'route_editor_screen.dart';

class RouteDetailedAnalysisScreen extends StatelessWidget {
  final double averageSpeed; // cm/s
  final double averageCurrent; // mAh
  final double operatingVoltage; // V
  final double energyConsumed; // J
  final double distanceTraveled; // cm
  final double executionTime; // s

  const RouteDetailedAnalysisScreen({
    super.key,
    required this.averageSpeed,
    required this.averageCurrent,
    required this.operatingVoltage,
    required this.energyConsumed,
    required this.distanceTraveled,
    required this.executionTime,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botão Voltar + Título
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Voltar',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Título Principal
              Text(
                'Análise detalhada',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'métricas completas do percurso',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              // Grid de Métricas (2 colunas)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildMetricCard(
                      label: 'Velocidade Média',
                      value: '${averageSpeed.toStringAsFixed(1)}cm/s',
                    ),
                    _buildMetricCard(
                      label: 'Corrente Média',
                      value: '${averageCurrent.toStringAsFixed(0)}mAh',
                    ),
                    _buildMetricCard(
                      label: 'Tensão de Operação',
                      value: '${operatingVoltage.toStringAsFixed(0)}V',
                    ),
                    _buildMetricCard(
                      label: 'Energia Consumida',
                      value: '${energyConsumed.toStringAsFixed(0)}J',
                    ),
                    _buildMetricCard(
                      label: 'Distância Percorrida',
                      value: '${distanceTraveled.toStringAsFixed(0)}cm',
                    ),
                    _buildMetricCard(
                      label: 'Tempo de Execução',
                      value: '${executionTime.toStringAsFixed(0)}s',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botão Criar Nova Rota
              OutlinedButton(
                onPressed: () {
                  // Volta para o editor de rotas
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const RouteEditorScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFF33DDFF),
                  side: const BorderSide(color: Color(0xFF33DDFF), width: 1.5),
                  padding: EdgeInsets.zero,
                  fixedSize: const Size(double.infinity, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Criar Nova rota',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF191C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

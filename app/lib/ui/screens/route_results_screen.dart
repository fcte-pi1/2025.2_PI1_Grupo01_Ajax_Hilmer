import 'package:flutter/material.dart';
import 'route_editor_screen.dart';
import 'route_detailed_analysis_screen.dart';
import '../../models/trajectory_command.dart';
import 'dart:math' as math;

class RouteResultsScreen extends StatefulWidget {
  final double totalTime; // em segundos
  final double totalDistance; // em cm
  final List<TrajectoryCommand>? commands; // Comandos para desenhar o caminho

  // Dados opcionais de telemetria para análise detalhada
  final double? averageSpeed; // cm/s
  final double? averageCurrent; // mAh
  final double? operatingVoltage; // V
  final double? energyConsumed; // J

  const RouteResultsScreen({
    super.key,
    required this.totalTime,
    required this.totalDistance,
    this.commands,
    this.averageSpeed,
    this.averageCurrent,
    this.operatingVoltage,
    this.energyConsumed,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Configura animação do gráfico (0 a 1 em 2 segundos)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Inicia a animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
              // Título
              Text(
                'Resultados da entrega',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                '(análise do percurso realizado)',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // Card de Visualização do Percurso
              Container(
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF191C23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'visualização do percurso',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildPathVisualization(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cards de Métricas
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.access_time,
                      label: 'Tempo Total',
                      value: '${widget.totalTime.toStringAsFixed(1)}s',
                      iconColor: const Color(0xFF33DDFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.location_on,
                      label: 'Distância Percorrida',
                      value: '${widget.totalDistance.toStringAsFixed(0)}cm',
                      iconColor: const Color(0xFF33DDFF),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Botão Ver Análise Detalhada
              ElevatedButton(
                onPressed: () {
                  // Navegar para tela de análise detalhada
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RouteDetailedAnalysisScreen(
                        averageSpeed: widget.averageSpeed ??
                            (widget.totalDistance / widget.totalTime),
                        averageCurrent: widget.averageCurrent ?? 2.0,
                        operatingVoltage: widget.operatingVoltage ?? 16.0,
                        energyConsumed: widget.energyConsumed ?? 21.0,
                        distanceTraveled: widget.totalDistance,
                        executionTime: widget.totalTime,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33DDFF),
                  foregroundColor: const Color(0xFF0D0F14),
                  padding: EdgeInsets.zero,
                  fixedSize: const Size(double.infinity, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bar_chart, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Ver Análise detalhada',
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0D0F14),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Botão Nova Rota
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
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38, width: 1.5),
                  padding: EdgeInsets.zero,
                  fixedSize: const Size(double.infinity, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Nova rota',
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
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathVisualization() {
    // Visualização animada do caminho baseada nos comandos reais
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: PathPainter(
            commands: widget.commands,
            animationProgress: _animation.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

// Painter customizado para desenhar o caminho baseado nos comandos reais
class PathPainter extends CustomPainter {
  final List<TrajectoryCommand>? commands;
  final double animationProgress; // 0.0 a 1.0 para animar o desenho

  PathPainter({
    this.commands,
    this.animationProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (commands == null || commands!.isEmpty) {
      _drawExamplePath(canvas, size);
      return;
    }

    // Calcula o caminho real baseado nos comandos
    final pathPoints = _calculatePathPoints(commands!);

    // Estilos de pintura
    final dashedPaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF33DDFF)
      ..style = PaintingStyle.fill;

    // Centraliza e escala o caminho para caber no canvas
    final scaledPoints = _scaleAndCenterPath(pathPoints, size);

    // Determina quantos pontos mostrar baseado na animação
    final pointsToShow = (scaledPoints.length * animationProgress).round();

    if (pointsToShow < 2) return;

    // Desenha o caminho tracejado
    final path = Path();
    path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);

    for (int i = 1; i < pointsToShow; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }

    _drawDashedPath(canvas, path, dashedPaint);

    // Desenha os pontos de virada
    for (int i = 0; i < pointsToShow; i++) {
      if (i == 0) {
        // Ponto inicial - bolinha verde
        final startPaint = Paint()
          ..color = const Color(0xFF4ADE80)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(scaledPoints[i], 7, startPaint);
      } else if (i == scaledPoints.length - 1 &&
          pointsToShow == scaledPoints.length) {
        // Ponto final - X vermelho
        _drawX(canvas, scaledPoints[i], 10, const Color(0xFFFF6B6B));
      } else {
        // Pontos intermediários - azul
        canvas.drawCircle(scaledPoints[i], 4, pointPaint);
      }
    }
  }

  // Desenha um X no ponto final
  void _drawX(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final halfSize = size / 2;

    // Linha diagonal \
    canvas.drawLine(
      Offset(center.dx - halfSize, center.dy - halfSize),
      Offset(center.dx + halfSize, center.dy + halfSize),
      paint,
    );

    // Linha diagonal /
    canvas.drawLine(
      Offset(center.dx - halfSize, center.dy + halfSize),
      Offset(center.dx + halfSize, center.dy - halfSize),
      paint,
    );
  }

  // Calcula pontos do caminho baseado nos comandos
  List<Offset> _calculatePathPoints(List<TrajectoryCommand> cmds) {
    final points = <Offset>[];
    double x = 0;
    double y = 0;
    double angle = -90; // Começa apontando para cima (-90°)

    points.add(Offset(x, y)); // Ponto inicial

    for (final cmd in cmds) {
      if (cmd.type == CommandType.andar) {
        // Move na direção atual
        final distance = (cmd.value ?? 0).toDouble();
        final radians = angle * math.pi / 180;
        x += distance * math.cos(radians);
        y += distance * math.sin(radians);
        points.add(Offset(x, y));
      } else if (cmd.type == CommandType.girar) {
        // Apenas muda o ângulo, não adiciona ponto
        angle += (cmd.value ?? 0).toDouble();
      }
    }

    return points;
  }

  // Escala e centraliza o caminho para caber no canvas
  List<Offset> _scaleAndCenterPath(List<Offset> points, Size size) {
    if (points.isEmpty) return points;

    // Encontra os limites do caminho
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    final pathWidth = maxX - minX;
    final pathHeight = maxY - minY;

    // Adiciona margem (20% do tamanho do canvas)
    final margin = 0.15;
    final availableWidth = size.width * (1 - 2 * margin);
    final availableHeight = size.height * (1 - 2 * margin);

    // Calcula escala para caber no canvas
    final scale = math.min(
      pathWidth > 0 ? availableWidth / pathWidth : 1.0,
      pathHeight > 0 ? availableHeight / pathHeight : 1.0,
    );

    // Escala e centraliza
    return points.map((point) {
      final scaledX = (point.dx - minX) * scale;
      final scaledY = (point.dy - minY) * scale;
      final centeredX = scaledX + (size.width - pathWidth * scale) / 2;
      final centeredY = scaledY + (size.height - pathHeight * scale) / 2;
      return Offset(centeredX, centeredY);
    }).toList();
  }

  // Desenha um caminho de exemplo se não houver comandos
  void _drawExamplePath(Canvas canvas, Size size) {
    final dashedPaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF33DDFF)
      ..style = PaintingStyle.fill;

    final endPointPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.fill;

    final path = Path();
    final startX = size.width * 0.3;
    final startY = size.height * 0.2;

    path.moveTo(startX, startY);
    path.lineTo(startX + size.width * 0.2, startY + size.height * 0.15);
    path.lineTo(startX + size.width * 0.25, startY + size.height * 0.35);
    path.lineTo(startX + size.width * 0.15, startY + size.height * 0.5);

    _drawDashedPath(canvas, path, dashedPaint);

    canvas.drawCircle(Offset(startX, startY), 5, pointPaint);
    canvas.drawCircle(
      Offset(startX + size.width * 0.2, startY + size.height * 0.15),
      4,
      pointPaint,
    );
    canvas.drawCircle(
      Offset(startX + size.width * 0.25, startY + size.height * 0.35),
      4,
      pointPaint,
    );
    canvas.drawCircle(
      Offset(startX + size.width * 0.15, startY + size.height * 0.5),
      6,
      endPointPaint,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        final nextDistance = distance + length;

        if (draw) {
          final extractPath = metric.extractPath(
            distance,
            nextDistance > metric.length ? metric.length : nextDistance,
          );
          canvas.drawPath(extractPath, paint);
        }

        distance = nextDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.commands != commands;
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';
import '../../models/trajectory_command.dart';
import 'route_results_screen.dart';

class PreviousRoutesScreen extends StatefulWidget {
  const PreviousRoutesScreen({super.key});
  @override
  State<PreviousRoutesScreen> createState() => _PreviousRoutesScreenState();
}

class _PreviousRoutesScreenState extends State<PreviousRoutesScreen> {
  final ApiService _apiService = locator<ApiService>();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _routes = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _fetchMoreData();
    }
  }

  Future<void> _fetchInitialData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routes = await _apiService.getPreviousRoutes(
        limit: _limit,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _routes.clear();
        _routes.addAll(routes);
        _offset = routes.length;
        _hasMore = routes.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchMoreData() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final routes = await _apiService.getPreviousRoutes(
        limit: _limit,
        offset: _offset,
      );

      if (!mounted) return;
      setState(() {
        _routes.addAll(routes);
        _offset += routes.length;
        _hasMore = routes.length == _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _offset = 0;
    _hasMore = true;
    _routes.clear();
    await _fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotas Anteriores'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 50),
              const SizedBox(height: 15),
              const Text(
                'Erro ao carregar rotas.\nVerifique sua conexão.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_routes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off,
                          size: 60, color: Colors.white24),
                      SizedBox(height: 15),
                      Text(
                        'Nenhuma rota anterior encontrada.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(15),
        itemCount: _routes.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _routes.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final route = _routes[index];
          final routeId = route['id'] ?? (index + 1);
          final commands = route['commands'] as String? ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF191C23),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF33DDFF), width: 1),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                'Rota $routeId',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  commands.isNotEmpty ? commands : 'Sem comandos',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () => _navigateToResults(routeId, commands),
              splashColor: const Color(0xFF33DDFF),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToResults(int routeId, String commands) async {
    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Busca telemetrias e filtra pela rota
      final telemetries =
          await _apiService.getTelemetries(limit: 100, offset: 0);
      final telemetry = telemetries.firstWhere(
        (t) => t['route_id'] == routeId,
        orElse: () => <String, dynamic>{},
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Fecha loading

      if (telemetry.isNotEmpty) {
        final distance =
            (telemetry['distance_traveled'] as num?)?.toDouble() ?? 0.0;
        final speed = (telemetry['average_speed'] as num?)?.toDouble() ?? 1.0;
        final time = speed > 0 ? distance / speed : 0.0;
        final current =
            (telemetry['average_current'] as num?)?.toDouble() ?? 0.0;
        final energy =
            (telemetry['energy_consumed'] as num?)?.toDouble() ?? 0.0;

        final commandList = _parseCommands(commands);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RouteResultsScreen(
              totalTime: time,
              totalDistance: distance,
              commands: commandList,
              averageSpeed: speed,
              averageCurrent: current,
              operatingVoltage: 16.0,
              energyConsumed: energy,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma execução encontrada para esta rota'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao buscar dados da rota'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<TrajectoryCommand> _parseCommands(String commandsStr) {
    final commands = <TrajectoryCommand>[];
    if (commandsStr.isEmpty) return commands;

    final parts = commandsStr.toUpperCase().split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      final tokens = trimmed.split(RegExp(r'\s+'));

      if (tokens.isEmpty) continue;

      if (tokens[0] == 'ANDAR' && tokens.length >= 2) {
        final value = int.tryParse(tokens[1]);
        if (value != null) {
          commands
              .add(TrajectoryCommand(type: CommandType.andar, value: value));
        }
      } else if (tokens[0] == 'GIRAR' && tokens.length >= 2) {
        final value = int.tryParse(tokens[1]);
        if (value != null) {
          final isLeft = trimmed.contains('ESQUERDA');
          commands.add(TrajectoryCommand(
            type: CommandType.girar,
            value: isLeft ? -value : value,
          ));
        }
      }
    }

    return commands;
  }
}

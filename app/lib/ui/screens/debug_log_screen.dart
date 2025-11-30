import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/debug_logger.dart';

// Tela para visualizar logs de debug em tempo real
// NAO FUNCIONA EM PROD
class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String? _filterSource;

  @override
  void initState() {
    super.initState();
    // Escuta mudanças nos logs
    logger.logCount.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    logger.logCount.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) {
      setState(() {});
      // Auto-scroll para o final
      if (_autoScroll && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        });
      }
    }
  }

  List<LogEntry> get _filteredLogs {
    if (_filterSource == null) {
      return logger.logs;
    }
    return logger.logsFrom(_filterSource!);
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: const Color(0xFF191C23),
        actions: [
          // Toggle auto-scroll
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_center,
              color: _autoScroll ? Colors.green : Colors.grey,
            ),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () {
              setState(() => _autoScroll = !_autoScroll);
            },
          ),
          // Copiar logs
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar logs',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logger.getLogsAsText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Logs copiados para a área de transferência')),
              );
            },
          ),
          // Limpar logs
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar logs',
            onPressed: () {
              logger.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF15171C),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'Todos'),
                  _buildFilterChip('WifiManager', 'WiFi'),
                  _buildFilterChip('RouteExecution', 'Execução'),
                  _buildFilterChip('SyncService', 'Sync'),
                  _buildFilterChip('BleManager', 'BLE'),
                ],
              ),
            ),
          ),
          // Lista de logs
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum log ainda.\nExecute uma rota para ver os logs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(log);
                    },
                  ),
          ),
          // Status bar
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF15171C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${logs.length} logs',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _filterSource ?? 'Todos os sources',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? source, String label) {
    final isSelected = _filterSource == source;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filterSource = source);
        },
        selectedColor: const Color(0xFF33DDFF).withOpacity(0.3),
        checkmarkColor: const Color(0xFF33DDFF),
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    Color bgColor;
    Color textColor;

    switch (log.level) {
      case LogLevel.success:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case LogLevel.warning:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case LogLevel.error:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case LogLevel.info:
      default:
        bgColor = Colors.transparent;
        textColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            log.formattedTime,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // Source
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getSourceColor(log.source).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.source,
              style: TextStyle(
                color: _getSourceColor(log.source),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Message
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'WifiManager':
        return Colors.green;
      case 'RouteExecution':
        return Colors.blue;
      case 'SyncService':
        return Colors.purple;
      case 'BleManager':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

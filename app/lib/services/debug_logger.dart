import 'package:flutter/foundation.dart';
// CLASSE RESPONSAVEL PELO LOG DE DEBUG, NÃO UTILIZADA EM PRODUÇÃO
enum LogLevel { info, success, warning, error }

class LogEntry {
  final DateTime timestamp;
  final String source;
  final String message;
  final LogLevel level;

  LogEntry({
    required this.timestamp,
    required this.source,
    required this.message,
    required this.level,
  });

  String get levelIcon {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    return '[$formattedTime][$levelIcon][$source] $message';
  }
}

/// Logger para debug que armazena logs em memória para visualização na UI
/// Permite ver logs mesmo sem estar conectado ao console de debug
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final List<LogEntry> _logs = [];
  final ValueNotifier<int> logCount = ValueNotifier(0);

  static const int maxLogs = 500;

  /// Adiciona um log
  void log(String source, String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      source: source,
      message: message,
      level: level,
    );

    _logs.add(entry);

    // Limita quantidade de logs
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    logCount.value = _logs.length;

    // Também imprime no console normal para quando estiver em debug
    print("[${entry.levelIcon}][$source] $message");
  }

  void info(String source, String message) =>
      log(source, message, level: LogLevel.info);
  void success(String source, String message) =>
      log(source, message, level: LogLevel.success);
  void warning(String source, String message) =>
      log(source, message, level: LogLevel.warning);
  void error(String source, String message) =>
      log(source, message, level: LogLevel.error);

  /// Retorna todos os logs
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Retorna logs filtrados por fonte
  List<LogEntry> logsFrom(String source) {
    return _logs.where((log) => log.source == source).toList();
  }

  /// Limpa todos os logs
  void clear() {
    _logs.clear();
    logCount.value = 0;
  }

  /// Retorna logs como texto formatado
  String getLogsAsText() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln(log.toString());
    }
    return buffer.toString();
  }
}

/// Singleton global para fácil acesso
final logger = DebugLogger();

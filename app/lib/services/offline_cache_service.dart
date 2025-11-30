import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para armazenar dados offline e sincronizar com a API depois
/// Usado quando o celular está conectado ao WiFi do carrinho (sem internet)
class OfflineCacheService {
  static const String _pendingTelemetriesKey = 'pending_telemetries';
  static const String _pendingRoutesKey = 'pending_routes';

  /// Salva telemetria localmente para sincronizar depois
  /// Chamado quando o carrinho retorna dados mas não há internet
  Future<void> saveTelemetryLocally(Map<String, dynamic> telemetry) async {
    final prefs = await SharedPreferences.getInstance();

    // Adiciona timestamp
    telemetry['saved_at'] = DateTime.now().toIso8601String();

    // Busca lista existente
    final List<String> pending =
        prefs.getStringList(_pendingTelemetriesKey) ?? [];

    // Adiciona nova telemetria
    pending.add(jsonEncode(telemetry));

    // Salva
    await prefs.setStringList(_pendingTelemetriesKey, pending);

    print(
        "[OfflineCache] 💾 Telemetria salva localmente (${pending.length} pendentes)");
  }

  /// Salva rota localmente para sincronizar depois
  Future<void> saveRouteLocally(String commands) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> routeData = {
      'commands': commands,
      'saved_at': DateTime.now().toIso8601String(),
    };

    final List<String> pending = prefs.getStringList(_pendingRoutesKey) ?? [];
    pending.add(jsonEncode(routeData));

    await prefs.setStringList(_pendingRoutesKey, pending);

    print(
        "[OfflineCache] 💾 Rota salva localmente (${pending.length} pendentes)");
  }

  /// Retorna telemetrias pendentes de sincronização
  Future<List<Map<String, dynamic>>> getPendingTelemetries() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending =
        prefs.getStringList(_pendingTelemetriesKey) ?? [];

    return pending
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
  }

  /// Retorna rotas pendentes de sincronização
  Future<List<Map<String, dynamic>>> getPendingRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingRoutesKey) ?? [];

    return pending
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
  }

  /// Retorna contagem de itens pendentes
  Future<int> getPendingCount() async {
    final telemetries = await getPendingTelemetries();
    final routes = await getPendingRoutes();
    return telemetries.length + routes.length;
  }

  /// Limpa telemetrias pendentes após sincronização bem-sucedida
  Future<void> clearPendingTelemetries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingTelemetriesKey);
    print("[OfflineCache] ✅ Telemetrias pendentes limpas");
  }

  /// Limpa rotas pendentes após sincronização bem-sucedida
  Future<void> clearPendingRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRoutesKey);
    print("[OfflineCache] ✅ Rotas pendentes limpas");
  }

  /// Limpa todos os dados pendentes
  Future<void> clearAll() async {
    await clearPendingTelemetries();
    await clearPendingRoutes();
  }

  /// Remove uma telemetria específica (após sincronização individual)
  Future<void> removeTelemetry(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending =
        prefs.getStringList(_pendingTelemetriesKey) ?? [];

    if (index >= 0 && index < pending.length) {
      pending.removeAt(index);
      await prefs.setStringList(_pendingTelemetriesKey, pending);
    }
  }

  /// Remove uma rota específica (após sincronização individual)
  Future<void> removeRoute(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingRoutesKey) ?? [];

    if (index >= 0 && index < pending.length) {
      pending.removeAt(index);
      await prefs.setStringList(_pendingRoutesKey, pending);
    }
  }
}

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'offline_cache_service.dart';

/// Serviço para sincronizar dados offline com a API
/// Detecta quando há internet e envia dados pendentes
class SyncService {
  final OfflineCacheService _cache = OfflineCacheService();
  final Connectivity _connectivity = Connectivity();

  // URL base da API (configurar conforme ambiente)
  String _apiBaseUrl = 'http://localhost:8000';

  // Estado
  final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  final ValueNotifier<int> pendingCount = ValueNotifier(0);
  final ValueNotifier<bool> hasInternet = ValueNotifier(false);

  SyncService({String? apiBaseUrl}) {
    if (apiBaseUrl != null) {
      _apiBaseUrl = apiBaseUrl;
    }
    _initConnectivityListener();
    _updatePendingCount();
  }

  /// Configura URL da API
  void setApiUrl(String url) {
    _apiBaseUrl = url;
  }

  /// Inicializa listener de conectividade
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      // Verifica se está conectado a alguma rede
      final connected = _isConnected(result);

      hasInternet.value = connected;

      if (connected) {
        print(
            "[SyncService] 🌐 Internet detectada - verificando sincronização");
        // Tenta sincronizar automaticamente quando detecta internet
        syncIfNeeded();
      }
    });

    // Verifica estado inicial
    _checkInitialConnectivity();
  }

  /// Verifica se o resultado indica conexão
  bool _isConnected(dynamic result) {
    if (result is List) {
      return result.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
    } else if (result is ConnectivityResult) {
      return result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet;
    }
    return false;
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    hasInternet.value = _isConnected(result);
  }

  /// Atualiza contagem de itens pendentes
  Future<void> _updatePendingCount() async {
    pendingCount.value = await _cache.getPendingCount();
  }

  /// Verifica se há internet real (não apenas WiFi do carrinho)
  Future<bool> hasRealInternet() async {
    try {
      // Tenta fazer uma requisição simples para verificar internet real
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sincroniza dados pendentes se houver internet
  Future<bool> syncIfNeeded() async {
    await _updatePendingCount();

    if (pendingCount.value == 0) {
      print("[SyncService] ✅ Nada para sincronizar");
      return true;
    }

    // Verifica se realmente tem internet
    final realInternet = await hasRealInternet();
    if (!realInternet) {
      print(
          "[SyncService] ⚠️ Sem internet real (provavelmente no WiFi do carrinho)");
      return false;
    }

    return await syncAll();
  }

  /// Força sincronização de todos os dados pendentes
  Future<bool> syncAll() async {
    if (isSyncing.value) {
      print("[SyncService] ⚠️ Sincronização já em andamento");
      return false;
    }

    isSyncing.value = true;
    print("[SyncService] 🔄 Iniciando sincronização...");

    try {
      // Sincroniza rotas
      final routeSuccess = await _syncRoutes();

      // Sincroniza telemetrias
      final telemetrySuccess = await _syncTelemetries();

      await _updatePendingCount();

      final success = routeSuccess && telemetrySuccess;
      print(
          "[SyncService] ${success ? '✅' : '❌'} Sincronização ${success ? 'completa' : 'parcial'}");

      return success;
    } catch (e) {
      print("[SyncService] ❌ Erro na sincronização: $e");
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Sincroniza rotas pendentes com a API e retorna os IDs criados
  Future<List<int>> _syncRoutesAndGetIds() async {
    final routes = await _cache.getPendingRoutes();
    if (routes.isEmpty) return [];

    print("[SyncService] 📤 Sincronizando ${routes.length} rotas...");

    List<int> routeIds = [];

    for (int i = routes.length - 1; i >= 0; i--) {
      final route = routes[i];
      try {
        final response = await http
            .post(
              Uri.parse('$_apiBaseUrl/routes'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'commands': route['commands']}),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final routeId = data['id'] as int?;
          if (routeId != null) {
            routeIds.add(routeId);
          }
          await _cache.removeRoute(i);
          print("[SyncService] ✅ Rota sincronizada (ID: $routeId)");
        } else {
          print(
              "[SyncService] ❌ Erro ao sincronizar rota: ${response.statusCode}");
        }
      } catch (e) {
        print("[SyncService] ❌ Erro ao sincronizar rota: $e");
      }
    }

    return routeIds;
  }

  /// Sincroniza rotas pendentes com a API (mantém compatibilidade)
  Future<bool> _syncRoutes() async {
    await _syncRoutesAndGetIds();
    final routes = await _cache.getPendingRoutes();
    return routes.isEmpty; // Sucesso se não há mais rotas pendentes
  }

  /// Sincroniza telemetrias pendentes com a API
  /// Precisa do route_id, então primeiro sincroniza rotas
  Future<bool> _syncTelemetries() async {
    final telemetries = await _cache.getPendingTelemetries();
    if (telemetries.isEmpty) return true;

    print(
        "[SyncService] 📤 Sincronizando ${telemetries.length} telemetrias...");

    int successCount = 0;

    for (int i = telemetries.length - 1; i >= 0; i--) {
      final telemetry = telemetries[i];
      try {
        // Primeiro precisa criar/buscar a rota para ter o route_id
        final commands = telemetry['commands'] as String? ?? '';
        int? routeId;

        // Tenta criar a rota primeiro (ou buscar se já existe)
        if (commands.isNotEmpty) {
          try {
            final routeResponse = await http
                .post(
                  Uri.parse('$_apiBaseUrl/routes'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'commands': commands}),
                )
                .timeout(const Duration(seconds: 10));

            if (routeResponse.statusCode == 200 ||
                routeResponse.statusCode == 201) {
              final routeData = jsonDecode(routeResponse.body);
              routeId = routeData['id'] as int?;
              print("[SyncService] ✅ Rota criada/obtida (ID: $routeId)");
            }
          } catch (e) {
            print("[SyncService] ⚠️ Erro ao criar rota: $e");
          }
        }

        // Se não conseguiu o routeId, usa 1 como fallback (ou pula)
        if (routeId == null) {
          print("[SyncService] ⚠️ Sem route_id, usando fallback ou pulando...");
          routeId = 1; // Fallback - idealmente deve pular
        }

        // Monta payload no formato da API
        // Converte status do ESP32 para o enum da API
        String apiStatus = 'success';
        final espStatus = telemetry['status'];
        if (espStatus == 'error' || espStatus == 'failed') {
          apiStatus = 'failed';
        }

        final payload = {
          'average_speed': _toDouble(telemetry['average_speed']),
          'distance_traveled': _toDouble(
              telemetry['distance'] ?? telemetry['distance_traveled']),
          'energy_consumed': _toDouble(telemetry['energy_consumed']),
          'average_current': _toDouble(telemetry['average_current']),
          'status': apiStatus,
        };

        print(
            "[SyncService] 📤 Enviando telemetria para rota $routeId: $payload");

        final response = await http
            .post(
              Uri.parse('$_apiBaseUrl/telemetries/$routeId'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _cache.removeTelemetry(i);
          successCount++;
          print("[SyncService] ✅ Telemetria sincronizada");
        } else {
          print(
              "[SyncService] ❌ Erro ao sincronizar telemetria: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("[SyncService] ❌ Erro ao sincronizar telemetria: $e");
      }
    }

    return successCount == telemetries.length;
  }

  /// Converte valor para double de forma segura
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Salva rota e telemetria localmente (chamado após execução no carrinho)
  Future<void> saveExecution(
      String commands, Map<String, dynamic> telemetry) async {
    print("[SyncService] 💾 Salvando execução localmente");
    print("[SyncService] 📝 Comandos: $commands");
    print("[SyncService] 📊 Telemetria: $telemetry");

    // Salva rota
    await _cache.saveRouteLocally(commands);

    // Adiciona os comandos à telemetria para referência
    final telemetryWithCommands = Map<String, dynamic>.from(telemetry);
    telemetryWithCommands['commands'] = commands;

    // Salva telemetria
    await _cache.saveTelemetryLocally(telemetryWithCommands);

    await _updatePendingCount();

    // Tenta sincronizar se tiver internet
    syncIfNeeded();
  }

  void dispose() {
    isSyncing.dispose();
    pendingCount.dispose();
    hasInternet.dispose();
  }
}

// lib/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';
import 'services/ble_manager.dart';
import 'services/wifi_manager.dart';
import 'services/offline_cache_service.dart';
import 'services/sync_service.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // Carrega o arquivo .env
  print("🔍 [ServiceLocator] Tentando carregar .env...");
  try {
    await dotenv.load(fileName: ".env");
    print(" [ServiceLocator] .env carregado com sucesso!");
  } catch (e) {
    print(" [ServiceLocator] ERRO ao carregar .env: $e");
  }

  // Pega a URL do ambiente
  final apiBaseUrl = dotenv.env['API_BASE_URL'];
  print(" [ServiceLocator] API_BASE_URL carregada: '$apiBaseUrl'");

  if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
    print(" ERRO FATAL: API_BASE_URL não foi encontrada no arquivo .env");
  }

  // lazySingleton: Cria a instância apenas na primeira vez que é chamada.

  // ApiService
  locator.registerLazySingleton<ApiService>(() {
    print("ServiceLocator: Criando instância Singleton do ApiService...");
    return ApiService(
      baseUrl: apiBaseUrl ?? "", // Passa a URL carregada do .env
    );
  });

  // BleManager
  locator.registerLazySingleton<BleManager>(() {
    print("ServiceLocator: Criando instância Singleton do BleManager...");
    return BleManager();
  });

  //  WifiManager
  locator.registerLazySingleton<WifiManager>(() {
    print("ServiceLocator: Criando instância Singleton do WifiManager...");
    return WifiManager();
  });

  // OfflineCacheService (para salvar dados localmente quando offline)
  locator.registerLazySingleton<OfflineCacheService>(() {
    print(
        "ServiceLocator: Criando instância Singleton do OfflineCacheService...");
    return OfflineCacheService();
  });

  // SyncService (para sincronizar dados com a API)
  locator.registerLazySingleton<SyncService>(() {
    print("ServiceLocator: Criando instância Singleton do SyncService...");
    return SyncService(apiBaseUrl: apiBaseUrl ?? "");
  });
}

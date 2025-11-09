// lib/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';
import 'services/ble_manager.dart';

// Instância global do GetIt
final locator = GetIt.instance;

Future<void> setupLocator() async {
  // Carrega o arquivo .env
  await dotenv.load(fileName: ".env");

  // Pega a URL do ambiente
  final apiBaseUrl = dotenv.env['API_BASE_URL'];
  if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
    print(
      "ERRO FATAL: API_BASE_URL não foi encontrada no arquivo .env",
    );
  }

  // --- Registra os Serviços como Singletons ---

  // lazySingleton: Cria a instância apenas na primeira vez que é chamada.

  // 1. ApiService
  locator.registerLazySingleton<ApiService>(() {
    print("ServiceLocator: Criando instância Singleton do ApiService...");
    return ApiService(
      baseUrl: apiBaseUrl ??
          "", // Passa a URL carregada do .env
    );
  });

  // 2. BleManager
  locator.registerLazySingleton<BleManager>(() {
    print("ServiceLocator: Criando instância Singleton do BleManager...");
    return BleManager();
  });
}
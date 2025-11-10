import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:app/services/api_service.dart';
import 'package:app/services/ble_manager.dart';

class MockBleManager implements BleManager {
  @override
  ValueNotifier<bool> isScanning = ValueNotifier(false);

  @override
  ValueNotifier<List<dynamic>> scanResults = ValueNotifier([]);

  @override
  ValueNotifier<dynamic> connectedDevice = ValueNotifier(null);

  @override
  ValueNotifier<dynamic> connectionState = ValueNotifier(null);

  @override
  Future<bool> connectToDevice(dynamic device) async => true;

  @override
  Future<void> disconnectFromDevice() async {}

  @override
  void dispose() {}

  @override
  bool get isReadyToSend => true;

  @override
  Future<bool> sendTrajectory(String commandString) async => true;

  @override
  Future<void> startScan({int durationSeconds = 5}) async {}

  @override
  Future<void> stopScan() async {}
}

class MockApiService implements ApiService {
  @override
  Future<List<Map<String, dynamic>>> getPreviousRoutes({
    int limit = 20,
    int offset = 0,
  }) async {
    return [
      {
        'id': 1,
        'commands': 'ANDAR 100 CM, GIRAR 90 GRAUS DIREITA',
        'created_at': '2024-01-01T10:00:00Z'
      }
    ];
  }

  @override
  Future<bool> saveRoute(String commandsString) async => true;
}

void setupTestLocator() {
  if (GetIt.I.isRegistered<BleManager>()) {
    GetIt.I.unregister<BleManager>();
  }
  if (GetIt.I.isRegistered<ApiService>()) {
    GetIt.I.unregister<ApiService>();
  }

  GetIt.I.registerLazySingleton<BleManager>(() => MockBleManager());
  GetIt.I.registerLazySingleton<ApiService>(() => MockApiService());
}
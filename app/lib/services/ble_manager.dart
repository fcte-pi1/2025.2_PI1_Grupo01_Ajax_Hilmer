import 'dart:async';
import 'dart:convert'; // Para utf8.encode
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleManager {
  BleManager(); 

  // Notificadores de Estado
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<List<ScanResult>> scanResults = ValueNotifier([]);
  final ValueNotifier<BluetoothDevice?> connectedDevice = ValueNotifier(null);
  final ValueNotifier<BluetoothConnectionState> connectionState = ValueNotifier(
    BluetoothConnectionState.disconnected,
  );

  // Subscriptions para Streams
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  BluetoothCharacteristic? _writeCharacteristic; // Característica para escrita

// Scan
  Future<void> startScan({int durationSeconds = 5}) async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      print("[BleManager] Erro: Adaptador Bluetooth desligado.");
      return;
    }
    await stopScan();
    print("[BleManager] Iniciando scan por $durationSeconds segundos...");
    scanResults.value = [];
    isScanning.value = true;
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: durationSeconds),
      );
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          scanResults.value = results;
        },
        onError: (error) {
          print("[BleManager] Erro stream scan: $error");
          stopScan();
        },
      );
      await Future.delayed(Duration(seconds: durationSeconds));
      if (isScanning.value) await stopScan();
    } catch (e) {
      print("[BleManager] Exceção startScan: $e");
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("[BleManager] Exceção stopScan: $e");
    }
    if (isScanning.value) {
      isScanning.value = false;
      print("[BleManager] Scan parado.");
    }
  }

  // Conexão
  Future<bool> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    if (connectedDevice.value?.remoteId == device.remoteId &&
        (connectionState.value == BluetoothConnectionState.connecting ||
            connectionState.value == BluetoothConnectionState.connected)) {
      print("[BleManager] Já conectado/conectando a ${device.remoteId}");
      return connectionState.value == BluetoothConnectionState.connected;
    }
    String deviceNameLog = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();
    print("[BleManager] Conectando a $deviceNameLog...");
    connectionState.value = BluetoothConnectionState.connecting;
    connectedDevice.value = device;
    _writeCharacteristic = null;

    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        print("[BleManager] Novo estado conexão: $state");
        connectionState.value = state;
        if (state == BluetoothConnectionState.connected) {
          print("[BleManager] Conectado! Descobrindo serviços...");
          bool success = await _discoverServices(device);
          if (!success) {
            print(
              "[BleManager] Falha ao descobrir serviços essenciais. Desconectando.",
            );
            await disconnectFromDevice();
          } else {
            print("[BleManager] Serviços e característica de escrita OK.");
          }
        } else if (state == BluetoothConnectionState.disconnected) {
          print("[BleManager] Dispositivo desconectado.");
          _handleDisconnectCleanup();
        }
      },
      onError: (error) {
        print("[BleManager] Erro stream conexão: $error");
        _handleDisconnectCleanup();
      },
    );

    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      // Espera um pouco para a descoberta de serviços tentar completar
      await Future.delayed(const Duration(milliseconds: 1000));
      // Confirma se está conectado E se a característica foi encontrada
      return connectionState.value == BluetoothConnectionState.connected &&
          _writeCharacteristic != null;
    } catch (e) {
      print("[BleManager] Exceção conectar: $e");
      _handleDisconnectCleanup();
      return false;
    }
  }

  Future<void> disconnectFromDevice() async {
    final device = connectedDevice.value;
    if (device == null) return;
    String deviceNameLog = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();
    print("[BleManager] Desconectando de $deviceNameLog...");
    connectionState.value = BluetoothConnectionState.disconnecting;
    try {
      await device.disconnect();
      print("[BleManager] Solicitação de desconexão enviada.");
      // O listener cuidará da limpeza final ao receber 'disconnected'
    } catch (e) {
      print("[BleManager] Exceção desconectar: $e");
      _handleDisconnectCleanup();
    }
  }

  // envio de dados
  Future<bool> sendTrajectory(String commandString) async {
    if (connectedDevice.value == null ||
        connectionState.value != BluetoothConnectionState.connected ||
        _writeCharacteristic == null) {
      print(
        "[BleManager] Erro: Não pronto para enviar (desconectado ou característica não encontrada).",
      );
      return false;
    }
    try {
      print("[BleManager] Enviando via BLE: $commandString");
      List<int> bytesToSend = utf8.encode(commandString);

      // --- IMPORTANTE: Ajuste 'withoutResponse' conforme o firmware do carrinho ---
      // false = espera confirmação (mais confiável); true = não espera (mais rápido)
      await _writeCharacteristic!.write(bytesToSend, withoutResponse: false);

      print("[BleManager] Envio BLE bem-sucedido.");
      return true;
    } catch (e) {
      print("[BleManager] Exceção escrita BLE: $e");
      return false;
    }
  }

  // Limpeza
  void dispose() {
    print("[BleManager] Disposing...");
    stopScan();
    _connectionStateSubscription?.cancel();
    // Tenta desconectar, mas não espera indefinidamente para não bloquear
    connectedDevice.value
        ?.disconnect()
        .timeout(const Duration(seconds: 1))
        .catchError((e) {
          print("[BleManager] Timeout/Erro ao desconectar no dispose: $e");
        });
    isScanning.dispose();
    scanResults.dispose();
    connectedDevice.dispose();
    connectionState.dispose();
  }

  void _handleDisconnectCleanup() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    if (connectionState.value != BluetoothConnectionState.disconnected) {
      connectionState.value = BluetoothConnectionState.disconnected;
    }
    connectedDevice.value = null;
    _writeCharacteristic = null;
    print("[BleManager] Estado interno de conexão resetado.");
  }

  Future<bool> _discoverServices(BluetoothDevice device) async {
    _writeCharacteristic = null; // Reseta antes de procurar
    try {
      print("[BleManager] Descobrindo serviços para ${device.remoteId}...");
      // Define um timeout para a descoberta de serviços
      List<BluetoothService> services = await device.discoverServices().timeout(
        const Duration(seconds: 10),
      ); // Timeout de 10s
      print("[BleManager] ${services.length} serviços encontrados.");

      // CONFIGURAÇÃO ESPECÍFICA DO CARRINHO AQUI
      // Substitua pelos UUIDs REAIS definidos pela equipe de Firmware
      // Estes são exemplos comuns para módulos como HM-10/HC-08
      const String SERVICE_UUID_STR = "0000ffe0-0000-1000-8000-00805f9b34fb";
      const String WRITE_CHAR_UUID_STR = "0000ffe1-0000-1000-8000-00805f9b34fb";

      for (var service in services) {
        // Compara os UUIDs convertendo as strings para Guid
        if (service.uuid == Guid(SERVICE_UUID_STR)) {
          print("[BleManager]   Serviço alvo (${service.uuid}) encontrado!");
          for (var char in service.characteristics) {
            if (char.uuid == Guid(WRITE_CHAR_UUID_STR)) {
              print(
                "[BleManager]     Característica alvo (${char.uuid}) encontrada.",
              );
              if (char.properties.write ||
                  char.properties.writeWithoutResponse) {
                print(
                  "[BleManager]       -> Permite escrita! Característica guardada.",
                );
                _writeCharacteristic = char; // Guarda a referência
                return true; 
              } else {
                print(
                  "[BleManager]       -> ERRO: Característica encontrada, mas não permite escrita.",
                );
              }
            }
          }
        }
      }
      print(
        "[BleManager] AVISO: Serviço/Característica de escrita com UUIDs $SERVICE_UUID_STR / $WRITE_CHAR_UUID_STR não encontrada!",
      );
      return false;
    } catch (e) {
      print("[BleManager] Exceção ao descobrir serviços/timeout: $e");
      return false; // Falha na descoberta
    }
  }

  bool get isReadyToSend =>
      connectionState.value == BluetoothConnectionState.connected &&
      _writeCharacteristic != null;
}

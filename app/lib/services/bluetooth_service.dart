import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<List<ScanResult>> scanResults = ValueNotifier([]);
  final ValueNotifier<BluetoothDevice?> connectedDevice = ValueNotifier(null);
  final ValueNotifier<BluetoothConnectionState> connectionState = ValueNotifier(
    BluetoothConnectionState.disconnected,
  );

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  Future<void> startScan({int durationSeconds = 5}) async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      // Usa BluetoothAdapterState
      print("Bluetooth desligado.");
      return;
    }
    await stopScan();
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
          print("Erro no stream de scan: $error");
          stopScan();
        },
      );
      await Future.delayed(Duration(seconds: durationSeconds));
      if (isScanning.value) {
        await stopScan();
      }
    } catch (e) {
      print("Erro ao chamar FlutterBluePlus.startScan: $e");
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Erro ao chamar FlutterBluePlus.stopScan: $e");
    }
    if (isScanning.value) {
      isScanning.value = false;
      print("Scan parado.");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    // Usa BluetoothDevice
    await stopScan();
    print("Tentando conectar a ${device.platformName} (${device.remoteId})...");
    connectionState.value =
        BluetoothConnectionState.connecting; // Usa BluetoothConnectionState
    connectedDevice.value = device;
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen(
      // Usa connectionState
      (BluetoothConnectionState state) async {
        // Usa BluetoothConnectionState
        print("Estado da conexão mudou para: $state");
        connectionState.value = state;
        if (state == BluetoothConnectionState.connected) {
          print("Conectado com sucesso!");
        } else if (state == BluetoothConnectionState.disconnected) {
          print("Dispositivo desconectado.");
          connectedDevice.value = null;
        }
      },
      onError: (error) {
        print("Erro no stream de conexão: $error");
        connectionState.value = BluetoothConnectionState.disconnected;
        connectedDevice.value = null;
      },
    );
    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
    } catch (e) {
      print("Erro ao chamar device.connect: $e");
      if (connectionState.value != BluetoothConnectionState.disconnected) {
        connectionState.value = BluetoothConnectionState.disconnected;
        connectedDevice.value = null;
      }
    }
  }

  Future<void> disconnectFromDevice() async {
    final device = connectedDevice.value;
    if (device == null) return;
    print("Desconectando de ${device.platformName} (${device.remoteId})...");
    connectionState.value = BluetoothConnectionState.disconnecting;
    try {
      await device.disconnect();
      print("Desconexão solicitada.");
    } catch (e) {
      print("Erro ao chamar device.disconnect: $e");
      if (connectionState.value != BluetoothConnectionState.disconnected) {
        connectionState.value = BluetoothConnectionState.disconnected;
        connectedDevice.value = null;
      }
    } finally {
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
    }
  }

  Future<void> sendTrajectory(String trajectoryJson) async {
    final device = connectedDevice.value;
    if (device == null ||
        connectionState.value != BluetoothConnectionState.connected) {
      print("Erro: Não conectado a um dispositivo para enviar trajetória.");
      return;
    }
    print("Enviando trajetória: $trajectoryJson");
    // TODO: Implementar o envio de verdade via Bluetooth
  }

  void dispose() {
    stopScan();
    _connectionStateSubscription?.cancel();
    connectedDevice.value?.disconnect();
    isScanning.dispose();
    scanResults.dispose();
    connectedDevice.dispose();
    connectionState.dispose();
  }
}

import 'dart:async';
import 'dart:convert'; // Para utf8.encode
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ESSE CÓDIGO NÃO ESTÁ FUNCIONANDO NO MOMENTO, TENTEI ARRUMAR COM O LUCAS, MAS SEM SUCESSO!! ATUALMENTE ESTAMOS USANDO O WIFI PARA COMUNICAÇÃO COM O CARRINHO.

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
  BluetoothCharacteristic?
      _notifyCharacteristic; // Característica para receber dados
  StreamSubscription<List<int>>? _notifySubscription;

  // Stream controller para telemetria (dados que vêm do carrinho)
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream que emite dados de telemetria do carrinho
  /// Formato esperado: {'status': 'success'/'error', 'time': 20.5, 'distance': 150, 'message': '...'}
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;

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

    // IMPORTANTE: Se já houver uma conexão anterior, desconecta primeiro
    if (connectedDevice.value != null) {
      print(
          "[BleManager] Desconectando dispositivo anterior antes de reconectar...");
      await disconnectFromDevice();
      await Future.delayed(const Duration(milliseconds: 500));
    }

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
    _notifyCharacteristic = null;

    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        print("[BleManager] Novo estado conexão: $state");
        connectionState.value = state;
        if (state == BluetoothConnectionState.connected) {
          print(
              "[BleManager] Conectado! Aguardando 2s antes de descobrir serviços...");
          // AUMENTADO para 2 segundos - ESP32 precisa de tempo para estabilizar
          await Future.delayed(const Duration(milliseconds: 2000));
          print("[BleManager] Iniciando descoberta de serviços...");
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

      // IMPORTANTE: Aguardar a descoberta de serviços completar!
      // O listener connectionState vai chamar _discoverServices quando conectar.
      // Precisamos esperar até que _writeCharacteristic seja encontrada.

      print(
          "[BleManager] Conexão física OK. Aguardando descoberta de serviços...");

      // Aguarda até 15 segundos pela descoberta de serviços
      int tentativas = 0;
      const int maxTentativas = 30; // 30 * 500ms = 15 segundos

      while (_writeCharacteristic == null && tentativas < maxTentativas) {
        await Future.delayed(const Duration(milliseconds: 500));
        tentativas++;

        // Se desconectou durante a espera, sai
        if (connectionState.value == BluetoothConnectionState.disconnected) {
          print("[BleManager] Desconectou durante descoberta de serviços.");
          return false;
        }
      }

      bool sucesso =
          connectionState.value == BluetoothConnectionState.connected &&
              _writeCharacteristic != null;

      print(
          "[BleManager] Resultado final: ${sucesso ? 'SUCESSO ✅' : 'FALHA ❌'}");
      print("[BleManager]   - connectionState: ${connectionState.value}");
      print(
          "[BleManager]   - _writeCharacteristic: ${_writeCharacteristic != null ? 'ENCONTRADA' : 'NÃO ENCONTRADA'}");

      return sucesso;
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
    print("[BleManager] ========== ENVIANDO DADOS ==========");
    print("[BleManager] connectedDevice: ${connectedDevice.value?.remoteId}");
    print("[BleManager] connectionState: ${connectionState.value}");
    print(
        "[BleManager] _writeCharacteristic: ${_writeCharacteristic != null ? 'OK' : 'NULL'}");

    if (connectedDevice.value == null) {
      print("[BleManager]   Erro: Nenhum dispositivo conectado!");
      return false;
    }

    if (connectionState.value != BluetoothConnectionState.connected) {
      print(
          "[BleManager]   Erro: Estado não é 'connected', é: ${connectionState.value}");
      return false;
    }

    if (_writeCharacteristic == null) {
      print("[BleManager]    Erro: Característica de escrita não encontrada!");
      print("[BleManager]    Tentando redescobrir serviços...");

      // Tenta redescobrir os serviços
      if (connectedDevice.value != null) {
        bool success = await _discoverServices(connectedDevice.value!);
        if (!success || _writeCharacteristic == null) {
          print("[BleManager] Falha ao redescobrir serviços.");
          return false;
        }
        print("[BleManager] Serviços redescobertos com sucesso!");
      } else {
        return false;
      }
    }

    try {
      // O app envia: "ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 30 CM"
      String bleCommand = commandString;

      // Converte formato do app para formato do ESP32
      if (commandString.contains(', ')) {
        bleCommand = commandString.split(', ').map((cmd) {
          cmd = cmd.trim().toUpperCase();

          // "ANDAR 50 CM" -> "ANDAR:50"
          if (cmd.startsWith('ANDAR')) {
            final match = RegExp(r'ANDAR\s+(\d+)').firstMatch(cmd);
            if (match != null) {
              return 'ANDAR:${match.group(1)}';
            }
          }

          // "GIRAR 90 GRAUS DIREITA" -> "GIRAR:90"
          // "GIRAR 90 GRAUS ESQUERDA" -> "GIRAR:-90"
          if (cmd.startsWith('GIRAR')) {
            final match = RegExp(r'GIRAR\s+(\d+)').firstMatch(cmd);
            if (match != null) {
              int valor = int.parse(match.group(1)!);
              // Esquerda = negativo
              if (cmd.contains('ESQUERDA')) {
                valor = -valor;
              }
              return 'GIRAR:$valor';
            }
          }

          // Fallback: tenta extrair número do comando
          final parts = cmd.split(' ');
          if (parts.length >= 2) {
            final numMatch = RegExp(r'\d+').firstMatch(cmd);
            if (numMatch != null) {
              return '${parts[0]}:${numMatch.group(0)}';
            }
          }

          return cmd;
        }).join(';');
      }

      print("[BleManager]    Enviando via BLE: $bleCommand");
      print("[BleManager]    Tamanho: ${bleCommand.length} caracteres");

      List<int> bytesToSend = utf8.encode(bleCommand);
      print("[BleManager]    Bytes: ${bytesToSend.length}");

      // Verifica as propriedades da característica
      final props = _writeCharacteristic!.properties;
      print(
          "[BleManager]    Propriedades: write=${props.write}, writeWithoutResponse=${props.writeWithoutResponse}");

      // Tenta escrever usando o método apropriado
      if (props.writeWithoutResponse) {
        print("[BleManager]    Usando: writeWithoutResponse");
        await _writeCharacteristic!.write(bytesToSend, withoutResponse: true);
      } else if (props.write) {
        print("[BleManager]    Usando: write (com resposta)");
        await _writeCharacteristic!.write(bytesToSend, withoutResponse: false);
      } else {
        print("[BleManager]    Característica não suporta escrita!");
        return false;
      }

      print("[BleManager]    Envio BLE bem-sucedido!");
      return true;
    } catch (e) {
      print("[BleManager]    Exceção escrita BLE: $e");
      print("[BleManager]    Tipo do erro: ${e.runtimeType}");
      return false;
    }
  }

  // Limpeza
  void dispose() {
    print("[BleManager] Disposing...");
    stopScan();
    _scanResultsSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _notifySubscription?.cancel();
    _telemetryController.close();
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
    _notifySubscription?.cancel();
    _notifySubscription = null;
    if (connectionState.value != BluetoothConnectionState.disconnected) {
      connectionState.value = BluetoothConnectionState.disconnected;
    }
    connectedDevice.value = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    print("[BleManager] Estado interno de conexão resetado completamente.");
  }

  Future<bool> _discoverServices(BluetoothDevice device) async {
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    const String SERVICE_UUID_STR = "bbe292b4-7f84-4b15-a6c3-3595809838bd";
    const String WRITE_CHAR_UUID_STR = "58d79e09-6c87-4790-8ca5-54842887f8e2";
    const String NOTIFY_CHAR_UUID_STR = "9b3832d6-fc81-4c6a-ac26-9ec7bf3d2814";

    try {
      print("[BleManager] Descobrindo serviços para ${device.remoteId}...");

      List<BluetoothService> services = await device.discoverServices().timeout(
            const Duration(seconds: 30),
          );

      print("[BleManager] ✅ ${services.length} serviços encontrados:");

      // Debug: imprime TODOS os serviços e características
      for (var service in services) {
        print("[BleManager]   📦 Serviço: ${service.uuid}");
        for (var char in service.characteristics) {
          print(
              "[BleManager]       └─ Char: ${char.uuid} [W:${char.properties.write} WNR:${char.properties.writeWithoutResponse} N:${char.properties.notify}]");
        }
      }

      // Procura pelo serviço e características específicas
      for (var service in services) {
        if (service.uuid == Guid(SERVICE_UUID_STR)) {
          print("[BleManager] 🎯 SERVIÇO ALVO ENCONTRADO: ${service.uuid}");

          for (var char in service.characteristics) {
            // Característica de ESCRITA (comandos)
            if (char.uuid == Guid(WRITE_CHAR_UUID_STR)) {
              print(
                  "[BleManager]   Característica CMD encontrada: ${char.uuid}");
              if (char.properties.write ||
                  char.properties.writeWithoutResponse) {
                _writeCharacteristic = char;
                print("[BleManager]      → Permite escrita! GUARDADA.");
              } else {
                print("[BleManager]      NÃO permite escrita!");
              }
            }

            // Característica de NOTIFICAÇÃO (telemetria)
            if (char.uuid == Guid(NOTIFY_CHAR_UUID_STR)) {
              print(
                  "[BleManager]   ✅ Característica DATA encontrada: ${char.uuid}");
              if (char.properties.notify || char.properties.indicate) {
                _notifyCharacteristic = char;
                await _setupNotifications(char);
                print("[BleManager]      → Notificações configuradas.");
              }
            }
          }

          if (_writeCharacteristic != null) {
            print("[BleManager] 🎉 SUCESSO! Pronto para enviar comandos.");
            return true;
          }
        }
      }

      print("[BleManager] Serviço $SERVICE_UUID_STR NÃO encontrado!");
      print(
          "[BleManager]    Verifique se o ESP32 está com o firmware correto.");
      return false;
    } catch (e) {
      print("[BleManager] Exceção ao descobrir serviços: $e");
      return false;
    }
  }

  // Configura notificações para receber dados do carrinho em tempo real
  Future<void> _setupNotifications(BluetoothCharacteristic char) async {
    try {
      await _notifySubscription?.cancel();
      await char.setNotifyValue(true);
      print(
          "[BleManager] Notificações habilitadas para receber dados do carrinho.");

      _notifySubscription = char.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          try {
            // Decodifica os dados recebidos do carrinho
            String dataStr = utf8.decode(value).trim();
            print("[BleManager] Dados recebidos do carrinho: $dataStr");

            // Tenta parsear como JSON
            // Formato esperado: {"status":"success","time":20.5,"distance":150}
            // ou: {"status":"error","message":"Obstáculo detectado"}
            Map<String, dynamic> telemetry;

            try {
              final decoded = jsonDecode(dataStr);
              if (decoded is Map<String, dynamic>) {
                telemetry = decoded;
                telemetry['timestamp'] = DateTime.now().millisecondsSinceEpoch;
              } else {
                telemetry = {
                  'raw': dataStr,
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                };
              }
            } catch (_) {
              // Se não for JSON válido, envia como raw
              telemetry = {
                'raw': dataStr,
                'timestamp': DateTime.now().millisecondsSinceEpoch
              };
            }

            // Emite no stream para quem estiver escutando
            _telemetryController.add(telemetry);
          } catch (e) {
            print("[BleManager] Erro ao processar dados: $e");
          }
        }
      });
    } catch (e) {
      print("[BleManager] Erro ao configurar notificações: $e");
    }
  }

  bool get isReadyToSend =>
      connectionState.value == BluetoothConnectionState.connected &&
      _writeCharacteristic != null;
}

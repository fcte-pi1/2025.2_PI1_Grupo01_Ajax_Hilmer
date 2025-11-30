import 'package:flutter/material.dart';
import 'package:app/services/ble_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'route_editor_screen.dart';
import '../../service_locator.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  // Pede a instância Singleton ao locator
  late final BleManager _bleManager = locator<BleManager>();

  // Lista Mock COMENTAR/REMOVER para uso real
  // final List<ScanResult> _mockScanResults = [

  //   ScanResult(
  //     device: BluetoothDevice(
  //       remoteId: const DeviceIdentifier('00:11:22:33:AA:BB'),
  //     ),
  //     advertisementData: AdvertisementData(
  //       advName: 'Carrinho_PI1_001',
  //       txPowerLevel: null,
  //       appearance: null,
  //       connectable: true,
  //       manufacturerData: {},
  //       serviceData: {},
  //       serviceUuids: [],
  //     ),
  //     rssi: -50,
  //     timeStamp: DateTime.now(),
  //   ),
  //   ScanResult(
  //     device: BluetoothDevice(
  //       remoteId: const DeviceIdentifier('11:22:33:44:CC:DD'),
  //     ),
  //     advertisementData: AdvertisementData(
  //       advName: 'Outro_Dispositivo_BT',
  //       txPowerLevel: null,
  //       appearance: null,
  //       connectable: true,
  //       manufacturerData: {},
  //       serviceData: {},
  //       serviceUuids: [],
  //     ),
  //     rssi: -65,
  //     timeStamp: DateTime.now(),
  //   ),
  //   ScanResult(
  //     device: BluetoothDevice(
  //       remoteId: const DeviceIdentifier('22:33:44:55:EE:FF'),
  //     ),
  //     advertisementData: AdvertisementData(
  //       advName: '',
  //       txPowerLevel: null,
  //       appearance: null,
  //       connectable: false,
  //       manufacturerData: {},
  //       serviceData: {},
  //       serviceUuids: [],
  //     ),
  //     rssi: -80,
  //     timeStamp: DateTime.now(),
  //   ),
  // ];

  @override
  void initState() {
    super.initState();

    // Inicializa com dados mockados (COMENTE a linha abaixo para usar scan real)
    // _bleManager.scanResults.value = _mockScanResults;
    _setupConnectionListener(); // Configura o listener para navegação
  }

  // Configura o listener que reage a mudanças no estado da conexão
  void _setupConnectionListener() {
    _bleManager.connectionState.removeListener(_handleConnectionChange);
    _bleManager.connectionState.addListener(_handleConnectionChange);
  }

  // Função chamada quando o estado da conexão muda
  void _handleConnectionChange() {
    final state = _bleManager.connectionState.value;
    print("[ConnectionScreen] Listener: Estado da conexão mudou para $state");
    if (!mounted) return; // Garante que a tela ainda existe

    if (state == BluetoothConnectionState.connected) {
      // Verifica se a característica foi encontrada
      if (_bleManager.isReadyToSend) {
        // Adicionar getter `isReadyToSend` no BleManager
        print("[ConnectionScreen] Conectado e pronto! Navegando...");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RouteEditorScreen(),
          ),
        );
        // Remove o listener APÓS navegar com sucesso
        _bleManager.connectionState.removeListener(_handleConnectionChange);
      } else {
        // Se conectou mas não encontrou a característica, mostra erro e desconecta
        print(
          "[ConnectionScreen] Conectado, mas característica necessária não encontrada. Desconectando.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dispositivo incompatível. Característica não encontrada.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        _disconnect(); // Força desconexão
      }
    }
  }

  @override
  void dispose() {
    _bleManager.connectionState.removeListener(
      _handleConnectionChange,
    ); // Remove listener

    super.dispose();
  }

  // Inicia o scan COM verificação de permissões
  void _startScanning() async {
    // Verifica e solicita permissões de Bluetooth
    try {
      // Verifica se Bluetooth está suportado
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth não suportado neste dispositivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Verifica se Bluetooth está ligado
      var state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        print("[ConnectionScreen] Bluetooth desligado. Tentando ligar...");

        // Tenta ligar o Bluetooth (isso solicita permissão no Android 12+)
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          print("[ConnectionScreen] Erro ao ligar Bluetooth: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Por favor, ligue o Bluetooth nas configurações'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print("[ConnectionScreen] Erro ao verificar Bluetooth: $e");
    }

    // Agora faz o scan
    _bleManager.scanResults.value = [];
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Procurando dispositivos...'),
        duration: Duration(seconds: 5),
      ),
    );
    _bleManager.startScan();
  }

  // Tenta conectar - AGUARDA conexão completa antes de navegar
  void _connect(BluetoothDevice device) async {
    if (_bleManager.connectionState.value ==
            BluetoothConnectionState.connecting ||
        _bleManager.connectionState.value ==
            BluetoothConnectionState.connected) {
      return; // Ignora se já estiver conectando/conectado
    }
    String deviceName = device.platformName;
    if (deviceName.isEmpty) deviceName = device.advName;
    if (deviceName.isEmpty) deviceName = device.remoteId.toString();

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 12),
          Text('Conectando a $deviceName...'),
        ],
      ),
      duration: Duration(seconds: 30),
    ));

    // ESPERA a conexão completar ANTES de navegar
    print("[ConnectionScreen] Iniciando conexão com $deviceName...");
    bool success = await _bleManager.connectToDevice(device);

    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    if (success && _bleManager.isReadyToSend) {
      print(
          "[ConnectionScreen] Conexão completa! Navegando para RouteEditor...");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Conectado a $deviceName!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RouteEditorScreen(),
        ),
      );
    } else {
      print(
          "[ConnectionScreen] Falha na conexão ou serviços não encontrados");
      print(
          "[ConnectionScreen]    success=$success, isReadyToSend=${_bleManager.isReadyToSend}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(' Falha ao conectar. Verifique se o carrinho está ligado.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Desconecta
  void _disconnect() {
    _bleManager.disconnectFromDevice();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF191C23),
                  child: Icon(
                    Icons.bluetooth,
                    size: 75,
                    color: Color(0xFF33DDFF),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Conectar carrinho',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'selecione um dispositivo para começar',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 40),

              // lista de dispositivos
              Expanded(
                child: ValueListenableBuilder<List<ScanResult>>(
                  valueListenable: _bleManager.scanResults,
                  builder: (context, results, child) {
                    if (results.isEmpty && !_bleManager.isScanning.value) {
                      return const Center(
                        child: Text(
                          'Nenhum dispositivo encontrado.\nClique em "Procurar".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    if (results.isEmpty && _bleManager.isScanning.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.separated(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final device = result.device;
                        String deviceName = device.platformName;
                        if (deviceName.isEmpty)
                          deviceName = result.advertisementData.advName;
                        if (deviceName.isEmpty)
                          deviceName = 'ID: ${device.remoteId}';

                        return ElevatedButton(
                          onPressed: () => _connect(device),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundColor: Color(
                                    0x2633DDFF,
                                  ), // Sua Cor 15%
                                  child: const Icon(
                                    Icons.bluetooth,
                                    size: 25,
                                    color: Color(0xFF33DDFF),
                                  ), // Sua Cor
                                ),
                                const SizedBox(width: 15),
                                Flexible(
                                  child: Text(
                                    deviceName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${result.rssi} dBm',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10), //espaçamento
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              ValueListenableBuilder<bool>(
                valueListenable: _bleManager.isScanning,
                builder: (context, isScanning, _) {
                  return ValueListenableBuilder<BluetoothConnectionState>(
                    valueListenable: _bleManager.connectionState,
                    builder: (context, connState, _) {
                      Widget buttonChild;
                      VoidCallback? onPressedAction;
                      final bool isBusy = isScanning ||
                          connState == BluetoothConnectionState.connecting ||
                          connState == BluetoothConnectionState.disconnecting;

                      if (isScanning) {
                        buttonChild = const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        );
                      } else if (connState ==
                          BluetoothConnectionState.connecting) {
                        buttonChild = const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 15),
                            Text('Conectando...'),
                          ],
                        );
                      } else if (connState ==
                          BluetoothConnectionState.connected) {
                        buttonChild = const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_disabled),
                            SizedBox(width: 10),
                            Text('Desconectar'),
                          ],
                        );
                        onPressedAction = _disconnect;
                      } else {
                        // Desconectado
                        buttonChild = const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_searching),
                            SizedBox(width: 30),
                            Text('Procurar dispositivos'),
                          ],
                        );
                        onPressedAction = _startScanning;
                      }

                      return OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : onPressedAction, // Desabilita se ocupado
                        // Estilo herdado do tema
                        child: buttonChild,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),

              // Botão MODO TESTE (remover em produção)
              // TextButton(
              //   onPressed: () {
              //     // Pula direto para o RouteEditor sem Bluetooth
              //     Navigator.of(context).pushReplacement(
              //       MaterialPageRoute(
              //         builder: (context) => const RouteEditorScreen(),
              //       ),
              //     );
              //   },
              //   child: Text(
              //     '🧪 Modo Teste (sem Bluetooth)',
              //     style: TextStyle(
              //       color: Colors.orange.shade300,
              //       fontSize: 14,
              //       decoration: TextDecoration.underline,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

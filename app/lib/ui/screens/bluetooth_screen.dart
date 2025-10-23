import 'package:flutter/material.dart';
import 'package:app/services/bluetooth_service.dart' as service;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

//StatefulWidget é usado pq o conteúdo desta tela vai mudar com o tempo
class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  //cria uma instancia do serviço bluetooth
  // 'late final' significa que ela será inicializada no initState e não mudará mais
  late final service.BluetoothService _bluetoothService;

  final List<ScanResult> _mockScanResults = [
    ScanResult(
      device: BluetoothDevice(
        remoteId: const DeviceIdentifier('00:11:22:33:AA:BB'),
      ),
      // Preencha TODOS os parâmetros obrigatórios de AdvertisementData
      advertisementData: AdvertisementData(
        advName: 'Carrinho_PI1_001',
        txPowerLevel: null, // Nível de potência de transmissão (pode ser nulo)
        appearance: null, // Aparência do dispositivo BLE (pode ser nulo)
        connectable: true, // Indica se o dispositivo é conectável
        manufacturerData:
            {}, // Dados do fabricante (mapa vazio como placeholder)
        serviceData: {}, // Dados de serviço (mapa vazio como placeholder)
        serviceUuids:
            [], // Lista de UUIDs de serviço (lista vazia como placeholder)
      ),
      rssi: -50,
      timeStamp: DateTime.now(),
    ),
    ScanResult(
      device: BluetoothDevice(
        remoteId: const DeviceIdentifier('11:22:33:44:CC:DD'),
      ),
      advertisementData: AdvertisementData(
        advName: 'Outro_Dispositivo_BT',
        txPowerLevel: null,
        appearance: null,
        connectable: true,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [],
      ),
      rssi: -65,
      timeStamp: DateTime.now(),
    ),
    ScanResult(
      device: BluetoothDevice(
        remoteId: const DeviceIdentifier('22:33:44:55:EE:FF'),
      ),
      advertisementData: AdvertisementData(
        advName: '', // Dispositivo sem nome
        txPowerLevel: null,
        appearance: null,
        connectable: false, // Exemplo: um dispositivo não conectável (beacon)
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [],
      ),
      rssi: -80,
      timeStamp: DateTime.now(),
    ),
  ];

  // initState é chamado uma única vez quando o widget é criado.
  // Ideal para inicializar controladores, serviços, etc.
  @override
  void initState() {
    super.initState();
    _bluetoothService = service.BluetoothService(); // Inicializa o serviço aqui
    //para fins de desenvolvimento, vamos usar os resultados do scan mockados
    _bluetoothService.scanResults.value =
        _mockScanResults; // Usa os resultados mockados
  }

  // dispose é chamado quando o widget é removido permanentemente.
  // Essencial para limpar recursos (listeners, subscriptions) e evitar vazamentos de memória.
  @override
  void dispose() {
    _bluetoothService.dispose(); // Chama o método dispose do nosso serviço
    super.dispose();
  }

  // Função auxiliar para iniciar o scan, apenas chama o método do serviço.
  // Adiciona um feedback visual (SnackBar) para o usuário.
  void _startScanning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Procurando dispositivos Bluetooth...'),
        duration: Duration(seconds: 4),
      ),
    );
    _bluetoothService.startScan(); //chama o método real no serviço
  }

  void _connect(BluetoothDevice device) {
    _bluetoothService.connectToDevice(device);
    // TODO: Adicionar logica para navegar para a proxima tela
  }

  void _disconnect() {
    _bluetoothService.disconnectFromDevice();
  }

  // O método build é responsável por construir a árvore de widgets da interface
  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura básica da tela (fundo branco/escuro, pode ter AppBar, etc.)
    return Scaffold(
      // SafeArea nao deixa o conteudo ficar escondido atras de notches ou barras do sistema, igual o safeAreaView do react
      body: SafeArea(
        // Padding adiciona um espaçamento interno em todas as bordas da tela, iggual css
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // Column organiza os widgets filhos em uma coluna vertical.
          child: Column(
            // crossAxisAlignment.stretch faz os filhos esticarem para preencher a largura
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50), // Espaçamento vertical
              Center(
                // Center para centralizar o circulo do bluetooth na tela
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF191C23),
                  child: Icon(
                    Icons.bluetooth,
                    size: 75,
                    color: Color(0xFF33DDFF), // A cor azul claro para o ícone
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Conectar carrinho',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'selecione um dispositivo para começar',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 50),

              // Expanded faz esta seção ocupar todo o espaço vertical
              Expanded(
                // ValueListenableBuilder é o widget que "ouve" as mudanças em um ValueNotifier.
                //se reconstroi automaticamente quando o valor do `scanResults` muda
                child: ValueListenableBuilder<List<ScanResult>>(
                  valueListenable: _bluetoothService.scanResults,
                  // builder é a função que constrói a UI com base no valor atual.
                  // `results` aqui é a lista atual de ScanResult.
                  builder: (context, results, child) {
                    //se nao tiver resiultados, mostra uma mensagem
                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum dispositivo encontrado.\nClique em "Procurar".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    //se houver resultados, vai construir a lista
                    //ListView.separated é ótimo para listas com espaçamento entre os itens
                    return ListView.separated(
                      itemCount: results.length,
                      //constroi o visual de cada item da lista
                      itemBuilder: (context, index) {
                        final result =
                            results[index]; //pega o resultado do scan atua
                        final device = result.device;
                        final deviceName = device.platformName.isNotEmpty
                            ? device.platformName
                            : (result.advertisementData.advName.isNotEmpty
                                  ? result.advertisementData.advName
                                  : 'ID: ${device.remoteId}');

                        // Cada item da lista é um botão ElevatedButton.
                        return ElevatedButton(
                          onPressed: () => _connect(
                            device,
                          ), // Ao clicar, chama a função _connect.
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 21,
                                backgroundColor: Color(0x2633DDFF),
                                child: const Icon(
                                  Icons.bluetooth,
                                  size: 25,
                                  color: Color(0xFF33DDFF),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Espaço entre ícone e texto.
                              // Expanded garante que o texto não "empurre" outros elementos se for muito longo
                              Expanded(
                                child: Text(
                                  deviceName, // Mostra o nome do dispositivo
                                  overflow: TextOverflow
                                      .ellipsis, // se n couber vai adicionar o ...
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      // separatorBuilder define o que vai entre cada item da lista, no caso um espaço vertical
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              //Este ValueListenableBuilder ouve se o scan está ativo.
              ValueListenableBuilder<bool>(
                valueListenable: _bluetoothService.isScanning,
                builder: (context, isScanning, _) {
                  // Este ValueListenableBuilder interno ouve o estado da conexão, o que permite que o botão reaja a AMBOS os estados
                  return ValueListenableBuilder<BluetoothConnectionState>(
                    valueListenable: _bluetoothService.connectionState,
                    builder: (context, connState, _) {
                      // Variáveis para definir o conteúdo e a ação do botão dinamicamente
                      Widget buttonChild;
                      VoidCallback?
                      onPressedAction; // Pode ser nulo para desabilitar o botão

                      if (isScanning) {
                        // Se está escaneando: mostra um círculo de progresso
                        buttonChild = const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        );
                        onPressedAction = null; //desabilita o clique
                      } else if (connState ==
                          BluetoothConnectionState.connecting) {
                        // Se está conectando: mostra progresso e texto "Conectando..."
                        buttonChild = const Row(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Centraliza o conteúdo.
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
                        onPressedAction = null; // Desabilita o clique
                      } else if (connState ==
                          BluetoothConnectionState.connected) {
                        // Se está conectado: mostra ícone e texto "Desconectar".
                        buttonChild = const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_disabled),
                            SizedBox(width: 10),
                            Text('Desconectar'),
                          ],
                        );
                        onPressedAction =
                            _disconnect; // Ação agora é desconectar
                      } else {
                        // Estado padrão (desconectado e não escaneando): mostra "Procurar dispositivos"
                        buttonChild = const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_searching),
                            SizedBox(width: 30),
                            Text('Procurar dispositivos'),
                          ],
                        );
                        onPressedAction =
                            _startScanning; // Ação é iniciar o scan.
                      }

                      // Constrói o botão OutlinedButton com o conteúdo e ação definidos
                      return OutlinedButton(
                        onPressed: onPressedAction,
                        child: buttonChild,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

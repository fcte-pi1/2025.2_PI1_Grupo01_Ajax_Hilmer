import 'package:flutter/material.dart';
import 'package:app/services/wifi_manager.dart';
import 'route_editor_screen.dart';
import '../../service_locator.dart';

// TELA DE CONEXÃO WIFI

class WifiConnectionScreen extends StatefulWidget {
  const WifiConnectionScreen({super.key});

  @override
  State<WifiConnectionScreen> createState() => _WifiConnectionScreenState();
}

class _WifiConnectionScreenState extends State<WifiConnectionScreen> {
  late final WifiManager _wifiManager = locator<WifiManager>();

  bool _isConnecting = false;
  String _statusMessage = '';

  // Configuração padrão
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.4.1');

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    _wifiManager.isConnected.addListener(_handleConnectionChange);
  }

  void _handleConnectionChange() {
    if (!mounted) return;

    if (_wifiManager.isConnected.value) {
      print("[WifiConnectionScreen] Conectado! Navegando...");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RouteEditorScreen(connectionType: 'wifi'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _wifiManager.isConnected.removeListener(_handleConnectionChange);
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectToCarrinho() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Conectando...';
    });

    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Digite o IP do carrinho';
      });
      return;
    }

    print("[WifiConnectionScreen] Tentando conectar a $ip...");

    final success = await _wifiManager.connect(ip: ip);

    if (!mounted) return;

    if (success) {
      setState(() {
        _statusMessage = 'Conectado!';
      });
    } else {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Falha ao conectar. Verifique:\n'
            '• Se você está conectado à rede WiFi do carrinho\n'
            '• Se o carrinho está ligado';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conexão WiFi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Ícone WiFi
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191C23),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.wifi,
                    size: 60,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Conectar via WiFi',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // Instruções
              _InstructionCard(
                number: '1',
                title: 'Abra as configurações WiFi do celular',
                icon: Icons.settings,
              ),
              const SizedBox(height: 12),
              _InstructionCard(
                number: '2',
                title: 'Conecte à rede mesma rede do carrinho',
                icon: Icons.wifi_find,
              ),
              const SizedBox(height: 12),
              _InstructionCard(
                number: '3',
                title: 'Volte aqui e clique em Conectar',
                icon: Icons.touch_app,
              ),

              const SizedBox(height: 30),

              // Campo de IP
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF191C23),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicione o IP do Carrinho',
                      style:
                          textTheme.titleSmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '192.168.4.1',
                        prefixIcon:
                            const Icon(Icons.router, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('Conectado!')
                        ? Colors.green.withOpacity(0.2)
                        : _statusMessage.contains('Falha')
                            ? Colors.red.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Conectado!')
                          ? Colors.green
                          : _statusMessage.contains('Falha')
                              ? Colors.red
                              : Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Botão Conectar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _connectToCarrinho,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isConnecting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Conectando...',
                                style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi, size: 24),
                            SizedBox(width: 12),
                            Text('Conectar', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão para abrir configurações WiFi
              TextButton.icon(
                onPressed: () {
                  // Abre as configurações de WiFi do sistema
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Abra as Configurações > WiFi do seu celular'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Color(0xFF33DDFF)),
                label: const Text(
                  'Abrir configurações WiFi',
                  style: TextStyle(color: Color(0xFF33DDFF)),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String number;
  final String title;
  final String? subtitle;
  final IconData icon;

  const _InstructionCard({
    required this.number,
    required this.title,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191C23),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF33DDFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF33DDFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 24),
        ],
      ),
    );
  }
}

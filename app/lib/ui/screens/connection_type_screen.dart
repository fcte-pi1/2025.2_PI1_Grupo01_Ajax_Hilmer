import 'package:flutter/material.dart';
import 'connection_screen.dart';
import 'wifi_connection_screen.dart';

// Tela inicial para selecionar o tipo de conexão: Bluetooth ou WiFi
class ConnectionTypeScreen extends StatelessWidget {
  const ConnectionTypeScreen({super.key});

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
              const SizedBox(height: 60),

              // Logo/Ícone
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF191C23),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 70,
                    color: Color(0xFF33DDFF),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Carrinho PI1',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Escolha como deseja conectar',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),

              const SizedBox(height: 60),

              // Botão Bluetooth
              _ConnectionOptionCard(
                icon: Icons.bluetooth,
                title: 'Bluetooth',
                subtitle: 'Em desenvolvimento',
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ConnectionScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Botão WiFi
              _ConnectionOptionCard(
                icon: Icons.wifi,
                title: 'WiFi',
                subtitle: 'Pronto para usar',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WifiConnectionScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ConnectionOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191C23),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

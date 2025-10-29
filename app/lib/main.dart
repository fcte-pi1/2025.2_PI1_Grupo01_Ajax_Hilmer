import 'package:flutter/material.dart';
import 'package:app/ui/screens/bluetooth_screen.dart';

void main() {
  runApp(const MyApp()); //Inicia o widget principal MyApp
}

//Herda de `StatelessWidget`, O QUE Significa que este widget em si não tem estado interno que muda
//unica funcao dele é configurar coisas que raramente mudam, como o tema e a tela inicial.
class MyApp extends StatelessWidget {
  //construtor pafrão
  const MyApp({super.key});

  //    - O Flutter chama este método sempre que precisa desenhar este widget.
  //    - Retorna um `MaterialApp`: O widget fundamental que configura um app Material Design.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Carrinho PI1',
      debugShowCheckedModeBanner: false, // Remove a faixa de debug no canto superior direito do app
      //`theme`: Define a aparência global do app
      //`ThemeData`: Objeto que guarda todas as configurações de estilo.
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Cor de fundo padrão para as telas (`Scaffold`)
        scaffoldBackgroundColor: Color(0xFF0D0F14),  //por algum motivo a cor está um pouco diferente do esperado
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0F14), // Mesma cor do fundo
          elevation: 0,
        ),

        // Estilos Específicos para Tipos de Botões
        // Estilo para `ElevatedButton` (botões preenchidos, como os da lista)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF191C23), // Cor de fundo do botão
            foregroundColor: Colors.white, // Cor do texto e ícone
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ), // Espaçamento interno
            fixedSize: const Size(300, 70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bordas arredondadas
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ), // Estilo do texto
          ),
        ),

        // Estilo para `OutlinedButton` (botão de procurar, com borda)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF191C23), // Cor de fundo do botão
            foregroundColor: Colors.white, // Cor do texto e ícone
            side: const BorderSide(
              color: Color(0xFF33DDFF),
              width: 2,
            ), // Borda azul e espessura
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Estilo padrão para textos
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(
            color: Colors.white,
          ), // Cor padrão para textos normais
        ),
      ),

      //`home`: Define qual widget (tela) será exibido quando o app iniciar
      home: const BluetoothScreen(), // Aponta para a nossa tela de conexão
    );
  }
}

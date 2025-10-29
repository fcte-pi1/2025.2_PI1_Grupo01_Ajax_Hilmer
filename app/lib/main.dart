// lib/main.dart

import 'package:flutter/material.dart';
import 'ui/screens/connection_screen.dart';

void main() {
  runApp(const MyApp()); //Inicia o widget principal MyApp
}

//Herda de `StatelessWidget`, O QUE Significa que este widget em si não tem estado interno que muda
//unica funcao dele é configurar coisas que raramente mudam, como o tema e a tela inicial.
class MyApp extends StatelessWidget {
  //construtor pafrão
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Carrinho PI1',
      debugShowCheckedModeBanner: false,
      //`theme`: Define a aparência global do app
      //`ThemeData`: Objeto que guarda todas as configurações de estilo.
      theme: ThemeData(
        primarySwatch: Colors.blue, //azul como base para cores derivadas
        // Cor de fundo padrão para as telas (`Scaffold`)
        scaffoldBackgroundColor: Color(0xFF0D0F14), // Sua cor oficial de fundo
        fontFamily: 'Poppins', // Sua fonte oficial
        brightness: Brightness.dark,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0F14), // Mesma cor do fundo
          elevation: 0, // Sem sombra
          // Estilo de texto para a AppBar
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600, // SemiBold
            color: Colors.white, // Garante cor branca
          ),
          iconTheme: IconThemeData(
            color: Colors.white, // Cor dos ícones (ex: botão voltar)
          ),
        ),
        // Estilo para `ElevatedButton`
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF191C23),
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            fixedSize: const Size(300, 70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500, // Medium
              fontFamily: 'Poppins', // Garante a fonte
            ),
          ),
        ),

        // Estilo para `OutlinedButton` (botão de procurar, com borda)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF191C23),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF33DDFF), width: 2),
            padding: EdgeInsets.zero, // Zerado para usar fixedSize
            fixedSize: const Size(300, 70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold, // Bold
              fontFamily: 'Poppins', // Garante a fonte
            ),
          ),
        ),

        // alterar os deprecated para o padrao hexadecimal
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(
            0.3,
          ), // Fundo levemente transparente
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none, // Sem borda
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
          ), // Cor do placeholder
          prefixIconColor: Colors.white54,
        ),

        //estilo padrão para textos
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          titleMedium: TextStyle(color: Colors.white70, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
        ),

        // Cor padrão para ícones
        iconTheme: const IconThemeData(color: Colors.white),

        // Cor de destaque para elementos
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          accentColor: const Color(0xFF33DDFF),
        ).copyWith(secondary: const Color(0xFF33DDFF)),
      ),

      //home mostra qual tela vai ser iniciada ao abrir o app
      home: const ConnectionScreen(), // Aponta para a tela de conexão
    );
  }
}

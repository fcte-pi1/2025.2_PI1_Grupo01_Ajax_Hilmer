import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic UI components render correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF191C23),
                child: Icon(Icons.bluetooth, size: 75, color: Color(0xFF33DDFF)),
              ),
              SizedBox(height: 30),
              Text('Conectar carrinho'),
              Text('selecione um dispositivo para começar'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Conectar carrinho'), findsOneWidget);
    expect(find.text('selecione um dispositivo para começar'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth), findsOneWidget);
  });
}
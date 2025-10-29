import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Define a URL base baseada na plataforma (Android Emulador usa 10.0.2.2)
  // Para iOS simulador ou dispositivo físico, use o IP da sua máquina na rede local
  late final String _baseUrl;

  ApiService() {
    if (Platform.isAndroid) {
      _baseUrl = "http://10.0.2.2:8000"; // IP especial do emulador para localhost da máquina host
    } else {
      // TODO: Substituir pelo ip da maquina local
      _baseUrl = "http://localhost:8000"; // Ex: http://192.168.1.10:8000
    }
     print("[ApiService] Usando baseURL: $_baseUrl");
  }

  /// Salva a rota no backend via POST /routes/
  Future<bool> saveRoute(String commandsString) async {
    final url = Uri.parse('$_baseUrl/routes/');
    print("[ApiService] POST $url \n Body: {'commands': '$commandsString'}");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'commands': commandsString}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print("[ApiService] Rota salva com sucesso (201).");
        return true;
      } else {
        print("[ApiService] Erro ao salvar rota: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("[ApiService] Exceção ao salvar rota: $e");
      return false;
    }
  }

  /// Busca as rotas anteriores do backend via GET /routes/
  Future<List<Map<String, dynamic>>> getPreviousRoutes() async {
    final url = Uri.parse('$_baseUrl/routes/');
    print("[ApiService] GET $url");
    try {
      final response = await http.get(
          url,
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Usa utf8.decode para garantir decodificação correta
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        print("[ApiService] Rotas recebidas: ${data.length}");
        // Converte para o tipo correto e retorna
        return List<Map<String, dynamic>>.from(data.map((item) => item as Map<String, dynamic>));
      } else {
        print("[ApiService] Erro ao buscar rotas: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("[ApiService] Exceção ao buscar rotas: $e");
      return [];
    }
  }

  // TODO: Adicionar métodos para Telemetria
}
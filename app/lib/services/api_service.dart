import 'dart:convert';
// import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart' show kReleaseMode; 

class ApiService {
  late final String _baseUrl;
  final Duration _timeout = const Duration(seconds: 15);

  // recebe a baseUrl pelo construtor
  ApiService({required String baseUrl}) {
    _baseUrl = baseUrl;
    // Removida a lógica do kReleaseMode e a URL hardcoded
    print("[ApiService] Usando baseURL: $_baseUrl");
  }

  //POST /routes/
  Future<bool> saveRoute(String commandsString) async {

    final url = Uri.parse('$_baseUrl/routes/');
    print("[ApiService] POST $url \n Body: {'commands': '$commandsString'}");
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'commands': commandsString}),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        print("[ApiService] Rota salva com sucesso (201).");
        return true;
      } else {
        print(
          "[ApiService] Erro ao salvar rota: ${response.statusCode} - ${response.body}",
        );
        return false;
      }
    } catch (e) {
      print("[ApiService] Exceção ao salvar rota: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPreviousRoutes({
    int limit = 20,
    int offset = 0,
  }) async {
    final url = Uri.parse('$_baseUrl/routes/?limit=$limit&offset=$offset');
    print("[ApiService] GET $url");

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
       
        Map<String, dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> data = responseData['routes'] as List<dynamic>;

        print("[ApiService] Rotas recebidas: ${data.length} rotas.");
        return List<Map<String, dynamic>>.from(
          data.map((item) => item as Map<String, dynamic>),
        );
      } else {
        print(
          "[ApiService] Erro ao buscar rotas: ${response.statusCode} - ${response.body}",
        );
        return [];
      }
    } catch (e) {
      print("[ApiService] Exceção ao buscar rotas: $e");
      // Lança a exceção para que a UI saiba que falhou
      throw Exception('Falha ao buscar rotas: $e');
    }
  }

  // TODO: Adicionar métodos para Telemetria
}
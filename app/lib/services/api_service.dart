import 'dart:convert';
// import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart' show kReleaseMode;

// CLASSE RESPONSAVEL PELAS CHAMADAS À API

class ApiService {
  late final String _baseUrl;
  final Duration _timeout = const Duration(seconds: 15);

  ApiService({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  Future<bool> saveRoute(String commandsString) async {
    final url = Uri.parse('$_baseUrl/routes/');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'commands': commandsString}),
          )
          .timeout(_timeout);

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPreviousRoutes({
    int limit = 20,
    int offset = 0,
  }) async {
    final url = Uri.parse('$_baseUrl/routes/?limit=$limit&offset=$offset');
    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'}).timeout(_timeout);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> data = responseData['routes'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(
          data.map((item) => item as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Falha ao buscar rotas: $e');
    }
  }

  Future<Map<String, dynamic>?> createRoute(String commandsString) async {
    final url = Uri.parse('$_baseUrl/routes/');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'commands': commandsString}),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 409) {
        // Rota já existe, busca o ID dela
        return await _findRouteByCommands(commandsString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Busca uma rota pelo comando exato
  Future<Map<String, dynamic>?> _findRouteByCommands(String commands) async {
    try {
      // Busca todas as rotas
      final routes = await getPreviousRoutes(limit: 100, offset: 0);
      for (final route in routes) {
        if (route['commands'] == commands) {
          return route;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTelemetries({
    int limit = 10,
    int offset = 0,
    String orderBy = 'desc',
  }) async {
    final url = Uri.parse(
        '$_baseUrl/telemetries/?limit=$limit&offset=$offset&order_by=$orderBy');
    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'}).timeout(_timeout);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> data = responseData['telemetries'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(
          data.map((item) => item as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Falha ao buscar telemetrias: $e');
    }
  }

  Future<bool> createTelemetry(
      int routeId, Map<String, dynamic> telemetryData) async {
    final url = Uri.parse('$_baseUrl/telemetries/$routeId');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(telemetryData),
          )
          .timeout(_timeout);

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

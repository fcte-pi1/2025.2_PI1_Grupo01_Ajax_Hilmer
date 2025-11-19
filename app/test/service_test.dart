import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    test('ApiService initialization', () {
      final apiService = ApiService(baseUrl: 'http://localhost:8000');
      expect(apiService, isNotNull);
    });

    test('ApiService methods exist', () {
      final apiService = ApiService(baseUrl: 'http://localhost:8000');
      expect(apiService.saveRoute, isNotNull);
      expect(apiService.getPreviousRoutes, isNotNull);
    });

    test('ApiService method signatures', () {
      final apiService = ApiService(baseUrl: 'http://localhost:8000');
      final saveResult = apiService.saveRoute('ANDAR 100 CM');
      expect(saveResult, isA<Future<bool>>());
      final routesResult = apiService.getPreviousRoutes();
      expect(routesResult, isA<Future<List<Map<String, dynamic>>>>());
    });
  });
}
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vetpax_frontend/core/api/api_client.dart';
import 'package:vetpax_frontend/core/storage/token_storage.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';

class MemoryTokenStorage implements TokenStorage {
  String? access = 'test-token';
  @override Future<String?> getToken() async => access;
  @override Future<void> saveToken(String token) async { access = token; }
  @override Future<void> deleteToken() async { access = null; }
  @override Future<void> saveRefreshToken(String token) async {}
  @override Future<String?> getRefreshToken() async => null;
  @override Future<void> saveTokenExpiry(DateTime date) async {}
  @override Future<DateTime?> getTokenExpiry() async => null;
  @override Future<void> saveUserId(String id) async {}
  @override Future<String?> getUserId() async => null;
  @override Future<void> saveRole(String role) async {}
  @override Future<String?> getRole() async => null;
  @override Future<void> saveStatus(String status) async {}
  @override Future<String?> getStatus() async => null;
  @override Future<void> clearAll() async { access = null; }
}

void main() {
  test('Listado de mascotas envía Bearer y obtiene los UUID', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/pets');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(jsonEncode([{'petId':'abc-123','name':'Max','species':'Dog'}]), 200);
    });
    final repo = VetPaxRepository(ApiClient(
      baseUrl: 'http://localhost:5139/api/v1', tokenStorage: MemoryTokenStorage(), client: client));
    final pets = await repo.myPets();
    expect(pets.single['name'], 'Max');
    expect(pets.single['petId'], 'abc-123');
  });

  test('Directorio de clínicas utiliza los parámetros de paginación', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['page'], '1');
      expect(request.url.queryParameters['pageSize'], '20');
      return http.Response('{"page":1,"pageSize":20,"totalCount":1,"items":[{"clinicId":"c1","name":"VetPax"}]}', 200);
    });
    final repo = VetPaxRepository(ApiClient(
      baseUrl: 'http://localhost:5139/api/v1', tokenStorage: MemoryTokenStorage(), client: client));
    expect((await repo.clinics()).single['name'], 'VetPax');
  });

  test('404 al consultar alimentación activa significa sin plan activo', () async {
    final client = MockClient((request) async => http.Response('{"title":"Feeding plan not found"}', 404));
    final repo = VetPaxRepository(ApiClient(
      baseUrl: 'http://localhost:5139/api/v1', tokenStorage: MemoryTokenStorage(), client: client));
    expect(await repo.activeFeedingPlan('pet-id'), isNull);
  });

  test('No se pierde un error 403 de autorización', () async {
    final client = MockClient((request) async => http.Response('{"detail":"Access denied"}', 403));
    final repo = VetPaxRepository(ApiClient(
      baseUrl: 'http://localhost:5139/api/v1', tokenStorage: MemoryTokenStorage(), client: client));
    await expectLater(repo.myPets(), throwsA(isA<VetPaxApiException>()));
  });
}

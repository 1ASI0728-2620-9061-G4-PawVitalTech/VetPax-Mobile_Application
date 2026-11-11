import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vetpax_frontend/core/api/api_client.dart';
import 'package:vetpax_frontend/core/storage/token_storage.dart';

class MemoryTokenStorage implements TokenStorage {
  String? access = 'test-token';
  String? userId;
  MemoryTokenStorage({this.userId = 'user-1'});
  @override Future<String?> getToken() async => access;
  @override Future<void> saveToken(String token) async { access = token; }
  @override Future<void> deleteToken() async { access = null; }
  @override Future<void> saveRefreshToken(String token) async {}
  @override Future<String?> getRefreshToken() async => null;
  @override Future<void> saveTokenExpiry(DateTime date) async {}
  @override Future<DateTime?> getTokenExpiry() async => null;
  @override Future<void> saveUserId(String id) async { userId = id; }
  @override Future<String?> getUserId() async => userId;
  @override Future<void> saveRole(String role) async {}
  @override Future<String?> getRole() async => null;
  @override Future<void> saveStatus(String status) async {}
  @override Future<String?> getStatus() async => null;
  @override Future<void> clearAll() async { access = null; }
}

ApiClient apiWith(Future<http.Response> Function(http.Request request) handler,
        {MemoryTokenStorage? storage}) =>
    ApiClient(
      baseUrl: 'http://localhost:5139/api/v1',
      tokenStorage: storage ?? MemoryTokenStorage(),
      client: MockClient(handler),
    );

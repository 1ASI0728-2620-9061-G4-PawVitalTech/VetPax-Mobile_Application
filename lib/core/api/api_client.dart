import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class VetPaxApiException implements Exception {
  final int statusCode;
  final String message;
  const VetPaxApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final TokenStorage tokenStorage;
  Future<String?> Function()? refreshAccessToken;
  final http.Client _http;
  ApiClient({required this.baseUrl, required this.tokenStorage, http.Client? client})
      : _http = client ?? http.Client();

  Uri _uri(String endpoint, Map<String, String>? params) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$base$path');
    return params == null ? uri : uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  Future<dynamic> request(
    String method,
    String endpoint, {
    Object? body,
    bool requiresAuth = true,
    Map<String, String>? query,
  }) async {
    final uri = _uri(endpoint, query);
    var token = requiresAuth ? await tokenStorage.getToken() : null;
    // Si ya venció, intentar renovar antes de enviar la petición.
    if (requiresAuth && refreshAccessToken != null) {
      final expires = await tokenStorage.getTokenExpiry();
      if (token == null || (expires != null &&
          expires.isBefore(DateTime.now().toUtc().add(const Duration(seconds: 25))))) {
        token = await refreshAccessToken!();
      }
    }
    Future<http.Response> send(String? credential) {
      final headers = <String, String>{'Accept': 'application/json', 'Content-Type': 'application/json'};
      if (requiresAuth && credential != null) headers['Authorization'] = 'Bearer $credential';
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET': return _http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
        case 'POST': return _http.post(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 25));
        case 'PUT': return _http.put(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 25));
        case 'PATCH': return _http.patch(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 25));
        case 'DELETE': return _http.delete(uri, headers: headers).timeout(const Duration(seconds: 25));
        default: throw ArgumentError('Unsupported HTTP method: $method');
      }
    }
    var response = await send(token);
    if (requiresAuth && response.statusCode == 401 && refreshAccessToken != null) {
      token = await refreshAccessToken!();
      if (token != null) response = await send(token); // Solo un reintento.
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null; // 204 No Content
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    String detail = 'Error HTTP ${response.statusCode}';
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        detail = (data['detail'] ?? data['message'] ?? data['title'] ?? detail).toString();
      }
    } catch (_) {}
    throw VetPaxApiException(response.statusCode, detail);
  }

  Future<dynamic> get(String path, {bool requiresAuth = true, Map<String, String>? query}) =>
      request('GET', path, requiresAuth: requiresAuth, query: query);
  Future<dynamic> post(String path, {Object? body, bool requiresAuth = true}) =>
      request('POST', path, body: body, requiresAuth: requiresAuth);
  Future<dynamic> patch(String path, {Object? body, bool requiresAuth = true}) =>
      request('PATCH', path, body: body, requiresAuth: requiresAuth);
  Future<dynamic> put(String path, {Object? body, bool requiresAuth = true}) =>
      request('PUT', path, body: body, requiresAuth: requiresAuth);
  Future<dynamic> delete(String path, {bool requiresAuth = true}) =>
      request('DELETE', path, requiresAuth: requiresAuth);
}

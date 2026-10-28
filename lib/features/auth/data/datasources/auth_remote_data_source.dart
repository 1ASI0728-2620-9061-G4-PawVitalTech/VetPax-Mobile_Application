import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:vetpax_frontend/core/api/api_client.dart';
import 'package:vetpax_frontend/core/constants.dart';
import 'package:vetpax_frontend/features/auth/domain/entities/user.dart';

class KeycloakTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiry;
  const KeycloakTokens(this.accessToken, this.refreshToken, this.expiry);
}

class AuthRemoteDataSource {
  final ApiClient apiClient;
  final FlutterAppAuth _auth = const FlutterAppAuth();
  AuthRemoteDataSource({required this.apiClient});

  String get _issuer => '$KEYCLOAK_URL/realms/$KEYCLOAK_REALM';
  AuthorizationServiceConfiguration get _endpoints => AuthorizationServiceConfiguration(
    authorizationEndpoint: '$_issuer/protocol/openid-connect/auth',
    tokenEndpoint: '$_issuer/protocol/openid-connect/token',
    endSessionEndpoint: '$_issuer/protocol/openid-connect/logout',
  );

  // OAuth2 Authorization Code con PKCE. Password se escribe en Keycloak.
  Future<KeycloakTokens> login({String? loginHint}) async {
    final result = await _auth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        KEYCLOAK_CLIENT_ID, KEYCLOAK_REDIRECT_URI,
        issuer: _issuer,
        serviceConfiguration: _endpoints,
        scopes: const ['openid', 'profile', 'email'],
        loginHint: loginHint?.isEmpty == true ? null : loginHint,
        allowInsecureConnections: KEYCLOAK_URL.startsWith('http://'),
      ),
    );
    final token = result.accessToken;
    if (token == null || token.isEmpty) throw StateError('Keycloak no devolvió un access token.');
    return KeycloakTokens(token, result.refreshToken, result.accessTokenExpirationDateTime);
  }

  Future<KeycloakTokens?> refresh(String refreshToken) async {
    final result = await _auth.token(TokenRequest(
      KEYCLOAK_CLIENT_ID, KEYCLOAK_REDIRECT_URI,
      issuer: _issuer,
      serviceConfiguration: _endpoints,
      refreshToken: refreshToken,
      scopes: const ['openid', 'profile', 'email'],
      allowInsecureConnections: KEYCLOAK_URL.startsWith('http://'),
    ));
    if (result.accessToken == null) return null;
    return KeycloakTokens(result.accessToken!, result.refreshToken, result.accessTokenExpirationDateTime);
  }

  Future<User> me() async {
    final data = await apiClient.get('/auth/me');
    return User.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<User> register({
    required String email, required String password,
    required String firstName, required String lastName,
  }) async {
    final data = await apiClient.post('/auth/register', requiresAuth: false,
      body: {'email': email, 'password': password, 'firstName': firstName, 'lastName': lastName});
    return User.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

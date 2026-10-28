import 'package:vetpax_frontend/core/storage/token_storage.dart';
import 'package:vetpax_frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vetpax_frontend/features/auth/domain/entities/session.dart';
import 'package:vetpax_frontend/features/auth/domain/entities/user.dart';
import 'package:vetpax_frontend/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  Future<String?>? _refreshing;
  AuthRepositoryImpl({required this.remoteDataSource, required this.tokenStorage});

  Future<void> _saveTokens(KeycloakTokens tokens) async {
    await tokenStorage.saveToken(tokens.accessToken);
    if (tokens.refreshToken != null) await tokenStorage.saveRefreshToken(tokens.refreshToken!);
    if (tokens.expiry != null) await tokenStorage.saveTokenExpiry(tokens.expiry!);
  }

  @override
  Future<Session> login(String email, String password) async {
    // La contraseña NO se envía desde la app; AppAuth abre Keycloak con PKCE.
    final tokens = await remoteDataSource.login(loginHint: email);
    await _saveTokens(tokens);
    try {
      final user = await remoteDataSource.me();
      if (user.role != Role.owner) {
        await logout();
        throw StateError('Esta aplicación es solo para propietarios de mascotas.');
      }
      await tokenStorage.saveUserId(user.id);
      await tokenStorage.saveRole('owner');
      return Session(token: tokens.accessToken, user: user);
    } catch (_) { await tokenStorage.clearAll(); rethrow; }
  }

  @override
  Future<Session?> restoreSession() async {
    if (await tokenStorage.getRefreshToken() == null) return null;
    final token = await refreshAccessToken();
    if (token == null) return null;
    try {
      final user = await remoteDataSource.me();
      if (user.role != Role.owner) { await logout(); return null; }
      return Session(token: token, user: user);
    } catch (_) { await logout(); return null; }
  }

  @override
  Future<String?> refreshAccessToken() async {
    final previous = _refreshing;
    if (previous != null) return previous;
    final future = _performRefresh();
    _refreshing = future;
    try { return await future; } finally { _refreshing = null; }
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final result = await remoteDataSource.refresh(refreshToken);
      if (result == null) { await tokenStorage.clearAll(); return null; }
      await _saveTokens(result);
      return result.accessToken;
    } catch (_) { await tokenStorage.clearAll(); return null; }
  }

  @override
  Future<void> logout() => tokenStorage.clearAll();

  @override
  Future<User> register({required String email, required String password,
    required String firstName, required String lastName}) =>
      remoteDataSource.register(email: email, password: password,
        firstName: firstName, lastName: lastName);
}

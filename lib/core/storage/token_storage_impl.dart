import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

class TokenStorageImpl implements TokenStorage {
  final FlutterSecureStorage _store = const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) => _store.write(key: 'vp_access', value: token);
  @override
  Future<String?> getToken() => _store.read(key: 'vp_access');
  @override
  Future<void> deleteToken() => _store.delete(key: 'vp_access');
  @override
  Future<void> saveRefreshToken(String token) => _store.write(key: 'vp_refresh', value: token);
  @override
  Future<String?> getRefreshToken() => _store.read(key: 'vp_refresh');
  @override
  Future<void> saveTokenExpiry(DateTime date) =>
      _store.write(key: 'vp_expiry', value: date.toUtc().toIso8601String());
  @override
  Future<DateTime?> getTokenExpiry() async {
    final value = await _store.read(key: 'vp_expiry');
    return value == null ? null : DateTime.tryParse(value);
  }
  @override
  Future<void> saveUserId(String id) => _store.write(key: 'vp_user', value: id);
  @override
  Future<String?> getUserId() => _store.read(key: 'vp_user');
  @override
  Future<void> saveRole(String role) => _store.write(key: 'vp_role', value: role);
  @override
  Future<String?> getRole() => _store.read(key: 'vp_role');
  @override
  Future<void> saveStatus(String status) => _store.write(key: 'vp_status', value: status);
  @override
  Future<String?> getStatus() => _store.read(key: 'vp_status');
  @override
  Future<void> clearAll() async {
    for (final key in ['vp_access','vp_refresh','vp_expiry','vp_user','vp_role','vp_status',
                       'auth_token','user_id','user_role','user_status']) {
      await _store.delete(key: key);
    }
  }
}

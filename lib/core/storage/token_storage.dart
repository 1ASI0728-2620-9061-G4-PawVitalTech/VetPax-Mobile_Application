abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> saveTokenExpiry(DateTime date);
  Future<DateTime?> getTokenExpiry();
  Future<void> saveUserId(String id);
  Future<String?> getUserId();
  Future<void> saveRole(String role);
  Future<String?> getRole();
  Future<void> saveStatus(String status);
  Future<String?> getStatus();
  Future<void> clearAll();
}

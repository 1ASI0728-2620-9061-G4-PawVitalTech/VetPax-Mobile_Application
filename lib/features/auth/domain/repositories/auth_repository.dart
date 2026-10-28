import '../entities/session.dart';
import '../entities/user.dart';
abstract class AuthRepository {
  Future<Session> login(String email, String password);
  Future<Session?> restoreSession();
  Future<void> logout();
  Future<String?> refreshAccessToken();
  Future<User> register({required String email, required String password,
    required String firstName, required String lastName});
}

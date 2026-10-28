import '../entities/session.dart';
import '../repositories/auth_repository.dart';
 
class LoginUser {
  final AuthRepository repository;
 
  LoginUser(this.repository);
 
  Future<Session> call(String email, String password) {
    return repository.login(email, password);
  }
}
 
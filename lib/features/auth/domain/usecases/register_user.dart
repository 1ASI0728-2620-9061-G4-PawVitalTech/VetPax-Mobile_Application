import '../entities/user.dart';
import '../repositories/auth_repository.dart';
 
class RegisterUser {
  final AuthRepository repository;
 
  RegisterUser(this.repository);
 
  Future<User> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return repository.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
 
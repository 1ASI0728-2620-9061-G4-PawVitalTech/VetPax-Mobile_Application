import 'user.dart';
class Session {
  final String token;
  final User user;
  const Session({required this.token, required this.user});
}

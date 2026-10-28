import 'package:vetpax_frontend/app/pages/main_page.dart';
import 'package:vetpax_frontend/features/auth/domain/usecases/login_user.dart';
import 'package:vetpax_frontend/features/auth/domain/usecases/register_user.dart';
import 'package:vetpax_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:vetpax_frontend/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';

class AppRouter {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  AppRouter({required this.loginUser, required this.registerUser});
  Widget loginPage() => LoginPage(loginUser: loginUser);
  Widget mainPage() => const MainPage();

  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login': return MaterialPageRoute(builder: (_) => loginPage());
      case '/register': return MaterialPageRoute(builder: (_) => RegisterPage(registerUser: registerUser));
      case '/main': return MaterialPageRoute(builder: (_) => mainPage());
      default: return MaterialPageRoute(builder: (_) => Scaffold(
        body: Center(child: Text('No route defined for ${settings.name}'))));
    }
  }
}

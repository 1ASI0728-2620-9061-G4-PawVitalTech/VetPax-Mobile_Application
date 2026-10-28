import 'package:vetpax_frontend/app/router/app_router.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:vetpax_frontend/features/auth/domain/usecases/login_user.dart';
import 'package:vetpax_frontend/features/auth/domain/usecases/register_user.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureInjector();
  final router = AppRouter(loginUser: injector<LoginUser>(), registerUser: injector<RegisterUser>());
  runApp(MyApp(appRouter: router));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: appRouter.generateRoute,
      home: FutureBuilder(
        future: injector<AuthRepository>().restoreSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data == null
              ? appRouter.loginPage()
              : appRouter.mainPage();
        },
      ),
    );
  }
}

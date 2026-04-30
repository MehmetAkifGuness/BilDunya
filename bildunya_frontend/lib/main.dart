import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';

void main() {
  runApp(const BilDunyaApp());
}

class BilDunyaApp extends StatelessWidget {
  const BilDunyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BilDünya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
      },
    );
  }
}

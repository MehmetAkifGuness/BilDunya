import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/content_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/content/providers/contents_provider.dart';
import 'features/shell/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final dio = DioClient.create(storage);
  final authRepository = AuthRepository(dio, storage);
  final contentRepository = ContentRepository(dio);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ContentsProvider(contentRepository),
        ),
      ],
      child: const BilDunyaApp(),
    ),
  );
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
        MainShell.routeName: (_) => const MainShell(),
      },
    );
  }
}

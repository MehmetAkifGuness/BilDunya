import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/comment_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/content/providers/contents_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/content/screens/content_detail_view.dart';
import 'features/content/screens/create_content_view.dart';
import 'features/content/screens/location_picker_view.dart';
import 'features/shell/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final dio = DioClient.create(storage);
  final authRepository = AuthRepository(dio, storage);
  final contentRepository = ContentRepository(dio);
  final commentRepository = CommentRepository(dio);
  final chatRepository = ChatRepository(dio);
  final profileRepository = ProfileRepository(dio);

  runApp(
    MultiProvider(
      providers: [
        Provider<ContentRepository>.value(value: contentRepository),
        Provider<CommentRepository>.value(value: commentRepository),
        Provider<ChatRepository>.value(value: chatRepository),
        Provider<ProfileRepository>.value(value: profileRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ContentsProvider(contentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(profileRepository, contentRepository),
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
        CreateContentView.routeName: (_) => const CreateContentView(),
        LocationPickerView.routeName: (_) => const LocationPickerView(),
        ContentDetailView.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! ContentDetailArgs) {
            return const Scaffold(
              body: Center(child: Text('Geçersiz içerik bağlantısı')),
            );
          }
          return ContentDetailView(args: args);
        },
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_auth_button.dart';
import '../widgets/splash_page_indicator.dart';
import '../../shell/main_shell.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoLogin());
  }

  Future<void> _tryAutoLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();
    if (!mounted || _navigated) return;
    if (auth.isAuthenticated) {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed(MainShell.routeName);
    }
  }

  void _onExplore() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(MainShell.routeName);
    } else {
      Navigator.of(context).pushNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 288,
                height: 288,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.08),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  Column(
                    children: [
                      Text(
                        'BilDünya',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryContainer,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'THE MIDNIGHT NAVIGATOR',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary.withValues(alpha: 0.6),
                          letterSpacing: 4.8,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yolculuğun Burada Başlıyor.',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Şehrin gizli rotalarını ve seçkin mekanlarını keşfetmek için profesyonel rehberin.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.secondary.withValues(alpha: 0.8),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  GradientAuthButton(
                    label: 'Keşfetmeye Başla',
                    height: 56,
                    onPressed: _onExplore,
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: const Center(child: SplashPageIndicator(activeIndex: 0)),
          ),
        ],
      ),
    );
  }
}

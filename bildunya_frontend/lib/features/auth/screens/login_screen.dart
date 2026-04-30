import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_auth_button.dart';
import '../widgets/social_auth_row.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 112),
              Text(
                'Tekrar Hoş Geldin.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hesabına giriş yaparak keşfe devam et.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondary.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              AuthTextField(
                controller: _emailController,
                label: 'E-posta adresi',
                hint: 'isim@ornek.com',
                prefixIcon: Symbols.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                height: 64,
                iconSize: 26,
              ),
              const SizedBox(height: 28),
              AuthTextField(
                controller: _passwordController,
                label: 'Şifre',
                hint: '••••••••',
                prefixIcon: Symbols.lock,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                height: 64,
                iconSize: 26,
                suffix: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Symbols.visibility_off
                        : Symbols.visibility,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    padding: const EdgeInsets.only(top: 8),
                  ),
                  child: Text(
                    'Şifremi Unuttum',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GradientAuthButton(
                label: 'Giriş Yap',
                height: 64,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                onPressed: () {},
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'VEYA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        letterSpacing: 3.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SocialAuthRow(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RegisterScreen.routeName);
                },
                child: Text(
                  'Hesabın yok mu? Kayıt ol',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary.withValues(alpha: 0.75),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.secondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

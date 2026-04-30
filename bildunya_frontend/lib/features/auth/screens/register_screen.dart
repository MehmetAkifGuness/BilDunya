import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/outline_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = true;

  @override
  void dispose() {
    _nameController.dispose();
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
                'Hesap Oluştur.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'BilDünya ekosistemine katılın.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondary.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              AuthTextField(
                controller: _nameController,
                label: 'Ad soyad',
                hint: 'Adınız Soyadınız',
                prefixIcon: Symbols.person,
                textInputAction: TextInputAction.next,
                height: 56,
                iconSize: 22,
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _emailController,
                label: 'E-posta',
                hint: 'eposta@adresiniz.com',
                prefixIcon: Symbols.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                height: 56,
                iconSize: 22,
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _passwordController,
                label: 'Şifre oluştur',
                hint: '••••••••',
                prefixIcon: Symbols.lock,
                obscureText: true,
                textInputAction: TextInputAction.done,
                height: 56,
                iconSize: 22,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _termsAccepted = !_termsAccepted);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _termsAccepted
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _termsAccepted
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: _termsAccepted
                          ? Icon(
                              Symbols.check,
                              size: 16,
                              color: AppColors.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Kullanım Koşullarını ve Gizlilik Politikasını okudum, kabul ediyorum.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlineAuthButton(
                label: 'Kayıt Ol',
                onPressed: () {},
              ),
              const Spacer(),
              Center(
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'Zaten bir hesabınız var mı? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed(
                              LoginScreen.routeName,
                            );
                          },
                          child: Text(
                            'Giriş Yap',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryContainer,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryContainer,
                              decorationThickness: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}

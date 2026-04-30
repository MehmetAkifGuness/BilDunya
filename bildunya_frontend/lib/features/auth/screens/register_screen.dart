import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/register_request.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/outline_auth_button.dart';
import '../../shell/main_shell.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_termsAccepted) {
      showAppSnackBar(
        context,
        'Devam etmek için koşulları kabul etmelisin.',
        isError: true,
      );
      return;
    }
    final username = _usernameController.text.trim();
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (username.length < 3) {
      showAppSnackBar(
        context,
        'Kullanıcı adı en az 3 karakter olmalı.',
        isError: true,
      );
      return;
    }
    if (fullName.isEmpty || email.isEmpty || password.length < 8) {
      showAppSnackBar(
        context,
        'Ad soyad, e-posta ve en az 8 karakterlik şifre gerekli.',
        isError: true,
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      RegisterRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        isAnonymous: false,
      ),
    );
    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(
        context,
        err.replaceFirst('Exception: ', ''),
        isError: true,
      );
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(MainShell.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  controller: _usernameController,
                  label: 'Kullanıcı adı',
                  hint: 'gezgin42',
                  prefixIcon: Symbols.alternate_email,
                  textInputAction: TextInputAction.next,
                  height: 56,
                  iconSize: 22,
                ),
                const SizedBox(height: 24),
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
                  onSubmitted: (_) => _submit(),
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
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
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
                  isLoading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),
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
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(LoginScreen.routeName);
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
      ),
    );
  }
}

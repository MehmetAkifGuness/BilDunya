import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/login_request.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_auth_button.dart';
import '../../shell/main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      showAppSnackBar(
        context,
        'Kullanıcı adı ve şifre gerekli.',
        isError: true,
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.login(
      LoginRequest(username: username, password: password),
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
                  controller: _usernameController,
                  label: 'Kullanıcı adı',
                  hint: 'gezgin42',
                  prefixIcon: Symbols.person,
                  keyboardType: TextInputType.text,
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
                  onSubmitted: (_) => _submit(),
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
                const SizedBox(height: 24),
                GradientAuthButton(
                  label: 'Giriş Yap',
                  height: 64,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  isLoading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),
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
                      decorationColor: AppColors.secondary.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

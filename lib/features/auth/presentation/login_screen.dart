import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/red_button.dart';
import '../../home/presentation/home_shell.dart';

/// Badar Tyres sign-in screen. A full-bleed garage photograph fades into the
/// dark "Garage Charcoal" surface, with the centered brand logo, a welcome
/// header, and the login form built from the shared [CustomTextField] and
/// [RedButton] components.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreSavedCredentials();
  }

  Future<void> _restoreSavedCredentials() async {
    final username = await SessionStore.instance.savedUsername;
    final remember = await SessionStore.instance.rememberMe;
    if (!mounted) return;
    setState(() {
      if (username != null) _usernameController.text = username;
      _rememberMe = remember;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _authRepository.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final user = await _authRepository.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (user.isAdminRole) {
        setState(() => _isLoading = false);
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please use the Web Admin Panel')),
        );
        return;
      }

      await SessionStore.instance.save(user, rememberMe: _rememberMe);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Stack(
        children: [
          // Garage photo anchored to the top, covering the upper portion.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/bg_1.png',
              height: size.height * 0.55,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Gradient that darkens the photo and blends it into the surface.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.surface.withValues(alpha: 0.30),
                    context.colors.surface.withValues(alpha: 0.55),
                    context.colors.surface,
                    context.colors.surface,
                  ],
                  stops: const [0.0, 0.35, 0.56, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerPadding,
              ),
              child: Column(
                children: [
                  // Logo centered over the photographic area.
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/badar_logo_black.svg',
                        width: size.width * 0.55,
                        semanticsLabel: 'Badar Tyres',
                      ),
                    ),
                  ),

                  // Login form on the dark surface.
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: context.typography.displayLg,
                            ),
                            const SizedBox(height: AppSpacing.base),
                            Text(
                              'Please login to your account',
                              textAlign: TextAlign.center,
                              style: context.typography.bodyMd.copyWith(
                                color: context.colors.secondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.stackLg),
                            CustomTextField(
                              hint: 'User Name',
                              controller: _usernameController,
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter your user name'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                            CustomTextField(
                              hint: 'Password',
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              suffixIcon: _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Please enter your password'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.base),
                            _RememberAndForgotRow(
                              rememberMe: _rememberMe,
                              onRememberChanged: (v) =>
                                  setState(() => _rememberMe = v),
                              onForgot: () {},
                            ),
                            const SizedBox(height: AppSpacing.stackLg),
                            RedButton(
                              label: 'Login',
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RememberAndForgotRow extends StatelessWidget {
  const _RememberAndForgotRow({
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgot,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => onRememberChanged(!rememberMe),
          borderRadius: AppRadius.brBase,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (v) => onRememberChanged(v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Text(
                  'Remember me',
                  style: context.typography.bodyMd.copyWith(
                    fontSize: 14,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onForgot,
          style: TextButton.styleFrom(
            foregroundColor: context.colors.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: context.typography.bodyMd.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

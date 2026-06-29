import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class _AuthPalette {
  const _AuthPalette({
    required this.primary,
    required this.soft,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color primary;
  final Color soft;
  final Color backgroundTop;
  final Color backgroundBottom;
  final IconData icon;
  final String title;
  final String subtitle;

  static const user = _AuthPalette(
    primary: Color(0xFFD32F2F),
    soft: Color(0xFFFFEBEE),
    backgroundTop: Color(0xFFFFF2F0),
    backgroundBottom: Color(0xFFFFFFFF),
    icon: Icons.restaurant_menu,
    title: 'Akun User & Kasir',
    subtitle:
        'Masuk dengan akun terdaftar, sistem akan membuka halaman sesuai role.',
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  _AuthPalette get _palette => _AuthPalette.user;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      debugPrint('Current User: ${authService.currentUser?.email}');
      debugPrint('Current Session: ${authService.currentSession != null}');

      if (!mounted) return;

      ref.invalidate(currentUserProvider);
      ref.invalidate(userRoleProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login berhasil!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      context.go('/');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.backgroundTop, palette.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 20,
                shadowColor: palette.primary.withValues(alpha: 0.14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo Container
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: palette.soft,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: 0.20),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            palette.icon,
                            size: 50,
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Welcome Text
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: palette.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk untuk melanjutkan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        _RoleHintCard(palette: palette),
                        const SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'contoh@email.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: palette.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Masukkan password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: palette.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: palette.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Belum punya akun?',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            TextButton(
                              onPressed: () {
                                context.push('/register');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: palette.primary,
                              ),
                              child: const Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleHintCard extends StatelessWidget {
  const _RoleHintCard({required this.palette});

  final _AuthPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            foregroundColor: palette.primary,
            child: Icon(palette.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  palette.title,
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  palette.subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _RoleBadges(),
        ],
      ),
    );
  }
}

class _RoleBadges extends StatelessWidget {
  const _RoleBadges();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _RoleBadge(label: 'User', icon: Icons.person_outline),
        SizedBox(height: 6),
        _RoleBadge(label: 'Kasir', icon: Icons.point_of_sale),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD32F2F)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

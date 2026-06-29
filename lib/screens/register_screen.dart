import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class _RegisterPalette {
  static const userPrimary = Color(0xFFD32F2F);
  static const userSoft = Color(0xFFFFEBEE);
  static const userBackground = Color(0xFFFFF2F0);
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validasi field kosong
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi username minimal 3 karakter
    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username minimal 3 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi email
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi password minimal 6 karakter
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 6 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi konfirmasi password
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      await authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      // Navigasi ke login setelah 1.5 detik
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          context.go('/');
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_RegisterPalette.userBackground, Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo Cafe
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _RegisterPalette.userSoft,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _RegisterPalette.userPrimary.withValues(
                          alpha: 0.18,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    size: 45,
                    color: _RegisterPalette.userPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  "Buat Akun",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _RegisterPalette.userPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Daftar sebagai user untuk mulai memesan",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Username Field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Masukkan username',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: _RegisterPalette.userPrimary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          labelStyle: GoogleFonts.poppins(),
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'contoh@email.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: _RegisterPalette.userPrimary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          labelStyle: GoogleFonts.poppins(),
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Minimal 6 karakter',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: _RegisterPalette.userPrimary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _RegisterPalette.userPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          labelStyle: GoogleFonts.poppins(),
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          hintText: 'Ketik ulang password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: _RegisterPalette.userPrimary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _RegisterPalette.userPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          labelStyle: GoogleFonts.poppins(),
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _RegisterPalette.userPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Daftar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Sudah punya akun? ",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go('/');
                            },
                            child: Text(
                              "Masuk",
                              style: GoogleFonts.poppins(
                                color: _RegisterPalette.userPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

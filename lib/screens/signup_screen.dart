// ===========================
// SIGNUP SCREEN COMPLETA
// lib/screens/signup_screen.dart
// ===========================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final usernameController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  bool loading = false;

  Future<void> register() async {
    final username = usernameController.text.trim();

    final email = emailController.text.trim();

    final password = passwordController.text.trim();

    final confirm = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));

      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem')));

      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/register'),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020817),

      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Container(
                width: 420,

                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.88),

                  borderRadius: BorderRadius.circular(24),

                  border: Border.all(color: Colors.white10),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Create Account',

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 36,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Join the next generation of social gaming.',

                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 32),

                    buildInput(
                      'USERNAME',
                      usernameController,
                      Icons.person_outline,
                    ),

                    const SizedBox(height: 20),

                    buildInput(
                      'EMAIL ADDRESS',
                      emailController,
                      Icons.email_outlined,
                    ),

                    const SizedBox(height: 20),

                    buildInput(
                      'PASSWORD',
                      passwordController,
                      Icons.lock_outline,
                      obscure: true,
                    ),

                    const SizedBox(height: 20),

                    buildInput(
                      'CONFIRM PASSWORD',
                      confirmPasswordController,
                      Icons.shield_outlined,
                      obscure: true,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,

                      height: 58,

                      child: ElevatedButton(
                        onPressed: loading ? null : register,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39FF14),

                          foregroundColor: Colors.black,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child:
                            loading
                                ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                                : const Text(
                                  'REGISTER NOW',

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Voltar para login',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInput(
    String label,

    TextEditingController controller,

    IconData icon, {

    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: TextStyle(
            color: Colors.white.withOpacity(0.75),

            fontSize: 13,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          obscureText: obscure,

          style: const TextStyle(color: Colors.white),

          decoration: InputDecoration(
            hintText: label,

            hintStyle: const TextStyle(color: Colors.white38),

            prefixIcon: Icon(icon, color: Colors.white54),

            filled: true,

            fillColor: const Color(0xFF081225),

            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: BorderSide(color: Colors.white10),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),

              borderSide: const BorderSide(
                color: Color(0xFF39FF14),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

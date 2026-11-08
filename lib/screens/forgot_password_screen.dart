import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../widgets/auth_input.dart';
import 'login_screen.dart';

// Recuperação de senha em duas etapas:
// 1) informa o e-mail e recebe um código; 2) digita o código e a nova senha.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  final codeController = TextEditingController();

  final passwordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  bool codeSent = false;

  bool loading = false;

  bool resending = false;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}$path'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      showMessage('Digite um e-mail válido');

      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final data = await postJson('/forgot-password', {'email': email});

      if (data['success'] == true) {
        setState(() {
          codeSent = true;
        });

        showMessage('Se o e-mail estiver cadastrado, você vai receber um código');
      } else {
        showMessage(data['message'] ?? 'Não foi possível enviar o código');
      }
    } catch (e) {
      showMessage('Erro de conexão. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> resendCode() async {
    try {
      setState(() {
        resending = true;
      });

      final data = await postJson('/resend-code', {
        'email': emailController.text.trim(),
        'purpose': 'reset',
      });

      showMessage(
        data['success'] == true
            ? 'Se o e-mail estiver cadastrado, enviamos um novo código'
            : (data['message'] ?? 'Não foi possível reenviar o código'),
      );
    } catch (e) {
      showMessage('Erro de conexão. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          resending = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final code = codeController.text.trim();

    final password = passwordController.text.trim();

    final confirm = confirmPasswordController.text.trim();

    if (code.length != 6) {
      showMessage('Digite o código de 6 dígitos');

      return;
    }

    if (password.length < 6) {
      showMessage('A senha deve ter pelo menos 6 caracteres');

      return;
    }

    if (password != confirm) {
      showMessage('As senhas não coincidem');

      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final data = await postJson('/reset-password', {
        'email': emailController.text.trim(),
        'code': code,
        'newPassword': password,
      });

      if (data['success'] == true) {
        showMessage(data['message'] ?? 'Senha alterada!');

        backToLogin();
      } else {
        showMessage(data['message'] ?? 'Não foi possível alterar a senha');
      }
    } catch (e) {
      showMessage('Erro de conexão. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void backToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      onBack: backToLogin,

      children: [
        const Text(
          'Esqueci minha senha',

          style: TextStyle(
            color: Colors.white,

            fontSize: 32,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          codeSent
              ? 'Digite o código enviado para ${emailController.text.trim()} '
                  'e escolha uma nova senha. Confira também a caixa de spam.'
              : 'Informe o e-mail da sua conta para receber um código de recuperação.',

          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),

        const SizedBox(height: 32),

        if (!codeSent) ...[
          AuthInput(
            label: 'EMAIL ADDRESS',
            controller: emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 32),

          AuthPrimaryButton(
            label: 'ENVIAR CÓDIGO',
            loading: loading,
            onPressed: sendCode,
          ),
        ] else ...[
          AuthInput(
            label: 'CÓDIGO',
            controller: codeController,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          const SizedBox(height: 20),

          AuthInput(
            label: 'NOVA SENHA',
            controller: passwordController,
            icon: Icons.lock_outline,
            obscure: true,
          ),

          const SizedBox(height: 20),

          AuthInput(
            label: 'CONFIRMAR NOVA SENHA',
            controller: confirmPasswordController,
            icon: Icons.shield_outlined,
            obscure: true,
          ),

          const SizedBox(height: 32),

          AuthPrimaryButton(
            label: 'ALTERAR SENHA',
            loading: loading,
            onPressed: resetPassword,
          ),

          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: resending ? null : resendCode,

              child: Text(
                resending ? 'ENVIANDO...' : 'REENVIAR CÓDIGO',

                style: const TextStyle(
                  color: Color(0xFF39FF14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

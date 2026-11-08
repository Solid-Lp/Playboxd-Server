import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../widgets/auth_input.dart';
import 'login_screen.dart';

// Confirmação do e-mail com o código de 6 dígitos enviado pelo backend
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final codeController = TextEditingController();

  bool loading = false;

  bool resending = false;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> verify() async {
    final code = codeController.text.trim();

    if (code.length != 6) {
      showMessage('Digite o código de 6 dígitos');

      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/verify-email'),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({'email': widget.email, 'code': code}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        if (mounted) await startSession(context, data);
      } else {
        showMessage(data['message'] ?? 'Código inválido');
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

  Future<void> resend() async {
    try {
      setState(() {
        resending = true;
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/resend-code'),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({'email': widget.email, 'purpose': 'verify'}),
      );

      final data = jsonDecode(response.body);

      showMessage(
        data['success'] == true
            ? 'Enviamos um novo código para ${widget.email}'
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
          'Confirme seu e-mail',

          style: TextStyle(
            color: Colors.white,

            fontSize: 32,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Enviamos um código de 6 dígitos para ${widget.email}. '
          'Confira também a caixa de spam.',

          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),

        const SizedBox(height: 32),

        AuthInput(
          label: 'CÓDIGO',
          controller: codeController,
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),

        const SizedBox(height: 32),

        AuthPrimaryButton(
          label: 'VERIFICAR',
          loading: loading,
          onPressed: verify,
        ),

        const SizedBox(height: 20),

        Center(
          child: TextButton(
            onPressed: resending ? null : resend,

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
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/auth_input.dart';
import 'app_shell.dart';
import 'login_screen.dart';

// Escolha do nome de usuário: obrigatória no 1º login com Google
// (onboarding) e disponível depois em Configurações.
class ChooseUsernameScreen extends StatefulWidget {
  final String initialUsername;
  final bool onboarding;

  const ChooseUsernameScreen({
    super.key,
    required this.initialUsername,
    required this.onboarding,
  });

  @override
  State<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends State<ChooseUsernameScreen> {
  late final usernameController =
      TextEditingController(text: widget.initialUsername);

  bool loading = false;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> save() async {
    final username = usernameController.text.trim();

    if (username.length < 3) {
      showMessage('O nome deve ter entre 3 e 20 caracteres');

      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final prefs = await SharedPreferences.getInstance();

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/profile/username'),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('token')}',
        },

        body: jsonEncode({'username': username}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        showMessage(data['message'] ?? 'Não foi possível salvar o nome');

        return;
      }

      await prefs.setString('username', data['username']);

      if (!mounted) return;

      if (widget.onboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
          (_) => false,
        );
      } else {
        showMessage('Nome atualizado');

        Navigator.pop(context, data['username']);
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

  // No onboarding, voltar cancela o login para a pessoa não ficar presa
  Future<void> back() async {
    if (!widget.onboarding) {
      Navigator.pop(context);

      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    GoogleAuthService.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      onBack: back,

      children: [
        Text(
          widget.onboarding
              ? 'Escolha seu nome de usuário'
              : 'Alterar nome de usuário',

          style: const TextStyle(
            color: Colors.white,

            fontSize: 30,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          widget.onboarding
              ? 'É assim que os outros jogadores vão ver você nas reviews. '
                  'Você pode mudar depois em Configurações.'
              : 'Seu novo nome aparece em todas as suas reviews.',

          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),

        const SizedBox(height: 32),

        AuthInput(
          label: 'USERNAME',
          controller: usernameController,
          icon: Icons.person_outline,
          maxLength: 20,
        ),

        const SizedBox(height: 8),

        const Text(
          'De 3 a 20 caracteres: letras, números, espaço, ponto, hífen ou _.',

          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),

        const SizedBox(height: 32),

        AuthPrimaryButton(
          label: widget.onboarding ? 'CONTINUAR' : 'SALVAR',
          loading: loading,
          onPressed: save,
        ),
      ],
    );
  }
}

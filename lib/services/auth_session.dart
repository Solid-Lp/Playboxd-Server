import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/app_shell.dart';
import '../screens/choose_username_screen.dart';
import 'session_store.dart';

// Salva a sessão devolvida pelo backend (/login, /auth/google, /verify-email)
// e abre o app, removendo as telas de login/cadastro do histórico.
Future<void> startSession(
  BuildContext context,
  Map<String, dynamic> data,
) async {

  final prefs =
      await SharedPreferences.getInstance();

  await SessionStore.setToken(data['token']);

  await prefs.setString(
    'username',
    data['user']['username'],
  );

  await prefs.setString(
    'email',
    data['user']['email'],
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Login realizado com sucesso!',
      ),
    ),
  );

  // Conta criada pelo Google: escolhe o nome antes de entrar no app
  final needsUsername = data['needsUsername'] == true;

  Navigator.pushAndRemoveUntil(

    context,

    MaterialPageRoute(
      builder: (_) => needsUsername
          ? ChooseUsernameScreen(
              initialUsername: data['user']['username'] ?? '',
              onboarding: true,
            )
          : const AppShell(),
    ),

    (_) => false,
  );
}

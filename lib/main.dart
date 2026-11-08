import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/app_settings.dart';
import 'services/session_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings().load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _settings = AppSettings();

  // Uma vez só: mudar fonte/contraste reconstrói o app e não deve revalidar
  late final Future<bool> _loginCheck = checkLogin();

  // Valida o login ao abrir o app e troca o token por um novo de 7 dias
  Future<bool> checkLogin() async {
    await SessionStore.migrateFromPrefs();

    final token = await SessionStore.getToken();
    if (token == null) return false;

    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 401) {
        // Login vencido ou senha redefinida em outro aparelho
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');
        await prefs.remove('email');
        await SessionStore.clear();
        return false;
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await SessionStore.setToken(data['token']);
        await prefs.setString('username', data['user']['username']);
        await prefs.setString('email', data['user']['email']);
      }
    } catch (e) {
      // Sem internet ou servidor acordando: segue com o token atual
      debugPrint('Erro ao validar login: $e');
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isHighContrast = _settings.highContrast;
        final colorScheme = ColorScheme.fromSeed(
          seedColor: _settings.accentColor,
          brightness: isHighContrast ? Brightness.light : Brightness.dark,
          background: _settings.bgColor,
          surface: _settings.cardColor,
          onBackground: _settings.textColor,
          onSurface: _settings.textColor,
          onPrimary: _settings.accentTextColor,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: colorScheme,
            scaffoldBackgroundColor: _settings.bgColor,
            cardColor: _settings.cardColor,
            textTheme: ThemeData(brightness: isHighContrast ? Brightness.light : Brightness.dark)
                .textTheme
                .apply(
                  bodyColor: _settings.textColor,
                  displayColor: _settings.textColor,
                ),
            iconTheme: IconThemeData(color: _settings.textColor),
            useMaterial3: true,
          ),
          home: FutureBuilder<bool>(
            future: _loginCheck,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  backgroundColor: Color(0xFF020817),
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF39FF14),
                    ),
                  ),
                );
              }

              final logged = snapshot.data!;

              if (logged) {
                return const AppShell();
              } else {
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}

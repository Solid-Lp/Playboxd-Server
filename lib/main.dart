import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings().load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _settings = AppSettings();

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
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
            future: checkLogin(),
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

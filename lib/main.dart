import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/navigation/bottom_navbar.dart';
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();
  final _settings = AppSettings();

  void _selectTab(int index) {
    if (index == 1) _libraryKey.currentState?.loadLibrary();
    if (index == 2) _profileKey.currentState?.loadProfile();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _settings.bgColor,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              MainScreen(onProfileTap: () => _selectTab(2)),
              LibraryScreen(
                key: _libraryKey,
                onProfileTap: () => _selectTab(2),
              ),
              ProfileScreen(key: _profileKey),
            ],
          ),
          bottomNavigationBar: BottomNavbar(
            currentIndex: _currentIndex,
            onTap: _selectTab,
          ),
        );
      },
    );
  }
}

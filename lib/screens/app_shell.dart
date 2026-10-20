import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../widgets/navigation/bottom_navbar.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Nome e avatar de quem está logado. Avisa as telas quando mudam,
// para o avatar do topo da Home/Biblioteca atualizar na hora.
class CurrentUser extends ChangeNotifier {
  static final CurrentUser _instance = CurrentUser._internal();
  factory CurrentUser() => _instance;
  CurrentUser._internal();

  String _username = '';
  String? _avatarColor;

  String get username => _username;
  String? get avatarColor => _avatarColor;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? '';
    _avatarColor = prefs.getString('avatar_color');
    notifyListeners();
  }

  // Salva os dados do usuário vindos do servidor (campo 'user' das respostas)
  Future<void> setFromServer(Map<String, dynamic> user) async {
    await update(username: user['username']);
    await setAvatarColor(user['avatar_color']);
  }

  Future<void> update({String? username}) async {
    if (username == null) return;
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    notifyListeners();
  }

  // null volta para a inicial no estilo padrão
  Future<void> setAvatarColor(String? color) async {
    _avatarColor = color;
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove('avatar_color');
    } else {
      await prefs.setString('avatar_color', color);
    }
    notifyListeners();
  }

  void clear() {
    _username = '';
    _avatarColor = null;
    notifyListeners();
  }
}

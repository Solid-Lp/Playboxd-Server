import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Guarda o token de login no armazenamento seguro do aparelho
// (Keystore no Android), e não em texto puro no SharedPreferences.
class SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<void> clear() => _storage.delete(key: _tokenKey);

  // Versões antigas do app salvavam o token no SharedPreferences:
  // move para o armazenamento seguro sem deslogar ninguém.
  static Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString(_tokenKey);
    if (oldToken == null) return;

    await setToken(oldToken);
    await prefs.remove(_tokenKey);
  }
}

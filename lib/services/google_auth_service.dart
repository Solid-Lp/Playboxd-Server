import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';

class GoogleAuthService {

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: ApiService.googleServerClientId,
    );
    _initialized = true;
  }

  // Só chama o plugin se ele foi iniciado nesta sessão: no web, signOut()
  // antes de initialize() fica esperando para sempre.
  static Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance
          .signOut()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}

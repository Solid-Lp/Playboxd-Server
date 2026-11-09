import 'package:flutter/foundation.dart';

// Avisa as telas abertas (Home, Top Rated) que uma review foi publicada,
// editada ou apagada, para recarregarem as notas sem o usuário puxar a tela.
class ReviewEvents extends ChangeNotifier {
  static final ReviewEvents _instance = ReviewEvents._();
  factory ReviewEvents() => _instance;
  ReviewEvents._();

  void changed() => notifyListeners();
}

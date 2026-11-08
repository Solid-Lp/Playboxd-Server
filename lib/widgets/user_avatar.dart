import 'package:flutter/material.dart';

import '../services/app_settings.dart';

// Cores que o usuário pode escolher (mesmas chaves aceitas pelo servidor)
const avatarColors = {
  'green': Color(0xFF39FF14),
  'blue': Color(0xFF4FC3F7),
  'red': Color(0xFFFF4A4A),
  'purple': Color(0xFFB388FF),
};

// Avatar desenhado no app: a inicial do nome, no estilo padrão
// (fundo escuro e letra na cor de destaque) ou sobre a cor escolhida.
class UserAvatar extends StatelessWidget {
  final String username;
  final String? colorKey;
  final double size;

  const UserAvatar({
    super.key,
    required this.username,
    this.colorKey,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppSettings().accentColor;
    final color = avatarColors[colorKey];
    final initial = username.trim().isNotEmpty
        ? username.trim().characters.first.toUpperCase()
        : 'P';

    return Container(
      width: size,
      height: size,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: color ?? const Color(0xFF111827),

        border: color == null
            ? Border.all(color: accent, width: size >= 80 ? 2.5 : 1.5)
            : null,
      ),

      child: Text(
        initial,

        style: TextStyle(
          color: color == null ? accent : Colors.black,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

// Etiquetas das plataformas de um jogo da IGDB (ex.: PS2, XBOX, NGC, PC),
// coloridas pela família, para diferenciar os ports de um mesmo jogo.
class PlatformTags extends StatelessWidget {
  final List<dynamic>? platforms;

  const PlatformTags({super.key, required this.platforms});

  // Famílias da IGDB (platform_family)
  static const _playstation = 1;
  static const _xbox = 2;
  static const _nintendo = 5;

  // PC (Windows), Linux, DOS e Mac. A família "Linux" da IGDB inclui o
  // Android, por isso o PC é identificado pelo ID da plataforma.
  static const _pcIds = {6, 3, 13, 14};

  // Ordem de exibição: PC, PlayStation, Xbox, Nintendo, outras
  static const _styles = [
    Colors.white,
    Color(0xFF4FC3F7),
    Color(0xFF39FF14),
    Color(0xFFFF4A4A),
    Color(0xFF8A9A92),
  ];

  static int _group(Map<String, dynamic> platform) {
    if (_pcIds.contains(platform['id'])) return 0;

    switch (platform['platform_family']) {
      case _playstation:
        return 1;
      case _xbox:
        return 2;
      case _nintendo:
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = (platforms ?? [])
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => _group(a).compareTo(_group(b)));

    if (list.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 20,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemCount: list.length,

        separatorBuilder: (_, __) => const SizedBox(width: 4),

        itemBuilder: (context, index) {
          final platform = list[index];
          final color = _styles[_group(platform)];
          final label = platform['abbreviation'] ?? platform['name'] ?? '';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7),

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),

            child: Text(
              label,

              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}

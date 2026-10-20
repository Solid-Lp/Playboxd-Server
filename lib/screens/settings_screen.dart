import 'package:flutter/material.dart';

import '../services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final bg = _settings.bgColor;
        final card = _settings.cardColor;
        final text = _settings.textColor;
        final muted = _settings.mutedColor;
        final border = _settings.borderColor;
        final accent = _settings.accentColor;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, color: text, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Configurações',
                        style: TextStyle(
                          color: accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Seção Acessibilidade
                        Text(
                          'ACESSIBILIDADE',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Alto Contraste
                        _buildToggleTile(
                          icon: Icons.contrast,
                          title: 'Alto Contraste',
                          subtitle: 'Fundo branco com texto escuro para melhor leitura',
                          value: _settings.highContrast,
                          onChanged: _settings.setHighContrast,
                          cardColor: card,
                          textColor: text,
                          mutedColor: muted,
                          borderColor: border,
                          accentColor: accent,
                        ),

                        const SizedBox(height: 12),

                        // Tamanho de Fonte
                        _buildFontScaleTile(
                          cardColor: card,
                          textColor: text,
                          mutedColor: muted,
                          borderColor: border,
                          accentColor: accent,
                        ),

                        const SizedBox(height: 32),

                        // Preview
                        Text(
                          'PRÉVIA',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildPreview(
                          cardColor: card,
                          textColor: text,
                          mutedColor: muted,
                          borderColor: border,
                          accentColor: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFontScaleTile({
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    final scale = _settings.fontScale;
    String scaleLabel = 'Normal';
    if (scale <= 0.85) scaleLabel = 'Pequeno';
    else if (scale >= 1.3) scaleLabel = 'Grande';
    else if (scale >= 1.15) scaleLabel = 'Médio+';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.text_fields, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tamanho da Fonte',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scaleLabel,
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('A', style: TextStyle(color: mutedColor, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: scale,
                  min: 0.85,
                  max: 1.3,
                  divisions: 3,
                  activeColor: accentColor,
                  inactiveColor: accentColor.withOpacity(0.2),
                  onChanged: (v) => _settings.setFontScale(
                    [0.85, 1.0, 1.15, 1.3].reduce(
                      (a, b) => (a - v).abs() < (b - v).abs() ? a : b,
                    ),
                  ),
                ),
              ),
              Text('A', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview({
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    final scale = _settings.fontScale;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAYBOXED',
            style: TextStyle(
              color: accentColor,
              fontSize: 22 * scale,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exemplo de título de jogo',
            style: TextStyle(
              color: textColor,
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Texto de descrição e informações secundárias do aplicativo.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 13 * scale,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'BOTÃO DE EXEMPLO',
              style: TextStyle(
                color: _settings.accentTextColor,
                fontSize: 13 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
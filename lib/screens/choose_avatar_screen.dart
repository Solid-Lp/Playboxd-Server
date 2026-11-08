import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../services/current_user.dart';
import '../services/session_store.dart';
import '../widgets/user_avatar.dart';

// Escolha do avatar: a inicial no estilo padrão ou uma das cores sólidas
class ChooseAvatarScreen extends StatefulWidget {
  const ChooseAvatarScreen({super.key});

  @override
  State<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends State<ChooseAvatarScreen> {
  final _settings = AppSettings();

  // null = inicial no estilo padrão
  String? _selected = CurrentUser().avatarColor;

  bool _loading = false;

  static const _labels = {
    null: 'Inicial',
    'green': 'Verde',
    'blue': 'Azul',
    'red': 'Vermelho',
    'purple': 'Roxo',
  };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    try {
      final token = await SessionStore.getToken();

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/profile/avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'avatar_color': _selected}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        _showMessage(data['message'] ?? 'Não foi possível salvar o avatar');
        return;
      }

      await CurrentUser().setAvatarColor(_selected);

      if (!mounted) return;
      _showMessage('Avatar atualizado');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Erro de conexão. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = CurrentUser().username;

    return Scaffold(
      backgroundColor: _settings.bgColor,
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
                    child: Icon(Icons.arrow_back, color: _settings.textColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Avatar',
                    style: TextStyle(
                      color: _settings.accentColor,
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
                  children: [
                    const SizedBox(height: 12),

                    UserAvatar(username: username, colorKey: _selected, size: 120),

                    const SizedBox(height: 12),

                    Text(
                      _labels[_selected] ?? '',
                      style: TextStyle(color: _settings.mutedColor, fontSize: 14),
                    ),

                    const SizedBox(height: 32),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 16,
                      children: _labels.keys.map(_buildOption).toList(),
                    ),

                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _loading ? null : _save,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _settings.accentColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: _loading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: _settings.accentTextColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'SALVAR',
                                  style: TextStyle(
                                    color: _settings.accentTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String? colorKey) {
    final selected = colorKey == _selected;

    return GestureDetector(
      onTap: () => setState(() => _selected = colorKey),
      child: Column(
        children: [
          // Anel em volta da opção escolhida
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? _settings.textColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: UserAvatar(
              username: CurrentUser().username,
              colorKey: colorKey,
              size: 56,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[colorKey]!,
            style: TextStyle(
              color: selected ? _settings.textColor : _settings.mutedColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

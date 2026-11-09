import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'cover_image.dart';
import '../services/app_settings.dart';
import '../services/api_service.dart';
import '../services/review_events.dart';
import '../services/session_store.dart';
import '../screens/write_review_screen.dart';
import 'platform_tags.dart';

class GameDetailsHeader extends StatefulWidget {
  final dynamic game;

  final String imageUrl;

  final VoidCallback? onReviewSubmitted;

  const GameDetailsHeader({
    super.key,

    required this.game,

    required this.imageUrl,

    this.onReviewSubmitted,
  });

  @override
  State<GameDetailsHeader> createState() => GameDetailsHeaderState();
}

class GameDetailsHeaderState extends State<GameDetailsHeader> {
  bool _inLibrary = false;
  Map<String, dynamic>? _myReview;

  @override
  void initState() {
    super.initState();
    _checkLibrary();
    _loadMyReview();
  }

  Future<String?> _getToken() => SessionStore.getToken();

  // Chamado pela tela do jogo ao puxar para atualizar
  Future<void> refresh() => Future.wait([_checkLibrary(), _loadMyReview()]);

  Future<void> _checkLibrary() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/library'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        final list = data['data'] as List;
        final gameId = widget.game['id'].toString();
        setState(() {
          _inLibrary = list.any(
            (entry) => entry['game_id'].toString() == gameId,
          );
        });
      }
    } catch (error) {
      debugPrint('Erro ao checar biblioteca: $error');
    }
  }

  Future<void> _addToLibrary(String status) async {
    try {
      final token = await _getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faça login para adicionar à biblioteca.'),
            ),
          );
        }
        return;
      }

      final game = widget.game;
      final coverUrl =
          game['cover'] != null
              ? 'https:${game['cover']['url']}'.replaceAll('t_thumb', 't_1080p')
              : widget.imageUrl;
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/library'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'game_id': game['id'].toString(),
          'game_name': game['name'],
          'cover_url': coverUrl,
          'status': status,
          'progress': 0,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() => _inLibrary = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adicionado como "$status"'),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  data['error'] ??
                  'Não foi possível adicionar o jogo à biblioteca.',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Erro ao adicionar à biblioteca: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível adicionar o jogo à biblioteca.'),
          ),
        );
      }
    }
  }

  // Review do usuário para este jogo (null se ainda não avaliou)
  Future<void> _loadMyReview() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/my-reviews/${widget.game['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() => _myReview = data['data']);
      }
    } catch (error) {
      debugPrint('Erro ao carregar sua review: $error');
    }
  }

  void _openReviewEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          game: widget.game,
          imageUrl: widget.imageUrl,
          existingReview: _myReview,
        ),
      ),
    ).then((submitted) {
      if (submitted == true) {
        _loadMyReview();
        widget.onReviewSubmitted?.call();
      }
    });
  }

  Future<void> _deleteMyReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar review'),
        content: const Text('Apagar sua review deste jogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Apagar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/reviews/${widget.game['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() => _myReview = null);
        widget.onReviewSubmitted?.call();
        ReviewEvents().changed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review apagada')),
        );
      }
    } catch (error) {
      debugPrint('Erro ao apagar review: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível apagar a review.')),
        );
      }
    }
  }

  Future<void> _removeFromLibrary() async {
    try {
      final token = await _getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faça login para remover da biblioteca.'),
            ),
          );
        }
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/library/${widget.game['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() => _inLibrary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removido da biblioteca'),
            backgroundColor: Color(0xFF39FF14),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(data['error'] ?? 'Não foi possível remover o jogo.');
      }
    } catch (error) {
      debugPrint('Erro ao remover da biblioteca: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível remover o jogo da biblioteca.'),
          ),
        );
      }
    }
  }

  void _showAddMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: const Color(0xFF0E1A16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1A2D24)),
      ),
      items: [
        _menuItem('playing', Icons.sports_esports_outlined, 'Playing'),
        _menuItem('completed', Icons.check_circle_outline, 'Completed'),
        _menuItem('dropped', Icons.cancel_outlined, 'Dropped'),
        if (_inLibrary)
          _menuItem('remove', Icons.delete_outline, 'Remove from library'),
      ],
    ).then((status) {
      if (status == 'remove') {
        _removeFromLibrary();
      } else if (status != null) {
        _addToLibrary(status);
      }
    });
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7A9185), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings();
    final game = widget.game;
    final imageUrl = widget.imageUrl;

    return SizedBox(
      height: 520,

      child: Stack(
        children: [
          CoverImage(
            imageUrl: imageUrl,

            width: double.infinity,

            height: 520,

            fit: BoxFit.cover,
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,

                end: Alignment.topCenter,

                colors: [
                  Colors.black.withOpacity(0.95),

                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    'PLAYBOXD',
                    style: TextStyle(
                      color: settings.accentColor,

                      fontSize: 28,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: Icon(Icons.close, color: settings.textColor),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 20,

            right: 20,

            bottom: 40,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                if (game['platforms'] != null) ...[
                  PlatformTags(platforms: game['platforms']),

                  const SizedBox(height: 16),
                ],

                Text(
                  game['name'] ?? '',
                  style: TextStyle(
                    color: settings.textColor,

                    fontSize: 42,

                    height: 1,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(Icons.star, color: settings.accentColor),

                    const SizedBox(width: 6),

                    Text(
                      (game['rating'] ?? 0).toStringAsFixed(1),

                      style: TextStyle(color: settings.textColor, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown:
                            (details) =>
                                _showAddMenu(context, details.globalPosition),
                        child: Container(
                          height: 56,

                          decoration: BoxDecoration(
                            color: settings.accentColor,
                            borderRadius: BorderRadius.circular(16),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _inLibrary
                                    ? Icons.check_circle_outline
                                    : Icons.add_circle_outline,
                                color: settings.accentTextColor,
                              ),

                              SizedBox(width: 8),

                              Flexible(
                                child: Text(
                                  _inLibrary
                                      ? 'IN LIBRARY · CHANGE STATUS'
                                      : 'ADD TO LIBRARY',
                                  style: TextStyle(
                                    color: settings.accentTextColor,

                                    fontWeight: FontWeight.bold,
                                  ),

                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Já avaliou: o botão vira EDITAR e aparece a lixeira
                    GestureDetector(
                      onTap: _openReviewEditor,

                      child: Container(
                        height: 56,

                        padding: const EdgeInsets.symmetric(horizontal: 18),

                        decoration: BoxDecoration(
                          color: settings.cardColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: settings.borderColor),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: settings.textColor,
                            ),

                            SizedBox(width: 8),

                            Text(
                              _myReview != null ? 'EDITAR' : 'REVIEW',
                              style: TextStyle(
                                color: settings.textColor,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_myReview != null) ...[
                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: _deleteMyReview,

                        child: Container(
                          width: 56,
                          height: 56,

                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                            ),
                          ),

                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

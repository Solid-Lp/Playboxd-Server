import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_settings.dart';
import '../services/api_service.dart';
import '../screens/write_review_screen.dart';

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
  State<GameDetailsHeader> createState() => _GameDetailsHeaderState();
}

class _GameDetailsHeaderState extends State<GameDetailsHeader> {
  bool _inLibrary = false;

  @override
  void initState() {
    super.initState();
    _checkLibrary();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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
      } else {
        throw Exception(data['error'] ?? 'Não foi possível adicionar o jogo.');
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
          CachedNetworkImage(
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
                    'PLAYBOXED',
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
                Row(
                  children: [
                    buildTag('ACTION RPG'),

                    const SizedBox(width: 8),

                    buildTag('OPEN WORLD'),
                  ],
                ),

                const SizedBox(height: 16),

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

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => WriteReviewScreen(
                                  game: game,
                                  imageUrl: imageUrl,
                                ),
                          ),
                        ).then((submitted) {
                          if (submitted == true) {
                            widget.onReviewSubmitted?.call();
                          }
                        });
                      },

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
                              'REVIEW',
                              style: TextStyle(
                                color: settings.textColor,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTag(String text) {
    final settings = AppSettings();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: settings.bgColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: settings.accentColor,

          fontWeight: FontWeight.bold,

          fontSize: 12,
        ),
      ),
    );
  }
}

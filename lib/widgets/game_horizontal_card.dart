import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/game_details_screen.dart';
import '../../services/api_service.dart';

class GameHorizontalCard extends StatefulWidget {
  final dynamic game;
  final String imageUrl;

  const GameHorizontalCard({
    super.key,
    required this.game,
    required this.imageUrl,
  });

  @override
  State<GameHorizontalCard> createState() => _GameHorizontalCardState();
}

class _GameHorizontalCardState extends State<GameHorizontalCard> {
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
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/library'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        final list = data['data'] as List;
        final id = widget.game['id'].toString();
        setState(() {
          _inLibrary = list.any((g) => g['game_id'].toString() == id);
        });
      }
    } catch (e) {
      debugPrint('Erro ao checar biblioteca: $e');
    }
  }

  Future<void> _addToLibrary(String status) async {
    try {
      final token = await _getToken();
      final game = widget.game;
      final coverUrl = game['cover'] != null
          ? 'https:${game['cover']['url']}'.replaceAll('t_thumb', 't_1080p')
          : '';

      final res = await http.post(
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

      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() => _inLibrary = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Adicionado como "$status"'),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      debugPrint('Erro ao adicionar à biblioteca: $e');
    }
  }

  void _showAddMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: const Color(0xFF0E1A16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1A2D24)),
      ),
      items: <PopupMenuEntry<String>>[
        _menuItem('playing', Icons.sports_esports_outlined, 'Playing'),
        _menuItem('completed', Icons.check_circle_outline, 'Completed'),
        _menuItem('dropped', Icons.cancel_outlined, 'Dropped'),
      ],
    ).then((value) {
      if (value != null) _addToLibrary(value);
    });
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7A9185), size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameDetailsScreen(
              game: widget.game,
              imageUrl: widget.imageUrl,
            ),
          ),
        ).then((_) => _checkLibrary());
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTapDown: (details) =>
                          _showAddMenu(context, details.globalPosition),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _inLibrary
                              ? const Color(0xFF39FF14)
                              : Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _inLibrary
                                ? const Color(0xFF39FF14)
                                : Colors.white24,
                          ),
                        ),
                        child: Icon(
                          _inLibrary ? Icons.check : Icons.add,
                          color: _inLibrary ? Colors.black : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.game['name'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
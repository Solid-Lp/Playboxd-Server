import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const LibraryScreen({super.key, this.onProfileTap});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, dynamic>> _library = [];
  int _selectedTab = 0;
  bool _loading = true;

  final List<String> _tabs = ['Playing', 'Completed', 'Dropped'];

  @override
  void initState() {
    super.initState();
    loadLibrary();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> loadLibrary() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/library'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() {
          _library = List<Map<String, dynamic>>.from(data['data']);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar biblioteca: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _removeGame(String gameId) async {
    try {
      final token = await _getToken();
      await http.delete(
        Uri.parse('${ApiService.baseUrl}/library/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      setState(() {
        _library.removeWhere((g) => g['game_id'].toString() == gameId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Removido da biblioteca'),
          backgroundColor: Color(0xFF39FF14),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('Erro ao remover jogo: $e');
    }
  }

  Future<void> _changeStatus(String gameId, String status) async {
    try {
      final token = await _getToken();
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/library/$gameId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      setState(() {
        final idx = _library.indexWhere((g) => g['game_id'].toString() == gameId);
        if (idx >= 0) _library[idx]['status'] = status;
      });
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredGames {
    final statusMap = ['playing', 'completed', 'dropped'];
    final status = statusMap[_selectedTab];
    return _library.where((g) => (g['status'] ?? 'playing') == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF39FF14)),
                  )
                : _filteredGames.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PLAYBOXED',
                style: TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_library.length} Games',
                    style: const TextStyle(
                      color: Color(0xFF7A9185),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.white),
              ),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF39FF14),
                  child: Icon(Icons.person, color: Colors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? const Color(0xFF39FF14) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabs[i],
                style: TextStyle(
                  color: active ? const Color(0xFF39FF14) : const Color(0xFF7A9185),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredGames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final game = _filteredGames[index];
        return _LibraryCard(
          game: game,
          onRemove: () => _removeGame(game['game_id'].toString()),
          onStatusChanged: (status) =>
              _changeStatus(game['game_id'].toString(), status),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline,
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Nenhum jogo aqui ainda.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione jogos na tela Discover!',
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Library Card ─────────────────────────────────────────────────────────────
class _LibraryCard extends StatelessWidget {
  final Map<String, dynamic> game;
  final VoidCallback onRemove;
  final ValueChanged<String> onStatusChanged;

  const _LibraryCard({
    required this.game,
    required this.onRemove,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = game['cover_url'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A2D24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        game['game_name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTapDown: (details) =>
                          _showOptions(context, details.globalPosition),
                      child: const Icon(Icons.more_vert,
                          color: Color(0xFF4A6A5A), size: 20),
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

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: const Color(0xFF1A2520),
      child: const Icon(Icons.videogame_asset_outlined,
          color: Color(0xFF2A4A3A), size: 40),
    );
  }

  void _showOptions(BuildContext context, Offset position) {
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
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '__remove__',
          child: const Row(
            children: [
              Icon(Icons.delete_outline, color: Color(0xFFFF4A4A), size: 18),
              SizedBox(width: 10),
              Text('Remover',
                  style: TextStyle(color: Color(0xFFFF4A4A), fontSize: 14)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == '__remove__') {
        onRemove();
      } else if (value != null) {
        onStatusChanged(value);
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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
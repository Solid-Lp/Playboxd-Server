import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/app_settings.dart';

import 'game_details_screen.dart';

class TopRatedScreen extends StatefulWidget {
  const TopRatedScreen({super.key});

  @override
  State<TopRatedScreen> createState() => _TopRatedScreenState();
}

class _TopRatedScreenState extends State<TopRatedScreen> {
  final _settings = AppSettings();
  List _topRated = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/top-rated'),
      );
      final data = jsonDecode(res.body);
      setState(() {
        _topRated = data['success'] ? data['data'] : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final bg = _settings.bgColor;
        final card = _settings.cardColor;
        final text = _settings.textColor;
        final muted = _settings.mutedColor;
        final accent = _settings.accentColor;
        final border = _settings.borderColor;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: accent,
                          ),
                        )
                      : _topRated.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: _settings.textColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAYBOXED',
                style: TextStyle(
                  color: _settings.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Top Rated by Community',
                style: TextStyle(
                  color: _settings.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _topRated.length,
      itemBuilder: (context, index) {
        final game = _topRated[index];
        final avgRating = double.tryParse(game['avg_rating'].toString()) ?? 0;
        final reviewCount = game['review_count'] ?? 0;
        final coverUrl = game['cover_url'] ?? '';

        Color positionColor;
        if (index == 0) positionColor = const Color(0xFFFFD700);
        else if (index == 1) positionColor = const Color(0xFFC0C0C0);
        else if (index == 2) positionColor = const Color(0xFFCD7F32);
        else positionColor = Colors.white.withOpacity(0.4);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameDetailsScreen(
                game: {
                  'id': game['game_id'],
                  'name': game['game_name'] ?? '',
                  'rating': 0,
                },
                imageUrl: coverUrl.toString(),
              ),
            ),
          ),
          child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _settings.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: index == 0
                  ? _settings.accentColor.withOpacity(0.3)
                  : _settings.borderColor,
            ),
          ),
          child: Row(
            children: [

              // Capa
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 90,
                        height: 110,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: positionColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (index < 3) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.emoji_events,
                              color: positionColor,
                              size: 14,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        game['game_name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFF39FF14), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              color: _settings.accentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ 5',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '$reviewCount ${reviewCount == 1 ? 'avaliação' : 'avaliações'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 110,
      color: _settings.cardColor,
      child: Icon(
        Icons.videogame_asset_outlined,
        color: _settings.mutedColor.withOpacity(0.8),
        size: 28,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 64, color: _settings.textColor.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Nenhum jogo avaliado ainda.',
            style: TextStyle(
              color: _settings.mutedColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seja o primeiro a avaliar um jogo!',
            style: TextStyle(
              color: _settings.mutedColor.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
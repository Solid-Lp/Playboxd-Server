import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../widgets/game_details_header.dart';
import '../widgets/review_card_large.dart';
import '../screens/write_review_screen.dart';

class GameDetailsScreen extends StatefulWidget {

  final dynamic game;

  final String imageUrl;

  const GameDetailsScreen({

    super.key,

    required this.game,

    required this.imageUrl,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final _settings = AppSettings();

  late dynamic _game = widget.game;

  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    // Aberto com dados parciais (Popular Reviews, Favoritos): busca o jogo completo
    if (widget.game['cover'] == null) _loadFullGame();
  }

  Future<void> _loadFullGame() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/games/${widget.game['id']}'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        setState(() => _game = data['data']);
      }
    } catch (e) {
      debugPrint('Erro ao carregar jogo: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      final gameId = widget.game['id'].toString();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/reviews/$gameId'),
      );
      final data = jsonDecode(res.body);
      setState(() {
        _reviews = data['success']
            ? List<Map<String, dynamic>>.from(data['data'])
            : [];
        _loadingReviews = false;
      });
    } catch (e) {
      setState(() => _loadingReviews = false);
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _settings.bgColor,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameDetailsHeader(
                  game: _game,
                  imageUrl: widget.imageUrl,
                  onReviewSubmitted: _loadReviews,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildAboutSection(),
                      const SizedBox(height: 32),
                      buildReviewsHeader(),
                      const SizedBox(height: 20),
                      buildReviews(),
                      const SizedBox(height: 32),
                      buildFriendsPlaying(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _settings.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _settings.borderColor),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            'About',
            style: TextStyle(
              color: _settings.accentColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _game['summary'] ?? 'No description.',
            style: TextStyle(
              color: _settings.textColor.withOpacity(0.9),
              height: 1.7,
            ),
          ),

          const SizedBox(height: 24),

          Divider(color: _settings.borderColor.withOpacity(0.4)),

          const SizedBox(height: 20),

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    'GENRE',
                    style: TextStyle(color: _settings.mutedColor),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _getGenre(),
                    style: TextStyle(color: _settings.textColor),
                  ),
                ],
              ),

              Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    'RATING',
                    style: TextStyle(color: _settings.mutedColor),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _game['rating'] != null
                        ? '⭐ ${(_game['rating'] as num).toStringAsFixed(1)}'
                        : 'N/A',
                    style: TextStyle(color: _settings.textColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGenre() {
    final genres = _game['genres'] as List?;
    if (genres == null || genres.isEmpty) return 'N/A';
    return genres.map((g) => g['name']).join(', ');
  }

  Widget buildReviewsHeader() {
    return Row(

      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        Expanded(
          child: Text(
            'Community Reviews',
            style: TextStyle(
              color: _settings.textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 12),

        GestureDetector(

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WriteReviewScreen(
                  game: _game,
                  imageUrl: widget.imageUrl,
                ),
              ),
            ).then((submitted) {
              if (submitted == true) _loadReviews();
            });
          },

          child: Container(

            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: _settings.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _settings.accentColor.withOpacity(0.4),
              ),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: _settings.accentColor,
                  size: 16,
                ),

                SizedBox(width: 6),

                Text(
                  'Write Review',
                  style: TextStyle(
                    color: _settings.accentColor,

                    fontWeight: FontWeight.bold,

                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildReviews() {
    if (_loadingReviews) {
      return Center(
        child: CircularProgressIndicator(color: _settings.accentColor),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _settings.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _settings.borderColor),
        ),
        child: Text(
          'Nenhuma review ainda. Seja o primeiro!',
          style: TextStyle(
            color: _settings.mutedColor,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children: _reviews.map((r) {
        return ReviewCardLarge(
          username: r['username'] ?? '',
          review: r['review_text'] ?? '',
          date: _timeAgo(r['created_at']?.toString()),
          rating: double.tryParse(r['rating'].toString()) ?? 0,
        );
      }).toList(),
    );
  }

  Widget buildFriendsPlaying() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _settings.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _settings.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FRIENDS PLAYING',
            style: TextStyle(
              color: _settings.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _settings.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _settings.accentColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              'EM BREVE',
              style: TextStyle(
                color: _settings.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Em breve você poderá ver quais amigos estão jogando isso.',
            style: TextStyle(
              color: _settings.mutedColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
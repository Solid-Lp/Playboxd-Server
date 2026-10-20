import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/app_settings.dart';

import '../widgets/game_grid_card.dart';
import '../widgets/game_horizontal_card.dart';
import '../widgets/review_card.dart';
import '../widgets/section_title.dart';

import 'game_details_screen.dart';
import 'search_screen.dart';
import 'top_rated_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const MainScreen({super.key, this.onProfileTap});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List popularGames = [];
  List newReleases = [];
  List popularReviews = [];
  List topRated = [];

  bool loading = true;
  final _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiService.baseUrl}/popular-games')),
        http.get(Uri.parse('${ApiService.baseUrl}/new-releases')),
        http.get(Uri.parse('${ApiService.baseUrl}/reviews/popular')),
        http.get(Uri.parse('${ApiService.baseUrl}/top-rated')),
      ]);

      final popularData = jsonDecode(responses[0].body);
      final releasesData = jsonDecode(responses[1].body);
      final reviewsData = jsonDecode(responses[2].body);
      final topRatedData = jsonDecode(responses[3].body);

      if (popularData['success'] != true) {
        debugPrint('Erro em /popular-games: ${popularData['error']}');
      }
      if (releasesData['success'] != true) {
        debugPrint('Erro em /new-releases: ${releasesData['error']}');
      }

      setState(() {
        popularGames =
            popularData['success'] == true ? (popularData['data'] ?? []) : [];
        newReleases =
            releasesData['success'] == true ? (releasesData['data'] ?? []) : [];
        popularReviews = reviewsData['success'] ? reviewsData['data'] : [];
        topRated = topRatedData['success'] ? topRatedData['data'] : [];
        loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar dados da Home: $e');
      setState(() => loading = false);
    }
  }

  String getImage(dynamic game) {
    if (game['cover'] == null) return '';
    return 'https:${game['cover']['url']}'.replaceAll('t_thumb', 't_1080p');
  }

  Future<void> _openVLibras() async {
    final appUri = Uri.parse('vlibras://');
    final webUri = Uri.parse('https://vlibras.gov.br/');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final text = _settings.textColor;
        final muted = _settings.mutedColor;
        final accent = _settings.accentColor;
        final card = _settings.cardColor;
        final border = _settings.borderColor;

        return loading
            ? Center(child: CircularProgressIndicator(color: accent))
            : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildHeader(text, accent),
                    const SizedBox(height: 20),

                    buildHeroBanner(text, accent, card, border),
                    const SizedBox(height: 32),

                    SectionTitle(title: 'NEW RELEASES', color: text),
                    const SizedBox(height: 16),
                    buildNewReleases(),
                    const SizedBox(height: 32),

                    SectionTitle(title: 'POPULAR REVIEWS', color: text),
                    const SizedBox(height: 16),
                    buildPopularReviews(muted, card, border),
                    const SizedBox(height: 32),

                    buildTopRatedHeader(text, accent),
                    const SizedBox(height: 16),
                    buildTopRated(text, muted, accent, card, border),
                    const SizedBox(height: 32),

                    SectionTitle(title: 'POPULAR GAMES', color: text),
                    const SizedBox(height: 16),
                    buildPopularGames(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
      },
    );
  }

  Widget buildHeader(Color text, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PLAYBOXED',
            style: TextStyle(
              color: accent,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _openVLibras,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sign_language, color: accent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'LIBRAS',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                icon: Icon(Icons.search, color: text),
              ),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: accent,
                  child: Icon(Icons.person, color: _settings.accentTextColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTopRatedHeader(Color text, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOP RATED BY COMMUNITY',
            style: TextStyle(
              color: text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TopRatedScreen()),
              );
            },
            child: Row(
              children: [
                Text(
                  'Ver todos',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: accent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeroBanner(Color text, Color accent, Color card, Color border) {
    if (popularGames.isEmpty) return const SizedBox.shrink();

    final game = popularGames.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameDetailsScreen(
              game: game,
              imageUrl: getImage(game),
            ),
          ),
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: const BoxConstraints(minHeight: 520),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
              image: CachedNetworkImageProvider(getImage(game)),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.95),
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    game['summary'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text.withOpacity(0.8),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget buildNewReleases() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: newReleases.length,
        itemBuilder: (context, index) {
          final game = newReleases[index];
          return GameHorizontalCard(game: game, imageUrl: getImage(game));
        },
      ),
    );
  }

  Widget buildPopularReviews(Color muted, Color card, Color border) {
    if (popularReviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Text(
            'Nenhuma review ainda.',
            style: TextStyle(color: muted.withOpacity(0.6), fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: popularReviews.length,
        itemBuilder: (context, index) {
          final review = popularReviews[index];
          return ReviewCard(
            game: review['game_name'] ?? '',
            review: review['review_text'] ?? '',
            user: review['username'] ?? '',
            rating: (review['rating'] ?? '0').toString(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailsScreen(
                  game: {
                    'id': review['game_id'],
                    'name': review['game_name'] ?? '',
                    'rating': 0,
                  },
                  imageUrl: (review['cover_url'] ?? '').toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTopRated(
    Color text,
    Color muted,
    Color accent,
    Color card,
    Color border,
  ) {
    if (topRated.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Text(
            'Nenhum jogo avaliado ainda.',
            style: TextStyle(color: muted.withOpacity(0.6), fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(topRated.length > 5 ? 5 : topRated.length, (
          index,
        ) {
          final game = topRated[index];
          final avgRating = double.tryParse(game['avg_rating'].toString()) ?? 0;
          final reviewCount = game['review_count'] ?? 0;
          final coverUrl = game['cover_url'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: index == 0 ? accent : muted,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: 48,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => _coverPlaceholder(card, muted),
                          )
                          : _coverPlaceholder(card, muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['game_name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF39FF14).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFF39FF14),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _coverPlaceholder(Color card, Color muted) {
    return Container(
      width: 48,
      height: 60,
      color: card,
      child: Icon(
        Icons.videogame_asset_outlined,
        color: muted.withOpacity(0.9),
        size: 20,
      ),
    );
  }

  Widget buildPopularGames() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: popularGames.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final game = popularGames[index];
          return GameGridCard(game: game, imageUrl: getImage(game));
        },
      ),
    );
  }
}

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../services/google_auth_service.dart';
import 'game_details_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _email = '';

  List<Map<String, dynamic>> _library = [];
  List<Map<String, dynamic>> _activities = [];

  int _gamesPlayed = 0;
  int _reviewsWritten = 0;
  int _followers = 0;

  bool _loading = true;

  final _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiService.baseUrl}/library'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiService.baseUrl}/activity'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiService.baseUrl}/profile/stats'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      final libraryData = jsonDecode(results[0].body);
      final activityData = jsonDecode(results[1].body);
      final statsData = jsonDecode(results[2].body);

      setState(() {
        _username = prefs.getString('username') ?? 'Player';
        _email = prefs.getString('email') ?? '';

        _library =
            libraryData['success']
                ? List<Map<String, dynamic>>.from(libraryData['data'])
                : [];

        _activities =
            activityData['success']
                ? List<Map<String, dynamic>>.from(activityData['data'])
                : [];

        if (statsData['success']) {
          _gamesPlayed = statsData['data']['games_played'] ?? 0;
          _reviewsWritten = statsData['data']['reviews_written'] ?? 0;
          _followers = statsData['data']['followers'] ?? 0;
        }

        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Permite escolher outra conta Google no próximo login (sem bloquear a saída)
    GoogleAuthService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Sua conta, biblioteca e reviews serão apagadas permanentemente. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/account'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await _logout();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir a conta')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao excluir conta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao excluir a conta')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _favoriteGames => _library.take(3).toList();

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'AGORA';
    if (diff.inMinutes < 60) return '${diff.inMinutes} MIN ATRÁS';
    if (diff.inHours < 24) return '${diff.inHours}H ATRÁS';
    if (diff.inDays < 30) return '${diff.inDays}D ATRÁS';
    return '${(diff.inDays / 30).floor()}M ATRÁS';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      );
    }

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final bg = _settings.bgColor;
        final text = _settings.textColor;
        final accent = _settings.accentColor;
        final scale = _settings.fontScale;

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Container(
            color: bg,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(text, accent),
                    _buildAvatar(accent, bg),
                    _buildUsername(text, accent),
                    _buildStats(text),
                    const SizedBox(height: 32),
                    _buildFavoriteGames(text, accent),
                    const SizedBox(height: 32),
                    _buildActivity(text, accent),
                    const SizedBox(height: 32),
                    _buildLogout(),
                    const SizedBox(height: 16),
                    _buildDeleteAccount(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color text, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PLAYBOXED',
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Row(
            children: [
              Icon(Icons.search, color: text, size: 24),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: Icon(Icons.settings_outlined, color: text, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color accent, Color bg) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2.5),
              color: const Color(0xFF111827),
            ),
            child: ClipOval(
              child: Center(
                child: Text(
                  _username.isNotEmpty ? _username[0].toUpperCase() : 'P',
                  style: TextStyle(
                    color: accent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: bg, width: 2),
              ),
              child: Icon(
                Icons.verified,
                color: _settings.accentTextColor,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsername(Color text, Color accent) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Center(
          child: Text(
            _username,
            style: TextStyle(
              color: accent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _email,
            style: TextStyle(color: text.withOpacity(0.5), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(Color text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(_gamesPlayed.toString(), 'GAMES PLAYED', text),
          _statDivider(),
          _statItem(_reviewsWritten.toString(), 'REVIEWS WRITTEN', text),
          _statDivider(),
          _statItem(_followers.toString(), 'FOLLOWERS', text),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color text) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: text,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: text.withOpacity(0.4),
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: _settings.borderColor);
  }

  Widget _buildFavoriteGames(Color text, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorite Games',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_favoriteGames.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _settings.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.videogame_asset_outlined,
                    color: text.withOpacity(0.2),
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nenhum jogo na biblioteca ainda.',
                    style: TextStyle(
                      color: text.withOpacity(0.35),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildFavGrid(accent),
          ),
      ],
    );
  }

  Widget _buildFavGrid(Color accent) {
    if (_favoriteGames.length == 1)
      return _favCard(_favoriteGames[0], accent, large: true);
    if (_favoriteGames.length == 2) {
      return Row(
        children: [
          Expanded(child: _favCard(_favoriteGames[0], accent)),
          const SizedBox(width: 12),
          Expanded(child: _favCard(_favoriteGames[1], accent)),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _favCard(_favoriteGames[0], accent)),
            const SizedBox(width: 12),
            Expanded(child: _favCard(_favoriteGames[1], accent)),
          ],
        ),
        const SizedBox(height: 12),
        _favCard(_favoriteGames[2], accent, large: true),
      ],
    );
  }

  Widget _favCard(
    Map<String, dynamic> game,
    Color accent, {
    bool large = false,
  }) {
    final imgUrl = (game['cover_url'] ?? '').toString();
    final status = (game['status'] ?? 'playing').toString().toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => GameDetailsScreen(
                  game: {
                    'id': game['game_id'],
                    'name': game['game_name'] ?? '',
                    'rating': 0,
                  },
                  imageUrl: imgUrl,
                ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            imgUrl.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: imgUrl,
                  height: large ? 200 : 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                )
                : Container(
                  height: large ? 200 : 180,
                  color: const Color(0xFF111827),
                  child: const Icon(
                    Icons.videogame_asset_outlined,
                    color: Color(0xFF2A4A3A),
                    size: 40,
                  ),
                ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _settings.accentTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      game['game_name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildActivity(Color text, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Activity',
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _settings.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nenhuma atividade ainda.',
                style: TextStyle(color: text.withOpacity(0.35), fontSize: 14),
              ),
            ),
          )
        else
          ..._activities.map((a) => _activityItem(a, text, accent)),
      ],
    );
  }

  Widget _activityItem(Map<String, dynamic> a, Color text, Color accent) {
    final isReview = a['type'] == 'review';
    final icon = isReview ? Icons.star_outline : Icons.add_box_outlined;
    final action = isReview ? 'Reviewed' : 'Added';
    final title =
        isReview ? a['game_name'] ?? '' : '${a['game_name'] ?? ''} to library';
    final sub = isReview ? (a['detail'] ?? '') : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _settings.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: text, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '$action ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: title),
                    ],
                  ),
                ),
                if (sub.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"$sub"',
                    style: TextStyle(
                      color: text.withOpacity(0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _timeAgo(a['created_at']?.toString()),
                  style: TextStyle(
                    color: text.withOpacity(0.3),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _logout,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Text(
                'LOGOUT',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _deleteAccount,
        child: const SizedBox(
          width: double.infinity,
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'EXCLUIR CONTA',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

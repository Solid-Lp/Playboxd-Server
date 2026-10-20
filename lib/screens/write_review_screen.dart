import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/app_settings.dart';

class WriteReviewScreen extends StatefulWidget {
  final dynamic game;
  final String imageUrl;

  const WriteReviewScreen({
    super.key,
    required this.game,
    required this.imageUrl,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _controller = TextEditingController();
  final _settings = AppSettings();
  double _rating = 0;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma nota antes de enviar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva sua review antes de enviar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final coverUrl = widget.game['cover'] != null
          ? 'https:${widget.game['cover']['url']}'.replaceAll('t_thumb', 't_1080p')
          : widget.imageUrl;

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'game_id': widget.game['id'].toString(),
          'game_name': widget.game['name'],
          'cover_url': coverUrl,
          'rating': _rating,
          'review_text': _controller.text.trim(),
        }),
      );

      print('STATUS: ${res.statusCode}');
      print('BODY: ${res.body}');

      final data = jsonDecode(res.body);

      if (data['success']) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review publicada!'),
              backgroundColor: Color(0xFF39FF14),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Erro ao publicar review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGameInfo(),
                      const SizedBox(height: 32),
                      _buildRating(),
                      const SizedBox(height: 32),
                      _buildReviewField(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
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

  Widget _buildHeader() {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          widget.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                )
              : Container(height: 260, color: const Color(0xFF111827)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF050816),
                  Colors.transparent,
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
                      color: _settings.accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: _settings.textColor),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Text(
              'Write a Review',
              style: TextStyle(
                color: _settings.textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: widget.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  width: 64,
                  height: 80,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 64,
                  height: 80,
                  color: const Color(0xFF111827),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getGenre(),
                style: TextStyle(
                  color: _settings.mutedColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGenre() {
    final genres = widget.game['genres'] as List?;
    if (genres == null || genres.isEmpty) return 'Game';
    return genres.map((g) => g['name']).join(', ');
  }

  Widget _buildRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR RATING',
          style: TextStyle(
            color: _settings.accentColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final value = (i + 1).toDouble();
            return GestureDetector(
              onTap: () => setState(() => _rating = value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  _rating >= value ? Icons.star : Icons.star_border,
                  color: _settings.accentColor,
                  size: 42,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _rating == 0
                ? 'Toque nas estrelas para avaliar'
                : '${_rating.toInt()} / 5',
            style: TextStyle(
              color: _settings.mutedColor,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR REVIEW',
          style: TextStyle(
            color: _settings.accentColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _settings.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _settings.borderColor),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 6,
            style: TextStyle(color: _settings.textColor, height: 1.6),
            decoration: InputDecoration(
              hintText: 'O que você achou desse jogo?',
              hintStyle: TextStyle(color: _settings.mutedColor.withOpacity(0.3)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF39FF14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'PUBLISH REVIEW',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
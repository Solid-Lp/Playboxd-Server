import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../widgets/my_review_card.dart';
import 'game_details_screen.dart';

// Monta o card de uma review do usuário; usado no perfil e na lista completa
Widget buildMyReviewCard(
  BuildContext context,
  Map<String, dynamic> review,
  AppSettings settings,
) {
  final coverUrl = (review['cover_url'] ?? '').toString();

  return MyReviewCard(
    gameName: review['game_name'] ?? '',
    coverUrl: coverUrl,
    review: review['review_text'] ?? '',
    rating: double.tryParse(review['rating'].toString()) ?? 0,
    cardColor: settings.cardColor,
    textColor: settings.textColor,
    accentColor: settings.accentColor,
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailsScreen(
          game: {
            'id': review['game_id'],
            'name': review['game_name'] ?? '',
            'rating': 0,
          },
          imageUrl: coverUrl,
        ),
      ),
    ),
  );
}

// Lista completa das reviews do usuário, aberta pelo "View All" do perfil
class MyReviewsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const MyReviewsScreen({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
          child: Scaffold(
            backgroundColor: settings.bgColor,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: settings.textColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'My Reviews',
                          style: TextStyle(
                            color: settings.accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${reviews.length})',
                          style: TextStyle(
                            color: settings.textColor.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) =>
                          buildMyReviewCard(context, reviews[index], settings),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

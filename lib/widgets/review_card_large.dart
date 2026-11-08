import 'package:flutter/material.dart';

class ReviewCardLarge extends StatelessWidget {

  final String username;

  final String review;

  final String date;

  final double rating;

  // Status do jogo na biblioteca de quem escreveu ('playing', 'completed',
  // 'dropped'); null quando o jogo não está na biblioteca dele
  final String? libraryStatus;

  const ReviewCardLarge({

    super.key,

    required this.username,

    required this.review,

    required this.date,

    required this.rating,

    this.libraryStatus,
  });

  static const _statusStyles = {
    'playing': (Icons.sports_esports_outlined, 'Playing', Color(0xFF39FF14)),
    'completed': (Icons.check_circle_outline, 'Completed', Color(0xFF4FC3F7)),
    'dropped': (Icons.cancel_outlined, 'Dropped', Color(0xFFFF4A4A)),
  };

  Widget _buildStatusChip() {
    final style = _statusStyles[libraryStatus];
    if (style == null) return const SizedBox.shrink();

    final (icon, label, color) = style;

    return Container(
      margin: const EdgeInsets.only(top: 8),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: color, size: 14),

          const SizedBox(width: 6),

          Text(
            label,

            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.clamp(0, 5).toDouble();

    return Container(

      margin: const EdgeInsets.only(
        bottom: 18,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: const Color(0xFF0D1320),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              const CircleAvatar(

                backgroundColor:
                    Color(0xFF39FF14),

                child: Icon(
                  Icons.person,
                  color: Colors.black,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      username,

                      style:
                          const TextStyle(

                        color: Colors.white,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(

                      children: List.generate(5, (index) {
                        final starValue = clampedRating - index;
                        final icon = starValue >= 1
                            ? Icons.star
                            : starValue >= 0.5
                                ? Icons.star_half
                                : Icons.star_border;

                        return Icon(
                          icon,
                          color: const Color(0xFF39FF14),
                          size: 18,
                        );
                      }),
                    ),

                    _buildStatusChip(),
                  ],
                ),
              ),

              Text(

                date,

                style: TextStyle(

                  color: Colors.white
                      .withOpacity(0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(

            review,

            style: TextStyle(

              color:
                  Colors.white.withOpacity(
                0.82,
              ),

              height: 1.5,
            ),
          ),

        ],
      ),
    );
  }
}
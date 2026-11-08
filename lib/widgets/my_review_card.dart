import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Review do próprio usuário no perfil: capa e nome à esquerda,
// estrelas e texto à direita, com "Ler mais..." quando o texto não cabe.
class MyReviewCard extends StatefulWidget {
  final String gameName;
  final String coverUrl;
  final String review;
  final double rating;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onTap;

  const MyReviewCard({
    super.key,
    required this.gameName,
    required this.coverUrl,
    required this.review,
    required this.rating,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<MyReviewCard> createState() => _MyReviewCardState();
}

class _MyReviewCardState extends State<MyReviewCard> {
  static const _collapsedLines = 4;
  static const _coverWidth = 90.0;
  static const _coverHeight = 120.0;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildGame(),

          const SizedBox(width: 12),

          Expanded(child: _buildReview()),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return GestureDetector(
      onTap: widget.onTap,

      child: SizedBox(
        width: _coverWidth,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),

              child: widget.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.coverUrl,
                      width: _coverWidth,
                      height: _coverHeight,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _coverPlaceholder(),
                      errorWidget: (_, __, ___) => _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),

            const SizedBox(height: 6),

            Text(
              widget.gameName,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: widget.textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: _coverWidth,
      height: _coverHeight,
      color: const Color(0xFF111827),
      child: const Icon(
        Icons.videogame_asset_outlined,
        color: Color(0xFF2A4A3A),
        size: 32,
      ),
    );
  }

  Widget _buildReview() {
    final clampedRating = widget.rating.clamp(0, 5).toDouble();

    final textStyle = TextStyle(
      color: widget.textColor.withValues(alpha: 0.82),
      fontSize: 13,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: List.generate(5, (index) {
            final starValue = clampedRating - index;
            final icon = starValue >= 1
                ? Icons.star
                : starValue >= 0.5
                    ? Icons.star_half
                    : Icons.star_border;

            return Icon(icon, color: widget.accentColor, size: 20);
          }),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),

          // Mede o texto para só mostrar "Ler mais..." quando ele não cabe
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: widget.review, style: textStyle),
                maxLines: _collapsedLines,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: constraints.maxWidth);

              final overflows = painter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    widget.review.isEmpty ? 'Sem texto.' : widget.review,

                    maxLines: _expanded ? null : _collapsedLines,

                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,

                    style: textStyle,
                  ),

                  if (overflows || _expanded)
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),

                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),

                          child: Text(
                            _expanded ? 'Ler menos' : 'Ler mais...',

                            style: TextStyle(
                              color: widget.textColor.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  widget.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

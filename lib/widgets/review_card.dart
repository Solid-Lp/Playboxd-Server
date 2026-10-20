import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String game;

  final String review;

  final String user;

  final String rating;

  final VoidCallback? onTap;

  const ReviewCard({
    super.key,

    required this.game,

    required this.review,

    required this.user,

    required this.rating,

    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 300,

      margin: const EdgeInsets.only(right: 18),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF111827),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white10),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF39FF14),
                child: Icon(Icons.person, color: Colors.black),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    user,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '⭐ $rating',

                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            game,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 20,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ClipRect(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.75, 1.0],
                ).createShader(bounds),

                blendMode: BlendMode.dstIn,

                child: Text(
                  review,

                  overflow: TextOverflow.clip,

                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),

                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ReviewCardLarge extends StatelessWidget {

  final String username;

  final String review;

  final String date;

  final double rating;

  const ReviewCardLarge({

    super.key,

    required this.username,

    required this.review,

    required this.date,

    required this.rating,
  });

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
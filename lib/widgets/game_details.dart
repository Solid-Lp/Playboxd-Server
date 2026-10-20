import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GameDetailsHeader extends StatelessWidget {

  final dynamic game;

  final String imageUrl;

  const GameDetailsHeader({

    super.key,

    required this.game,

    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      height: 520,

      child: Stack(

        children: [

          CachedNetworkImage(

            imageUrl: imageUrl,

            width: double.infinity,

            height: 520,

            fit: BoxFit.cover,
          ),

          Container(

            decoration: BoxDecoration(

              gradient: LinearGradient(

                begin: Alignment.bottomCenter,

                end: Alignment.topCenter,

                colors: [

                  Colors.black.withOpacity(0.95),

                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),

          SafeArea(

            child: Padding(

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),

              child: Row(

                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  const Text(

                    'PLAYBOXED',

                    style: TextStyle(

                      color:
                          Color(0xFF39FF14),

                      fontSize: 28,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  IconButton(

                    onPressed: () {

                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(

            left: 20,

            right: 20,

            bottom: 40,

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    buildTag(
                      'ACTION RPG',
                    ),

                    const SizedBox(width: 8),

                    buildTag(
                      'OPEN WORLD',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(

                  game['name'] ?? '',

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 42,

                    height: 1,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(

                  children: [

                    const Icon(
                      Icons.star,
                      color: Color(0xFF39FF14),
                    ),

                    const SizedBox(width: 6),

                    Text(

                      (game['rating'] ?? 0).toStringAsFixed(1),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Container(

                  height: 56,

                  decoration: BoxDecoration(

                    color:
                        const Color(0xFF39FF14),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: const Row(

                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.black,
                      ),

                      SizedBox(width: 8),

                      Text(

                        'ADD TO LIBRARY',

                        style: TextStyle(

                          color: Colors.black,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTag(String text) {

    return Container(

      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(

        color: Colors.black.withOpacity(0.55),

        borderRadius:
            BorderRadius.circular(8),
      ),

      child: Text(

        text,

        style: const TextStyle(

          color: Color(0xFF39FF14),

          fontWeight: FontWeight.bold,

          fontSize: 12,
        ),
      ),
    );
  }
}
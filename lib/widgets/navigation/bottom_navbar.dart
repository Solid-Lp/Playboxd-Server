import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {

  final int currentIndex;

  final Function(int) onTap;

  const BottomNavbar({

    super.key,

    required this.currentIndex,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      height: 90,

      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),

      decoration: BoxDecoration(

        color: const Color(0xFF0D1320),

        border: Border(

          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),

      child: Row(

        mainAxisAlignment:
            MainAxisAlignment.spaceAround,

        children: [

          buildItem(
            Icons.explore,
            'Discover',
            0,
          ),

          buildItem(
            Icons.bookmark_border,
            'Library',
            1,
          ),

          buildItem(
            Icons.person_outline,
            'Profile',
            2,
          ),
        ],
      ),
    );
  }

  Widget buildItem(

    IconData icon,

    String label,

    int index,

  ) {

    final bool active =
        currentIndex == index;

    return GestureDetector(

      onTap: () => onTap(index),

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(

            icon,

            color: active

                ? const Color(0xFF39FF14)

                : Colors.white54,

            size: 28,
          ),

          const SizedBox(height: 6),

          Text(

            label,

            style: TextStyle(

              color: active

                  ? const Color(0xFF39FF14)

                  : Colors.white54,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
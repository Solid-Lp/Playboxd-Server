import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {

  final String title;
  final Color? color;

  const SectionTitle({
    super.key,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),

      child: Text(

        title,

        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class StudentBanner extends StatelessWidget {
  const StudentBanner({super.key, required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [AcademixColors.purple, Color(0xFF86198F), Color(0xFF1D4ED8)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACADEMIX · MI APRENDIZAJE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: Colors.white, height: 1.4)),
      ],
    ),
  );
}

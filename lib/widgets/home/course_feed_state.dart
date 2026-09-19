import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class CourseFeedState extends StatelessWidget {
  const CourseFeedState({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.isEmpty,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasMore;
  final bool isEmpty;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(
            color: AcademixColors.lavender)),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Column(
          children: [
            const Text('No se pudieron cargar los cursos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFCA5A5))),
            const SizedBox(height: 6),
            Text(error!, maxLines: 4, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AcademixColors.muted, fontSize: 11)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: Text('Todavía no hay cursos publicados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AcademixColors.muted))),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Text('Ya viste todos los cursos disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AcademixColors.muted, fontSize: 12)),
      );
    }
    return const SizedBox(height: 24);
  }
}

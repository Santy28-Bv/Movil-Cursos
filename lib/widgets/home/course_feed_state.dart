import 'package:flutter/material.dart';

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
      return Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Column(
          children: [
            Text(
              'No se pudieron cargar los cursos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 6),
            Text(
              error!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (isEmpty) {
      return Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Todavía no hay cursos publicados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Text(
          'Ya viste todos los cursos disponibles.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

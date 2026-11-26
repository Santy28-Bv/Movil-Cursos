import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 24),
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      gradient: AcademixColors.heroGradient(context),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: AcademixColors.purple.withValues(alpha: .22),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .45),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            'INICIA TU CARRERA TECH HOY',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 23),
        Text(
          'Aprende habilidades',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        Text(
          'reales',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Text(
          'para el futuro.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Explora cursos especializados, aprende de expertos '
          'y desarrolla habilidades a tu ritmo.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explorar cursos'),
            style: FilledButton.styleFrom(
              backgroundColor: AcademixColors.purple,
              foregroundColor: const Color(0xFFFFFFFF),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Conviértete en instructor · Próximamente',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          height: 132,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AcademixColors.softGradient(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 42,
              ),
              SizedBox(height: 9),
              Text(
                'CURSOS DE TECNOLOGÍA',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Aprende desde cualquier lugar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

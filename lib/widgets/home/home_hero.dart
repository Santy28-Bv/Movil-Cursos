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
          border: Border.all(color: AcademixColors.border),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF43227B), Color(0xFF1C274B), AcademixColors.background],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: AcademixColors.purple.withOpacity(.22),
                border: Border.all(color: AcademixColors.lavender.withOpacity(.45)),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text('INICIA TU CARRERA TECH HOY',
                  style: TextStyle(color: Color(0xFFE9DCFF), fontSize: 10,
                      letterSpacing: 1, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 23),
            const Text('Aprende habilidades',
                style: TextStyle(color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.w900, height: 1.12)),
            const Text('reales',
                style: TextStyle(color: AcademixColors.lavender, fontSize: 36,
                    fontWeight: FontWeight.w900, height: 1.1)),
            const Text('para el futuro.',
                style: TextStyle(color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.w900, height: 1.12)),
            const SizedBox(height: 18),
            const Text('Explora cursos especializados, aprende de expertos '
                'y desarrolla habilidades a tu ritmo.',
                style: TextStyle(color: Color(0xFFDEDAED), height: 1.55)),
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
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Conviértete en instructor · Próximamente'),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              height: 132,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [Color(0xFF4B2380), Color(0xFF203A6A)]),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline_rounded,
                      color: AcademixColors.lavender, size: 42),
                  SizedBox(height: 9),
                  Text('CURSOS DE TECNOLOGÍA',
                      style: TextStyle(color: AcademixColors.lavender,
                          fontSize: 11, letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Text('Aprende desde cualquier lugar',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}

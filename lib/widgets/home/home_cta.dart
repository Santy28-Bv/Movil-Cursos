import 'package:flutter/material.dart';

class HomeCta extends StatelessWidget {
  const HomeCta({super.key, required this.onExplore, required this.onRegister});
  final VoidCallback onExplore;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        stops: const [0, .45, 1],
        colors: [
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF6D28D9)
              : const Color(0xFF7C3AED),
          const Color(0xFF9333EA),
          const Color(0xFF2563EB),
        ],
      ),
    ),
    child: Column(
      children: [
        const Text(
          'Empieza hoy mismo tu transformación',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Únete a Academix y descubre cursos '
          'para seguir aprendiendo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, height: 1.5),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onExplore,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Explorar catálogo'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onRegister,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6D28D9),
            ),
            child: const Text('Crear cuenta gratis'),
          ),
        ),
      ],
    ),
  );
}

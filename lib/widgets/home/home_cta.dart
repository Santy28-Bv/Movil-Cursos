import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

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
          gradient: const LinearGradient(colors: [
            Color(0xFF6D28D9), Color(0xFFA21CAF), Color(0xFF1D4ED8),
          ]),
        ),
        child: Column(
          children: [
            const Text('Empieza hoy mismo tu transformación',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24,
                    height: 1.2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            const Text('Únete a Academix y descubre cursos '
                'para seguir aprendiendo.', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.5)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onExplore,
                style: FilledButton.styleFrom(
                    backgroundColor: AcademixColors.background,
                    foregroundColor: Colors.white),
                child: const Text('Explorar catálogo'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRegister,
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6D28D9)),
                child: const Text('Crear cuenta gratis'),
              ),
            ),
          ],
        ),
      );
}

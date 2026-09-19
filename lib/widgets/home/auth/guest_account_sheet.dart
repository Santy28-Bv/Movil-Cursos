import 'package:flutter/material.dart';

import '../../../theme/academix_colors.dart';

/// Menú visible sin sesión. No consulta ni modifica datos privados.
class GuestAccountSheet extends StatelessWidget {
  const GuestAccountSheet({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.school_rounded,
                color: AcademixColors.lavender,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Bienvenido a Academix',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Explora los cursos sin una cuenta. '
                'Inicia sesión para acceder a las funciones de aprendizaje.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AcademixColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Iniciar sesión'),
                style: FilledButton.styleFrom(
                  backgroundColor: AcademixColors.purple,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Crear cuenta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AcademixColors.lavender,
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AcademixColors.border),
                ),
              ),
            ],
          ),
        ),
      );
}

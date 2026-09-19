import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class LearningStepsSection extends StatelessWidget {
  const LearningStepsSection({super.key});

  static const _steps = [
    ('Regístrate', 'Crea tu cuenta gratuita en segundos y accede a '
        'nuestro ecosistema educativo.', Icons.person_add_alt_1_outlined),
    ('Aprende', 'Accede a videolecciones, recursos descargables '
        'y material de apoyo.', Icons.play_lesson_outlined),
    ('Certifícate', 'Completa tus proyectos y obtén certificados '
        'cuando tu curso los ofrezca.', Icons.workspace_premium_outlined),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: AcademixColors.card.withOpacity(.55),
        padding: const EdgeInsets.fromLTRB(20, 35, 20, 38),
        child: Column(
          children: [
            const Text('Tu camino al éxito\nen 3 pasos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 25,
                    height: 1.2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            const Text('Aprende haciendo, desde cero hasta profesional.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AcademixColors.muted)),
            const SizedBox(height: 25),
            for (var i = 0; i < _steps.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 13),
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AcademixColors.card,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AcademixColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AcademixColors.purple.withOpacity(.23),
                      child: Icon(_steps[i].$3, color: AcademixColors.lavender),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${_steps[i].$1}',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(_steps[i].$2,
                              style: const TextStyle(
                                  color: AcademixColors.muted,
                                  height: 1.5, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

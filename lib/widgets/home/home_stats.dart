import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

/// Cifras promocionales de ejemplo de la página web, NO datos de Supabase.
class HomeStats extends StatelessWidget {
  const HomeStats({super.key});

  static const items = [
    ('1000+', 'Estudiantes activos'),
    ('150+', 'Cursos premium'),
    ('50+', 'Instructores expertos'),
    ('95%', 'Satisfacción'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 23, 20, 22),
        color: AcademixColors.card.withOpacity(.6),
        child: LayoutBuilder(
          builder: (context, limits) {
            final width = (limits.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 20,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        Text(item.$1,
                            style: const TextStyle(fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 5),
                        Text(item.$2, textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AcademixColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

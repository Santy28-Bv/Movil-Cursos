import 'package:flutter/material.dart';

/// Ventajas de aprendizaje, sin presentar cifras ficticias.
class HomeStats extends StatelessWidget {
  const HomeStats({super.key});

  static const items = [
    ('A tu ritmo', 'Aprende desde donde estés'),
    ('Cursos', 'Explora el catálogo de Academix'),
    ('Recursos', 'Contenido y materiales de clase'),
    ('Logros', 'Consulta tus certificados'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 23, 20, 22),
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .6),
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
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

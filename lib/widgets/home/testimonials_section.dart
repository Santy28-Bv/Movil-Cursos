import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

/// Testimonios estáticos tomados del Home web; no son reseñas verificadas en BD.
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  static const testimonials = [
    (
      'Amaury Martinez Diaz',
      'Desarrollador junior',
      'Gracias a los cursos de Academix logré mi primer empleo en tecnología '
          'en menos de 6 meses. El contenido es extremadamente práctico.',
    ),
    (
      'Sanitago',
      'Diseñador freelance',
      'La calidad de los instructores es insuperable. El curso de UI/UX '
          'cambió por completo mi forma de entender los productos digitales.',
    ),
    (
      'Marco',
      'Emprendedor',
      'El soporte de la comunidad es increíble. Siempre hay alguien '
          'dispuesto a ayudarte con tus dudas en los foros de cada curso.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 35, 20, 37),
    child: Column(
      children: [
        Text(
          'Lo que dicen nuestros estudiantes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Historias de la comunidad Academix.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        for (final testimonial in testimonials)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 13),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AcademixColors.rose,
                  size: 27,
                ),
                const SizedBox(height: 4),
                Text(
                  '“${testimonial.$3}”',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  testimonial.$1,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  testimonial.$2,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

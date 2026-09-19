import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../theme/academix_colors.dart';

/// Vista previa temporal: después se sustituirá por CourseDetailScreen.
class CoursePreviewSheet extends StatelessWidget {
  const CoursePreviewSheet({super.key, required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(course.title,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(course.description,
                    style: const TextStyle(color: AcademixColors.muted,
                        height: 1.55, fontSize: 15)),
                const SizedBox(height: 20),
                Text(course.priceLabel,
                    style: const TextStyle(color: AcademixColors.lavender,
                        fontWeight: FontWeight.bold, fontSize: 21)),
                const SizedBox(height: 16),
                const Text('Vista previa: el detalle, los módulos y la '
                    'inscripción se conectarán en la siguiente etapa.',
                    style: TextStyle(color: AcademixColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../theme/academix_colors.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 17),
        decoration: BoxDecoration(
          color: AcademixColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AcademixColors.border),
          boxShadow: const [BoxShadow(color: Color(0x30000000),
              blurRadius: 18, offset: Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 152,
                  width: double.infinity,
                  child: course.imageUrl.isEmpty
                      ? const _ImagePlaceholder()
                      : Image.network(course.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ImagePlaceholder()),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.category.toUpperCase(), maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AcademixColors.lavender,
                              fontSize: 11, letterSpacing: 1,
                              fontWeight: FontWeight.bold)),
                      if (course.isDemo)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 7),
                          child: Text('CURSO DE DEMOSTRACIÓN',
                            style: TextStyle(color: Color(0xFFE6B4FF),
                              fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      const SizedBox(height: 9),
                      Text(course.title, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 9),
                      Text(course.description, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AcademixColors.muted,
                              fontSize: 13, height: 1.5)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: Text(course.priceLabel,
                              style: const TextStyle(
                                  color: AcademixColors.lavender,
                                  fontSize: 19, fontWeight: FontWeight.w900))),
                          const Text('Ver curso', style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold,
                              fontSize: 13)),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward_rounded, size: 16,
                              color: AcademixColors.rose),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(
            colors: [Color(0xFF48216D), Color(0xFF253957)])),
        child: Center(child: Icon(Icons.auto_stories_rounded,
            size: 64, color: AcademixColors.lavender)),
      );
}

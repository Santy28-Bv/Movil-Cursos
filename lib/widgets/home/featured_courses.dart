import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../repositories/course_repository.dart';
import 'course_card.dart';

class FeaturedCourses extends StatefulWidget {
  const FeaturedCourses({
    super.key,
    required this.repository,
    required this.onOpen,
  });
  final ApiCourseRepository repository;
  final ValueChanged<Course> onOpen;
  @override
  State<FeaturedCourses> createState() => _FeaturedCoursesState();
}

class _FeaturedCoursesState extends State<FeaturedCourses> {
  late Future<List<Course>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.featured();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Course>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: LinearProgressIndicator(),
        );
      }
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: TextButton(
            onPressed:
                () => setState(() {
                  _future = widget.repository.featured();
                }),
            child: const Text('Reintentar cursos destacados'),
          ),
        );
      }
      final courses = snapshot.data ?? [];
      if (courses.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cursos destacados',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (final course in courses)
              CourseCard(course: course, onTap: () => widget.onOpen(course)),
          ],
        ),
      );
    },
  );
}

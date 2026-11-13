import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../repositories/course_repository.dart';
import '../../services/academix_api.dart';
import '../../widgets/home/course_card.dart';
import 'course_detail_screen.dart';

class InstructorScreen extends StatefulWidget {
  const InstructorScreen({
    super.key,
    required this.id,
    required this.repository,
  });
  final String id;
  final ApiCourseRepository repository;
  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  late Future<Map<String, dynamic>> _profile;
  final List<Course> _courses = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _profile = widget.repository.instructor(widget.id);
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.instructorCourses(
        widget.id,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _courses.addAll(page.items.map(Course.fromJson));
          _page = page.page;
          _hasMore = page.hasMore;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = studentError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Instructor')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(studentError(snapshot.error)),
                  TextButton(
                    onPressed:
                        () => setState(() {
                          _profile = widget.repository.instructor(widget.id);
                        }),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final profile = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile['name']}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text('${profile['specialty'] ?? ''}'),
                const SizedBox(height: 16),
                Text(
                  '${profile['biography'] ?? ''}',
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 16),
                Text(
                  '${profile['experienceYears'] ?? 0} años de experiencia · ${profile['courseCount'] ?? 0} cursos',
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
        Text(
          'Cursos del instructor',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final course in _courses)
          CourseCard(
            course: course,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(course: course),
                  ),
                ),
          ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) Text(_error!),
        if (!_loading && (_hasMore || _error != null))
          TextButton(
            onPressed: _load,
            child: Text(_error != null ? 'Reintentar' : 'Ver más cursos'),
          ),
      ],
    ),
  );
}

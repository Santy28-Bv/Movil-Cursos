import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/demo_learning_store.dart';
import '../../theme/academix_colors.dart';
import 'course_detail_screen.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AcademixColors.background,
    appBar: AppBar(title: const Text('Mis cursos'),
        backgroundColor: AcademixColors.card, foregroundColor: Colors.white),
    body: AnimatedBuilder(
      animation: DemoLearningStore.instance,
      builder: (context, _) {
        final courses = DemoLearningStore.instance.myCourses;
        if (Supabase.instance.client.auth.currentUser == null) {
          return const Center(child: Text('Inicia sesión para ver tus cursos.',
              style: TextStyle(color: Colors.white70)));
        }
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Inscripciones de demostración', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Estas inscripciones se mantienen únicamente durante la '
              'sesión actual de la app. No son matrículas reales de Supabase.',
              style: TextStyle(color: AcademixColors.muted)),
          const SizedBox(height: 20),
          if (courses.isEmpty) const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('No te has inscrito en ningún curso de demostración.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70))),
          ),
          ...courses.map((course) {
            final total = course.modules.expand((m) => m.lessons).length;
            final completed = DemoLearningStore.instance.completedCount(course);
            return Card(
              color: AcademixColors.card,
              child: ListTile(
                title: Text(course.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text('$completed / $total lecciones completadas (demo)',
                    style: const TextStyle(color: AcademixColors.muted)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(course: course))),
              ),
            );
          }),
        ]);
      },
    ),
  );
}

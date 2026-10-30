import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/learning_schema.dart';
import '../../models/course.dart';
import '../../repositories/learning_repository.dart';
import '../../services/demo_learning_store.dart';
import '../../theme/academix_colors.dart';
import 'course_detail_screen.dart';

/// Biblioteca: separa cursos demo en memoria de matrículas verificadas en BD.
class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});
  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late Future<List<Course>> _realCourses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _realCourses = SupabaseLearningRepository(Supabase.instance.client).myCourses();
  }

  void _open(Course course) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
  );

  Widget _courseTile(Course course) {
    final demo = course.isDemo;
    final total = demo ? course.modules.expand((m) => m.lessons).length : 0;
    final completed = demo ? DemoLearningStore.instance.completedCount(course) : 0;
    return Card(
      color: AcademixColors.card,
      child: ListTile(
        title: Text(course.title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(demo
            ? '$completed / $total lecciones completadas (demo)'
            : 'Inscripción real · Consulta tu temario',
            style: const TextStyle(color: AcademixColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: () => _open(course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AcademixColors.background,
    appBar: AppBar(title: const Text('Mis cursos'),
      backgroundColor: AcademixColors.card, foregroundColor: Colors.white,
      actions: [IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh),
        onPressed: () => setState(_load))]),
    body: AnimatedBuilder(
      animation: DemoLearningStore.instance,
      builder: (context, _) {
        if (Supabase.instance.client.auth.currentUser == null) {
          return const Center(child: Text('Inicia sesión para ver tus cursos.',
              style: TextStyle(color: Colors.white70)));
        }
        final demoCourses = DemoLearningStore.instance.myCourses;
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Mi aprendizaje', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (LearningSchema.enabled) FutureBuilder<List<Course>>(
            future: _realCourses,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return const Text(
                'No se pudieron consultar tus inscripciones reales.',
                style: TextStyle(color: Colors.white70));
              final courses = snapshot.data ?? [];
              if (courses.isEmpty) return const Text('Todavía no hay cursos inscritos en Supabase.',
                style: TextStyle(color: Colors.white70));
              return Column(children: courses.map(_courseTile).toList());
            },
          ) else const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Las inscripciones reales aún no están configuradas.',
              style: TextStyle(color: AcademixColors.muted)),
          ),
          const SizedBox(height: 24),
          const Text('Prácticas de demostración', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Estas prácticas no se guardan en Supabase ni son matrícula académica.',
              style: TextStyle(color: AcademixColors.muted)),
          const SizedBox(height: 12),
          if (demoCourses.isEmpty) const Text('No hay prácticas iniciadas.',
              style: TextStyle(color: Colors.white70)),
          ...demoCourses.map(_courseTile),
        ]);
      },
    ),
  );
}

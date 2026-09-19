import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/course.dart';
import '../../services/demo_learning_store.dart';
import '../../theme/academix_colors.dart';
import '../auth/login_screen.dart';
import 'lesson_screen.dart';

/// Detalle público: el temario puede verse sin sesión; aprender requiere login.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.course});
  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final store = DemoLearningStore.instance;

  Future<void> _enrollOrLearn() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
      setState(() {});
    }

    if (!widget.course.isDemo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La inscripción real necesita configurar las tablas y permisos de Supabase.'),
      ));
      return;
    }

    if (!store.isEnrolled(widget.course.id)) {
      final accept = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inscripción de demostración'),
          content: const Text('Este curso procede del catálogo de ejemplo de CursosWeb. '
              'La inscripción y el avance se guardan solo mientras está abierta la aplicación; '
              'no se registra ninguna compra ni inscripción en Supabase.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Probar demo')),
          ],
        ),
      );
      if (accept != true || !mounted) return;
      store.enroll(widget.course);
      setState(() {});
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Modo demostración: abre una lección del temario para practicar.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final signedIn = Supabase.instance.client.auth.currentUser != null;
    return Scaffold(
      backgroundColor: AcademixColors.background,
      appBar: AppBar(title: const Text('Detalle del curso'),
          backgroundColor: AcademixColors.card, foregroundColor: Colors.white),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final enrolled = signedIn && store.isEnrolled(course.id);
          return ListView(padding: const EdgeInsets.all(20), children: [
            if (course.isDemo)
              const _InfoBanner('CATÁLOGO DEMO · Basado en CursosWeb. No hay compras ni inscripciones reales.'),
            Text(course.category.toUpperCase(),
                style: const TextStyle(color: AcademixColors.lavender,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(course.title, style: const TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(course.description, style: const TextStyle(
                color: AcademixColors.muted, fontSize: 15, height: 1.5)),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 10, children: [
              Chip(label: Text(course.priceLabel)),
              if (course.level.isNotEmpty) Chip(label: Text(course.level)),
              if (course.durationHours > 0)
                Chip(label: Text('${course.durationHours} horas')),
              if (course.rating > 0)
                Chip(label: Text('★ ${course.rating}')),
            ]),
            if (course.instructor.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Instructor: ${course.instructor}',
                  style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _enrollOrLearn,
              icon: Icon(!signedIn ? Icons.login :
                  enrolled ? Icons.check_circle_outline : Icons.school_outlined),
              label: Text(!signedIn ? 'Iniciar sesión para inscribirse' :
                  enrolled ? 'Inscrito en demo' :
                  course.isDemo ? 'Probar inscripción (demo)' :
                  'Consultar inscripción'),
              style: FilledButton.styleFrom(
                  backgroundColor: AcademixColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
            )),
            if (course.learningOutcomes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Lo que aprenderás', style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...course.learningOutcomes.map((text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.check, color: AcademixColors.lavender, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text,
                      style: const TextStyle(color: Colors.white70))),
                ]),
              )),
            ],
            const SizedBox(height: 24),
            const Text('Contenido del curso', style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (course.modules.isEmpty)
              const Text('El temario y las tareas aún no están disponibles en la base de datos.',
                  style: TextStyle(color: AcademixColors.muted)),
            ...course.modules.map((module) => Card(
              color: AcademixColors.card,
              child: ExpansionTile(
                iconColor: AcademixColors.lavender,
                collapsedIconColor: Colors.white70,
                title: Text(module.title, style: const TextStyle(color: Colors.white)),
                children: module.lessons.map((lesson) {
                  final done = store.isCompleted('${course.id}/${lesson.id}');
                  return ListTile(
                    leading: Icon(done ? Icons.check_circle :
                        enrolled ? Icons.play_circle_outline : Icons.lock_outline,
                        color: AcademixColors.lavender),
                    title: Text(lesson.title, style: const TextStyle(color: Colors.white70)),
                    subtitle: Text('${lesson.durationMinutes} min',
                        style: const TextStyle(color: AcademixColors.muted)),
                    onTap: enrolled ? () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => LessonScreen(
                          course: course, lesson: lesson,
                        ))) : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inicia sesión e inscríbete a la demo para abrir lecciones.')),
                    ),
                  );
                }).toList(),
              ),
            )),
            const SizedBox(height: 26),
          ]);
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF38254D), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AcademixColors.purple),
    ),
    child: Text(message, style: const TextStyle(
        color: Colors.white70, fontSize: 12)),
  );
}

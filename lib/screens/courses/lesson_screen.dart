import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/course.dart';
import '../../services/demo_learning_store.dart';
import '../../theme/academix_colors.dart';

/// Solo se usa para el catálogo DEMO. No registra progreso académico real.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.course, required this.lesson});
  final Course course;
  final CourseLesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _answer = TextEditingController();
  final store = DemoLearningStore.instance;

  @override
  void initState() {
    super.initState();
    _answer.text = store.responseFor('${widget.course.id}/${widget.lesson.id}') ?? '';
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  bool get _allowed => widget.course.isDemo &&
      Supabase.instance.client.auth.currentUser != null &&
      store.isEnrolled(widget.course.id);

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      backgroundColor: AcademixColors.background,
      appBar: AppBar(backgroundColor: AcademixColors.card,
          foregroundColor: Colors.white, title: const Text('Aula de demostración')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('MODO DEMO · No se guarda en Supabase',
            style: TextStyle(color: AcademixColors.lavender,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(lesson.title, style: const TextStyle(color: Colors.white,
            fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('${lesson.durationMinutes} minutos',
            style: const TextStyle(color: AcademixColors.muted)),
        const SizedBox(height: 22),
        const Text('Los recursos y videos reales de esta lección aún no están '
            'conectados a la base de datos. El nombre y duración proceden del '
            'catálogo de demostración de CursosWeb.',
            style: TextStyle(color: Colors.white70, height: 1.5)),
        const SizedBox(height: 22),
        if (lesson.task.isNotEmpty) ...[
          const Text('Actividad de práctica (demo)', style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(lesson.task, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          TextField(
            controller: _answer, maxLines: 5, minLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Escribe tu respuesta de práctica',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: !_allowed ? null : () {
              if (_answer.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Escribe una respuesta antes de enviarla.')));
                return;
              }
              store.submitDemoTask(widget.course.id, lesson.id, _answer.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Respuesta guardada temporalmente (demo).')));
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('Guardar respuesta de práctica'),
          ),
          const SizedBox(height: 14),
        ],
        FilledButton.tonalIcon(
          onPressed: !_allowed ? null : () {
            store.complete(widget.course.id, lesson.id);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Lección marcada como completada (solo demo).')));
            setState(() {});
          },
          icon: Icon(store.isCompleted('${widget.course.id}/${lesson.id}')
              ? Icons.check_circle : Icons.check_circle_outline),
          label: const Text('Marcar lección como completada'),
        ),
      ]),
    );
  }
}

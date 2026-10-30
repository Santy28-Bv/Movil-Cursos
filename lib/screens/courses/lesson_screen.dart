import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/learning_schema.dart';
import '../../models/course.dart';
import '../../repositories/learning_repository.dart';
import '../../services/demo_learning_store.dart';
import '../../services/lesson_video_service.dart';
import '../../theme/academix_colors.dart';
import '../../widgets/courses/lesson_video_player.dart';

/// Aula. Los ejercicios de demo permanecen locales; las entregas reales
/// requieren que el esquema y las políticas RLS estén confirmados.
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
  late final SupabaseLearningRepository repository;
  late final Future<bool> _access;
  late final Future<List<Map<String, dynamic>>> _tasks;
  late final Future<Uri?> _video;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    repository = SupabaseLearningRepository(Supabase.instance.client);
    if (widget.course.isDemo) {
      _answer.text = store.responseFor('${widget.course.id}/${widget.lesson.id}') ?? '';
      _access = Future.value(store.isEnrolled(widget.course.id));
      _tasks = Future.value([]);
      _video = Future.value(null);
    } else {
      _access = repository.isEnrolled(widget.course.id);
      // No consultar tareas ni firmar URLs de video hasta verificar matrícula.
      _tasks = _access.then((allowed) => allowed
          ? repository.getTasks(widget.lesson.id) : <Map<String, dynamic>>[]);
      _video = _access.then((allowed) => allowed
          ? LessonVideoService(Supabase.instance.client).resolve(widget.lesson)
          : null);
    }
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _submitReal(String taskId) async {
    if (_submitting || _answer.text.trim().isEmpty) {
      if (_answer.text.trim().isEmpty) _message('Escribe una respuesta.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await repository.submitTask(taskId: taskId, answer: _answer.text);
      if (mounted) _message('Entrega registrada en Supabase.');
    } catch (e) {
      if (mounted) _message('No se pudo entregar la tarea: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );

  Future<void> _openResource() async {
    final uri = Uri.tryParse(widget.lesson.resourceUrl);
    if (uri == null || uri.scheme != 'https') {
      _message('Recurso no disponible.');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _message('No se pudo abrir el recurso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final demo = widget.course.isDemo;
    return Scaffold(
      backgroundColor: AcademixColors.background,
      appBar: AppBar(backgroundColor: AcademixColors.card,
          foregroundColor: Colors.white,
          title: Text(demo ? 'Aula de demostración' : 'Aula Academix')),
      body: FutureBuilder<bool>(
        future: _access,
        builder: (context, access) {
          if (access.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (access.hasError || access.data != true ||
              Supabase.instance.client.auth.currentUser == null) {
            return const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text('No tienes una inscripción activa para abrir esta lección.',
                style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)));
          }
          return ListView(padding: const EdgeInsets.all(20), children: [
            if (demo) const Text('MODO DEMO · No se guarda en Supabase',
                style: TextStyle(color: AcademixColors.lavender,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(lesson.title, style: const TextStyle(color: Colors.white,
                fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (lesson.durationMinutes > 0)
              Text('${lesson.durationMinutes} minutos',
                  style: const TextStyle(color: AcademixColors.muted)),
            const SizedBox(height: 20),
            if (!demo && (lesson.videoUrl.isNotEmpty || lesson.videoPath.isNotEmpty))
              FutureBuilder<Uri?>(
                future: _video,
                builder: (context, video) {
                  if (video.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (video.hasError || video.data == null) {
                    return const Text('El video no está disponible para esta sesión.',
                        style: TextStyle(color: Colors.white70));
                  }
                  return LessonVideoPlayer(uri: video.data!);
                },
              )
            else
              Text(demo
                ? 'Esta lección de demostración no tiene video real.'
                : 'Esta lección no tiene un video asociado en la base de datos.',
                style: const TextStyle(color: AcademixColors.muted)),
            if (lesson.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(lesson.description, style: const TextStyle(
                  color: Colors.white70, height: 1.5)),
            ],
            if (!demo && lesson.resourceUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _openResource,
                icon: const Icon(Icons.attach_file), label: const Text('Abrir recurso')),
            ],
            const SizedBox(height: 25),
            if (demo && lesson.task.isNotEmpty) ...[
              const Text('Actividad de práctica (demo)', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(lesson.task, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              _answerField(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  if (_answer.text.trim().isEmpty) {
                    _message('Escribe una respuesta antes de guardarla.');
                    return;
                  }
                  store.submitDemoTask(widget.course.id, lesson.id, _answer.text);
                  _message('Respuesta guardada temporalmente (demo).');
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Guardar respuesta demo'),
              ),
            ],
            if (!demo) FutureBuilder<List<Map<String, dynamic>>>(
              future: _tasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('No se pudieron consultar las actividades.',
                    style: TextStyle(color: Colors.white70));
                }
                final tasks = snapshot.data ?? [];
                if (tasks.isEmpty) {
                  return const Text('Sin actividades configuradas para esta lección.',
                    style: TextStyle(color: AcademixColors.muted));
                }
                // La escritura solo se permite si el esquema de entregas fue validado.
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tareas', style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  ...tasks.map((task) => Card(
                    color: AcademixColors.card,
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((task['title'] ?? task['titulo'] ?? 'Actividad').toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text((task['description'] ?? task['descripcion'] ?? '').toString(),
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        _answerField(),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _submitting || !LearningSchema.submissionsEnabled
                            ? null : () => _submitReal((task['id'] ?? task['id_tarea']).toString()),
                          icon: const Icon(Icons.send),
                          label: const Text('Entregar tarea'),
                        ),
                      ],
                    )),
                  )),
                ]);
              },
            ),
            if (demo) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () {
                  store.complete(widget.course.id, lesson.id);
                  _message('Lección completada (solo demo).');
                  setState(() {});
                },
                icon: Icon(store.isCompleted('${widget.course.id}/${lesson.id}')
                    ? Icons.check_circle : Icons.check_circle_outline),
                label: const Text('Marcar lección completada'),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _answerField() => TextField(
    controller: _answer,
    minLines: 3, maxLines: 5,
    style: const TextStyle(color: Colors.white),
    decoration: const InputDecoration(
      labelText: 'Tu respuesta', border: OutlineInputBorder(),
    ),
  );
}

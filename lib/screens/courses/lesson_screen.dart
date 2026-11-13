import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/course.dart';
import '../../repositories/learning_repository.dart';
import '../../services/academix_api.dart';
import '../../widgets/courses/lesson_resource.dart';
import '../student/certificates_screen.dart';
import '../../widgets/student/student_guard.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.course,
    this.lesson,
    this.repository,
  });
  final Course course;
  final CourseLesson? lesson;
  final LearningRepository? repository;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LearningRepository _repository;
  late Future<LearningCourse> _future;
  String? _activeId;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? LearningRepository(Supabase.instance.client);
    _activeId = widget.lesson?.id;
    _reload();
  }

  void _reload() {
    _future = _repository.learning(widget.course.id);
  }

  Future<void> _progress(CourseLesson lesson) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.setProgress(lesson.id, !lesson.isCompleted);
      final result = await _repository.learning(widget.course.id);
      if (mounted) {
        setState(() {
          _future = Future.value(result);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = studentError(error, 'No pudimos guardar tu progreso.'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aula virtual')),
    body: FutureBuilder<LearningCourse>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    studentError(
                      snapshot.error,
                      'No pudimos abrir este curso.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final course = snapshot.data!;
        final lessons = course.lessons;
        if (lessons.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Este curso todavía no tiene lecciones publicadas.'),
            ),
          );
        }
        final active =
            lessons.where((l) => l.id == _activeId).firstOrNull ??
            lessons.where((l) => !l.isCompleted).firstOrNull ??
            lessons.first;
        _activeId = active.id;
        final index = lessons.indexOf(active);
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(course.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (course.percentage / 100).clamp(0, 1).toDouble(),
            ),
            const SizedBox(height: 8),
            Text('Progreso total: ${course.percentage}%'),
            const SizedBox(height: 18),
            Card(
              child: ExpansionTile(
                title: const Text('Contenido del curso'),
                subtitle: Text('${lessons.length} lecciones'),
                children: [
                  for (final module in course.modules)
                    ExpansionTile(
                      title: Text(module.title),
                      children: [
                        for (final lesson in module.lessons)
                          ListTile(
                            selected: lesson.id == active.id,
                            leading: Icon(
                              lesson.isCompleted
                                  ? Icons.check_circle
                                  : Icons.play_circle_outline,
                            ),
                            title: Text(lesson.title),
                            subtitle: Text('${lesson.durationMinutes} min'),
                            onTap:
                                () => setState(() {
                                  _activeId = lesson.id;
                                  _error = null;
                                }),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('${active.durationMinutes} minutos')),
                        if (active.isCompleted)
                          const Chip(label: Text('Completada')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      active.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (active.description.isNotEmpty)
                      Text(
                        active.description,
                        style: const TextStyle(height: 1.6),
                      ),
                    if (active.content.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          active.content,
                          style: const TextStyle(height: 1.7),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_error!),
                      ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _progress(active),
                      icon: Icon(
                        active.isCompleted
                            ? Icons.undo
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        _saving
                            ? 'Guardando…'
                            : active.isCompleted
                            ? 'Marcar como pendiente'
                            : 'Marcar como completada',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (index > 0)
                          OutlinedButton(
                            onPressed:
                                () => setState(
                                  () => _activeId = lessons[index - 1].id,
                                ),
                            child: const Text('← Anterior'),
                          ),
                        if (index < lessons.length - 1)
                          OutlinedButton(
                            onPressed:
                                () => setState(
                                  () => _activeId = lessons[index + 1].id,
                                ),
                            child: const Text('Siguiente →'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (active.resources.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'Recursos de la lección',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final resource in active.resources)
                LessonResource(
                  key: ValueKey('${active.id}/${resource.id}'),
                  resource: resource,
                  api: _repository.api,
                ),
            ],
            const SizedBox(height: 20),
            Text('Instructor: ${course.instructor}'),
            if (course.percentage >= 100 && widget.course.certificateEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudentGuard(
                                builder: (_) => const CertificatesScreen(),
                              ),
                        ),
                      ),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Ver mis certificados'),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    ),
  );
}

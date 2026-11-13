import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/learning_repository.dart';
import '../../services/academix_api.dart';
import '../../widgets/student/student_banner.dart';
import '../../widgets/student/student_guard.dart';
import 'lesson_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key, this.repository});
  final LearningRepository? repository;
  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late final LearningRepository _repository;
  final List<EnrolledCourse> _entries = [];
  Map<String, dynamic>? _summary;
  bool _summaryError = false;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;
  int _filter = 0;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? LearningRepository(Supabase.instance.client);
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([_load(reset: true), _metrics()]);
  }

  Future<void> _metrics() async {
    final owner = _repository.api.client.auth.currentUser?.id;
    try {
      final summary = await _repository.summary();
      if (mounted && owner == _repository.api.client.auth.currentUser?.id) {
        setState(() {
          _summary = summary;
          _summaryError = false;
        });
      }
    } catch (_) {
      if (mounted && owner == _repository.api.client.auth.currentUser?.id) {
        setState(() => _summaryError = true);
      }
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final revision = reset ? ++_revision : _revision;
    setState(() {
      if (reset) {
        _page = 0;
        _entries.clear();
        _hasMore = true;
      }
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.myCoursesPage(
        page: _page + 1,
        status:
            _filter == 0
                ? null
                : _filter == 1
                ? 'in_progress'
                : 'completed',
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        _entries.addAll(result.items.map(EnrolledCourse.fromJson));
        _page = result.page;
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(
          () =>
              _error = studentError(error, 'No pudimos cargar tu biblioteca.'),
        );
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _loading = false);
    }
  }

  Future<void> _open(EnrolledCourse entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentGuard(
              builder: (_) => LessonScreen(course: entry.course),
            ),
      ),
    );
    if (mounted) await _refresh();
  }

  Widget _metric(String label, String key, double width) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_summary?[key] ?? '—'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi aprendizaje'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          const StudentBanner(
            title: 'Sigue aprendiendo',
            message: 'Retoma tus cursos y consulta tus logros.',
          ),
          LayoutBuilder(
            builder: (context, box) {
              final width = (box.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric('En progreso', 'inProgress', width),
                  _metric('Completados', 'completed', width),
                  _metric('Certificados', 'certificates', width),
                  _metric('Horas de aprendizaje', 'learningHours', width),
                ],
              );
            },
          ),
          if (_summaryError)
            TextButton(
              onPressed: _metrics,
              child: const Text(
                'No se pudieron actualizar las métricas. Reintentar',
              ),
            ),
          const SizedBox(height: 24),
          Text('Mis cursos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(['Todos', 'En progreso', 'Completados'][i]),
                  selected: _filter == i,
                  onSelected: (_) {
                    setState(() => _filter = i);
                    _load(reset: true);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final entry in _entries)
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: entry.accessActive ? () => _open(entry) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (entry.course.imageUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 16 / 8,
                        child: Image.network(
                          entry.course.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const Icon(Icons.school_outlined, size: 48),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.course.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(entry.course.instructor),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value:
                                (entry.percentage / 100).clamp(0, 1).toDouble(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${entry.completedLessons} / ${entry.totalLessons} lecciones · ${entry.percentage}%',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            !entry.accessActive
                                ? 'Tu acceso ya no está activo.'
                                : entry.completed
                                ? 'Completado · Volver al aula'
                                : 'Continuar aprendiendo',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null) ...[
            Text(_error!),
            TextButton(
              onPressed: () => _load(),
              child: const Text('Reintentar'),
            ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_entries.isEmpty && _error == null) ...[
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No tienes cursos en esta categoría.',
                textAlign: TextAlign.center,
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Explorar cursos'),
            ),
          ] else if (_hasMore && _error == null)
            TextButton(
              onPressed: () => _load(),
              child: const Text('Cargar más cursos'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

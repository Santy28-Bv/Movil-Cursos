import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/learning_schema.dart';
import '../../config/student_schema.dart';
import '../../models/course.dart';
import '../../models/course_progress.dart';
import '../../repositories/learning_repository.dart';
import '../../repositories/student_repository.dart';
import '../../services/demo_learning_store.dart';
import '../../widgets/student/student_banner.dart';
import 'course_detail_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});
  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _LibraryEntry {
  const _LibraryEntry(this.course, this.progress, this.completed);
  final Course course;
  final CourseProgress? progress;
  final bool completed;
}

class _LibraryData {
  const _LibraryData(this.entries, this.certificates);
  final List<_LibraryEntry> entries;
  final int? certificates;
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late Future<_LibraryData> _future;
  int _filter = 0;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_LibraryData> _load() async {
    final client = Supabase.instance.client;
    final learning = SupabaseLearningRepository(client);
    final student = StudentRepository(client);
    final records = await learning.myCourseRecords();
    final entries = await Future.wait(
      records.map((record) async {
        CourseProgress? progress;
        if (StudentSchema.enabled) {
          final modules = await learning.getModules(record.course.id);
          final completed = await student.completedLessons(record.course.id);
          progress = CourseProgress.fromModules(modules, completed);
        }
        return _LibraryEntry(
          record.course,
          progress,
          record.completed || (progress?.isCompleted ?? false),
        );
      }),
    );
    final certificates =
        StudentSchema.enabled ? (await student.certificates()).length : null;
    return _LibraryData(entries, certificates);
  }

  Future<void> _open(Course course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
    );
    if (mounted) setState(_reload);
  }

  Widget _tile(_LibraryEntry entry, {bool demo = false}) => Card(
    child: InkWell(
      onTap: () => _open(entry.course),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.course.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(entry.completed ? 'Completado' : 'En progreso'),
            if (entry.progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: entry.progress!.fraction),
              const SizedBox(height: 8),
              Text(
                '${entry.progress!.done} / ${entry.progress!.total} lecciones${demo ? ' · Demo' : ''}',
              ),
            ] else
              const Text('Progreso aún no conectado'),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.play_circle_outline),
                SizedBox(width: 8),
                Expanded(child: Text('Continuar aprendiendo')),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _metric(String label, String value, double width) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
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
      title: const Text('Mis cursos'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(_reload),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: DemoLearningStore.instance,
      builder:
          (context, _) => RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              try {
                await _future;
              } catch (_) {
                /* FutureBuilder muestra el error. */
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                const StudentBanner(
                  title: 'Tu panel de aprendizaje',
                  message:
                      'Retoma tus cursos y sigue cada paso de tu formación.',
                ),
                FutureBuilder<_LibraryData>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          const Text(
                            'No se pudo consultar tu biblioteca. Tus datos no se han modificado.',
                          ),
                          TextButton(
                            onPressed: () => setState(_reload),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      );
                    }
                    final data = snapshot.data ?? const _LibraryData([], null);
                    final completed =
                        data.entries.where((e) => e.completed).length;
                    final minutes = data.entries.fold(
                      0,
                      (sum, e) => sum + (e.progress?.learnedMinutes ?? 0),
                    );
                    final entries = data.entries.where(
                      (e) => _filter == 0 || (_filter == 2) == e.completed,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, box) {
                            final width = (box.maxWidth - 12) / 2;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _metric(
                                  'Cursos en progreso',
                                  '${data.entries.length - completed}',
                                  width,
                                ),
                                _metric(
                                  'Cursos completados',
                                  '$completed',
                                  width,
                                ),
                                _metric(
                                  'Certificados obtenidos',
                                  data.certificates?.toString() ?? '—',
                                  width,
                                ),
                                _metric(
                                  'Horas de aprendizaje',
                                  StudentSchema.enabled
                                      ? '${(minutes / 60).toStringAsFixed(1)} h'
                                      : '—',
                                  width,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        if (!LearningSchema.enabled)
                          const Text(
                            'Tus inscripciones reales aún no están conectadas al servidor.',
                          ),
                        if (!StudentSchema.enabled)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              'El progreso y los certificados se mostrarán al conectar esos servicios.',
                            ),
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (var i = 0; i < 3; i++)
                              ChoiceChip(
                                label: Text(
                                  ['Todos', 'En progreso', 'Completados'][i],
                                ),
                                selected: _filter == i,
                                onSelected: (_) => setState(() => _filter = i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (entries.isEmpty) ...[
                          Text(
                            data.entries.isEmpty
                                ? 'Aún no tienes cursos inscritos.'
                                : 'No hay cursos en esta categoría.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed:
                                () => Navigator.of(
                                  context,
                                ).popUntil((r) => r.isFirst),
                            child: const Text('Explorar cursos'),
                          ),
                        ],
                        ...entries.map(_tile),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  'Prácticas de demostración',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'El avance de estas prácticas es temporal. No son inscripciones ni certificados académicos.',
                ),
                const SizedBox(height: 12),
                if (DemoLearningStore.instance.myCourses.isEmpty)
                  const Text('No has iniciado prácticas demo.'),
                ...DemoLearningStore.instance.myCourses.map((course) {
                  final progress = CourseProgress.fromModules(course.modules, {
                    for (final m in course.modules)
                      for (final l in m.lessons)
                        if (DemoLearningStore.instance.isCompleted(
                          '${course.id}/${l.id}',
                        ))
                          l.id,
                  });
                  return _tile(
                    _LibraryEntry(course, progress, progress.isCompleted),
                    demo: true,
                  );
                }),
              ],
            ),
          ),
    ),
  );
}

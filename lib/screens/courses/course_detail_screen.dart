import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/course.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/learning_repository.dart';
import '../../services/academix_api.dart';
import '../../services/student_session.dart';
import '../../theme/academix_colors.dart';
import '../../widgets/student/student_guard.dart';
import '../../widgets/student/course_reviews.dart';
import '../auth/login_screen.dart';
import 'lesson_screen.dart';
import 'instructor_screen.dart';
import '../../widgets/home/course_card.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.course,
    this.catalog,
    this.learning,
  });
  final Course course;
  final ApiCourseRepository? catalog;
  final LearningRepository? learning;
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final ApiCourseRepository _catalog;
  late final LearningRepository _learning;
  late final StreamSubscription<AuthState> _subscription;
  late Future<Course> _future;
  late Future<List<Course>> _related;
  String? _owner;
  bool _enrolled = false;
  bool _completed = false;
  bool _checking = false;
  bool _saving = false;
  String? _accessError;
  int _accessVersion = 0;
  @override
  void initState() {
    super.initState();
    final client = widget.catalog?.api.client ?? Supabase.instance.client;
    _catalog = widget.catalog ?? ApiCourseRepository(client);
    _learning = widget.learning ?? LearningRepository(client);
    _owner = client.auth.currentUser?.id;
    _future = _catalog.detail(widget.course.id);
    _related = _catalog.related(widget.course.id);
    _subscription = client.auth.onAuthStateChange.listen((event) {
      if (!mounted || _owner == event.session?.user.id) return;
      setState(() {
        _owner = event.session?.user.id;
        _enrolled = false;
        _completed = false;
        _accessError = null;
      });
      _checkAccess();
    }, onError: (Object error, StackTrace stack) {});
    _checkAccess();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final version = ++_accessVersion;
    if (_owner == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    setState(() {
      _checking = true;
      _accessError = null;
    });
    try {
      final enrollment = await _learning.enrollment(widget.course.id);
      if (mounted && version == _accessVersion) {
        setState(() {
          _enrolled = enrollment?.accessActive == true;
          _completed = enrollment?.completed == true;
        });
      }
    } catch (error) {
      if (mounted && version == _accessVersion) {
        setState(
          () =>
              _accessError = studentError(
                error,
                'No pudimos comprobar tu inscripción.',
              ),
        );
      }
    } finally {
      if (mounted && version == _accessVersion) {
        setState(() => _checking = false);
      }
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> _openLesson(Course course, [CourseLesson? lesson]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentGuard(
              builder: (_) => LessonScreen(course: course, lesson: lesson),
            ),
      ),
    );
    if (mounted) _checkAccess();
  }

  Future<void> _primary(Course course, {bool checkIncluded = false}) async {
    if (_saving || _checking) return;
    if (_owner == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || _catalog.api.client.auth.currentUser == null) return;
      await _checkAccess();
    }
    if (!mounted || _accessError != null) return;
    if (_enrolled) {
      await _openLesson(course);
      return;
    }
    if (course.price != null && course.price! > 0 && !checkIncluded) {
      try {
        StudentSession.instance.addToCart(course);
        _message('Curso añadido a tu carrito.');
      } catch (error) {
        _message(studentError(error, 'No pudimos añadir el curso.'));
      }
      return;
    }
    final owner = _owner;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar inscripción'),
            content: Text(
              '¿Quieres inscribirte en ${course.title}? Se comprobarán las condiciones de acceso.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Inscribirme'),
              ),
            ],
          ),
    );
    if (confirm != true || !mounted || owner != _owner) return;
    setState(() => _saving = true);
    try {
      final enrollment = await _learning.enroll(course);
      if (!mounted || owner != _owner) return;
      setState(() {
        _enrolled = true;
        _completed = enrollment.completed;
      });
      _message('Inscripción confirmada. El curso ya está en Mis cursos.');
      await _openLesson(course);
    } catch (error) {
      _message(studentError(error, 'No pudimos confirmar la inscripción.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _title(String value) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Text(value, style: Theme.of(context).textTheme.titleLarge),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del curso')),
    body: FutureBuilder<Course>(
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
                      'No pudimos consultar este curso.',
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => setState(() {
                          _future = _catalog.detail(widget.course.id);
                        }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final course = snapshot.data!;
        return ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B0764), Color(0xFF1E1235)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(course.category)),
                  const SizedBox(height: 12),
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    course.shortDescription,
                    style: const TextStyle(
                      color: Color(0xFFDDD6FE),
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed:
                        course.instructorId.isEmpty
                            ? null
                            : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => InstructorScreen(
                                      id: course.instructorId,
                                      repository: _catalog,
                                    ),
                              ),
                            ),
                    child: Text(
                      'Por ${course.instructor}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        '★ ${course.rating.toStringAsFixed(1)} (${course.reviewCount} reseñas)',
                      ),
                      Text('${course.durationHours} horas'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child:
                          course.imageUrl.isEmpty
                              ? const ColoredBox(
                                color: Color(0xFF261842),
                                child: Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: AcademixColors.lavender,
                                ),
                              )
                              : Image.network(
                                course.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const ColoredBox(
                                      color: Color(0xFF261842),
                                      child: Icon(
                                        Icons.school_outlined,
                                        size: 64,
                                      ),
                                    ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            course.priceLabel,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${course.levelLabel} · ${course.durationHours} horas',
                          ),
                          if (course.certificateEnabled)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Incluye certificado al completar el curso',
                              ),
                            ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed:
                                _checking || _saving || _accessError != null
                                    ? null
                                    : () => _primary(course),
                            icon: Icon(
                              _enrolled
                                  ? Icons.play_circle_outline
                                  : Icons.school_outlined,
                            ),
                            label: Text(
                              _checking
                                  ? 'Comprobando acceso…'
                                  : _saving
                                  ? 'Inscribiendo…'
                                  : _enrolled
                                  ? 'Continuar aprendiendo'
                                  : _owner == null
                                  ? 'Iniciar sesión para continuar'
                                  : course.price != null && course.price! > 0
                                  ? 'Añadir al carrito'
                                  : 'Inscribirme',
                            ),
                          ),
                          if (_owner != null &&
                              !_enrolled &&
                              course.price != null &&
                              course.price! > 0)
                            TextButton(
                              onPressed:
                                  _checking || _saving || _accessError != null
                                      ? null
                                      : () =>
                                          _primary(course, checkIncluded: true),
                              child: const Text('Consultar acceso incluido'),
                            ),
                          if (_accessError != null) ...[
                            const SizedBox(height: 10),
                            Text(_accessError!),
                            TextButton(
                              onPressed: _checkAccess,
                              child: const Text('Reintentar acceso'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (course.learningOutcomes.isNotEmpty) ...[
                    _title('Lo que aprenderás'),
                    for (final text in course.learningOutcomes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check,
                              color: AcademixColors.lavender,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(text)),
                          ],
                        ),
                      ),
                  ],
                  _title('Descripción general'),
                  Text(course.description, style: const TextStyle(height: 1.7)),
                  _title('Temario del curso'),
                  Text('${course.modules.length} módulos'),
                  const SizedBox(height: 12),
                  if (course.modules.isEmpty)
                    const Text(
                      'Este curso todavía no tiene lecciones publicadas.',
                    ),
                  for (final module in course.modules)
                    Card(
                      child: ExpansionTile(
                        title: Text(module.title),
                        subtitle: Text('${module.lessons.length} lecciones'),
                        children: [
                          for (final lesson in module.lessons)
                            ListTile(
                              leading: Icon(
                                _enrolled
                                    ? Icons.play_circle_outline
                                    : Icons.lock_outline,
                                color: AcademixColors.lavender,
                              ),
                              title: Text(lesson.title),
                              subtitle: Text('${lesson.durationMinutes} min'),
                              onTap:
                                  _enrolled
                                      ? () => _openLesson(course, lesson)
                                      : () => _message(
                                        'Inicia sesión e inscríbete para abrir el aula.',
                                      ),
                            ),
                        ],
                      ),
                    ),
                  if (course.requirements.isNotEmpty) ...[
                    _title('Requisitos'),
                    for (final text in course.requirements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('• $text'),
                      ),
                  ],
                  _title('Cursos relacionados'),
                  FutureBuilder<List<Course>>(
                    future: _related,
                    builder: (context, related) {
                      if (related.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      if (related.hasError) {
                        return TextButton(
                          onPressed:
                              () => setState(() {
                                _related = _catalog.related(course.id);
                              }),
                          child: const Text('Reintentar cursos relacionados'),
                        );
                      }
                      if (related.data!.isEmpty) {
                        return const Text(
                          'No hay cursos relacionados por ahora.',
                        );
                      }
                      return Column(
                        children: [
                          for (final item in related.data!)
                            CourseCard(
                              course: item,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              CourseDetailScreen(course: item),
                                    ),
                                  ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  CourseReviews(
                    key: ValueKey('${course.id}/$_owner'),
                    courseId: course.id,
                    hasAccess: _enrolled,
                    isCompleted: _completed,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

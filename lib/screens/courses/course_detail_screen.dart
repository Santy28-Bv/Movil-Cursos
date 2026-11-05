import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/learning_schema.dart';
import '../../config/student_schema.dart';
import '../../services/student_session.dart';
import '../../widgets/student/student_guard.dart';
import '../../widgets/student/course_reviews.dart';
import '../student/cart_screen.dart';
import '../../models/course.dart';
import '../../repositories/learning_repository.dart';
import '../../services/demo_learning_store.dart';
import '../../theme/academix_colors.dart';
import '../auth/login_screen.dart';
import 'lesson_screen.dart';

/// Los visitantes pueden consultar el detalle público.
/// La inscripción y las lecciones requieren sesión y autorización.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.course});
  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final store = DemoLearningStore.instance;
  late final SupabaseLearningRepository repository;
  late Future<List<CourseModule>> _modulesFuture;
  bool _realEnrolled = false;
  bool _checking = false;
  late final StreamSubscription<AuthState> _authSubscription;
  String? _owner;

  @override
  void initState() {
    super.initState();
    repository = SupabaseLearningRepository(Supabase.instance.client);
    _owner = Supabase.instance.client.auth.currentUser?.id;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      if (!mounted || _owner == event.session?.user.id) return;
      setState(() {
        _owner = event.session?.user.id;
        _realEnrolled = false;
        _modulesFuture =
            widget.course.isDemo
                ? Future.value(widget.course.modules)
                : repository.getModules(widget.course.id);
      });
      _refreshEnrollment();
    });
    _modulesFuture =
        widget.course.isDemo
            ? Future.value(widget.course.modules)
            : repository.getModules(widget.course.id);
    _refreshEnrollment();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _refreshEnrollment() async {
    if (widget.course.isDemo ||
        !LearningSchema.enabled ||
        Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    try {
      final owner = _owner;
      final enrolled = await repository.isEnrolled(widget.course.id);
      if (mounted && _owner == owner) setState(() => _realEnrolled = enrolled);
    } catch (_) {
      // El error se mostrará cuando el estudiante intente inscribirse.
    }
  }

  void _notice(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _enrollOrLearn() async {
    if (_checking) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
      setState(() {
        if (!widget.course.isDemo && LearningSchema.enabled) {
          // Volver a consultar el temario con el JWT recién autenticado.
          _modulesFuture = repository.getModules(widget.course.id);
        }
      });
      await _refreshEnrollment();
    }

    if (!mounted) return;

    if (widget.course.isDemo) {
      if (!store.isEnrolled(widget.course.id)) {
        final accept = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Inscripción de demostración'),
                content: const Text(
                  'No es un pago ni una inscripción real. El avance y las respuestas '
                  'se guardan solo en la memoria de esta ejecución.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Probar demo'),
                  ),
                ],
              ),
        );
        if (accept != true || !mounted) return;
        store.enroll(widget.course);
        setState(() {});
      }
      _notice('Abre una lección del temario para comenzar (demo).');
      return;
    }
    if (widget.course.price != null &&
        widget.course.price! > 0 &&
        (widget.course.organizationId.isEmpty ||
            StudentSchema.includedEnrollmentRpc.isEmpty) &&
        !_realEnrolled) {
      await _addToCart();
      return;
    }
    if (!LearningSchema.enabled) {
      _notice('La inscripción a este curso todavía no está disponible.');
      return;
    }
    if (_realEnrolled) {
      _notice('Ya estás inscrito. Selecciona una lección para continuar.');
      return;
    }
    if (widget.course.price != 0) {
      if (widget.course.organizationId.isEmpty ||
          StudentSchema.includedEnrollmentRpc.isEmpty) {
        await _addToCart();
        return;
      }
    }
    if (!mounted) return;
    final owner = _owner;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar inscripción'),
            content: Text(
              widget.course.price == 0
                  ? '¿Quieres inscribirte gratis en ${widget.course.title}?'
                  : 'Se comprobará si tu organización incluye este curso sin costo para ti.',
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
    if (confirmed != true || !mounted || owner != _owner) return;
    setState(() => _checking = true);
    try {
      if (widget.course.price == 0) {
        await repository.enrollFree(widget.course);
      } else {
        await repository.enrollIncluded(widget.course);
      }
      if (mounted && owner == _owner) {
        setState(() {
          _realEnrolled = true;
          _modulesFuture = repository.getModules(widget.course.id);
        });
        _notice(
          'Inscripción confirmada. Ya puedes abrir el aula o consultar Mis cursos.',
        );
      }
    } catch (_) {
      _notice(
        'No se pudo confirmar la inscripción. Comprueba tu acceso e intenta nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _addToCart() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    try {
      StudentSession.instance.addToCart(widget.course);
      _notice('Curso añadido a tu carrito.');
    } on StateError catch (e) {
      _notice(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final signedIn = Supabase.instance.client.auth.currentUser != null;
    return Scaffold(
      backgroundColor: AcademixColors.background,
      appBar: AppBar(
        title: const Text('Detalle del curso'),
        backgroundColor: AcademixColors.card,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: StudentSession.instance,
            builder:
                (context, _) => IconButton(
                  tooltip: 'Mi carrito',
                  onPressed: () async {
                    if (Supabase.instance.client.auth.currentUser == null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                    if (!context.mounted ||
                        Supabase.instance.client.auth.currentUser == null) {
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => StudentGuard(
                              builder: (_) => const CartScreen(),
                            ),
                      ),
                    );
                  },
                  icon: Badge(
                    isLabelVisible: StudentSession.instance.cart.isNotEmpty,
                    label: Text('${StudentSession.instance.cart.length}'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final enrolled =
              signedIn &&
              (course.isDemo ? store.isEnrolled(course.id) : _realEnrolled);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (course.isDemo)
                const _InfoBanner(
                  'CATÁLOGO DEMO · Basado en CursosWeb. No hay pagos ni inscripciones reales.',
                ),
              Text(
                course.category.toUpperCase(),
                style: const TextStyle(
                  color: AcademixColors.lavender,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                course.description,
                style: const TextStyle(
                  color: AcademixColors.muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  Chip(label: Text(course.priceLabel)),
                  if (course.level.isNotEmpty) Chip(label: Text(course.level)),
                  if (course.durationHours > 0)
                    Chip(label: Text('${course.durationHours} horas')),
                  if (course.rating > 0)
                    Chip(label: Text('★ ${course.rating}')),
                ],
              ),
              if (course.instructor.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Instructor: ${course.instructor}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checking ? null : _enrollOrLearn,
                  icon: Icon(
                    !signedIn
                        ? Icons.login
                        : enrolled
                        ? Icons.check_circle_outline
                        : Icons.school_outlined,
                  ),
                  label: Text(
                    _checking
                        ? 'Registrando...'
                        : !signedIn
                        ? 'Iniciar sesión para inscribirse'
                        : enrolled
                        ? 'Continuar aprendiendo'
                        : course.isDemo
                        ? 'Probar inscripción (demo)'
                        : course.price == 0
                        ? 'Inscribirme gratis'
                        : course.organizationId.isNotEmpty &&
                            StudentSchema.includedEnrollmentRpc.isNotEmpty
                        ? 'Consultar acceso institucional'
                        : 'Añadir al carrito',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AcademixColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              if (course.price != null &&
                  course.price! > 0 &&
                  !enrolled &&
                  (course.isDemo || course.organizationId.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Añadir al carrito'),
                  ),
                ),
              if (course.learningOutcomes.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Lo que aprenderás',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...course.learningOutcomes.map(
                  (text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          color: AcademixColors.lavender,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Contenido del curso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<CourseModule>>(
                future: _modulesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'No fue posible obtener el temario desde Supabase. '
                      'Revisa las tablas y las políticas de acceso.',
                      style: TextStyle(color: Colors.white70),
                    );
                  }
                  final modules = snapshot.data ?? [];
                  if (modules.isEmpty) {
                    return const Text(
                      'Todavía no hay módulos disponibles o el esquema real '
                      'no está configurado.',
                      style: TextStyle(color: AcademixColors.muted),
                    );
                  }
                  return Column(
                    children:
                        modules
                            .map(
                              (module) => Card(
                                color: AcademixColors.card,
                                child: ExpansionTile(
                                  iconColor: AcademixColors.lavender,
                                  collapsedIconColor: Colors.white70,
                                  title: Text(
                                    module.title,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  children:
                                      module.lessons.map((lesson) {
                                        final done =
                                            course.isDemo &&
                                            store.isCompleted(
                                              '${course.id}/${lesson.id}',
                                            );
                                        return ListTile(
                                          leading: Icon(
                                            done
                                                ? Icons.check_circle
                                                : enrolled
                                                ? Icons.play_circle_outline
                                                : Icons.lock_outline,
                                            color: AcademixColors.lavender,
                                          ),
                                          title: Text(
                                            lesson.title,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          subtitle: Text(
                                            lesson.durationMinutes > 0
                                                ? '${lesson.durationMinutes} min'
                                                : 'Lección',
                                            style: const TextStyle(
                                              color: AcademixColors.muted,
                                            ),
                                          ),
                                          onTap:
                                              enrolled
                                                  ? () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) => StudentGuard(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => LessonScreen(
                                                                  course:
                                                                      course,
                                                                  lesson:
                                                                      lesson,
                                                                ),
                                                          ),
                                                    ),
                                                  )
                                                  : () => _notice(
                                                    'Inicia sesión e inscríbete para abrir las lecciones.',
                                                  ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
              const SizedBox(height: 26),
              CourseReviews(
                key: ValueKey(_owner),
                courseId: course.id,
                hasAccess: enrolled,
                isDemo: course.isDemo,
              ),
              const SizedBox(height: 26),
            ],
          );
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
      color: const Color(0xFF38254D),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AcademixColors.purple),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    ),
  );
}

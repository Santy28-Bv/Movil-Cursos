import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/student_schema.dart';
import '../config/learning_schema.dart';
import '../models/student_data.dart';
import 'learning_repository.dart';

class StudentRepository {
  const StudentRepository(
    this.client, {
    this.enabled = StudentSchema.enabled,
    this.learningEnabled = LearningSchema.enabled,
  });
  final SupabaseClient client;
  final bool enabled;
  final bool learningEnabled;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Inicia sesión para continuar.');
    return id;
  }

  void _requireConfigured() {
    if (!enabled) {
      throw StateError('Esta función aún no está conectada al servidor.');
    }
  }

  Future<List<StudentNotice>> notifications() async {
    _requireConfigured();
    final owner = _userId;
    final rows = await client
        .from(StudentSchema.notifications)
        .select()
        .eq('user_id', owner)
        .order('created_at', ascending: false);
    return rows
        .where((r) => r['user_id'] == owner)
        .map(StudentNotice.fromJson)
        .toList();
  }

  Future<void> markRead([String? id]) async {
    _requireConfigured();
    final owner = _userId;
    var query = client
        .from(StudentSchema.notifications)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', owner)
        .isFilter('read_at', null);
    if (id != null) query = query.eq('id', id);
    final updated = await query.select('id');
    if (client.auth.currentUser?.id != owner) {
      throw StateError('La cuenta cambió.');
    }
    if (id != null && !updated.any((r) => r['id'].toString() == id)) {
      throw StateError('No se confirmó la lectura. Actualiza los avisos.');
    }
    if (id == null) {
      final unread = await client
          .from(StudentSchema.notifications)
          .select('id')
          .eq('user_id', owner)
          .isFilter('read_at', null)
          .limit(1);
      if (unread.isNotEmpty) {
        throw StateError('Algunos avisos siguen sin leer.');
      }
    }
  }

  Future<List<CourseReview>> reviews(String courseId) async {
    _requireConfigured();
    // Proyección pública: no descarga correos ni datos privados del autor.
    final rows = await client
        .from(StudentSchema.reviews)
        .select('author_name,rating,comment')
        .eq('course_id', courseId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);
    return rows.map(CourseReview.fromJson).toList();
  }

  Future<void> publishReview(
    String courseId,
    int rating,
    String comment,
  ) async {
    _requireConfigured();
    CourseReview.validate(rating, comment);
    final owner = _userId;
    if (!await SupabaseLearningRepository(
      client,
      enabled: learningEnabled,
    ).isEnrolled(courseId)) {
      throw StateError('Necesitas acceso al curso para publicar una reseña.');
    }
    if (client.auth.currentUser?.id != owner) {
      throw StateError('La cuenta cambió.');
    }
    // No permite al cliente eludir moderación cambiando is_visible.
    await client.from(StudentSchema.reviews).insert({
      'course_id': courseId,
      'user_id': owner,
      'rating': rating,
      'comment': comment.trim(),
    });
  }

  Future<List<StudentCertificate>> certificates() async {
    _requireConfigured();
    final owner = _userId;
    final rows = await client
        .from(StudentSchema.certificates)
        .select()
        .eq('user_id', owner)
        .order('issued_at', ascending: false);
    return rows
        .where((r) => r['user_id'] == owner)
        .map(StudentCertificate.fromJson)
        .toList();
  }

  Future<Set<String>> completedLessons(String courseId) async {
    _requireConfigured();
    final rows = await client
        .from(StudentSchema.progress)
        .select('lesson_id')
        .eq('user_id', _userId)
        .eq('course_id', courseId)
        .eq('completed', true);
    return rows.map((r) => r['lesson_id'].toString()).toSet();
  }

  Future<void> completeLesson(String courseId, String lessonId) async {
    _requireConfigured();
    final owner = _userId;
    final learning = SupabaseLearningRepository(
      client,
      enabled: learningEnabled,
    );
    if (!await learning.isEnrolled(courseId)) {
      throw StateError('Necesitas una inscripción activa o completada.');
    }
    final modules = await learning.getModules(courseId);
    if (!modules.expand((m) => m.lessons).any((l) => l.id == lessonId)) {
      throw StateError('La lección no pertenece a este curso.');
    }
    if (client.auth.currentUser?.id != owner) {
      throw StateError('La cuenta cambió.');
    }
    await client.from(StudentSchema.progress).upsert({
      'user_id': owner,
      'course_id': courseId,
      'lesson_id': lessonId,
      'completed': true,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,lesson_id');
  }
}

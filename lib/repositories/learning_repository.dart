import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/learning_schema.dart';
import '../config/supabase_settings.dart';
import '../models/course.dart';

/// Adaptador a la BD. Los nombres se habilitan SOLO tras comprobar el esquema.
/// Todas las operaciones se ejecutan con el JWT del usuario y quedan sujetas a RLS.
class SupabaseLearningRepository {
  const SupabaseLearningRepository(this.client);
  final SupabaseClient client;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Debes iniciar sesión.');
    return id;
  }

  Future<List<CourseModule>> getModules(String courseId) async {
    if (!LearningSchema.enabled) return [];
    final modules = await client.from(LearningSchema.modulesTable)
        .select().eq(LearningSchema.courseFk, courseId);
    final lessons = await client.from(LearningSchema.lessonsTable)
        .select().eq(LearningSchema.courseFk, courseId);
    final rows = List<Map<String, dynamic>>.from(modules);
    final lessonRows = List<Map<String, dynamic>>.from(lessons);
    rows.sort((a, b) => _position(a).compareTo(_position(b)));
    lessonRows.sort((a, b) => _position(a).compareTo(_position(b)));
    return rows.map((row) {
      final id = (row['id'] ?? row['id_modulo']).toString();
      return CourseModule.fromJson(row, lessons: lessonRows
          .where((lesson) => (lesson[LearningSchema.moduleFk] ?? '').toString() == id)
          .map(CourseLesson.fromJson).toList());
    }).toList();
  }

  static int _position(Map<String, dynamic> item) =>
      int.tryParse((item['position'] ?? item['orden'] ?? 0).toString()) ?? 0;

  Future<bool> isEnrolled(String courseId) async {
    if (!LearningSchema.enabled) return false;
    final item = await client.from(LearningSchema.enrollmentsTable)
        .select(LearningSchema.courseFk)
        .eq(LearningSchema.courseFk, courseId)
        .eq(LearningSchema.userFk, _userId)
        .limit(1);
    return item.isNotEmpty;
  }

  /// SOLO cursos gratuitos. No fabricamos una matrícula en cursos de pago.
  Future<void> enrollFree(Course course) async {
    if (!LearningSchema.enabled) {
      throw StateError('No se ha verificado la tabla de inscripciones.');
    }
    if (course.isDemo || course.price != 0) {
      throw StateError('Solo pueden inscribirse cursos reales y gratuitos.');
    }
    if (await isEnrolled(course.id)) return;
    await client.from(LearningSchema.enrollmentsTable).insert({
      LearningSchema.courseFk: course.id,
      LearningSchema.userFk: _userId,
    });
  }

  Future<List<Course>> myCourses() async {
    if (!LearningSchema.enabled) return [];
    final enrollments = await client.from(LearningSchema.enrollmentsTable)
        .select(LearningSchema.courseFk)
        .eq(LearningSchema.userFk, _userId);
    final ids = enrollments.map((e) => e[LearningSchema.courseFk]?.toString())
        .whereType<String>().where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return [];
    final rows = await client.from(SupabaseSettings.coursesTable)
        .select().inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows).map(Course.fromJson).toList();
  }

  /// Tarea escrita asociada a una lección, si existe una tarea en BD.
  Future<List<Map<String, dynamic>>> getTasks(String lessonId) async {
    if (!LearningSchema.enabled || !LearningSchema.submissionsEnabled) return [];
    final rows = await client.from(LearningSchema.tasksTable)
        .select().eq(LearningSchema.lessonFk, lessonId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> submitTask({required String taskId, required String answer}) async {
    if (!LearningSchema.enabled || !LearningSchema.submissionsEnabled) {
      throw StateError('Las entregas reales requieren esquema y RLS confirmados.');
    }
    if (answer.trim().isEmpty) throw StateError('La respuesta no puede estar vacía.');
    await client.from(LearningSchema.submissionsTable).insert({
      LearningSchema.taskFk: taskId,
      LearningSchema.userFk: _userId,
      LearningSchema.submissionAnswer: answer.trim(),
    });
  }
}

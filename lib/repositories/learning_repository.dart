import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/learning_schema.dart';
import '../config/supabase_settings.dart';
import '../config/student_schema.dart';
import '../models/course.dart';

/// Adaptador a la BD. Los nombres se habilitan SOLO tras comprobar el esquema.
/// Todas las operaciones se ejecutan con el JWT del usuario y quedan sujetas a RLS.
class SupabaseLearningRepository {
  const SupabaseLearningRepository(
    this.client, {
    this.enabled = LearningSchema.enabled,
  });
  final SupabaseClient client;
  final bool enabled;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Debes iniciar sesión.');
    return id;
  }

  Future<List<CourseModule>> getModules(String courseId) async {
    if (!enabled) return [];
    final modules = await client
        .from(LearningSchema.modulesTable)
        .select()
        .eq(LearningSchema.courseFk, courseId);
    final lessons = await client
        .from(LearningSchema.lessonsTable)
        .select()
        .eq(LearningSchema.courseFk, courseId);
    final rows = List<Map<String, dynamic>>.from(modules);
    final lessonRows = List<Map<String, dynamic>>.from(lessons);
    rows.sort((a, b) => _position(a).compareTo(_position(b)));
    lessonRows.sort((a, b) => _position(a).compareTo(_position(b)));
    return rows.map((row) {
      final id = (row['id'] ?? row['id_modulo']).toString();
      return CourseModule.fromJson(
        row,
        lessons:
            lessonRows
                .where(
                  (lesson) =>
                      (lesson[LearningSchema.moduleFk] ?? '').toString() == id,
                )
                .map(CourseLesson.fromJson)
                .toList(),
      );
    }).toList();
  }

  static int _position(Map<String, dynamic> item) =>
      int.tryParse((item['position'] ?? item['orden'] ?? 0).toString()) ?? 0;

  Future<bool> isEnrolled(String courseId) async {
    if (!enabled) return false;
    final item = await client
        .from(LearningSchema.enrollmentsTable)
        .select(LearningSchema.courseFk)
        .eq(LearningSchema.courseFk, courseId)
        .eq(LearningSchema.userFk, _userId)
        .inFilter(LearningSchema.enrollmentStatusColumn, [
          LearningSchema.activeStatus,
          LearningSchema.completedStatus,
        ])
        .limit(1);
    return item.isNotEmpty;
  }

  /// SOLO cursos gratuitos. No fabricamos una matrícula en cursos de pago.
  Future<void> enrollFree(Course course) async {
    if (!enabled) {
      throw StateError('No se ha verificado la tabla de inscripciones.');
    }
    if (course.isDemo || course.price != 0) {
      throw StateError('Solo pueden inscribirse cursos reales y gratuitos.');
    }
    final owner = _userId;
    if (await isEnrolled(course.id)) return;
    if (client.auth.currentUser?.id != owner) {
      throw StateError('La cuenta cambió.');
    }
    try {
      await client.from(LearningSchema.enrollmentsTable).insert({
        LearningSchema.courseFk: course.id,
        LearningSchema.userFk: owner,
        LearningSchema.enrollmentStatusColumn: LearningSchema.activeStatus,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505' || !await isEnrolled(course.id)) rethrow;
    }
  }

  Future<void> enrollIncluded(Course course) async {
    final owner = _userId;
    if (!enabled ||
        course.isDemo ||
        course.organizationId.isEmpty ||
        StudentSchema.includedEnrollmentRpc.isEmpty) {
      throw StateError(
        'La inscripción institucional todavía no está disponible.',
      );
    }
    // El servidor comprueba membresía activa, organización y beneficio.
    await client.rpc(
      StudentSchema.includedEnrollmentRpc,
      params: {'p_course_id': course.id},
    );
    if (client.auth.currentUser?.id != owner || !await isEnrolled(course.id)) {
      throw StateError('No se confirmó el acceso institucional.');
    }
  }

  Future<List<Course>> myCourses() async =>
      (await myCourseRecords()).map((record) => record.course).toList();

  Future<List<EnrolledCourse>> myCourseRecords() async {
    if (!enabled) return [];
    final enrollments = await client
        .from(LearningSchema.enrollmentsTable)
        .select(
          '${LearningSchema.courseFk},${LearningSchema.enrollmentStatusColumn}',
        )
        .eq(LearningSchema.userFk, _userId)
        .inFilter(LearningSchema.enrollmentStatusColumn, [
          LearningSchema.activeStatus,
          LearningSchema.completedStatus,
        ]);
    // No incluir matrículas pendientes, canceladas o reembolsadas.
    final ids =
        enrollments
            .map((e) => e[LearningSchema.courseFk]?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
    if (ids.isEmpty) return [];
    final rows = await client
        .from(SupabaseSettings.coursesTable)
        .select()
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows).map((row) {
      final course = Course.fromJson(row);
      final completed = enrollments.any(
        (e) =>
            e[LearningSchema.courseFk].toString() == course.id &&
            e[LearningSchema.enrollmentStatusColumn] ==
                LearningSchema.completedStatus,
      );
      return EnrolledCourse(course, completed);
    }).toList();
  }

  /// Tarea escrita asociada a una lección, si existe una tarea en BD.
  Future<List<Map<String, dynamic>>> getTasks(String lessonId) async {
    if (!enabled || !LearningSchema.submissionsEnabled) {
      return [];
    }
    final rows = await client
        .from(LearningSchema.tasksTable)
        .select()
        .eq(LearningSchema.lessonFk, lessonId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> submitTask({
    required String taskId,
    required String answer,
  }) async {
    if (!enabled || !LearningSchema.submissionsEnabled) {
      throw StateError(
        'Las entregas reales requieren esquema y RLS confirmados.',
      );
    }
    if (answer.trim().isEmpty) {
      throw StateError('La respuesta no puede estar vacía.');
    }
    await client.from(LearningSchema.submissionsTable).insert({
      LearningSchema.taskFk: taskId,
      LearningSchema.userFk: _userId,
      LearningSchema.submissionAnswer: answer.trim(),
    });
  }
}

class EnrolledCourse {
  const EnrolledCourse(this.course, this.completed);
  final Course course;
  final bool completed;
}

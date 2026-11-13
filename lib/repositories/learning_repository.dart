import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../services/academix_api.dart';

class LearningRepository {
  LearningRepository(SupabaseClient client, {AcademixApi? api})
    : api = api ?? AcademixApi(client);
  final AcademixApi api;
  Future<LearningCourse> learning(String courseId) async =>
      LearningCourse.fromJson(
        Map<String, dynamic>.from(
          await api.get(
                '/users/me/courses/${Uri.encodeComponent(courseId)}/learning',
              )
              as Map,
        ),
      );
  Future<bool> isEnrolled(String courseId) async {
    final ids = await api.get(
      '/users/me/course-ownership',
      query: {'courseIds': courseId},
    );
    return ids is List && ids.contains(courseId);
  }

  Future<EnrolledCourse?> enrollment(String courseId) async {
    final result = await api.page(
      '/users/me/courses',
      query: {'page': '1', 'limit': '1', 'courseIds': courseId},
    );
    return result.items.isEmpty
        ? null
        : EnrolledCourse.fromJson(result.items.single);
  }

  /// El servidor comparte las reglas de gratuidad y membresía con la web.
  Future<EnrolledCourse> enroll(Course course) async => EnrolledCourse.fromJson(
    Map<String, dynamic>.from(
      await api.post('/courses/${Uri.encodeComponent(course.id)}/enrollments')
          as Map,
    ),
  );
  Future<ApiPage> myCoursesPage({
    int page = 1,
    int limit = 10,
    String? status,
  }) => api.page(
    '/users/me/courses',
    query: {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
    },
  );
  Future<Map<String, dynamic>> summary() async => Map<String, dynamic>.from(
    await api.get('/users/me/learning-summary') as Map,
  );
  Future<void> setProgress(String lessonId, bool completed) async {
    await api.patch('/lessons/${Uri.encodeComponent(lessonId)}/progress', {
      'completed': completed,
    });
  }
}

class EnrolledCourse {
  const EnrolledCourse(
    this.course,
    this.completed, {
    this.percentage = 0,
    this.completedLessons = 0,
    this.totalLessons = 0,
    this.accessActive = true,
  });
  final Course course;
  final bool completed;
  final num percentage;
  final int completedLessons;
  final int totalLessons;
  final bool accessActive;
  factory EnrolledCourse.fromJson(Map<String, dynamic> row) => EnrolledCourse(
    Course.fromJson(Map<String, dynamic>.from(row['course'] as Map)),
    row['status'] == 'completed',
    percentage: row['progressPercentage'] as num? ?? 0,
    completedLessons: (row['completedLessons'] as num?)?.toInt() ?? 0,
    totalLessons: (row['totalLessons'] as num?)?.toInt() ?? 0,
    accessActive: row['accessActive'] != false,
  );
}

class LearningCourse {
  const LearningCourse({
    required this.id,
    required this.title,
    required this.instructor,
    required this.modules,
    required this.percentage,
  });
  final String id;
  final String title;
  final String instructor;
  final List<CourseModule> modules;
  final num percentage;
  List<CourseLesson> get lessons => modules.expand((m) => m.lessons).toList();
  factory LearningCourse.fromJson(Map<String, dynamic> row) => LearningCourse(
    id: '${row['id']}',
    title: '${row['title']}',
    instructor: '${row['instructorName'] ?? ''}',
    modules: jsonRows(row['modules']).map(CourseModule.fromJson).toList(),
    percentage: row['progressPercentage'] as num? ?? 0,
  );
}

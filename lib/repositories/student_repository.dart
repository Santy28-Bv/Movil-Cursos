import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_data.dart';
import '../services/academix_api.dart';

class StudentRepository {
  StudentRepository(SupabaseClient client, {AcademixApi? api})
    : api = api ?? AcademixApi(client);
  final AcademixApi api;
  Future<List<StudentNotice>> notifications() async =>
      jsonRows(
        await api.get('/notifications', query: {'limit': '30'}),
      ).map(StudentNotice.fromJson).toList();
  Future<int> unreadNoticeCount() async {
    final result = await api.get('/notifications/unread-count');
    if (result is Map && result['count'] is int && result['count'] >= 0) {
      return result['count'] as int;
    }
    throw const ApiException('No pudimos consultar el total de avisos.');
  }

  Future<void> markRead([String? id]) async {
    await api.patch(
      id == null
          ? '/notifications/read-all'
          : '/notifications/${Uri.encodeComponent(id)}/read',
    );
  }

  Future<ApiPage> reviewsPage(String courseId, {int page = 1}) => api.page(
    '/courses/${Uri.encodeComponent(courseId)}/reviews',
    authenticated: false,
    query: {'page': '$page', 'limit': '10'},
  );
  Future<List<CourseReview>> reviews(String courseId) async =>
      (await reviewsPage(courseId)).items.map(CourseReview.fromJson).toList();
  Future<void> publishReview(
    String courseId,
    int rating,
    String comment,
  ) async {
    CourseReview.validate(rating, comment);
    await api.post('/courses/${Uri.encodeComponent(courseId)}/reviews', {
      'rating': rating,
      'comment': comment.trim(),
    });
  }

  Future<ApiPage> certificatesPage({int page = 1}) => api.page(
    '/users/me/certificates',
    query: {'page': '$page', 'limit': '10'},
  );
  Future<StudentCertificate> certificate(String id) async =>
      StudentCertificate.fromJson(
        Map<String, dynamic>.from(
          await api.get('/users/me/certificates/${Uri.encodeComponent(id)}')
              as Map,
        ),
      );
  Future<StudentCertificate> verify(String code) async {
    final row = Map<String, dynamic>.from(
      await api.get(
            '/certificates/verify/${Uri.encodeComponent(code)}',
            authenticated: false,
          )
          as Map,
    );
    if (row['valid'] != true) {
      throw const ApiException('El certificado no es válido.');
    }
    return StudentCertificate.fromJson(row);
  }

  Future<List<Map<String, dynamic>>> organizations() async =>
      jsonRows(await api.get('/organizations'));
  Future<void> joinOrganization(String code, String studentNumber) async {
    await api.post('/organizations/join', {
      'joinCode': code.trim().toUpperCase(),
      'studentNumber': studentNumber.trim(),
    });
  }

  Future<ApiPage> organizationCourses(String id, {int page = 1}) => api.page(
    '/organizations/${Uri.encodeComponent(id)}/courses',
    query: {'page': '$page', 'limit': '10', 'status': 'published'},
  );
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../services/academix_api.dart';

class CoursePage {
  const CoursePage({required this.items, required this.hasMore});
  final List<Course> items;
  final bool hasMore;
}

abstract class CourseRepository {
  Future<CoursePage> fetchPublished({
    required int offset,
    required int limit,
    String search = '',
  });
}

class ApiCourseRepository implements CourseRepository {
  ApiCourseRepository(SupabaseClient client, {AcademixApi? api})
    : api = api ?? AcademixApi(client);
  final AcademixApi api;
  String? category;
  String? level;
  @override
  Future<CoursePage> fetchPublished({
    required int offset,
    required int limit,
    String search = '',
  }) async {
    final page = await api.page(
      '/courses',
      authenticated: false,
      query: {
        'page': '${offset ~/ limit + 1}',
        'limit': '$limit',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null) 'category': category!,
        if (level != null) 'level': level!,
      },
    );
    return CoursePage(
      items: page.items.map(Course.fromJson).toList(),
      hasMore: page.hasMore,
    );
  }

  Future<List<Course>> featured() async =>
      jsonRows(
        await api.get('/courses/featured', authenticated: false),
      ).map(Course.fromJson).toList();
  Future<Course> detail(String id) async => Course.fromJson(
    Map<String, dynamic>.from(
      await api.get('/courses/${Uri.encodeComponent(id)}', authenticated: false)
          as Map,
    ),
  );
  Future<List<Map<String, dynamic>>> categories() async =>
      jsonRows(await api.get('/categories', authenticated: false));
  Future<List<Course>> related(String id) async =>
      jsonRows(
        await api.get(
          '/courses/${Uri.encodeComponent(id)}/related',
          authenticated: false,
        ),
      ).map(Course.fromJson).toList();
  Future<Map<String, dynamic>> instructor(String id) async =>
      Map<String, dynamic>.from(
        await api.get(
              '/instructors/${Uri.encodeComponent(id)}',
              authenticated: false,
            )
            as Map,
      );
  Future<ApiPage> instructorCourses(String id, {int page = 1}) => api.page(
    '/instructors/${Uri.encodeComponent(id)}/courses',
    authenticated: false,
    query: {'page': '$page', 'limit': '10'},
  );
}

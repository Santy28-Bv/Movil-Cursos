import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../repositories/learning_repository.dart';

class LessonResourceService {
  const LessonResourceService(this.client);
  final SupabaseClient client;
  Future<Uri?> resolve(String courseId, CourseLesson lesson) async {
    final owner = client.auth.currentUser?.id;
    if (owner == null ||
        !await SupabaseLearningRepository(client).isEnrolled(courseId)) {
      throw StateError('No tienes acceso a este recurso.');
    }
    if (client.auth.currentUser?.id != owner) {
      throw StateError('La cuenta cambió.');
    }
    if (lesson.resourceBucket.isNotEmpty && lesson.resourcePath.isNotEmpty) {
      return validatedExternal(
        await client.storage
            .from(lesson.resourceBucket)
            .createSignedUrl(lesson.resourcePath, 300),
      );
    }
    return validatedExternal(lesson.resourceUrl);
  }

  static Uri? validatedExternal(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    if (uri.path.contains('/storage/v1/object/public/')) return null;
    return uri;
  }
}

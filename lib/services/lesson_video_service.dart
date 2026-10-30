import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';

/// Devuelve el video sin inventar URLs ni buckets.
/// Las rutas privadas se convierten en enlaces de expiración corta con el
/// JWT del usuario; la política SELECT de Storage decide si está autorizado.
class LessonVideoService {
  const LessonVideoService(this.client);
  final SupabaseClient client;

  Future<Uri?> resolve(CourseLesson lesson) async {
    if (client.auth.currentUser == null) {
      throw StateError('Inicia sesión para reproducir esta lección.');
    }
    if (lesson.videoBucket.isNotEmpty && lesson.videoPath.isNotEmpty) {
      final signed = await client.storage.from(lesson.videoBucket)
          .createSignedUrl(lesson.videoPath, 900);
      return _validatedHttps(signed);
    }
    return _validatedHttps(lesson.videoUrl);
  }

  static Uri? _validatedHttps(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) return null;
    return uri;
  }
}

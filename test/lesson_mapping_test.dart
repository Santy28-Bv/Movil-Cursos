import 'package:flutter_test/flutter_test.dart';
import 'package:academix/config/learning_schema.dart';
import 'package:academix/models/course.dart';

void main() {
  test('La lección interpreta los campos de video y recursos de Supabase', () {
    final lesson = CourseLesson.fromJson({
      'id': 'leccion-123',
      'titulo': 'Introducción',
      'duracion_minutos': 20,
      'bucket_video': 'videos-privados',
      'ruta_video': 'cursos/123/intro.mp4',
      'descripcion': 'Aprender conceptos básicos',
      'vista_previa': false,
    });
    expect(lesson.id, 'leccion-123');
    expect(lesson.title, 'Introducción');
    expect(lesson.videoBucket, 'videos-privados');
    expect(lesson.videoPath, 'cursos/123/intro.mp4');
    expect(lesson.durationMinutes, 20);
    expect(lesson.isPreview, false);
  });

  test('Los repositorios de escritura real permanecen apagados por defecto', () {
    expect(LearningSchema.enabled, false);
    expect(LearningSchema.submissionsEnabled, false);
  });
}

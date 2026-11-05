import 'package:academix/models/course.dart';
import 'package:academix/models/course_progress.dart';
import 'package:academix/services/lesson_resource_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('métricas solo cuentan lecciones pertenecientes al curso', () {
    final progress = CourseProgress.fromModules(
      const [
        CourseModule(
          id: 'm',
          title: '',
          lessons: [
            CourseLesson(id: '1', title: '', durationMinutes: 30),
            CourseLesson(id: '2', title: '', durationMinutes: 60),
          ],
        ),
      ],
      {'1', 'de-otro-curso'},
    );
    expect(progress.done, 1);
    expect(progress.total, 2);
    expect(progress.fraction, .5);
    expect(progress.learnedMinutes, 30);
    expect(progress.isCompleted, isFalse);
  });
  test('sin lecciones no se considera curso completado', () {
    expect(CourseProgress.fromModules([], {}).isCompleted, isFalse);
    expect(CourseProgress.fromModules([], {}).fraction, 0);
  });
  test(
    'recurso rechaza esquemas inseguros, credenciales y storage público',
    () {
      for (final url in [
        'javascript:alert(1)',
        'http://example.com/a',
        'https://user:pass@example.com/a',
        'https://x.supabase.co/storage/v1/object/public/docs/a.pdf',
      ]) {
        expect(LessonResourceService.validatedExternal(url), isNull);
      }
      expect(
        LessonResourceService.validatedExternal(
          'https://example.com/recurso.pdf',
        )?.host,
        'example.com',
      );
    },
  );
}

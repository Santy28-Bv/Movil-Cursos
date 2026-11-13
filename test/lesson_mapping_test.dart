import 'package:flutter_test/flutter_test.dart';
import 'package:academix/models/course.dart';
import 'package:academix/repositories/learning_repository.dart';

void main() {
  test('aula conserva contenido, avance y ruta protegida del backend web', () {
    final course = LearningCourse.fromJson({
      'id': 'c1',
      'title': 'Dart',
      'instructorName': 'Ana',
      'progressPercentage': 50,
      'modules': [
        {
          'id': 'm1',
          'title': 'Inicio',
          'lessons': [
            {
              'id': 'l1',
              'title': 'Video',
              'durationMinutes': 20,
              'content': 'Contenido real',
              'isCompleted': true,
              'resources': [
                {
                  'id': 'r1',
                  'title': 'Introducción',
                  'type': 'Video',
                  'url': null,
                  'contentPath': '/api/v1/lessons/l1/resources/r1/content',
                  'required': true,
                },
              ],
            },
          ],
        },
      ],
    });
    final lesson = course.lessons.single;
    expect(course.percentage, 50);
    expect(lesson.content, 'Contenido real');
    expect(lesson.isCompleted, isTrue);
    expect(lesson.resources.single.isVideo, isTrue);
    expect(lesson.resources.single.url, isEmpty);
    expect(
      lesson.resources.single.contentPath,
      '/api/v1/lessons/l1/resources/r1/content',
    );
  });
  test('temario público no fabrica contenido ni recursos privados', () {
    final lesson = CourseLesson.fromJson({
      'id': 'l1',
      'title': 'Introducción',
      'durationMinutes': 12,
    });
    expect(lesson.resources, isEmpty);
    expect(lesson.content, isEmpty);
    expect(lesson.durationMinutes, 12);
  });
}

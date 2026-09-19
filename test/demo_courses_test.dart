import 'package:flutter_test/flutter_test.dart';
import 'package:academix/data/cursos_web_demo.dart';
import 'package:academix/services/demo_learning_store.dart';

void main() {
  test('los seis cursos de CursosWeb están marcados como demo', () {
    expect(cursosWebDemo, hasLength(6));
    expect(cursosWebDemo.every((c) => c.isDemo), isTrue);
    expect(cursosWebDemo.first.modules, isNotEmpty);
  });

  test('inscripción y tarea demo se guardan solo en memoria', () {
    final store = DemoLearningStore.instance;
    store.clear();
    final course = cursosWebDemo.first;
    store.enroll(course);
    expect(store.isEnrolled(course.id), isTrue);
    store.submitDemoTask(course.id, 'web-lesson-1', 'Prueba');
    expect(store.responseFor('${course.id}/web-lesson-1'), 'Prueba');
    store.complete(course.id, 'web-lesson-1');
    expect(store.completedCount(course), 1);
    store.clear();
    expect(store.isEnrolled(course.id), isFalse);
  });
}

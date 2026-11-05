import 'package:academix/models/student_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adapter interpreta campos de avisos web y lectura', () {
    final notice = StudentNotice.fromJson({
      'id': '7',
      'asunto': 'Curso',
      'contenido': 'Ya disponible',
      'read_at': '2026-11-03T12:00:00Z',
    });
    expect(notice.title, 'Curso');
    expect(notice.message, 'Ya disponible');
    expect(notice.isRead, isTrue);
  });
  test('rechaza reseña vacía, estrellas fuera de rango y comentario largo', () {
    expect(() => CourseReview.validate(0, 'Bien'), throwsArgumentError);
    expect(() => CourseReview.validate(6, 'Bien'), throwsArgumentError);
    expect(() => CourseReview.validate(5, '  '), throwsArgumentError);
    expect(() => CourseReview.validate(5, 'x' * 1001), throwsArgumentError);
    expect(() => CourseReview.validate(5, 'x' * 1000), returnsNormally);
  });
}

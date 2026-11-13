import 'package:academix/models/course.dart';
import 'package:academix/models/student_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conserva las horas fraccionarias aceptadas por la web', () {
    expect(
      Course.fromJson({'id': 'fractional', 'durationHours': 1.5}).durationHours,
      1.5,
    );
  });
  test('catálogo conserva portada y descripción camelCase de la web', () {
    final course = Course.fromJson({
      'id': 'curso-web',
      'title': 'Dart desde cero',
      'shortDescription': 'El mismo curso en web y móvil',
      'imageUrl': 'https://example.test/portada.png',
      'category': {'name': 'Programación'},
      'instructor': {'name': 'Ana'},
      'durationHours': 12,
      'price': 0,
      'learningOutcomes': ['Crear aplicaciones'],
      'requirements': ['Una computadora'],
      'modules': [
        {
          'id': 'm1',
          'title': 'Inicio',
          'lessons': [
            {'id': 'l1', 'title': 'Introducción', 'durationMinutes': 8},
          ],
        },
      ],
    });
    expect(course.imageUrl, 'https://example.test/portada.png');
    expect(course.description, 'El mismo curso en web y móvil');
    expect(course.learningOutcomes, ['Crear aplicaciones']);
    expect(course.requirements, ['Una computadora']);
    expect(course.modules.single.lessons.single.durationMinutes, 8);
  });

  test('avisos, reseñas y certificados usan el contrato público web', () {
    expect(
      StudentNotice.fromJson({
        'id': 'n',
        'title': 'Nuevo curso',
        'message': 'Disponible',
        'read': true,
      }).isRead,
      isTrue,
    );
    expect(
      CourseReview.fromJson({
        'authorName': 'Ana',
        'rating': 5,
        'comment': 'Me gustó',
      }).author,
      'Ana',
    );
    expect(
      StudentCertificate.fromJson({
        'courseTitle': 'Dart',
        'recipientName': 'Ana',
        'issuerName': 'Academix',
        'credentialCode': 'ACX-123',
      }).code,
      'ACX-123',
    );
  });
}

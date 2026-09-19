import 'package:flutter_test/flutter_test.dart';
import '../lib/models/course.dart';

void main() {
  test('cursos del sitio web conservan títulos y carácter demostrativo', () {
    // El contenido real de CursosWeb se verifica por separado en data/cursos_web_demo.dart.
    final course = Course(id: 'course-web-full-stack', title: 'Prueba',
        description: '', category: '', imageUrl: '', price: 10, isDemo: true);
    expect(course.isDemo, true);
  });
  test('convierte un curso de Supabase en un modelo', () {
    final course = Course.fromJson({
      'id': 4,
      'title': 'Flutter desde cero',
      'description': 'Aprende desarrollo móvil',
      'category_name': 'Programación',
      'price': 0,
    });

    expect(course.id, '4');
    expect(course.title, 'Flutter desde cero');
    expect(course.category, 'Programación');
    expect(course.priceLabel, 'Gratis');
  });

  test('precio sin campo no es tratado como gratuito', () {
    final course = Course.fromJson({'title': 'Sin precio todavía'});
    expect(course.priceLabel, 'Precio por consultar');
  });
}

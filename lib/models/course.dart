/// Datos públicos de un curso. Los campos adicionales son opcionales para
/// mantener compatibilidad con tablas de Supabase que aún no hemos confirmado.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.price,
    this.instructor = '',
    this.level = '',
    this.durationHours = 0,
    this.rating = 0,
    this.learningOutcomes = const [],
    this.requirements = const [],
    this.modules = const [],
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final num? price;
  final String instructor;
  final String level;
  final int durationHours;
  final double rating;
  final List<String> learningOutcomes;
  final List<String> requirements;
  final List<CourseModule> modules;
  final bool isDemo;

  String get priceLabel {
    if (price == null) return 'Precio por consultar';
    if (price == 0) return 'Gratis';
    return '\$${price!.toStringAsFixed(2)}';
  }

  factory Course.fromJson(Map<String, dynamic> data) {
    String read(List<String> names, {String fallback = ''}) {
      for (final name in names) {
        final value = data[name];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    final categoryValue = data['category'];
    final categoryName = categoryValue is Map
        ? (categoryValue['name']?.toString() ?? 'CURSO ACADEMIX')
        : read(['category_name', 'category', 'category_id'],
            fallback: 'CURSO ACADEMIX');
    final rawPrice = data['price'];
    final instructorValue = data['instructor'];
    final instructorName = instructorValue is Map
        ? (instructorValue['name']?.toString() ?? '')
        : read(['instructor_name', 'instructor']);

    return Course(
      id: read(['id', 'slug']),
      title: read(['title', 'name'], fallback: 'Curso sin título'),
      description: read(['short_description', 'description'],
          fallback: 'Descubre este curso en Academix.'),
      category: categoryName,
      imageUrl: read(['image_url', 'thumbnail_url']),
      price: rawPrice is num
          ? rawPrice
          : num.tryParse(rawPrice?.toString() ?? ''),
      instructor: instructorName,
      level: read(['level', 'nivel']),
      durationHours: int.tryParse(
              read(['duration_hours', 'durationHours'], fallback: '0')) ??
          0,
      rating: double.tryParse(read(['rating'], fallback: '0')) ?? 0,
    );
  }
}

class CourseModule {
  const CourseModule({required this.id, required this.title,
    this.lessons = const []});
  final String id;
  final String title;
  final List<CourseLesson> lessons;
}

class CourseLesson {
  const CourseLesson({required this.id, required this.title,
    this.durationMinutes = 0, this.task = ''});
  final String id;
  final String title;
  final int durationMinutes;
  /// Ejercicio didáctico solo para demostración, no una tarea del servidor.
  final String task;
}

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
    this.videoUrl = '',
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
  /// URL pública de presentación del curso (no da acceso a clases privadas).
  final String videoUrl;

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
      videoUrl: read(['preview_video_url', 'video_url', 'url_video']),
    );
  }
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    this.lessons = const [],
  });
  final String id;
  final String title;
  final List<CourseLesson> lessons;

  factory CourseModule.fromJson(Map<String, dynamic> row,
      {List<CourseLesson> lessons = const []}) => CourseModule(
    id: (row['id'] ?? row['id_modulo'] ?? '').toString(),
    title: (row['title'] ?? row['titulo'] ?? row['nombre'] ?? 'Módulo').toString(),
    lessons: lessons,
  );
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    this.durationMinutes = 0,
    this.task = '',
    this.description = '',
    this.videoUrl = '',
    this.videoBucket = '',
    this.videoPath = '',
    this.resourceUrl = '',
    this.isPreview = false,
  });

  final String id;
  final String title;
  final int durationMinutes;
  /// En DEMO es ejercicio local; en cursos reales solo procede de la BD.
  final String task;
  final String description;
  /// URL HTTPS de video entregada por el backend/BD.
  final String videoUrl;
  /// Alternativa protegida: bucket privado + ruta en Storage.
  final String videoBucket;
  final String videoPath;
  final String resourceUrl;
  final bool isPreview;

  factory CourseLesson.fromJson(Map<String, dynamic> row) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = row[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }
    return CourseLesson(
      id: read(['id', 'id_leccion']),
      title: read(['title', 'titulo', 'nombre']),
      durationMinutes: int.tryParse(read(['duration_minutes', 'duracion_minutos'])) ?? 0,
      task: read(['task_prompt', 'actividad', 'tarea']),
      description: read(['description', 'descripcion', 'contenido']),
      videoUrl: read(['video_url', 'url_video', 'videoUrl']),
      videoBucket: read(['video_bucket', 'bucket_video']),
      videoPath: read(['video_path', 'ruta_video']),
      resourceUrl: read(['resource_url', 'url_recurso']),
      isPreview: row['is_preview'] == true || row['vista_previa'] == true,
    );
  }
}

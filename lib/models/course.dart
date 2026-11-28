/// Contrato público de Academix Web (/api/v1/courses).
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
    this.videoUrl = '',
    this.organizationId = '',
    this.shortDescription = '',
    this.certificateEnabled = false,
    this.reviewCount = 0,
    this.instructorId = '',
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final num? price;
  final String instructor;
  final String level;
  final num durationHours;
  final double rating;
  final List<String> learningOutcomes;
  final List<String> requirements;
  final List<CourseModule> modules;

  /// URL pública de presentación del curso (no da acceso a clases privadas).
  final String videoUrl;
  final String organizationId;
  final String shortDescription;
  final bool certificateEnabled;
  final int reviewCount;
  final String instructorId;
  String get levelLabel =>
      const {
        'beginner': 'Principiante',
        'intermediate': 'Intermedio',
        'advanced': 'Avanzado',
      }[level] ??
      level;

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
    final categoryName =
        categoryValue is Map
            ? (categoryValue['name']?.toString() ?? 'CURSO ACADEMIX')
            : read([
              'category_name',
              'category',
              'category_id',
            ], fallback: 'CURSO ACADEMIX');
    final rawPrice = data['price'];
    final instructorValue = data['instructor'];
    final instructorName =
        instructorValue is Map
            ? (instructorValue['name']?.toString() ?? '')
            : read(['instructor_name', 'instructor']);

    return Course(
      id: read(['id', 'slug']),
      title: read(['title', 'name'], fallback: 'Curso sin título'),
      description: read([
        'description',
        'shortDescription',
        'short_description',
      ], fallback: 'Descubre este curso en Academix.'),
      category: categoryName,
      imageUrl: read(['imageUrl', 'image_url', 'thumbnail_url']),
      price:
          rawPrice is num ? rawPrice : num.tryParse(rawPrice?.toString() ?? ''),
      instructor: instructorName,
      instructorId:
          instructorValue is Map ? '${instructorValue['id'] ?? ''}' : '',
      level: read(['level', 'nivel']),
      durationHours:
          num.tryParse(
            read(['duration_hours', 'durationHours'], fallback: '0'),
          ) ??
          0,
      rating: double.tryParse(read(['rating'], fallback: '0')) ?? 0,
      videoUrl: read([
        'introVideoUrl',
        'preview_video_url',
        'video_url',
        'url_video',
      ]),
      organizationId: read(['organization_id']),
      shortDescription: read([
        'shortDescription',
        'short_description',
        'description',
      ]),
      certificateEnabled: data['certificateEnabled'] == true,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      learningOutcomes:
          (data['learningOutcomes'] as List? ?? []).map((v) => '$v').toList(),
      requirements:
          (data['requirements'] as List? ?? []).map((v) => '$v').toList(),
      modules:
          (data['modules'] as List? ?? [])
              .map(
                (v) =>
                    CourseModule.fromJson(Map<String, dynamic>.from(v as Map)),
              )
              .toList(),
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

  factory CourseModule.fromJson(
    Map<String, dynamic> row, {
    List<CourseLesson>? lessons,
  }) => CourseModule(
    id: (row['id'] ?? row['id_modulo'] ?? '').toString(),
    title:
        (row['title'] ?? row['titulo'] ?? row['nombre'] ?? 'Módulo').toString(),
    lessons:
        lessons ??
        (row['lessons'] as List? ?? [])
            .map(
              (v) => CourseLesson.fromJson(Map<String, dynamic>.from(v as Map)),
            )
            .toList(),
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
    this.resourceBucket = '',
    this.resourcePath = '',
    this.isPreview = false,
    this.content = '',
    this.isCompleted = false,
    this.resources = const [],
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
  final String resourceBucket;
  final String resourcePath;
  final bool isPreview;
  final String content;
  final bool isCompleted;
  final List<LearningResource> resources;

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
      durationMinutes:
          int.tryParse(
            read(['durationMinutes', 'duration_minutes', 'duracion_minutos']),
          ) ??
          0,
      task: read(['task_prompt', 'actividad', 'tarea']),
      description: read(['description', 'descripcion', 'contenido']),
      videoUrl: read(['video_url', 'url_video', 'videoUrl']),
      videoBucket: read(['video_bucket', 'bucket_video']),
      videoPath: read(['video_path', 'ruta_video']),
      resourceUrl: read(['resource_url', 'url_recurso']),
      resourceBucket: read(['resource_bucket', 'bucket_recurso']),
      resourcePath: read(['resource_path', 'ruta_recurso']),
      isPreview:
          row['isPreview'] == true ||
          row['is_preview'] == true ||
          row['vista_previa'] == true,
      content: read(['content']),
      isCompleted: row['isCompleted'] == true,
      resources:
          (row['resources'] as List? ?? [])
              .map(
                (r) => LearningResource.fromJson(
                  Map<String, dynamic>.from(r as Map),
                ),
              )
              .toList(),
    );
  }
}

class LearningResource {
  const LearningResource({
    required this.id,
    required this.title,
    required this.type,
    this.description = '',
    this.url = '',
    this.contentPath = '',
    this.required = false,
  });
  final String id;
  final String title;
  final String type;
  final String description;
  final String url;
  final String contentPath;
  final bool required;
  bool get isVideo => type.toLowerCase().contains('video');
  factory LearningResource.fromJson(Map<String, dynamic> row) =>
      LearningResource(
        id: '${row['id'] ?? ''}',
        title: '${row['title'] ?? ''}',
        type: '${row['type'] ?? ''}',
        description: '${row['description'] ?? ''}',
        url: '${row['url'] ?? ''}',
        contentPath: '${row['contentPath'] ?? ''}',
        required: row['required'] == true,
      );
}

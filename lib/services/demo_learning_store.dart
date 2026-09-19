import 'package:flutter/foundation.dart';
import '../models/course.dart';

/// Progreso SOLO en memoria para probar la interfaz; no escribe en Supabase.
/// Las inscripciones reales y las entregas se conectarán al conocer el esquema.
class DemoLearningStore extends ChangeNotifier {
  DemoLearningStore._();
  static final DemoLearningStore instance = DemoLearningStore._();

  final Map<String, Course> _enrolled = {};
  final Set<String> _completed = {};
  final Map<String, String> _responses = {};

  List<Course> get myCourses => List.unmodifiable(_enrolled.values);
  bool isEnrolled(String id) => _enrolled.containsKey(id);
  bool isCompleted(String id) => _completed.contains(id);
  String? responseFor(String id) => _responses[id];

  void enroll(Course course) {
    if (!course.isDemo) {
      throw StateError('Las inscripciones reales necesitan las tablas de Supabase.');
    }
    _enrolled[course.id] = course;
    notifyListeners();
  }

  void complete(String courseId, String lessonId) {
    if (!_enrolled.containsKey(courseId)) return;
    _completed.add('$courseId/$lessonId');
    notifyListeners();
  }

  void submitDemoTask(String courseId, String lessonId, String answer) {
    if (!_enrolled.containsKey(courseId) || answer.trim().isEmpty) return;
    _responses['$courseId/$lessonId'] = answer.trim();
    notifyListeners();
  }

  int completedCount(Course course) => course.modules.expand((m) => m.lessons)
      .where((l) => isCompleted('${course.id}/${l.id}')).length;

  void clear() {
    _enrolled.clear();
    _completed.clear();
    _responses.clear();
    notifyListeners();
  }
}

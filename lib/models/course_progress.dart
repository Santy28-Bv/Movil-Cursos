import 'course.dart';

class CourseProgress {
  const CourseProgress(this.done, this.total, this.learnedMinutes);
  final int done;
  final int total;
  final int learnedMinutes;
  double get fraction => total == 0 ? 0 : done / total;
  bool get isCompleted => total > 0 && done == total;
  factory CourseProgress.fromModules(
    List<CourseModule> modules,
    Set<String> completed,
  ) {
    final lessons = {
      for (final m in modules)
        for (final l in m.lessons) l.id: l,
    };
    final done = lessons.values.where((l) => completed.contains(l.id));
    return CourseProgress(
      done.length,
      lessons.length,
      done.fold(0, (minutes, l) => minutes + l.durationMinutes),
    );
  }
}

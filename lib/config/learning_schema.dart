/// Nombres de tablas y columnas configurables sin modificar pantallas.
/// NO habilites escritura real sin verificar primero el esquema y sus RLS.
class LearningSchema {
  static const bool enabled = bool.fromEnvironment(
    'ACADEMIX_REAL_LEARNING', defaultValue: false);
  static const bool submissionsEnabled = bool.fromEnvironment(
    'ACADEMIX_REAL_SUBMISSIONS', defaultValue: false);

  static const String modulesTable = String.fromEnvironment(
    'ACADEMIX_MODULES_TABLE', defaultValue: 'course_modules');
  static const String lessonsTable = String.fromEnvironment(
    'ACADEMIX_LESSONS_TABLE', defaultValue: 'course_lessons');
  static const String enrollmentsTable = String.fromEnvironment(
    'ACADEMIX_ENROLLMENTS_TABLE', defaultValue: 'course_enrollments');
  static const String tasksTable = String.fromEnvironment(
    'ACADEMIX_TASKS_TABLE', defaultValue: 'course_tasks');
  static const String submissionsTable = String.fromEnvironment(
    'ACADEMIX_SUBMISSIONS_TABLE', defaultValue: 'course_task_submissions');

  static const String courseFk = String.fromEnvironment(
    'ACADEMIX_COURSE_FK', defaultValue: 'course_id');
  static const String moduleFk = String.fromEnvironment(
    'ACADEMIX_MODULE_FK', defaultValue: 'module_id');
  static const String lessonFk = String.fromEnvironment(
    'ACADEMIX_LESSON_FK', defaultValue: 'lesson_id');
  static const String userFk = String.fromEnvironment(
    'ACADEMIX_USER_FK', defaultValue: 'user_id');
  static const String taskFk = String.fromEnvironment(
    'ACADEMIX_TASK_FK', defaultValue: 'task_id');
  static const String submissionAnswer = String.fromEnvironment(
    'ACADEMIX_SUBMISSION_ANSWER', defaultValue: 'answer');
}

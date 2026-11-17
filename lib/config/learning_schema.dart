/// Helpers for interpreting PostgREST and PostgreSQL schema errors.
class LearningSchema {
  const LearningSchema._();

  /// Returns true only for errors that indicate a referenced table is missing.
  static bool isMissingTableCode(String? code) =>
      code == 'PGRST205' || code == '42P01';
}

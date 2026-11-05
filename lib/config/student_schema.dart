/// Contrato opcional, NO inferido de la BD real. Ver INTEGRACION_ESTUDIANTE.md.
/// Activar únicamente cuando tablas, constraints y RLS coincidan.
class StudentSchema {
  static const enabled = bool.fromEnvironment(
    'ACADEMIX_REAL_STUDENT',
    defaultValue: false,
  );
  static const notifications = String.fromEnvironment(
    'ACADEMIX_NOTIFICATIONS_TABLE',
    defaultValue: 'notifications',
  );
  static const reviews = String.fromEnvironment(
    'ACADEMIX_REVIEWS_TABLE',
    defaultValue: 'course_reviews',
  );
  static const certificates = String.fromEnvironment(
    'ACADEMIX_CERTIFICATES_TABLE',
    defaultValue: 'course_certificates',
  );
  static const progress = String.fromEnvironment(
    'ACADEMIX_PROGRESS_TABLE',
    defaultValue: 'lesson_progress',
  );

  /// Debe validar membresía activa y curso incluido en el servidor.
  static const includedEnrollmentRpc = String.fromEnvironment(
    'ACADEMIX_INCLUDED_ENROLL_RPC',
  );

  /// URL HTTPS del verificador web existente, recibe ?code=...
  static const verificationUrl = String.fromEnvironment(
    'ACADEMIX_CERTIFICATE_VERIFY_URL',
  );
}

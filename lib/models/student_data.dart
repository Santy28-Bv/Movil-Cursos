/// Adapter de avisos web al centro móvil. Sin datos inventados.
class StudentNotice {
  const StudentNotice({
    required this.id,
    required this.title,
    required this.message,
    this.isRead = false,
  });
  final String id;
  final String title;
  final String message;
  final bool isRead;

  factory StudentNotice.fromJson(Map<String, dynamic> row) => StudentNotice(
    id: (row['id'] ?? '').toString(),
    title:
        (row['title'] ?? row['asunto'] ?? row['tituloAviso'] ?? 'Aviso')
            .toString(),
    message: (row['body'] ?? row['contenido'] ?? '').toString(),
    isRead: row['read_at'] != null || row['is_read'] == true,
  );
  StudentNotice read() =>
      StudentNotice(id: id, title: title, message: message, isRead: true);
}

class CourseReview {
  const CourseReview({
    required this.author,
    required this.rating,
    required this.comment,
  });
  static const maxCommentLength = 1000;
  final String author;
  final int rating;
  final String comment;

  factory CourseReview.fromJson(Map<String, dynamic> row) => CourseReview(
    author: (row['author_name'] ?? 'Estudiante').toString(),
    rating: int.tryParse('${row['rating']}') ?? 0,
    comment: (row['comment'] ?? '').toString(),
  );

  static void validate(int rating, String comment) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Selecciona una calificación de 1 a 5.');
    }
    if (comment.trim().isEmpty || comment.runes.length > maxCommentLength) {
      throw ArgumentError(
        'Escribe un comentario de 1 a $maxCommentLength caracteres.',
      );
    }
  }
}

class StudentCertificate {
  const StudentCertificate({
    required this.course,
    required this.recipient,
    required this.issuer,
    required this.code,
  });
  final String course;
  final String recipient;
  final String issuer;
  final String code;
  factory StudentCertificate.fromJson(Map<String, dynamic> row) =>
      StudentCertificate(
        course: (row['course_title'] ?? '').toString(),
        recipient: (row['recipient_name'] ?? '').toString(),
        issuer: (row['issuer_name'] ?? '').toString(),
        code: (row['credential_code'] ?? '').toString(),
      );
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/student_schema.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';

class CourseReviews extends StatefulWidget {
  const CourseReviews({
    super.key,
    required this.courseId,
    required this.hasAccess,
    this.isDemo = false,
  });
  final String courseId;
  final bool hasAccess;
  final bool isDemo;
  @override
  State<CourseReviews> createState() => _CourseReviewsState();
}

class _CourseReviewsState extends State<CourseReviews> {
  final _comment = TextEditingController();
  late final StudentRepository _repository;
  late Future<List<CourseReview>> _future;
  int _rating = 5;
  bool _saving = false;
  bool get _enabled => StudentSchema.enabled && !widget.isDemo;
  @override
  void initState() {
    super.initState();
    _repository = StudentRepository(Supabase.instance.client);
    _load();
  }

  void _load() {
    _future =
        _enabled ? _repository.reviews(widget.courseId) : Future.value([]);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_saving) return;
    try {
      CourseReview.validate(_rating, _comment.text);
    } on ArgumentError catch (e) {
      _message('${e.message}');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.publishReview(widget.courseId, _rating, _comment.text);
      if (!mounted) return;
      _comment.clear();
      setState(_load);
      _message(
        'Reseña enviada. Su visibilidad depende de la moderación del curso.',
      );
    } catch (_) {
      if (mounted) {
        _message(
          'No se pudo publicar. Comprueba tu acceso o si ya tienes una reseña.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Opiniones de estudiantes',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      if (!_enabled)
        Text(
          widget.isDemo
              ? 'Las prácticas demo no publican reseñas reales.'
              : 'Las reseñas estarán disponibles cuando se conecten al servidor.',
        ),
      if (_enabled)
        FutureBuilder<List<CourseReview>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return TextButton(
                onPressed: () => setState(_load),
                child: const Text(
                  'No se pudieron cargar las reseñas. Reintentar',
                ),
              );
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return const Text(
                'Este curso todavía no tiene reseñas publicadas.',
              );
            }
            return Column(
              children:
                  reviews
                      .map(
                        (review) => Card(
                          child: ListTile(
                            title: Text(review.author),
                            subtitle: Text(review.comment),
                            trailing: Text('★ ${review.rating}/5'),
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      if (_enabled && widget.hasAccess) ...[
        const SizedBox(height: 20),
        const Text('Tu calificación'),
        DropdownButton<int>(
          value: _rating,
          isExpanded: true,
          items: List.generate(
            5,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text('${i + 1} estrellas'),
            ),
          ),
          onChanged:
              _saving ? null : (value) => setState(() => _rating = value ?? 5),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _comment,
          enabled: !_saving,
          minLines: 3,
          maxLines: 6,
          maxLength: CourseReview.maxCommentLength,
          decoration: const InputDecoration(
            labelText: 'Comparte tu experiencia',
          ),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _publish,
          icon: const Icon(Icons.rate_review_outlined),
          label: Text(_saving ? 'Enviando…' : 'Publicar reseña'),
        ),
      ] else if (_enabled)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            'Inicia sesión y accede al curso para publicar tu reseña.',
          ),
        ),
    ],
  );
}

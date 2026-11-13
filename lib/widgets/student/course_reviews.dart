import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../services/academix_api.dart';

class CourseReviews extends StatefulWidget {
  const CourseReviews({
    super.key,
    required this.courseId,
    required this.hasAccess,
    this.isCompleted = false,
    this.repository,
  });
  final String courseId;
  final bool hasAccess;
  final bool isCompleted;
  final StudentRepository? repository;
  @override
  State<CourseReviews> createState() => _CourseReviewsState();
}

class _CourseReviewsState extends State<CourseReviews> {
  final _comment = TextEditingController();
  late final StudentRepository _repository;
  final List<CourseReview> _reviews = [];
  int _rating = 5;
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _saving = false;
  bool _published = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? StudentRepository(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 0;
        _reviews.clear();
      }
    });
    try {
      final page = await _repository.reviewsPage(
        widget.courseId,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _reviews.addAll(page.items.map(CourseReview.fromJson));
          _page = page.page;
          _hasMore = page.hasMore;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = studentError(error, 'No pudimos cargar las reseñas.'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    if (_saving) return;
    try {
      CourseReview.validate(_rating, _comment.text);
    } on ArgumentError catch (error) {
      _message('${error.message}');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.publishReview(widget.courseId, _rating, _comment.text);
      if (!mounted) return;
      _comment.clear();
      setState(() => _published = true);
      _message('Tu reseña se publicó correctamente.');
      await _load(reset: true);
    } catch (error) {
      if (error is ApiException &&
          error.code == 'REVIEW_ALREADY_EXISTS' &&
          mounted) {
        setState(() => _published = true);
      }
      _message(studentError(error, 'No pudimos publicar tu reseña.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Opiniones de estudiantes',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 14),
      for (final review in _reviews)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.author,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('★ ${review.rating}/5'),
                const SizedBox(height: 10),
                Text(review.comment),
              ],
            ),
          ),
        ),
      if (_error != null) ...[
        Text(_error!),
        TextButton(onPressed: _load, child: const Text('Reintentar')),
      ],
      if (_loading)
        const LinearProgressIndicator()
      else if (_reviews.isEmpty && _error == null)
        const Text('Este curso todavía no tiene reseñas publicadas.')
      else if (_hasMore && _error == null)
        TextButton(onPressed: _load, child: const Text('Ver más reseñas')),
      if (widget.hasAccess && widget.isCompleted && !_published) ...[
        const SizedBox(height: 20),
        const Text('Tu calificación'),
        DropdownButton<int>(
          value: _rating,
          isExpanded: true,
          items: [
            for (var i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i estrellas')),
          ],
          onChanged: _saving ? null : (v) => setState(() => _rating = v ?? 5),
        ),
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
      ] else if (widget.hasAccess && !widget.isCompleted)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text('Completa el curso para publicar tu reseña.'),
        )
      else if (!widget.hasAccess)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            'Inicia sesión y accede al curso para compartir tu experiencia.',
          ),
        ),
    ],
  );
}

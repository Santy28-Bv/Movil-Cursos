import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

/// Maneja búsqueda, paginación, recarga y errores sin mezclar UI y SQL.
class CourseFeedController extends ChangeNotifier {
  CourseFeedController({required this.repository, this.pageSize = 6});

  final CourseRepository repository;
  final int pageSize;

  final List<Course> _courses = [];
  late final UnmodifiableListView<Course> _readonlyCourses =
      UnmodifiableListView<Course>(_courses);
  int _offset = 0;
  int _requestVersion = 0;
  bool _disposed = false;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  bool _isDemo = false;
  String? _notice;
  String _search = '';

  List<Course> get courses => _readonlyCourses;
  bool get isLoading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get search => _search;
  bool get isDemo => _isDemo;
  String? get notice => _notice;

  Future<void> loadMore() async {
    if (_disposed || _loading || !_hasMore || _error != null) return;
    final version = _requestVersion;
    _loading = true;
    notifyListeners();

    try {
      final page = await repository.fetchPublished(
        offset: _offset,
        limit: pageSize,
        search: _search,
      );
      if (_disposed || version != _requestVersion) return;

      _courses.addAll(page.items);
      _isDemo = page.isDemo;
      _notice = page.notice;
      _offset += page.items.length;
      _hasMore = page.hasMore;
    } catch (e) {
      if (_disposed || version != _requestVersion) return;
      _error = e.toString();
    } finally {
      if (!_disposed && version == _requestVersion) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh({String? search}) {
    _requestVersion++; // Ignora respuestas de consultas anteriores.
    if (search != null) _search = search.trim();
    _courses.clear();
    _offset = 0;
    _hasMore = true;
    _loading = false;
    _error = null;
    _isDemo = false;
    _notice = null;
    notifyListeners();
    return loadMore();
  }

  Future<void> retry() {
    _error = null;
    notifyListeners();
    return loadMore();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}

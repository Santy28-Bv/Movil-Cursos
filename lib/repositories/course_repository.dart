import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_settings.dart';
import '../data/cursos_web_demo.dart';
import '../models/course.dart';

class CoursePage {
  const CoursePage({required this.items, required this.hasMore,
    this.isDemo = false, this.notice});
  final List<Course> items;
  final bool hasMore;
  final bool isDemo;
  final String? notice;
}

abstract class CourseRepository {
  Future<CoursePage> fetchPublished({
    required int offset,
    required int limit,
    String search = '',
  });
}

/// Usa cursos públicos de Supabase cuando están disponibles.
/// Si aún no existe el catálogo público en la BD, usa un catálogo de DEMO,
/// claramente señalado en la interfaz, basado en CursosWeb.
class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository(this.client);
  final SupabaseClient client;
  bool _usingDemo = false;
  String _demoNotice = 'Catálogo de demostración: no se guarda en Supabase.';

  void resetSource() => _usingDemo = false;

  CoursePage _getDemo({required int offset, required int limit,
      required String search}) {
    final term = search.trim().toLowerCase();
    final filtered = cursosWebDemo.where((course) =>
        term.isEmpty ||
        '${course.title} ${course.category} ${course.instructor}'
            .toLowerCase().contains(term)).toList();
    final window = filtered.skip(offset).take(limit + 1).toList();
    return CoursePage(
      items: window.take(limit).toList(), hasMore: window.length > limit,
      isDemo: true, notice: _demoNotice,
    );
  }

  @override
  Future<CoursePage> fetchPublished({
    required int offset,
    required int limit,
    String search = '',
  }) async {
    if (_usingDemo) {
      return _getDemo(offset: offset, limit: limit, search: search);
    }

    try {
      var query = client.from(SupabaseSettings.coursesTable)
          .select()
          .eq(SupabaseSettings.statusColumn,
              SupabaseSettings.publishedStatus);

      if (search.trim().isNotEmpty) {
        query = query.ilike(
            SupabaseSettings.titleColumn, '%${search.trim()}%');
      }

      final rows = await query
          .order('id', ascending: false)
          .range(offset, offset + limit);
      final results = List<Map<String, dynamic>>.from(rows);

      // Si no hay registros en la primera carga y el catálogo no se ha
      // filtrado, se presenta la maqueta de CursosWeb, nunca como datos reales.
      if (offset == 0 && search.trim().isEmpty && results.isEmpty) {
        _usingDemo = true;
        _demoNotice = 'Sin cursos publicados en Supabase: se muestran ejemplos de CursosWeb.';
        return _getDemo(offset: offset, limit: limit, search: search);
      }
      return CoursePage(
        items: results.take(limit).map(Course.fromJson).toList(),
        hasMore: results.length > limit,
      );
    } catch (_) {
      // La tabla y sus columnas siguen pendientes de confirmar. No crear ni
      // fingir registros en Supabase; mostrar únicamente una demo identificada.
      _usingDemo = true;
      _demoNotice = 'Supabase no devolvió un catálogo público. Estos cursos son una demostración de CursosWeb.';
      return _getDemo(offset: offset, limit: limit, search: search);
    }
  }
}

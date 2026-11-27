import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/course.dart';
import '../../repositories/student_repository.dart';
import '../../services/academix_api.dart';
import '../../widgets/student/student_banner.dart';
import '../courses/course_detail_screen.dart';

/// Únicamente pertenencia y aprendizaje. La administración se realiza en la web.
class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key, this.repository});
  final StudentRepository? repository;
  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  late final StudentRepository _repository;
  late Future<List<Map<String, dynamic>>> _future;
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _number = TextEditingController();
  bool _joining = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? StudentRepository(Supabase.instance.client);
    _load();
  }

  void _load() {
    _future = _repository.organizations();
  }

  @override
  void dispose() {
    _code.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_joining || !_form.currentState!.validate()) return;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await _repository.joinOrganization(_code.text, _number.text);
      if (mounted) {
        _code.clear();
        _number.clear();
        setState(_load);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te uniste a la organización.')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = studentError(
                error,
                'No pudimos confirmar tu membresía.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis organizaciones')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StudentBanner(
          title: 'Aprende en comunidad',
          message: 'Consulta tus instituciones y los cursos incluidos para ti.',
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    studentError(
                      snapshot.error,
                      'No pudimos cargar tus organizaciones.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Text('Aún no perteneces a una organización.');
            }
            return Column(
              children: [
                for (final row in rows)
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.school_outlined),
                      title: Text('${row['name']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (row['description'] case final String description
                              when description.isNotEmpty)
                            Text(description),
                          Text(
                            'Creada por ${row['creatorName'] ?? 'Persona no disponible'}',
                          ),
                        ],
                      ),
                      children: [
                        if (row['subscription'] is Map &&
                            row['subscription']['active'] != true)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'El plan de esta organización no está activo.',
                            ),
                          ),
                        _OrganizationCourses(
                          id: '${row['id']}',
                          repository: _repository,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Unirme con matrícula',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _code,
                enabled: !_joining,
                textCapitalization: TextCapitalization.characters,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Código de la organización',
                ),
                validator:
                    (v) =>
                        (v?.trim().length ?? 0) < 6
                            ? 'Escribe un código de al menos 6 caracteres.'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                enabled: !_joining,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Tu matrícula'),
                validator:
                    (v) =>
                        (v?.trim().length ?? 0) < 2
                            ? 'Escribe tu matrícula.'
                            : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_error!),
                ),
              FilledButton.icon(
                onPressed: _joining ? null : _join,
                icon: const Icon(Icons.group_add_outlined),
                label: Text(
                  _joining ? 'Validando…' : 'Unirme a la organización',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class _OrganizationCourses extends StatefulWidget {
  const _OrganizationCourses({required this.id, required this.repository});
  final String id;
  final StudentRepository repository;
  @override
  State<_OrganizationCourses> createState() => _OrganizationCoursesState();
}

class _OrganizationCoursesState extends State<_OrganizationCourses> {
  final List<Map<String, dynamic>> _rows = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.organizationCourses(
        widget.id,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _rows.addAll(page.items);
          _page = page.page;
          _hasMore = page.hasMore;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = studentError(
                error,
                'No pudimos cargar los cursos incluidos.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in _rows)
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: Text('${row['title']}'),
          trailing: const Icon(Icons.chevron_right),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => CourseDetailScreen(course: Course.fromJson(row)),
                ),
              ),
        ),
      if (_error != null)
        Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
      if (_loading)
        const LinearProgressIndicator()
      else if (_hasMore || _error != null)
        TextButton(
          onPressed: _load,
          child: Text(_error != null ? 'Reintentar' : 'Ver más cursos'),
        )
      else if (_rows.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay cursos publicados en esta organización.'),
        ),
    ],
  );
}

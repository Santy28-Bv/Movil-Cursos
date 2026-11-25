import 'package:flutter/material.dart';
import '../../repositories/course_repository.dart';

class CatalogFilters extends StatefulWidget {
  const CatalogFilters({
    super.key,
    required this.repository,
    required this.onChanged,
  });
  final ApiCourseRepository repository;
  final VoidCallback onChanged;
  @override
  State<CatalogFilters> createState() => _CatalogFiltersState();
}

class _CatalogFiltersState extends State<CatalogFilters> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.categories();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TextButton(
                onPressed:
                    () => setState(() {
                      _future = widget.repository.categories();
                    }),
                child: const Text('Reintentar categorías'),
              );
            }
            final categories = snapshot.data ?? [];
            return DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: widget.repository.category ?? '',
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todas las categorías'),
                ),
                for (final row in categories)
                  DropdownMenuItem(
                    value: '${row['slug']}',
                    child: Text(
                      '${row['name']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                setState(() => widget.repository.category = v == '' ? null : v);
                widget.onChanged();
              },
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: widget.repository.level ?? '',
          decoration: const InputDecoration(labelText: 'Nivel'),
          items: const [
            DropdownMenuItem(value: '', child: Text('Todos los niveles')),
            DropdownMenuItem(value: 'beginner', child: Text('Principiante')),
            DropdownMenuItem(value: 'intermediate', child: Text('Intermedio')),
            DropdownMenuItem(value: 'advanced', child: Text('Avanzado')),
          ],
          onChanged: (v) {
            setState(() => widget.repository.level = v == '' ? null : v);
            widget.onChanged();
          },
        ),
      ],
    ),
  );
}

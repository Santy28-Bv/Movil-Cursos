import 'package:flutter/material.dart';

class CourseCatalogHeader extends StatelessWidget {
  const CourseCatalogHeader({
    super.key,
    required this.searchController,
    required this.currentSearch,
    required this.onSearch,
  });

  final TextEditingController searchController;
  final String currentSearch;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPLORA',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Catálogo de cursos',
          style: TextStyle(
            fontSize: 27,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Explora el catálogo y descubre tu próximo reto.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 19),
        TextField(
          controller: searchController,
          onSubmitted: onSearch,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar cursos...',
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: () => onSearch(searchController.text),
              icon: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        if (currentSearch.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              searchController.clear();
              onSearch('');
            },
            icon: const Icon(Icons.close, size: 17),
            label: const Text('Limpiar búsqueda'),
          ),
        ],
      ],
    ),
  );
}

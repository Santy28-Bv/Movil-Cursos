import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

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
            const Text('DESTACADO',
                style: TextStyle(color: AcademixColors.lavender,
                    fontSize: 11, fontWeight: FontWeight.bold,
                    letterSpacing: 1.3)),
            const SizedBox(height: 7),
            const Text('Cursos destacados',
                style: TextStyle(fontSize: 27, color: Colors.white,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('Explora el catálogo y descubre tu próximo reto.',
                style: TextStyle(color: AcademixColors.muted, height: 1.45)),
            const SizedBox(height: 19),
            TextField(
              controller: searchController,
              onSubmitted: onSearch,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cursos...',
                prefixIcon: const Icon(Icons.search,
                    color: AcademixColors.lavender),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => onSearch(searchController.text),
                  icon: const Icon(Icons.arrow_forward,
                      color: AcademixColors.lavender),
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

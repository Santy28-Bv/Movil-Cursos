import 'package:flutter/material.dart';

typedef _AvatarCollection = ({String title, Map<String, String> items});

const _collections = <_AvatarCollection>[
  (
    title: 'Clásicos de Academix',
    items: {
      'nova': 'Nova',
      'pixel': 'Píxel',
      'orbita': 'Órbita',
      'chispa': 'Chispa',
      'bosque': 'Bosque',
      'marea': 'Marea',
    },
  ),
  (
    title: 'Fauna fantástica',
    items: {
      'zorro': 'Canelo',
      'ajolote': 'Bruma',
      'buho': 'Ámbar',
      'carpincho': 'Moka',
    },
  ),
  (
    title: 'Laboratorio',
    items: {
      'rover': 'Rover',
      'prisma': 'Prisma',
      'buzo': 'Nautilus',
      'antena': 'Bita',
    },
  ),
  (
    title: 'Exploradores',
    items: {
      'cartografa': 'Vega',
      'ritmo': 'Ritmo',
      'cobalto': 'Cobalto',
      'alquimista': 'Lila',
    },
  ),
];

final _avatarNames = {
  for (final collection in _collections) ...collection.items,
};

String _avatarAsset(String id) =>
    'assets/avatars/$id.${_collections.first.items.containsKey(id) ? 'png' : 'webp'}';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatarId,
    required this.name,
    required this.diameter,
  });

  final String? avatarId;
  final String name;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().characters.firstOrNull?.toUpperCase() ?? 'A';
    final id = avatarId;
    return CircleAvatar(
      radius: diameter / 2,
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      foregroundImage:
          id != null && _avatarNames.containsKey(id)
              ? AssetImage(_avatarAsset(id))
              : null,
      child: Text(
        initial,
        style: TextStyle(fontSize: diameter * .38, fontWeight: FontWeight.bold),
      ),
    );
  }
}

Future<String?> showProfileAvatarPicker(
  BuildContext context,
  String? avatarId,
  String name,
) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => _AvatarGallery(avatarId: avatarId, name: name),
  ),
);

class _AvatarGallery extends StatefulWidget {
  const _AvatarGallery({required this.avatarId, required this.name});

  final String? avatarId;
  final String name;

  @override
  State<_AvatarGallery> createState() => _AvatarGalleryState();
}

class _AvatarGalleryState extends State<_AvatarGallery> {
  late String _selected =
      _avatarNames.containsKey(widget.avatarId) ? widget.avatarId! : '';
  int _filter = -1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visible = _filter == -1 ? _collections : [_collections[_filter]];
    final preview = _avatarNames[_selected] ?? 'Tu inicial';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige tu avatar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Semantics(
              label: 'Vista previa: $preview',
              liveRegion: true,
              child: ProfileAvatar(
                avatarId: _selected,
                name: widget.name,
                diameter: 40,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: colors.surfaceContainer,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = -1; index < _collections.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          index == -1 ? 'Todos' : _collections[index].title,
                        ),
                        selected: _filter == index,
                        onSelected: (_) => setState(() => _filter = index),
                        showCheckmark: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(_filter),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              children: [
                for (final collection in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _CollectionGrid(
                      collection: collection,
                      selected: _selected,
                      onSelected: (id) => setState(() => _selected = id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 4,
        color: colors.surfaceContainer,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed:
                    _selected.isEmpty
                        ? null
                        : () => setState(() => _selected = ''),
                child: const Text('Usar mi inicial'),
              ),
              FilledButton(
                onPressed:
                    _selected == (widget.avatarId ?? '')
                        ? null
                        : () => Navigator.pop(context, _selected),
                child: const Text('Guardar avatar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({
    required this.collection,
    required this.selected,
    required this.onSelected,
  });

  final _AvatarCollection collection;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(collection.title, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final columns =
                constraints.maxWidth >= 790
                    ? 6
                    : constraints.maxWidth >= 560
                    ? 4
                    : constraints.maxWidth >= 324
                    ? 3
                    : 2;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in collection.items.entries)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: selected == item.key,
                      button: true,
                      child: Material(
                        color:
                            selected == item.key
                                ? colors.primaryContainer
                                : colors.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color:
                                selected == item.key
                                    ? colors.primary
                                    : colors.outlineVariant,
                            width: selected == item.key ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onSelected(item.key),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.asset(
                                          _avatarAsset(item.key),
                                          fit: BoxFit.cover,
                                          excludeFromSemantics: true,
                                        ),
                                      ),
                                    ),
                                    if (selected == item.key)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: CircleAvatar(
                                          radius: 11,
                                          backgroundColor: colors.primary,
                                          foregroundColor: colors.onPrimary,
                                          child: const Icon(
                                            Icons.check,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    3,
                                    5,
                                    3,
                                    3,
                                  ),
                                  child: Text(
                                    item.value,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

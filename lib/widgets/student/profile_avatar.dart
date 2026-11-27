import 'package:flutter/material.dart';

const profileAvatars = {
  'nova': 'Nova',
  'pixel': 'Píxel',
  'orbita': 'Órbita',
  'chispa': 'Chispa',
  'bosque': 'Bosque',
  'marea': 'Marea',
};

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
          profileAvatars.containsKey(id)
              ? AssetImage('assets/avatars/$id.png')
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
) {
  var selected = avatarId ?? '';
  return showDialog<String>(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder:
              (context, update) => AlertDialog(
                title: const Text('Elige tu avatar'),
                scrollable: true,
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in profileAvatars.entries)
                            Semantics(
                              selected: selected == entry.key,
                              child: OutlinedButton(
                                onPressed:
                                    () => update(() => selected = entry.key),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      selected == entry.key
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                          : null,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProfileAvatar(
                                      avatarId: entry.key,
                                      name: entry.value,
                                      diameter: 50,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(entry.value),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ChoiceChip(
                        label: const Text('Usar mi inicial'),
                        avatar: ProfileAvatar(name: name, diameter: 22),
                        selected: selected.isEmpty,
                        onSelected: (_) => update(() => selected = ''),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed:
                        selected == (avatarId ?? '')
                            ? null
                            : () => Navigator.pop(context, selected),
                    child: const Text('Guardar avatar'),
                  ),
                ],
              ),
        ),
  );
}

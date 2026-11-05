import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/profile_repository.dart';
import '../../widgets/student/student_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late final String _owner;
  String _email = '';
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser!;
    _owner = user.id;
    _email = user.email ?? '';
    for (final key in [
      'nombres',
      'apellido_paterno',
      'apellido_materno',
      'telefono',
    ]) {
      _fields[key] = TextEditingController(
        text: '${user.userMetadata?[key] ?? ''}',
      );
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final auth = Supabase.instance.client.auth;
    if (auth.currentUser?.id != _owner) return;
    setState(() => _saving = true);
    try {
      await ProfileRepository(Supabase.instance.client).update(_owner, {
        for (final field in _fields.entries) field.key: field.value.text.trim(),
      });
      if (!mounted || auth.currentUser?.id != _owner) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu información se actualizó correctamente.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar tu información. Intenta nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi información')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const StudentBanner(
            title: 'Tu perfil',
            message: 'Mantén al día los datos de tu cuenta.',
          ),
          Text(_email, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('El correo identifica tu cuenta.'),
          const SizedBox(height: 20),
          ..._fields.entries.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: field.value,
                enabled: !_saving,
                maxLength: field.key == 'telefono' ? 30 : 80,
                keyboardType:
                    field.key == 'telefono'
                        ? TextInputType.phone
                        : TextInputType.name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText:
                      const {
                        'nombres': 'Nombre(s)',
                        'apellido_paterno': 'Apellido paterno',
                        'apellido_materno': 'Apellido materno',
                        'telefono': 'Teléfono (opcional)',
                      }[field.key],
                ),
                validator:
                    (value) =>
                        (field.key == 'nombres' ||
                                    field.key == 'apellido_paterno') &&
                                (value == null || value.trim().isEmpty)
                            ? 'Completa este campo.'
                            : null,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

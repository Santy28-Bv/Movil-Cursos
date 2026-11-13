import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/profile_repository.dart';
import '../../services/academix_api.dart';
import '../../services/student_session.dart';
import '../../widgets/student/student_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.repository});
  final ProfileRepository? repository;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in ['fullName', 'phone', 'country', 'bio'])
      key: TextEditingController(),
  };
  late final ProfileRepository _repository;
  late final String _owner;
  late Future<Map<String, dynamic>> _future;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? ProfileRepository(Supabase.instance.client);
    _owner = _repository.client.auth.currentUser?.id ?? '';
    _reload();
  }

  void _reload() {
    _future = _repository.get().then((profile) {
      if (mounted && _repository.client.auth.currentUser?.id == _owner) {
        for (final field in _fields.entries) {
          field.value.text = '${profile[field.key] ?? ''}';
        }
        StudentSession.instance.updateProfileName(
          _owner,
          '${profile['fullName'] ?? ''}',
        );
      }
      return profile;
    });
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
    setState(() => _saving = true);
    try {
      final profile = await _repository.update(_owner, {
        for (final field in _fields.entries) field.key: field.value.text.trim(),
      });
      if (!mounted || _repository.client.auth.currentUser?.id != _owner) return;
      StudentSession.instance.updateProfileName(
        _owner,
        '${profile['fullName'] ?? ''}',
      );
      setState(() {
        _future = Future.value(profile);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu información se actualizó correctamente.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(studentError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi información')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    studentError(
                      snapshot.error,
                      'No pudimos cargar tu perfil.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final profile = snapshot.data!;
        return Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const StudentBanner(
                title: 'Tu perfil',
                message: 'Tu información personal en Academix.',
              ),
              Text(
                '${profile['email'] ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('El correo identifica tu cuenta.'),
              const SizedBox(height: 20),
              for (final field in _fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: field.value,
                    enabled: !_saving,
                    maxLength:
                        const {
                          'fullName': 160,
                          'phone': 30,
                          'country': 100,
                          'bio': 2000,
                        }[field.key],
                    minLines: field.key == 'bio' ? 3 : 1,
                    maxLines: field.key == 'bio' ? 5 : 1,
                    keyboardType:
                        field.key == 'phone'
                            ? TextInputType.phone
                            : field.key == 'bio'
                            ? TextInputType.multiline
                            : TextInputType.text,
                    decoration: InputDecoration(
                      labelText:
                          const {
                            'fullName': 'Nombre completo',
                            'phone': 'Teléfono',
                            'country': 'País',
                            'bio': 'Acerca de mí',
                          }[field.key],
                    ),
                    validator:
                        (value) =>
                            field.key == 'fullName' &&
                                    (value?.trim().length ?? 0) < 2
                                ? 'Escribe tu nombre completo.'
                                : null,
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
        );
      },
    ),
  );
}

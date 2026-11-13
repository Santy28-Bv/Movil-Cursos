import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/student_faq.dart';
import '../../services/academix_api.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    initialIndex: initialIndex,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Academix'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Nosotros'),
            Tab(text: 'Preguntas'),
            Tab(text: 'Contacto'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Aprender transforma tu futuro',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              const Text(
                'Academix conecta a estudiantes, instructores e instituciones en un espacio de aprendizaje. Explora cursos, aprende a tu ritmo y sigue tu progreso desde la web o tu dispositivo móvil.',
                style: TextStyle(height: 1.7),
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(18),
            children: [
              for (final section in studentFaq) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    '${section['title']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final item in section['items'] as List)
                  Card(
                    child: ExpansionTile(
                      title: Text('${item['question']}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            '${item['answer']}',
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
          const _ContactForm(),
        ],
      ),
    ),
  );
}

class _ContactForm extends StatefulWidget {
  const _ContactForm();
  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in ['fullName', 'email', 'subject', 'message'])
      key: TextEditingController(),
  };
  bool _sending = false;
  String? _result;
  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _result = null;
    });
    try {
      await AcademixApi(
        Supabase.instance.client,
      ).postPublic('/contact/messages', {
        for (final field in _fields.entries) field.key: field.value.text.trim(),
      });
      if (mounted) {
        for (final field in _fields.values) {
          field.clear();
        }
        setState(
          () =>
              _result =
                  'Tu mensaje se envió correctamente. Gracias por contactar a Academix.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _result = studentError(error, 'No pudimos enviar tu mensaje.'),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Hablemos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 18),
        for (final field in _fields.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: field.value,
              enabled: !_sending,
              maxLength:
                  const {
                    'fullName': 160,
                    'email': 254,
                    'subject': 160,
                    'message': 4000,
                  }[field.key],
              minLines: field.key == 'message' ? 4 : 1,
              maxLines: field.key == 'message' ? 8 : 1,
              keyboardType:
                  field.key == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.text,
              decoration: InputDecoration(
                labelText:
                    const {
                      'fullName': 'Nombre completo',
                      'email': 'Correo electrónico',
                      'subject': 'Asunto',
                      'message': 'Mensaje',
                    }[field.key],
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (field.key == 'email') {
                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
                      ? null
                      : 'Escribe un correo válido.';
                }
                final min =
                    const {'fullName': 2, 'subject': 3, 'message': 12}[field
                        .key]!;
                return text.length < min
                    ? 'Escribe al menos $min caracteres.'
                    : null;
              },
            ),
          ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Enviando…' : 'Enviar mensaje'),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(_result!),
          ),
      ],
    ),
  );
}

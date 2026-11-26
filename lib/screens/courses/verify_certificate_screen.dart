import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';

/// Verificación pública: no requiere inicio de sesión.
class VerifyCertificateScreen extends StatefulWidget {
  const VerifyCertificateScreen({super.key});
  @override
  State<VerifyCertificateScreen> createState() =>
      _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  final input = TextEditingController();
  Future<StudentCertificate>? lookup;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void _verify() {
    final code = input.text.trim();
    if (code.isEmpty) {
      return;
    }
    setState(
      () => lookup = StudentRepository(Supabase.instance.client).verify(code),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text('Verificar certificado'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    ),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Validación de certificados',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Introduce el código que aparece en un certificado Academix. '
          'Solo se mostrarán constancias emitidas por la base de datos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: input,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: const InputDecoration(
            labelText: 'Código de verificación',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _verify, child: const Text('Verificar código')),
        if (lookup != null)
          FutureBuilder<StudentCertificate>(
            future: lookup,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Error al verificar: ${snap.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              if (snap.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No se encontró un certificado con este código.',
                    style: TextStyle(),
                  ),
                );
              }
              final record = snap.data!;
              return Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Certificado válido',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Titular: ${record.recipient}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Curso: ${record.course}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Código: ${record.code}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}

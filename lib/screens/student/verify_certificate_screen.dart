import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../services/academix_api.dart';

class VerifyCertificateScreen extends StatefulWidget {
  const VerifyCertificateScreen({super.key});
  @override
  State<VerifyCertificateScreen> createState() =>
      _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  final _code = TextEditingController();
  StudentCertificate? _certificate;
  bool _loading = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text.trim().toUpperCase();
    if (!RegExp(r'^ACX-\d{4}-[A-F0-9]{12}$').hasMatch(code)) {
      setState(() => _error = 'Usa el formato ACX-AAAA-XXXXXXXXXXXX.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _certificate = null;
    });
    try {
      final cert = await StudentRepository(
        Supabase.instance.client,
      ).verify(code);
      if (mounted) setState(() => _certificate = cert);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = studentError(
                error,
                'No encontramos un certificado vigente con ese código.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verificar certificado')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Cualquier persona puede comprobar una credencial de Academix con su código.',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Código de credencial'),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: Text(_loading ? 'Verificando…' : 'Verificar'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(_error!),
          ),
        if (_certificate != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text('Certificado válido'),
                  Text(
                    _certificate!.course,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(_certificate!.recipient),
                  Text(_certificate!.issuer),
                  Text(_certificate!.issuedAt.split('T').first),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

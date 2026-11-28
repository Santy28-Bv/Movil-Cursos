import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../services/academix_api.dart';
import '../../widgets/student/certificate_document.dart';

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
        if (_certificate != null) ...[
          const SizedBox(height: 18),
          const Text('Certificado válido'),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: CertificateDocument(certificate: _certificate!),
            ),
          ),
        ],
      ],
    ),
  );
}

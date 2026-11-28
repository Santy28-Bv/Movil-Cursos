import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../widgets/student/certificate_document.dart';

/// Nunca emite una constancia basada solo en información del cliente:
/// primero verifica en PostgreSQL que el código exista.
class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, required this.code});
  final String code;
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  late final Future<StudentCertificate> certificate;
  @override
  void initState() {
    super.initState();
    certificate = StudentRepository(
      Supabase.instance.client,
    ).verify(widget.code);
  }

  Future<void> _share(StudentCertificate record) async {
    await Printing.sharePdf(
      bytes: await buildCertificatePdf(record),
      filename:
          'academix_certificado_${record.code.replaceAll(RegExp(r"[^\w-]"), "_")}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text('Mi certificado'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    ),
    body: FutureBuilder<StudentCertificate>(
      future: certificate,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo verificar este certificado en Supabase.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final record = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.workspace_premium,
                color: Theme.of(context).colorScheme.primary,
                size: 84,
              ),
              const SizedBox(height: 14),
              Text(
                'Certificado verificado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              CertificateDocument(certificate: record),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: record.code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => _share(record),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generar y compartir PDF'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

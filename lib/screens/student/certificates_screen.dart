import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/student_schema.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../widgets/student/student_banner.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});
  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<List<StudentCertificate>> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future =
        StudentSchema.enabled
            ? StudentRepository(Supabase.instance.client).certificates()
            : Future.value([]);
  }

  Future<void> _verify(String code) async {
    final base = Uri.tryParse(StudentSchema.verificationUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty) {
      return;
    }
    try {
      final ok = await launchUrl(
        base.replace(queryParameters: {...base.queryParameters, 'code': code}),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw StateError('No disponible');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el verificador.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis certificados'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StudentBanner(
          title: 'Tus logros',
          message:
              'Consulta tus credenciales y comparte su código de verificación.',
        ),
        if (!StudentSchema.enabled)
          const Text('Los certificados aún no están conectados al servidor.'),
        FutureBuilder<List<StudentCertificate>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text('No se pudieron cargar tus certificados.'),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final certificates = snapshot.data ?? [];
            if (certificates.isEmpty && StudentSchema.enabled) {
              return const Text('Todavía no tienes certificados emitidos.');
            }
            return Column(
              children:
                  certificates
                      .map(
                        (cert) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_outlined,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  cert.course,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text('Destinatario: ${cert.recipient}'),
                                Text('Emisor: ${cert.issuer}'),
                                const SizedBox(height: 10),
                                SelectableText('Código: ${cert.code}'),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          cert.code.isEmpty
                                              ? null
                                              : () async {
                                                await Clipboard.setData(
                                                  ClipboardData(
                                                    text: cert.code,
                                                  ),
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Código copiado para compartir.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copiar código'),
                                    ),
                                    if (StudentSchema
                                        .verificationUrl
                                        .isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () => _verify(cert.code),
                                        icon: const Icon(
                                          Icons.verified_outlined,
                                        ),
                                        label: const Text('Verificar'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    ),
  );
}

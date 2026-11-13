import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../services/academix_api.dart';
import '../../widgets/student/student_banner.dart';
import '../../widgets/student/student_guard.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key, this.repository});
  final StudentRepository? repository;
  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late final StudentRepository _repository;
  final List<StudentCertificate> _certificates = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? StudentRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 0;
        _certificates.clear();
      }
    });
    try {
      final result = await _repository.certificatesPage(page: _page + 1);
      if (mounted) {
        setState(() {
          _certificates.addAll(result.items.map(StudentCertificate.fromJson));
          _page = result.page;
          _hasMore = result.hasMore;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = studentError(
                error,
                'No pudimos cargar tus certificados.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(StudentCertificate certificate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentGuard(
              builder:
                  (_) => CertificateDetailScreen(
                    id: certificate.id,
                    repository: _repository,
                  ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis certificados'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: () => _load(reset: true),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          const StudentBanner(
            title: 'Tus logros',
            message: 'Consulta y comparte tus credenciales de Academix.',
          ),
          for (final cert in _certificates)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const Icon(Icons.workspace_premium_outlined, size: 36),
                title: Text(cert.course),
                subtitle: Text(
                  '${cert.code}\n${cert.issuedAt.split('T').first}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(cert),
              ),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ] else if (_certificates.isEmpty)
            const Text('Todavía no tienes certificados emitidos.')
          else if (_hasMore)
            TextButton(
              onPressed: _load,
              child: const Text('Cargar más certificados'),
            ),
        ],
      ),
    ),
  );
}

class CertificateDetailScreen extends StatefulWidget {
  const CertificateDetailScreen({
    super.key,
    required this.id,
    required this.repository,
  });
  final String id;
  final StudentRepository repository;
  @override
  State<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  late Future<StudentCertificate> _future;
  bool _working = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.certificate(widget.id);
  }

  Future<void> _verify(StudentCertificate cert) async {
    setState(() => _working = true);
    try {
      final result = await widget.repository.verify(cert.code);
      if (mounted) {
        setState(
          () =>
              _message =
                  'Certificado válido · ${result.course} · ${result.recipient}',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _message = studentError(
                error,
                'No pudimos verificar el certificado.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pdf(StudentCertificate cert) async {
    setState(() => _working = true);
    try {
      final url =
          widget.repository.api.endpoint(cert.verificationPath).toString();
      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build:
              (_) => pw.Container(
                padding: const pw.EdgeInsets.all(30),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.deepPurple, width: 3),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      cert.issuer,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'CERTIFICADO DE FINALIZACIÓN',
                      style: const pw.TextStyle(fontSize: 20),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      cert.recipient,
                      style: pw.TextStyle(
                        fontSize: 25,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text('Completó satisfactoriamente el curso'),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      cert.course,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 20),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Text(
                      '${cert.durationHours} horas · Emitido: ${cert.issuedAt.split('T').first}',
                    ),
                    pw.SizedBox(height: 20),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: url,
                      width: 70,
                      height: 70,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(cert.code),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Firma SHA-256: ${cert.signature}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
        ),
      );
      final bytes = await document.save();
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Academix_${cert.code.replaceAll(RegExp(r"[^\w-]"), "_")}.pdf',
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = studentError(error, 'No pudimos preparar el PDF.'),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Certificado')),
    body: FutureBuilder<StudentCertificate>(
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
                  Text(studentError(snapshot.error)),
                  TextButton(
                    onPressed:
                        () => setState(() {
                          _future = widget.repository.certificate(widget.id);
                        }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final cert = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      cert.issuer,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CERTIFICADO DE FINALIZACIÓN',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      cert.recipient,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cert.course,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${cert.durationHours} horas · ${cert.issuedAt.split('T').first}',
                    ),
                    const SizedBox(height: 16),
                    SelectableText(cert.code),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _working ? null : () => _pdf(cert),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Descargar PDF'),
            ),
            OutlinedButton.icon(
              onPressed: _working ? null : () => _verify(cert),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verificar certificado'),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: cert.code));
                if (mounted) setState(() => _message = 'Código copiado.');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_message!),
              ),
          ],
        );
      },
    ),
  );
}

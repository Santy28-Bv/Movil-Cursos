import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_data.dart';
import '../../repositories/student_repository.dart';
import '../../theme/academix_colors.dart';

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
    certificate =
        StudentRepository(Supabase.instance.client).verify(widget.code);
  }

  Future<void> _share(StudentCertificate record) async {
    final doc = pw.Document(title: 'Certificado Academix');
    final date = DateTime.tryParse(record.issuedAt)?.toLocal();
    final formatted = date == null
        ? 'No disponible'
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}';
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(38),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(
          color: PdfColor.fromHex('#7138D7'), width: 4)),
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Text('ACADEMIX', style: pw.TextStyle(
              fontSize: 27, fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#632DB8'))),
            pw.SizedBox(height: 22),
            pw.Text('CERTIFICADO DE FINALIZACION', style: pw.TextStyle(
              fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 25),
            pw.Text('Se certifica que', style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Text(record.recipient, style: pw.TextStyle(
              fontSize: 26, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 14),
            pw.Text('ha aprobado las evaluaciones del curso',
              style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 10),
            pw.Text(record.course, textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 22,
                fontWeight: pw.FontWeight.bold)),
            pw.Spacer(),
            pw.Text('Fecha: $formatted    Codigo de verificacion: ${record.code}',
              style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Verifique el codigo con la funcion publica de Academix.',
              style: const pw.TextStyle(fontSize: 10)),
          ]),
      ),
    ));
    await Printing.sharePdf(bytes: await doc.save(),
        filename: 'academix_certificado_${record.code}.pdf');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AcademixColors.background,
    appBar: AppBar(title: const Text('Mi certificado'),
      backgroundColor: AcademixColors.card, foregroundColor: Colors.white),
    body: FutureBuilder<StudentCertificate>(future: certificate, builder: (ctx, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError || snap.data == null) {
        return const Center(child: Padding(padding: EdgeInsets.all(24),
          child: Text('No se pudo verificar este certificado en Supabase.',
            style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)));
      }
      final record = snap.data!;
      return SingleChildScrollView(padding: const EdgeInsets.all(25),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.workspace_premium, color: AcademixColors.lavender, size: 84),
          const SizedBox(height: 14),
          const Text('Certificado verificado', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          Card(color: AcademixColors.card, child: Padding(
            padding: const EdgeInsets.all(20), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.recipient, style: const TextStyle(color: Colors.white,
                fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(record.course, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Text('Código: ${record.code}',
                style: const TextStyle(color: AcademixColors.lavender)),
            ]))),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () async {
            await Clipboard.setData(ClipboardData(text: record.code));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código copiado.')));
          }, icon: const Icon(Icons.copy), label: const Text('Copiar código')),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: () => _share(record),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar y compartir PDF')),
        ]));
    }),
  );
}

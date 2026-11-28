import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/student_data.dart';

const _brand50 = 0xf5f3ff;
const _brand100 = 0xede9fe;
const _brand200 = 0xddd6fe;
const _brand300 = 0xc4b5fd;
const _brand700 = 0x6d28d9;
const _brand800 = 0x5b21b6;
const _slate300 = 0xcbd5e1;
const _slate400 = 0x94a3b8;
const _slate500 = 0x64748b;
const _slate600 = 0x475569;
const _slate950 = 0x020617;
const _title = 'CERTIFICADO DE FINALIZACIÓN';
const _recipient = 'Se hace constar que';
const _signature = 'Firma del sistema';
const _date = 'Fecha de emisión';

Color _color(int rgb) => Color(0xff000000 | rgb);

String _completion(StudentCertificate certificate) =>
    'completó satisfactoriamente el curso profesional de ${certificate.durationHours} horas';

String _credential(StudentCertificate certificate) =>
    'Credencial: ${certificate.code}';

String _formattedDate(StudentCertificate certificate) {
  final date = DateTime.tryParse(certificate.issuedAt)?.toLocal();
  if (date == null) return 'No disponible';
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}

/// Documento de Academix con el marco y la jerarquía del certificado web.
class CertificateDocument extends StatelessWidget {
  const CertificateDocument({super.key, required this.certificate});
  final StudentCertificate certificate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spacious = constraints.maxWidth >= 575;
      final rim = spacious ? 10.0 : 6.0;
      final fields = [
        _CertificateField(certificate.issuer, _signature, signature: true),
        _CertificateField(_formattedDate(certificate), _date),
      ];
      return DecoratedBox(
        decoration: BoxDecoration(
          color: _color(_brand800),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18)],
        ),
        child: Padding(
          padding: EdgeInsets.all(rim),
          child: ClipRect(
            child: ColoredBox(
              color: Colors.white,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(spacious ? 12 : 7),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: _color(_brand300)),
                        ),
                      ),
                    ),
                  ),
                  for (final isTop in [true, false])
                    Positioned(
                      top: isTop ? -60 : null,
                      left: isTop ? -60 : null,
                      bottom: isTop ? null : -60,
                      right: isTop ? null : -60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _color(_brand100),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: spacious ? 156 : 130),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacious ? 36 : 16,
                      vertical: spacious ? 36 : 24,
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(color: _color(_slate950), fontSize: 14),
                      textAlign: TextAlign.center,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _color(_brand700),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Academix',
                                style: TextStyle(
                                  color: _color(_brand700),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _title,
                            style: TextStyle(
                              color: _color(_brand700),
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _recipient,
                            style: TextStyle(color: _color(_slate500)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            certificate.recipient,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: spacious ? 43 : 29,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 550),
                            child: Divider(color: _color(_slate300), height: 1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _completion(certificate),
                            style: TextStyle(color: _color(_slate600)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            certificate.course,
                            style: TextStyle(
                              color: _color(_brand800),
                              fontSize: spacious ? 27 : 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (spacious)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final field in fields)
                                  Expanded(child: field),
                              ],
                            )
                          else ...[
                            fields.first,
                            const SizedBox(height: 14),
                            fields.last,
                          ],
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _color(_brand50),
                              border: Border.all(color: _color(_brand200)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SelectableText(
                              _credential(certificate),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _color(_brand800),
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _CertificateField extends StatelessWidget {
  const _CertificateField(this.value, this.label, {this.signature = false});
  final String value;
  final String label;
  final bool signature;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 224),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _color(signature ? _brand800 : _slate950),
            fontFamily: signature ? 'serif' : null,
            fontStyle: signature ? FontStyle.italic : FontStyle.normal,
            fontSize: signature ? 19 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Divider(color: _color(_slate400), height: 1),
        const SizedBox(height: 7),
        Text(label, style: TextStyle(color: _color(_slate600), fontSize: 11)),
      ],
    ),
  );
}

Future<Uint8List> buildCertificatePdf(StudentCertificate certificate) {
  final document = pw.Document(title: 'Certificado Academix');
  PdfColor palette(int rgb) => PdfColor.fromInt(0xff000000 | rgb);
  pw.Widget text(
    String value,
    int color,
    double size, {
    pw.Font? font,
    double? letterSpacing,
  }) => pw.Text(
    value,
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(
      color: palette(color),
      fontSize: size,
      font: font,
      letterSpacing: letterSpacing,
    ),
  );
  pw.Widget rule(double width, int color) =>
      pw.Container(width: width, height: 1, color: palette(color));
  pw.Widget field(pw.Widget value, String label) => pw.SizedBox(
    width: 225,
    child: pw.Column(
      children: [
        value,
        pw.SizedBox(height: 5),
        rule(168, _slate400),
        pw.SizedBox(height: 8),
        text(label, _slate600, 10),
      ],
    ),
  );
  final bold = pw.Font.helveticaBold();

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
      build:
          (_) => pw.Container(
            width: double.infinity,
            height: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            color: palette(_brand800),
            child: pw.ClipRect(
              child: pw.Container(
                color: PdfColors.white,
                child: pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: palette(_brand300)),
                        ),
                      ),
                    ),
                    for (final top in [true, false])
                      pw.Positioned(
                        top: top ? -58 : null,
                        left: top ? -58 : null,
                        bottom: top ? null : -58,
                        right: top ? null : -58,
                        child: pw.Container(
                          width: 162,
                          height: 162,
                          decoration: pw.BoxDecoration(
                            color: palette(_brand100),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                      ),
                    pw.Positioned.fill(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 23,
                        ),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  width: 38,
                                  height: 38,
                                  decoration: pw.BoxDecoration(
                                    color: palette(_brand700),
                                    borderRadius: pw.BorderRadius.circular(9),
                                  ),
                                  child: text('A', 0xffffff, 19, font: bold),
                                ),
                                pw.SizedBox(width: 9),
                                text('Academix', _brand700, 18, font: bold),
                              ],
                            ),
                            pw.SizedBox(height: 25),
                            text(
                              _title,
                              _brand700,
                              10,
                              font: bold,
                              letterSpacing: 3.3,
                            ),
                            pw.SizedBox(height: 19),
                            text(_recipient, _slate500, 12),
                            pw.SizedBox(height: 8),
                            text(
                              certificate.recipient,
                              _slate950,
                              certificate.recipient.length > 85 ? 26 : 39,
                              font: pw.Font.timesBold(),
                            ),
                            pw.SizedBox(height: 10),
                            rule(430, _slate300),
                            pw.SizedBox(height: 17),
                            text(_completion(certificate), _slate600, 12),
                            pw.SizedBox(height: 8),
                            text(
                              certificate.course,
                              _brand800,
                              certificate.course.length > 95 ? 20 : 24,
                              font: bold,
                            ),
                            pw.SizedBox(height: 24),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                field(
                                  text(
                                    certificate.issuer,
                                    _brand800,
                                    18,
                                    font: pw.Font.timesBoldItalic(),
                                  ),
                                  _signature,
                                ),
                                field(
                                  text(
                                    _formattedDate(certificate),
                                    _slate950,
                                    12,
                                    font: bold,
                                  ),
                                  _date,
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 24),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: pw.BoxDecoration(
                                color: palette(_brand50),
                                border: pw.Border.all(
                                  color: palette(_brand200),
                                ),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: text(
                                _credential(certificate),
                                _brand800,
                                10,
                                font: pw.Font.courier(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ),
  );
  return document.save();
}

import 'dart:convert';

import 'package:academix/models/student_data.dart';
import 'package:academix/widgets/student/certificate_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const certificate = StudentCertificate(
  course: 'Diseño de interfaces',
  recipient: 'María Pérez y Hernández',
  issuer: 'Academix',
  code: 'ACX-2026-01ABCDEF1234',
  issuedAt: '2026-11-27T12:00:00',
  durationHours: 8,
);

void main() {
  testWidgets('shows the web certificate fields on a narrow dark screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CertificateDocument(certificate: certificate),
          ),
        ),
      ),
    );
    expect(find.text('Se hace constar que'), findsOneWidget);
    expect(find.text(certificate.recipient), findsOneWidget);
    expect(find.text(certificate.course), findsOneWidget);
    expect(find.text('27 de noviembre de 2026'), findsOneWidget);
    expect(find.text('Firma del sistema'), findsOneWidget);
    expect(find.text('Credencial: ${certificate.code}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('produces an A4 landscape PDF from an issued certificate', () async {
    final bytes = await buildCertificatePdf(certificate);
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academix/widgets/home/home_header.dart';

void main() {
  testWidgets('El visitante ve el acceso al login en el encabezado', (
    WidgetTester tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeHeader(onProfile: () => pressed = true),
      ),
    ));

    expect(find.text('Academix'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.login_rounded));
    expect(pressed, isTrue);
  });

  testWidgets('El usuario autenticado ve el icono de cuenta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeHeader(
          isAuthenticated: true,
          onProfile: () {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
  });
}

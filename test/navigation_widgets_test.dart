import 'package:academix/widgets/home/auth/guest_account_sheet.dart';
import 'package:academix/widgets/home/home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('El navbar ofrece acceso a visitantes', (tester) async {
    var accessPressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: HomeNavigation(
          onHome: () {},
          onCourses: () {},
          onProfile: () => accessPressed = true,
        ),
      ),
    ));

    expect(find.text('Acceder'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    await tester.tap(find.text('Acceder'));
    expect(accessPressed, isTrue);
  });

  testWidgets('El navbar muestra Cuenta con sesión iniciada', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: HomeNavigation(
          isAuthenticated: true,
          onHome: () {},
          onCourses: () {},
          onProfile: () {},
        ),
      ),
    ));

    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Mis cursos'), findsOneWidget);
    expect(find.text('Acceder'), findsNothing);
  });

  testWidgets('El menú invitado permite elegir Login o Registro',
      (tester) async {
    var loginPressed = false;
    var registerPressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GuestAccountSheet(
          onLogin: () => loginPressed = true,
          onRegister: () => registerPressed = true,
        ),
      ),
    ));

    await tester.tap(find.text('Iniciar sesión'));
    expect(loginPressed, isTrue);
    await tester.tap(find.text('Crear cuenta'));
    expect(registerPressed, isTrue);
  });
}

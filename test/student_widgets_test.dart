import 'package:academix/models/course.dart';
import 'package:academix/screens/student/cart_screen.dart';
import 'package:academix/services/student_session.dart';
import 'package:academix/theme/academix_theme.dart';
import 'package:academix/widgets/home/home_header.dart';
import 'package:academix/widgets/home/home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('carrito permite quitar cursos en pantalla de 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = StudentSession()..bindUser('ana');
    session.addToCart(
      const Course(
        id: '1',
        title: 'Un curso con un título muy largo para probar el ancho',
        description: '',
        category: '',
        imageUrl: '',
        price: 12.25,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AcademixTheme.dark,
        home: CartScreen(session: session),
      ),
    );
    expect(find.text('Total: \$12.25'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(find.text('Total: \$0.00'), findsOneWidget);
    expect(find.textContaining('Tu carrito está vacío'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('navegación y avisos siguen accesibles en 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var cartOpened = false;
    var noticesOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AcademixTheme.dark,
        home: Scaffold(
          body: HomeHeader(
            isAuthenticated: true,
            onProfile: () {},
            unreadCount: 3,
            onNotifications: () => noticesOpened = true,
          ),
          bottomNavigationBar: HomeNavigation(
            isAuthenticated: true,
            onHome: () {},
            onCourses: () {},
            onProfile: () {},
            onCart: () => cartOpened = true,
            cartCount: 2,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Carrito'));
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    expect(cartOpened, isTrue);
    expect(noticesOpened, isTrue);
    expect(tester.takeException(), isNull);
  });
}

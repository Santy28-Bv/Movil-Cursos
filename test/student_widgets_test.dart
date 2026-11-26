import 'package:academix/theme/academix_theme.dart';
import 'package:academix/widgets/home/home_header.dart';
import 'package:academix/widgets/home/home_navigation.dart';
import 'package:academix/widgets/home/course_catalog_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catálogo y buscador cambian juntos con el tema web', (
    tester,
  ) async {
    final search = TextEditingController();
    addTearDown(search.dispose);
    for (final (theme, surface, foreground) in [
      (AcademixTheme.light, Colors.white, const Color(0xFF0F172A)),
      (AcademixTheme.dark, const Color(0xFF0F172A), const Color(0xFFF8FAFC)),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: CourseCatalogHeader(
              searchController: search,
              currentSearch: '',
              onSearch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      final context = tester.element(find.byType(TextField));
      final input = field.decoration!.applyDefaults(
        Theme.of(context).inputDecorationTheme,
      );
      expect(input.fillColor, surface);
      expect(field.style?.color, foreground);
      expect(tester.takeException(), isNull);
    }
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

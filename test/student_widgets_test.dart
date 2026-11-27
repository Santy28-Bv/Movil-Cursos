import 'package:academix/widgets/student/profile_avatar.dart';
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

  testWidgets('la galería filtra, conserva la elección y guarda a 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: AcademixTheme.dark,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () async =>
                          choice = await showProfileAvatarPicker(
                            context,
                            'nova',
                            'Marco',
                          ),
                  child: const Text('Cambiar avatar'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Cambiar avatar'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar avatar'),
          )
          .onPressed,
      isNull,
    );
    final lab = find.widgetWithText(ChoiceChip, 'Laboratorio');
    await tester.ensureVisible(lab);
    await tester.pumpAndSettle();
    await tester.tap(lab);
    await tester.pumpAndSettle();
    expect(find.text('Nova'), findsNothing);
    await tester.tap(find.text('Prisma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar avatar'));
    await tester.pumpAndSettle();
    expect(choice, 'prisma');
    expect(tester.takeException(), isNull);
  });
}

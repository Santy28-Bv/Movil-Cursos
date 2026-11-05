import 'dart:convert';
import 'package:academix/screens/courses/my_courses_screen.dart';
import 'package:academix/screens/student/profile_screen.dart';
import 'package:academix/screens/student/certificates_screen.dart';
import 'package:academix/screens/student/notifications_screen.dart';
import 'package:academix/theme/academix_theme.dart';
import 'package:academix/widgets/student/student_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MemoryAuthStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

String _session(String id) => jsonEncode({
  'access_token': 'local-test-token',
  'refresh_token': 'local-test-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': id,
    'email': '$id@example.test',
    'app_metadata': {},
    'user_metadata': {'nombres': id, 'apellido_paterno': 'Prueba'},
    'aud': 'authenticated',
    'created_at': '2026-11-03T00:00:00Z',
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://local.invalid',
      publishableKey: 'local-test',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
        authFlowType: AuthFlowType.implicit,
        pkceAsyncStorage: _MemoryAuthStorage(),
      ),
    );
  });
  tearDownAll(() async => Supabase.instance.dispose());

  testWidgets(
    'perfil permite llegar a Guardar con teclado y se oculta al cambiar cuenta',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final auth = Supabase.instance.client.auth;
      await auth.setInitialSession(_session('ana'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AcademixTheme.dark,
          home: StudentGuard(builder: (_) => const ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ana@example.test'), findsOneWidget);
      await tester.showKeyboard(find.byType(TextFormField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Guardar cambios')).bottom,
        lessThanOrEqualTo(450),
      );
      expect(tester.takeException(), isNull);
      await auth.setInitialSession(_session('luis'));
      await tester.pumpAndSettle();
      expect(find.text('ana@example.test'), findsNothing);
      expect(find.textContaining('Tu sesión cambió'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets(
    'biblioteca, avisos y certificados muestran estado honesto sin servidor',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final screen in [
        const MyCoursesScreen(),
        const NotificationsScreen(),
        const CertificatesScreen(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(theme: AcademixTheme.dark, home: screen),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('servidor'), findsWidgets);
      }
    },
  );
}

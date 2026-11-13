import 'dart:convert';
import 'package:academix/screens/courses/my_courses_screen.dart';
import 'package:academix/screens/courses/course_detail_screen.dart';
import 'package:academix/screens/courses/lesson_screen.dart';
import 'package:academix/screens/student/profile_screen.dart';
import 'package:academix/models/course.dart';
import 'package:academix/repositories/course_repository.dart';
import 'package:academix/repositories/learning_repository.dart';
import 'package:academix/repositories/profile_repository.dart';
import 'package:academix/repositories/student_repository.dart';
import 'package:academix/widgets/student/course_reviews.dart';
import 'package:academix/services/academix_api.dart';
import 'package:academix/theme/academix_theme.dart';
import 'package:academix/widgets/student/student_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  'access_token': 'token-$id',
  'refresh_token': 'refresh-$id',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': id,
    'email': '$id@example.test',
    'app_metadata': {},
    'user_metadata': {'full_name': 'Nombre desactualizado'},
    'aud': 'authenticated',
    'created_at': '2026-11-12T00:00:00Z',
  },
});
const _course = {
  'id': 'c1',
  'title': 'Programación desde cero',
  'shortDescription': 'El catálogo compartido',
  'description': 'Aprende paso a paso con contenido real.',
  'category': {'name': 'Programación'},
  'instructor': {'name': 'Ana'},
  'price': 0,
  'durationHours': 12,
  'learningOutcomes': ['Crear tu primer programa'],
  'requirements': ['Una computadora'],
  'modules': [
    {
      'id': 'm1',
      'title': 'Fundamentos',
      'lessons': [
        {'id': 'l1', 'title': 'Primera lección', 'durationMinutes': 10},
      ],
    },
  ],
};
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
  late AcademixApi api;
  late Map<String, dynamic> profile;
  late bool complete;
  late bool failCourse;
  late List<http.Request> requests;
  setUp(() async {
    final client = Supabase.instance.client;
    await client.auth.setInitialSession(_session('ana'));
    profile = {
      'id': 'ana',
      'fullName': 'Ana desde la web',
      'email': 'ana@example.test',
      'phone': '123',
      'country': 'México',
      'bio': 'Estudiante',
    };
    complete = false;
    failCourse = false;
    requests = [];
    api = AcademixApi(
      client,
      baseUrl: 'https://api.example.test/api/v1',
      transport: MockClient((r) async {
        requests.add(r);
        if (failCourse && r.url.path == '/api/v1/courses/c1') {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': 'UNAVAILABLE', 'message': 'No disponible'},
            }),
            502,
          );
        }
        dynamic data;
        Map<String, dynamic>? pagination;
        if (r.url.path == '/api/v1/users/me') {
          if (r.method == 'PATCH') {
            profile = {
              ...profile,
              ...jsonDecode(r.body) as Map<String, dynamic>,
            };
          }
          data = profile;
        } else if (r.url.path.endsWith('/learning-summary')) {
          data = {
            'inProgress': 1,
            'completed': 0,
            'certificates': 0,
            'learningHours': 2,
          };
        } else if (r.url.path.endsWith('/course-ownership')) {
          data = ['c1'];
        } else if (r.url.path.endsWith('/learning')) {
          data = {
            'id': 'c1',
            'title': 'Programación desde cero',
            'instructorName': 'Ana',
            'progressPercentage': complete ? 100 : 0,
            'modules': [
              {
                'id': 'm1',
                'title': 'Fundamentos',
                'lessons': [
                  {
                    'id': 'l1',
                    'title': 'Primera lección',
                    'durationMinutes': 10,
                    'description': 'Contenido real de la lección',
                    'content': 'Variables y tipos',
                    'isCompleted': complete,
                    'resources': [],
                  },
                ],
              },
            ],
          };
        } else if (r.url.path.endsWith('/progress')) {
          complete = jsonDecode(r.body)['completed'];
          return http.Response('', 204);
        } else if (r.url.path == '/api/v1/users/me/courses') {
          data = [
            {
              'course': _course,
              'status': 'in_progress',
              'completedLessons': 0,
              'totalLessons': 1,
              'progressPercentage': 0,
            },
          ];
          pagination = {'page': 1, 'limit': 10, 'total': 1};
        } else if (r.url.path == '/api/v1/courses/c1') {
          data = _course;
        } else {
          data = [];
          pagination = {'page': 1, 'limit': 10, 'total': 0};
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': data,
            if (pagination != null) 'pagination': pagination,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
  }

  testWidgets(
    'perfil carga la tabla web y conserva acceso a Guardar con teclado',
    (tester) async {
      narrow(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AcademixTheme.dark,
          home: StudentGuard(
            builder:
                (_) => ProfileScreen(
                  repository: ProfileRepository(
                    Supabase.instance.client,
                    api: api,
                  ),
                ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana desde la web'), findsOneWidget);
      expect(find.text('Nombre desactualizado'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ana actualizada',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Guardar cambios')).bottom,
        lessThanOrEqualTo(450),
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(profile['fullName'], 'Ana actualizada');
      expect(
        find.text('Tu información se actualizó correctamente.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await Supabase.instance.client.auth.setInitialSession(_session('luis'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('ana@example.test'), findsNothing);
      expect(find.textContaining('Tu sesión cambió'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );
  testWidgets('biblioteca usa los registros y métricas web en 320 px', (
    tester,
  ) async {
    narrow(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AcademixTheme.dark,
        home: MyCoursesScreen(
          repository: LearningRepository(Supabase.instance.client, api: api),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mis cursos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Programación desde cero'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Programación desde cero'), findsOneWidget);
    expect(find.textContaining('demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'detalle público muestra objetivos, requisitos y temario reales',
    (tester) async {
      narrow(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AcademixTheme.dark,
          home: CourseDetailScreen(
            course: Course.fromJson(_course),
            catalog: ApiCourseRepository(Supabase.instance.client, api: api),
            learning: LearningRepository(Supabase.instance.client, api: api),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Temario del curso'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fundamentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('aula guarda y vuelve a consultar el progreso web', (
    tester,
  ) async {
    narrow(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AcademixTheme.dark,
        home: LessonScreen(
          course: Course.fromJson(_course),
          repository: LearningRepository(Supabase.instance.client, api: api),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Variables y tipos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Marcar como completada'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Marcar como completada'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
    expect(complete, isTrue);
    expect(find.text('No pudimos guardar tu progreso.'), findsNothing);
    expect(find.text('Marcar como pendiente'), findsOneWidget);
    expect(
      requests.where((r) => r.method == 'PATCH').single.url.path,
      '/api/v1/lessons/l1/progress',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'reintentar el detalle recupera el curso sin un error de setState',
    (tester) async {
      narrow(tester);
      failCourse = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: AcademixTheme.dark,
          home: CourseDetailScreen(
            course: Course.fromJson(_course),
            catalog: ApiCourseRepository(Supabase.instance.client, api: api),
            learning: LearningRepository(Supabase.instance.client, api: api),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      failCourse = false;
      await tester.tap(find.text('Reintentar'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Programación desde cero'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reseña permite publicar al completar el curso, como exige el servidor',
    (tester) async {
      narrow(tester);
      final repository = StudentRepository(Supabase.instance.client, api: api);
      await tester.pumpWidget(
        MaterialApp(
          theme: AcademixTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CourseReviews(
                courseId: 'c1',
                hasAccess: true,
                isCompleted: false,
                repository: repository,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Completa el curso para publicar tu reseña.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          theme: AcademixTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CourseReviews(
                courseId: 'c1',
                hasAccess: true,
                isCompleted: true,
                repository: repository,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Publicar reseña'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

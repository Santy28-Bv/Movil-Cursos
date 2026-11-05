import 'dart:convert';
import 'dart:io';
import 'package:academix/models/course.dart';
import 'package:academix/repositories/learning_repository.dart';
import 'package:academix/repositories/student_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servidor HTTP local: ejercita los repositorios y serialización PostgREST
/// reales, sin tocar Supabase ni necesitar credenciales.
void main() {
  late HttpServer server;
  late SupabaseClient client;
  late StudentRepository repository;
  late List<({String method, Uri uri, dynamic body})> requests;
  late dynamic Function(HttpRequest) response;

  setUp(() async {
    requests = [];
    response = (_) => [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      requests.add((
        method: request.method,
        uri: request.uri,
        body: raw.isEmpty ? null : jsonDecode(raw),
      ));
      request.response.headers.contentType = ContentType.json;
      final body = response(request);
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'local-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'local-test-token',
        'refresh_token': 'local-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'ana',
          'app_metadata': {},
          'user_metadata': {},
          'aud': 'authenticated',
          'created_at': '2026-11-03T00:00:00Z',
        },
      }),
    );
    repository = StudentRepository(
      client,
      enabled: true,
      learningEnabled: true,
    );
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'avisos y certificados filtran propietario incluso ante filas ajenas',
    () async {
      response =
          (_) => [
            {
              'id': '1',
              'user_id': 'ana',
              'title': 'Mío',
              'credential_code': 'ABC',
            },
            {
              'id': '2',
              'user_id': 'luis',
              'title': 'Ajeno',
              'credential_code': 'XYZ',
            },
          ];
      expect((await repository.notifications()).single.title, 'Mío');
      expect((await repository.certificates()).single.code, 'ABC');
      expect(
        requests.every((r) => r.uri.queryParameters['user_id'] == 'eq.ana'),
        isTrue,
      );
    },
  );
  test(
    'lectura actualiza solo aviso propio y no modifica otros campos',
    () async {
      response =
          (_) => [
            {'id': 'n1'},
          ];
      await repository.markRead('n1');
      final request = requests.single;
      expect(request.method, 'PATCH');
      expect(request.uri.queryParameters['user_id'], 'eq.ana');
      expect(request.uri.queryParameters['id'], 'eq.n1');
      expect(request.body.keys.toList(), ['read_at']);
      expect(DateTime.tryParse(request.body['read_at']), isNotNull);
    },
  );
  test('lectura rechazada silenciosamente por RLS no se confirma', () async {
    response = (_) => [];
    await expectLater(repository.markRead('n1'), throwsStateError);
  });
  test(
    'reseñas públicas piden solo visibles y proyectan datos públicos',
    () async {
      await repository.reviews('c1');
      expect(requests.single.uri.queryParameters['is_visible'], 'eq.true');
      expect(requests.single.uri.queryParameters['course_id'], 'eq.c1');
      expect(
        requests.single.uri.queryParameters['select'],
        'author_name,rating,comment',
      );
    },
  );
  test('no publica reseña sin inscripción activa o completada', () async {
    await expectLater(
      repository.publishReview('c1', 4, 'Me gustó'),
      throwsStateError,
    );
    expect(requests.length, 1);
    expect(requests.single.method, 'GET');
    expect(
      requests.single.uri.queryParameters['status'],
      'in.("active","completed")',
    );
  });
  test('reseña autorizada envía identidad y no elude moderación', () async {
    response =
        (r) =>
            r.method == 'GET'
                ? [
                  {'course_id': 'c1'},
                ]
                : [];
    await repository.publishReview('c1', 4, '  Me gustó  ');
    expect(requests.last.method, 'POST');
    expect(requests.last.body, {
      'course_id': 'c1',
      'user_id': 'ana',
      'rating': 4,
      'comment': 'Me gustó',
    });
  });
  test('carrito de pago nunca se convierte en inscripción gratuita', () async {
    const course = Course(
      id: 'c1',
      title: '',
      description: '',
      category: '',
      imageUrl: '',
      price: 100,
    );
    await expectLater(
      SupabaseLearningRepository(client, enabled: true).enrollFree(course),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test('progreso de una lección ajena se rechaza antes de escribir', () async {
    response =
        (r) => switch (r.uri.path.split('/').last) {
          'course_enrollments' => [
            {'course_id': 'c1'},
          ],
          'course_modules' => [
            {'id': 'm1', 'title': 'Módulo'},
          ],
          'course_lessons' => [
            {'id': 'l1', 'module_id': 'm1', 'title': 'Lección'},
          ],
          _ => [],
        };
    await expectLater(
      repository.completeLesson('c1', 'otra'),
      throwsStateError,
    );
    expect(requests.every((r) => r.method == 'GET'), isTrue);
    await repository.completeLesson('c1', 'l1');
    expect(requests.last.method, 'POST');
    expect(
      requests.last.uri.queryParameters['on_conflict'],
      'user_id,lesson_id',
    );
    expect(requests.last.body['user_id'], 'ana');
    expect(requests.last.body['lesson_id'], 'l1');
  });
}

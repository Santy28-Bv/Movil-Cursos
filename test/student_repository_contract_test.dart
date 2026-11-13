import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:academix/services/academix_api.dart';
import 'package:academix/models/course.dart';
import 'package:academix/repositories/course_repository.dart';
import 'package:academix/repositories/learning_repository.dart';
import 'package:academix/repositories/profile_repository.dart';
import 'package:academix/repositories/student_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String testSession(String id) => jsonEncode({
  'access_token': 'token-$id',
  'refresh_token': 'refresh-$id',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': id,
    'email': '$id@example.test',
    'app_metadata': {},
    'user_metadata': {},
    'aud': 'authenticated',
    'created_at': '2026-11-12T00:00:00Z',
  },
});
void main() {
  late HttpServer server;
  late SupabaseClient client;
  late AcademixApi api;
  late List<({String method, Uri uri, dynamic body, String? auth})> requests;
  late FutureOr<dynamic> Function(HttpRequest) respond;
  setUp(() async {
    requests = [];
    respond = (_) => {'success': true, 'data': []};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      final text = await utf8.decoder.bind(r).join();
      requests.add((
        method: r.method,
        uri: r.uri,
        body: text.isEmpty ? null : jsonDecode(text),
        auth: r.headers.value('authorization'),
      ));
      final result = await respond(r);
      r.response.headers.contentType = ContentType.json;
      if (result != null) r.response.write(jsonEncode(result));
      await r.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth.setInitialSession(testSession('ana'));
    api = AcademixApi(
      client,
      baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
    );
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test('catálogo usa la API pública paginada y no envía token', () async {
    respond =
        (_) => {
          'success': true,
          'data': [
            {'id': 'c1', 'title': 'Dart', 'price': 0},
          ],
          'pagination': {'page': 2, 'limit': 10, 'total': 21},
        };
    final page = await ApiCourseRepository(
      client,
      api: api,
    ).fetchPublished(offset: 10, limit: 10, search: 'Flutter');
    expect(page.items.single.id, 'c1');
    expect(page.hasMore, isTrue);
    expect(requests.single.uri.path, '/api/v1/courses');
    expect(requests.single.uri.queryParameters, {
      'page': '2',
      'limit': '10',
      'search': 'Flutter',
    });
    expect(requests.single.auth, isNull);
  });
  test(
    'catálogo vacío permanece vacío y un error nunca produce demos',
    () async {
      respond =
          (_) => {
            'success': true,
            'data': [],
            'pagination': {'page': 1, 'limit': 10, 'total': 0},
          };
      final repo = ApiCourseRepository(client, api: api);
      expect((await repo.fetchPublished(offset: 0, limit: 10)).items, isEmpty);
      respond = (r) {
        r.response.statusCode = 502;
        return {
          'success': false,
          'error': {
            'code': 'DATABASE_ERROR',
            'message': 'database credentials',
          },
        };
      };
      await expectLater(
        repo.fetchPublished(offset: 0, limit: 10),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'mensaje',
            isNot(contains('credentials')),
          ),
        ),
      );
    },
  );
  test(
    'perfil escribe campos web sin permitir cambiar identidad o rol',
    () async {
      respond =
          (_) => {
            'success': true,
            'data': {
              'id': 'ana',
              'fullName': 'Ana editada',
              'email': 'ana@example.test',
            },
          };
      final repo = ProfileRepository(client, api: api);
      expect((await repo.get())['fullName'], 'Ana editada');
      await repo.update('ana', {
        'fullName': 'Ana editada',
        'phone': '123',
        'country': 'México',
        'bio': 'Estudiante',
      });
      expect(requests.last.uri.path, '/api/v1/users/me');
      expect(requests.last.method, 'PATCH');
      expect(requests.last.body, {
        'fullName': 'Ana editada',
        'phone': '123',
        'country': 'México',
        'bio': 'Estudiante',
      });
      expect(requests.last.auth, 'Bearer token-ana');
      await expectLater(
        repo.update('ana', {'role': 'admin'}),
        throwsArgumentError,
      );
      expect(requests.length, 2);
    },
  );
  test('descarta respuestas de la cuenta anterior', () async {
    final received = Completer<void>();
    final release = Completer<void>();
    respond = (_) async {
      received.complete();
      await release.future;
      return {
        'success': true,
        'data': {'id': 'ana', 'fullName': 'Ana'},
      };
    };
    final load = ProfileRepository(client, api: api).get();
    final expected = expectLater(
      load,
      throwsA(
        isA<ApiException>().having((e) => e.code, 'código', 'SESSION_CHANGED'),
      ),
    );
    await received.future;
    await client.auth.setInitialSession(testSession('luis'));
    release.complete();
    await expected;
    expect(client.auth.currentUser?.id, 'luis');
  });
  test(
    'inscripción y progreso usan las operaciones web con el JWT propio',
    () async {
      respond = (r) {
        if (r.uri.path.endsWith('/progress')) {
          r.response.statusCode = 204;
          return null;
        }
        return {
          'success': true,
          'data': {
            'course': {'id': 'c1', 'title': 'Dart', 'price': 0},
            'status': 'in_progress',
            'totalLessons': 1,
            'completedLessons': 0,
            'progressPercentage': 0,
          },
        };
      };
      final learning = LearningRepository(client, api: api);
      final result = await learning.enroll(
        Course.fromJson({'id': 'c1', 'title': 'Dart', 'price': 0}),
      );
      expect(result.course.id, 'c1');
      await learning.setProgress('l1', true);
      expect(requests.map((r) => r.method), ['POST', 'PATCH']);
      expect(requests.first.uri.path, '/api/v1/courses/c1/enrollments');
      expect(requests.last.body, {'completed': true});
      expect(requests.every((r) => r.auth == 'Bearer token-ana'), isTrue);
    },
  );
  test('recursos rechazan rutas externas antes de enviar el JWT', () async {
    await expectLater(
      api.binary('https://attacker.test/video'),
      throwsA(isA<ApiException>()),
    );
    expect(requests, isEmpty);
    expect(
      api.endpoint('/api/v1/lessons/l1/resources/r1/content').path,
      '/api/v1/lessons/l1/resources/r1/content',
    );
  });
  test('el límite de espera incluye la recepción de cabeceras', () async {
    final received = Completer<void>();
    final release = Completer<void>();
    respond = (_) async {
      received.complete();
      await release.future;
      return {'success': true, 'data': []};
    };
    final bounded = AcademixApi(
      client,
      baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
      timeout: const Duration(milliseconds: 40),
    );
    try {
      await expectLater(
        bounded.get('/slow').timeout(const Duration(milliseconds: 300)),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR'),
        ),
      );
      expect(received.isCompleted, isTrue);
    } finally {
      release.complete();
    }
  });
  test('reseñas, avisos y certificados usan endpoints compartidos', () async {
    respond =
        (r) => {
          'success': true,
          'data': [],
          if (r.uri.path.endsWith('/reviews') ||
              r.uri.path.endsWith('/certificates'))
            'pagination': {'page': 1, 'limit': 10, 'total': 0},
        };
    final repo = StudentRepository(client, api: api);
    await repo.reviews('c1');
    await repo.notifications();
    await repo.certificatesPage();
    await repo.markRead('n1');
    expect(requests.map((r) => r.uri.path), [
      '/api/v1/courses/c1/reviews',
      '/api/v1/notifications',
      '/api/v1/users/me/certificates',
      '/api/v1/notifications/n1/read',
    ]);
    expect(requests.first.auth, isNull);
    expect(requests.last.auth, 'Bearer token-ana');
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:academix/screens/services/auth_service.dart';
import 'package:academix/services/academix_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late AuthService service;
  late List<({String path, dynamic body, String? token})> requests;
  late bool active;
  final user = {
    'id': 'ana',
    'email': 'ana@example.test',
    'aud': 'authenticated',
    'app_metadata': {},
    'user_metadata': {},
    'created_at': '2026-11-13T00:00:00Z',
  };
  setUp(() async {
    active = true;
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      final text = await utf8.decoder.bind(r).join();
      requests.add((
        path: r.uri.path,
        body: text.isEmpty ? null : jsonDecode(text),
        token: r.headers.value('authorization'),
      ));
      r.response.headers.contentType = ContentType.json;
      dynamic data;
      if (r.uri.path.endsWith('/signup')) {
        data = user;
      } else if (r.uri.path.endsWith('/token')) {
        data = {
          'access_token': 'local-token',
          'refresh_token': 'local-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': user,
        };
      } else if (r.uri.path.endsWith('/logout')) {
        r.response.statusCode = 204;
      } else if (r.uri.path.endsWith('/auth/me')) {
        if (!active) r.response.statusCode = 403;
        data =
            active
                ? {
                  'success': true,
                  'data': {
                    'id': 'ana',
                    'fullName': 'Ana desde la web',
                    'role': 'student',
                  },
                }
                : {
                  'success': false,
                  'error': {
                    'code': 'ACCOUNT_INACTIVE',
                    'message': 'Tu cuenta está desactivada.',
                  },
                };
      } else {
        data = {'success': true, 'data': {}};
      }
      if (data != null) r.response.write(jsonEncode(data));
      await r.response.close();
    });
    final base = 'http://127.0.0.1:${server.port}';
    client = SupabaseClient(
      base,
      'local-test-key',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    service = AuthService(
      client: client,
      api: AcademixApi(client, baseUrl: '$base/api/v1'),
    );
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test(
    'registro usa full_name como la web y espera confirmación de correo',
    () async {
      final response = await service.register(
        nombres: ' Ana ',
        apellidoPaterno: ' Pérez ',
        apellidoMaterno: ' López ',
        email: 'ana@example.test',
        password: 'password123',
      );
      expect(response.session, isNull);
      expect(response.user?.id, 'ana');
      expect(requests.single.body['data'], {'full_name': 'Ana Pérez López'});
    },
  );
  test(
    'registro rechaza contraseñas fuera del contrato web antes de escribir',
    () async {
      await expectLater(
        service.register(
          nombres: 'Ana',
          apellidoPaterno: 'Pérez',
          email: 'ana@example.test',
          password: '123456',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(requests, isEmpty);
    },
  );
  test(
    'login confirma con el backend la cuenta autenticada por Supabase',
    () async {
      await service.login(email: 'ana@example.test', password: 'password123');
      expect(client.auth.currentUser?.id, 'ana');
      expect(requests.last.path, '/api/v1/auth/me');
      expect(requests.last.token, 'Bearer local-token');
    },
  );
  test('cuenta desactivada no conserva acceso tras el login', () async {
    active = false;
    await expectLater(
      service.login(email: 'ana@example.test', password: 'password123'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'ACCOUNT_INACTIVE'),
      ),
    );
    expect(client.auth.currentUser, isNull);
  });
  test(
    'recuperación usa respuesta neutra y el endpoint compartido web',
    () async {
      await service.requestPasswordReset('ana@example.test');
      expect(requests.single.path, '/api/v1/auth/password-reset');
      expect(requests.single.body, {'email': 'ana@example.test'});
    },
  );
}

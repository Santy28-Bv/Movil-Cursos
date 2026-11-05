import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:academix/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String sessionFor(String id) => jsonEncode({
  'access_token': 'token-$id',
  'refresh_token': 'refresh-$id',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': id,
    'app_metadata': {},
    'user_metadata': {'nombres': id},
    'aud': 'authenticated',
    'created_at': '2026-11-03T00:00:00Z',
  },
});

void main() {
  test('guardado tardío de Ana nunca reemplaza usuario de Luis', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<void>();
    final release = Completer<void>();
    server.listen((request) async {
      await request.drain<void>();
      received.complete();
      await release.future;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'id': 'ana',
          'app_metadata': {},
          'user_metadata': {'nombres': 'Ana editada'},
          'aud': 'authenticated',
          'created_at': '2026-11-03T00:00:00Z',
        }),
      );
      await request.response.close();
    });
    SupabaseClient makeClient() => SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final shared = makeClient();
    addTearDown(() async {
      await shared.dispose();
      await server.close(force: true);
    });
    await shared.auth.setInitialSession(sessionFor('ana'));
    final repository = ProfileRepository(shared, createIsolated: makeClient);
    final save = repository.update('ana', {'nombres': 'Ana editada'});
    final expected = expectLater(save, throwsStateError);
    await received.future;
    await shared.auth.setInitialSession(sessionFor('luis'));
    release.complete();
    await expected;
    expect(shared.auth.currentUser?.id, 'luis');
    expect(shared.auth.currentUser?.userMetadata?['nombres'], 'luis');
    expect(shared.auth.currentSession?.accessToken, 'token-luis');
  });
}

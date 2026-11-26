import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_settings.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.code = 'UNKNOWN_ERROR',
    this.status = 0,
  });
  final String message;
  final String code;
  final int status;
  @override
  String toString() => message;
}

String studentError(
  Object? error, [
  String fallback = 'No pudimos completar la operación. Intenta nuevamente.',
]) => error is ApiException ? error.message : fallback;

class ApiPage {
  const ApiPage(this.items, this.page, this.limit, this.total);
  final List<Map<String, dynamic>> items;
  final int page;
  final int limit;
  final int total;
  bool get hasMore => page * limit < total;
}

class ApiBinary {
  const ApiBinary(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
}

/// Mismo sobre y endpoints que CursosWeb. Supabase se usa solo para la sesión.
class AcademixApi {
  AcademixApi(
    this.client, {
    String? baseUrl,
    http.Client? transport,
    this.timeout = const Duration(seconds: 25),
  }) : base = Uri.parse(
         (baseUrl ?? ApiSettings.baseUrl).replaceFirst(RegExp(r'/+$'), ''),
       ),
       _transport = transport;
  final SupabaseClient client;
  final Uri base;
  final http.Client? _transport;
  final Duration timeout;

  Uri endpoint(String path, [Map<String, String> query = const {}]) {
    if (base.host.isEmpty) {
      throw const ApiException(
        'Esta versión de la app requiere una dirección HTTPS de Academix.',
        code: 'API_NOT_CONFIGURED',
      );
    }
    final relative = Uri.parse(path);
    if (!['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasQuery ||
        relative.hasFragment ||
        relative.pathSegments.any((p) => p == '..' || p == '.')) {
      throw const ApiException(
        'No pudimos abrir este recurso.',
        code: 'INVALID_PATH',
      );
    }
    final prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    var clean = relative.path;
    if (clean.startsWith('$prefix/') && prefix.isNotEmpty) {
      clean = clean.substring(prefix.length);
    }
    if (!clean.startsWith('/')) clean = '/$clean';
    return base.replace(
      path: '$prefix$clean',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, String> query = const {},
    bool authenticated = true,
  }) async =>
      (await _json(
        'GET',
        path,
        query: query,
        authenticated: authenticated,
      ))['data'];
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async =>
      (await _json('POST', path, body: body))['data'];
  Future<dynamic> postPublic(String path, Map<String, dynamic> body) async =>
      (await _json('POST', path, body: body, authenticated: false))['data'];
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async =>
      (await _json('PATCH', path, body: body))['data'];

  Future<ApiPage> page(
    String path, {
    Map<String, String> query = const {},
    bool authenticated = true,
  }) async {
    final result = await _json(
      'GET',
      path,
      query: query,
      authenticated: authenticated,
    );
    final pagination = result['pagination'];
    if (result['data'] is! List ||
        pagination is! Map ||
        pagination['page'] is! int ||
        pagination['limit'] is! int ||
        pagination['total'] is! int ||
        pagination['page'] < 1 ||
        pagination['limit'] < 1 ||
        pagination['total'] < 0) {
      throw const ApiException(
        'No pudimos cargar la lista. Intenta nuevamente.',
        code: 'INVALID_RESPONSE',
      );
    }
    return ApiPage(
      jsonRows(result['data']),
      pagination['page'],
      pagination['limit'],
      pagination['total'],
    );
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final firstCatalog =
        path == '/courses' &&
        query['page'] == '1' &&
        query['limit'] == '10' &&
        query.keys.every((key) => key == 'page' || key == 'limit');
    final cacheable =
        method == 'GET' &&
        !authenticated &&
        (firstCatalog || path == '/courses/featured' || path == '/categories');
    final owner = client.auth.currentUser?.id;
    final library =
        method == 'GET' &&
        authenticated &&
        owner != null &&
        path == '/users/me/courses' &&
        query['page'] == '1' &&
        query['limit'] == '10' &&
        query.keys.every(
          (name) => ['page', 'limit', 'status'].contains(name),
        ) &&
        [null, 'in_progress', 'completed'].contains(query['status']);
    final generation = _libraryGeneration;
    bool sameOwner() =>
        !library ||
        (client.auth.currentUser?.id == owner &&
            _libraryGeneration == generation);
    final key =
        library
            ? '${_libraryPrefix(owner)}${query['status'] ?? 'all'}'
            : cacheable
            ? 'academix.public.v1:${endpoint(path, query)}'
            : null;
    late final http.Response response;
    try {
      response = await _send(
        method,
        path,
        query: query,
        body: body,
        authenticated: authenticated,
      );
    } on ApiException catch (error) {
      if (key != null && sameOwner() && error.code == 'NETWORK_ERROR') {
        final saved = await _readPublicSnapshot(key);
        if (saved != null && sameOwner()) return saved;
      }
      rethrow;
    }
    if (key != null && [502, 503, 504].contains(response.statusCode)) {
      final saved = await _readPublicSnapshot(key);
      if (saved != null && sameOwner()) return saved;
    }
    if (response.statusCode == 204) return {'success': true, 'data': null};
    dynamic payload;
    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const ApiException(
        'No pudimos leer la respuesta. Intenta nuevamente.',
        code: 'INVALID_RESPONSE',
      );
    }
    if (payload is! Map<String, dynamic> ||
        payload['success'] != true ||
        response.statusCode >= 400) {
      final error = payload is Map ? payload['error'] : null;
      final code =
          error is Map
              ? '${error['code'] ?? 'UNKNOWN_ERROR'}'
              : 'UNKNOWN_ERROR';
      var message = error is Map ? '${error['message'] ?? ''}' : '';
      if (response.statusCode >= 500 ||
          message.isEmpty ||
          RegExp(
            r'supabase|postgres|sql|database|stack|node_modules|backend|\bapi\b',
            caseSensitive: false,
          ).hasMatch(message)) {
        message = 'No pudimos completar la operación. Intenta nuevamente.';
      }
      if (response.statusCode == 401) {
        message = 'Tu sesión venció. Inicia sesión nuevamente.';
      }
      throw ApiException(message, code: code, status: response.statusCode);
    }
    if (!payload.containsKey('data')) {
      throw const ApiException(
        'No pudimos leer la respuesta.',
        code: 'INVALID_RESPONSE',
      );
    }
    if (key != null &&
        payload['data'] is List &&
        (!(firstCatalog || library) || payload['pagination'] is Map)) {
      try {
        final prefs = SharedPreferencesAsync();
        if (sameOwner()) {
          await prefs.setString(key, jsonEncode(payload));
          if (!sameOwner()) await prefs.remove(key);
        }
      } catch (_) {
        // A storage failure does not prevent online browsing.
      }
    }
    return payload;
  }

  static int _libraryGeneration = 0;

  String _libraryPrefix(String owner) => 'academix.library.v1:$base:$owner:';

  Future<void> clearLibrary(String owner) async {
    _libraryGeneration++;
    final prefs = SharedPreferencesAsync();
    for (final status in ['all', 'in_progress', 'completed']) {
      await prefs.remove('${_libraryPrefix(owner)}$status');
    }
  }

  Future<Map<String, dynamic>?> _readPublicSnapshot(String key) async {
    try {
      final value = await SharedPreferencesAsync().getString(key);
      if (value == null) return null;
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic> &&
          decoded['success'] == true &&
          decoded['data'] is List) {
        return decoded;
      }
    } catch (_) {
      // Corrupt or unavailable snapshots require a successful network read.
    }
    return null;
  }

  Future<ApiBinary> binary(String path) async {
    final response = await _send('GET', path);
    if (response.statusCode >= 400) {
      throw ApiException(
        'No pudimos abrir el recurso. Comprueba tu acceso e intenta nuevamente.',
        status: response.statusCode,
      );
    }
    return ApiBinary(
      response.bodyBytes,
      response.headers['content-type'] ?? 'application/octet-stream',
    );
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final owner = client.auth.currentUser?.id;
    final token = client.auth.currentSession?.accessToken;
    if (authenticated && (owner == null || token == null)) {
      throw const ApiException(
        'Inicia sesión para continuar.',
        code: 'AUTH_REQUIRED',
        status: 401,
      );
    }
    var changed = false;
    final subscription =
        authenticated
            ? client.auth.onAuthStateChange.listen(
              (state) {
                if (state.session?.user.id != owner ||
                    state.event == AuthChangeEvent.signedOut) {
                  changed = true;
                }
              },
              onError: (Object error, StackTrace stack) {
                // Una renovación sin conexión no cambia la identidad.
                // La petición HTTP y el evento signedOut resuelven sus propios errores.
              },
            )
            : null;
    final transport = _transport ?? http.Client();
    try {
      final request = http.Request(method, endpoint(path, query))
        ..followRedirects = false;
      request.headers['Accept'] = 'application/json';
      if (authenticated) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await transport
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (authenticated && (changed || client.auth.currentUser?.id != owner)) {
        throw const ApiException(
          'Tu sesión cambió. Vuelve al inicio.',
          code: 'SESSION_CHANGED',
        );
      }
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const ApiException(
          'No pudimos abrir este recurso.',
          code: 'UNEXPECTED_REDIRECT',
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'No pudimos comunicarnos con Academix. Revisa tu conexión e intenta nuevamente.',
        code: 'NETWORK_ERROR',
      );
    } finally {
      // cancel detiene los eventos de forma síncrona. No abrir otra espera
      // después de comprobar la identidad y antes de entregar la respuesta.
      if (subscription != null) unawaited(subscription.cancel());
      if (_transport == null) transport.close();
    }
  }
}

List<Map<String, dynamic>> jsonRows(dynamic value) {
  if (value is! List || value.any((row) => row is! Map)) {
    throw const ApiException(
      'No pudimos leer la lista.',
      code: 'INVALID_RESPONSE',
    );
  }
  return value.map((row) => Map<String, dynamic>.from(row as Map)).toList();
}

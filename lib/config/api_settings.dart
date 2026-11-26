import 'package:flutter/foundation.dart';

class ApiSettings {
  static const _publicApi = 'https://academix-api-eioa.onrender.com/api/v1';
  static const _configured = String.fromEnvironment('ACADEMIX_API_URL');

  /// La misma base que VITE_API_URL en CursosWeb, incluido /api/v1.
  static String get baseUrl {
    final configured = _configured.trim();
    if (kReleaseMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      if (configured.isEmpty) return _publicApi;
      final url = Uri.tryParse(configured);
      if (url == null ||
          url.scheme != 'https' ||
          url.host.isEmpty ||
          const {
            'localhost',
            '127.0.0.1',
            '::1',
            '10.0.2.2',
          }.contains(url.host) ||
          url.path.replaceFirst(RegExp(r'/+$'), '') != '/api/v1') {
        return '';
      }
    }
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}

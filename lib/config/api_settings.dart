import 'package:flutter/foundation.dart';

class ApiSettings {
  static const _configured = String.fromEnvironment('ACADEMIX_API_URL');

  /// La misma base que VITE_API_URL en CursosWeb, incluido /api/v1.
  static String get baseUrl {
    if (_configured.trim().isNotEmpty) return _configured.trim();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}

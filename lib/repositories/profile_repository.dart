import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/academix_api.dart';

class ProfileRepository {
  ProfileRepository(this.client, {AcademixApi? api})
    : api = api ?? AcademixApi(client);
  final SupabaseClient client;
  final AcademixApi api;
  Future<Map<String, dynamic>> get() async {
    final owner = client.auth.currentUser?.id;
    final profile = Map<String, dynamic>.from(
      await api.get('/users/me') as Map,
    );
    if (owner == null ||
        profile['id'] != owner ||
        client.auth.currentUser?.id != owner) {
      throw const ApiException(
        'Tu sesión cambió. Vuelve al inicio.',
        code: 'SESSION_CHANGED',
      );
    }
    return profile;
  }

  Future<Map<String, dynamic>> update(
    String owner,
    Map<String, String> fields,
  ) async {
    if (client.auth.currentUser?.id != owner) {
      throw const ApiException(
        'Tu sesión cambió. Vuelve al inicio.',
        code: 'SESSION_CHANGED',
      );
    }
    const allowed = {'fullName', 'phone', 'country', 'bio'};
    if (fields.isEmpty || fields.keys.any((key) => !allowed.contains(key))) {
      throw ArgumentError('Campo de perfil no permitido.');
    }
    final profile = Map<String, dynamic>.from(
      await api.patch('/users/me', fields) as Map,
    );
    if (profile['id'] != owner || client.auth.currentUser?.id != owner) {
      throw const ApiException(
        'Tu sesión cambió. Vuelve al inicio.',
        code: 'SESSION_CHANGED',
      );
    }
    return profile;
  }
}

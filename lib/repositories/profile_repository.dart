import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_settings.dart';

/// La petición usa un cliente aislado: GoTrue.updateUser modifica la sesión
/// al terminar, por lo que una respuesta tardía de A no debe modificar a B.
class ProfileRepository {
  ProfileRepository(this.client, {SupabaseClient Function()? createIsolated})
    : _createIsolated =
          createIsolated ??
          (() => SupabaseClient(
            SupabaseSettings.url,
            SupabaseSettings.publishableKey,
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ));
  final SupabaseClient client;
  final SupabaseClient Function() _createIsolated;

  Future<void> update(String owner, Map<String, String> fields) async {
    final session = client.auth.currentSession;
    if (session == null || session.user.id != owner) {
      throw StateError('La cuenta cambió.');
    }
    const allowed = {
      'nombres',
      'apellido_paterno',
      'apellido_materno',
      'telefono',
    };
    if (fields.keys.any((key) => !allowed.contains(key))) {
      throw ArgumentError('Campo de perfil no permitido.');
    }
    var changed = false;
    final subscription = client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != owner) changed = true;
    });
    final isolated = _createIsolated();
    try {
      await isolated.auth.setInitialSession(jsonEncode(session.toJson()));
      final response = await isolated.auth.updateUser(
        UserAttributes(data: fields),
      );
      final live = client.auth.currentSession;
      if (changed || live == null || live.user.id != owner) {
        throw StateError('La cuenta cambió.');
      }
      if (response.user?.id != owner) {
        throw StateError('No se confirmó el cambio.');
      }
      // Inicialización en memoria síncrona: sin petición de red entre la
      // comprobación de identidad y la reconciliación de los datos del perfil.
      await client.auth.setInitialSession(
        jsonEncode(live.copyWith(user: response.user).toJson()),
      );
    } finally {
      await subscription.cancel();
      await isolated.dispose();
    }
  }
}

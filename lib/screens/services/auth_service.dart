import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/academix_api.dart';

class AuthService {
  AuthService({SupabaseClient? client, AcademixApi? api})
    : _supabase = client ?? Supabase.instance.client,
      _api = api ?? AcademixApi(client ?? Supabase.instance.client);
  final SupabaseClient _supabase;
  final AcademixApi _api;

  // INICIAR SESIÓN
  Future<void> login({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('No se pudo iniciar sesión.');
    }
    try {
      await _api.get('/auth/me');
    } catch (_) {
      await _supabase.auth.signOut(scope: SignOutScope.local);
      rethrow;
    }
  }

  // REGISTRAR CUENTA
  Future<AuthResponse> register({
    required String nombres,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String email,
    required String password,
  }) async {
    final fullName = [
      nombres,
      apellidoPaterno,
      apellidoMaterno ?? '',
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');
    if (fullName.isEmpty ||
        fullName.length > 100 ||
        password.length < 8 ||
        password.length > 72) {
      throw const AuthException(
        'Escribe tu nombre (máximo 100 caracteres) y una contraseña de 8 a 72 caracteres.',
      );
    }
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    // Misma operación web. No revela si la dirección existe.
    await _api.postPublic('/auth/password-reset', {'email': email.trim()});
  }

  // CERRAR SESIÓN
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // USUARIO ACTUAL
  User? get currentUser => _supabase.auth.currentUser;

  bool get isAuthenticated => currentUser != null;
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // INICIAR SESIÓN
  Future<void> login({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('No se pudo iniciar sesión.');
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
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nombres': nombres.trim(),
        'apellido_paterno': apellidoPaterno.trim(),
        'apellido_materno': apellidoMaterno?.trim(),
      },
    );
  }

  // CERRAR SESIÓN
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // USUARIO ACTUAL
  User? get currentUser => _supabase.auth.currentUser;

  bool get isAuthenticated => currentUser != null;
}

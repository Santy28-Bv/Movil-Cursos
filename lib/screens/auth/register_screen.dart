import 'package:academix/screens/services/auth_service.dart';
import 'package:academix/widgets/home/auth/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombres = TextEditingController();
  final _apellidoPaterno = TextEditingController();
  final _apellidoMaterno = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _auth = AuthService();

  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nombres.dispose();
    _apellidoPaterno.dispose();
    _apellidoMaterno.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await _auth.register(
        nombres: _nombres.text,
        apellidoPaterno: _apellidoPaterno.text,
        apellidoMaterno: _apellidoMaterno.text,
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;

      final needsConfirmation = response.session == null;

      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Registro exitoso'),
              content: Text(
                needsConfirmation
                    ? 'Revisa tu correo electrónico para '
                        'confirmar tu cuenta antes de iniciar sesión.'
                    : 'Tu cuenta de Academix fue creada correctamente.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );

      if (!mounted) return;

      // Informar a la pantalla anterior si ya existe una sesión.
      Navigator.of(context).pop(!needsConfirmation);
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear la cuenta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crear cuenta',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthInput(
              label: 'Nombre(s)',
              hint: 'Tus nombres',
              controller: _nombres,
              validator: _required,
            ),

            const SizedBox(height: 18),

            AuthInput(
              label: 'Apellido paterno',
              hint: 'Tu apellido paterno',
              controller: _apellidoPaterno,
              validator: _required,
            ),

            const SizedBox(height: 18),

            AuthInput(
              label: 'Apellido materno (opcional)',
              hint: 'Tu apellido materno',
              controller: _apellidoMaterno,
            ),

            const SizedBox(height: 18),

            AuthInput(
              label: 'Correo electrónico',
              hint: 'tu@correo.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            AuthInput(
              label: 'Contraseña',
              hint: 'Mínimo 6 caracteres',
              controller: _password,
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AuthColors.muted,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            AuthInput(
              label: 'Confirmar contraseña',
              hint: 'Repite tu contraseña',
              controller: _confirmPassword,
              obscureText: !_showPassword,
              validator: (value) {
                if (value != _password.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: AuthColors.purple,
                  disabledBackgroundColor: AuthColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    _loading
                        ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '¿Ya tienes cuenta? Inicia sesión',
                style: TextStyle(color: Color(0xFFC4B5FD)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

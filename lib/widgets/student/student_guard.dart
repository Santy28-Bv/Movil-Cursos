import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Desmonta datos y formularios cuando cambia la identidad de la ruta.
/// Una respuesta tardía ya no puede mostrar datos de la cuenta anterior.
class StudentGuard extends StatefulWidget {
  const StudentGuard({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  State<StudentGuard> createState() => _StudentGuardState();
}

class _StudentGuardState extends State<StudentGuard> {
  late final String? _owner;
  late final StreamSubscription<AuthState> _subscription;
  bool _valid = true;
  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _owner = auth.currentUser?.id;
    _subscription = auth.onAuthStateChange.listen((state) {
      if (mounted && state.session?.user.id != _owner) {
        setState(() => _valid = false);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_valid &&
        _owner != null &&
        Supabase.instance.client.auth.currentUser?.id == _owner) {
      return widget.builder(context);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Tu sesión cambió. Vuelve al inicio para continuar con tu cuenta.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

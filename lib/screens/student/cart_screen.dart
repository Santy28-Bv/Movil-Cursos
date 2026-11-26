import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/learning_repository.dart';
import '../../services/academix_api.dart';
import '../../services/student_session.dart';
import '../../widgets/student/student_guard.dart';
import '../courses/my_courses_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.session, this.repository});

  final StudentSession? session;
  final LearningRepository? repository;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final _session = widget.session ?? StudentSession.instance;
  late final _repository =
      widget.repository ?? LearningRepository(Supabase.instance.client);
  bool _checkingOwnership = false;
  bool _confirming = false;
  bool _alreadyOwned = false;
  String? _ownershipError;
  String? _checkoutError;
  CheckoutReceipt? _receipt;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final ids = _session.cart.map((course) => course.id).toList();
    if (ids.isEmpty || _session.checkingOut || _checkingOwnership) return;
    setState(() {
      _checkingOwnership = true;
      _ownershipError = null;
    });
    try {
      final owned = await _repository.ownedCourseIds(ids);
      if (!mounted || owned.isEmpty) return;
      _session.removeFromCartIds(owned);
      setState(() => _alreadyOwned = true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _ownershipError = studentError(
            error,
            'No pudimos comprobar cuáles cursos ya tienes.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _checkingOwnership = false);
    }
  }

  Future<void> _confirm() async {
    if (_confirming || _session.checkingOut || _session.cart.isEmpty) return;
    setState(() => _confirming = true);
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Confirmar compra simulada'),
            content: const Text(
              'Activarás el acceso a los cursos en tu cuenta. '
              'El servidor calculará el total y no se realizará ningún cobro.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    setState(() {
      _confirming = false;
      _checkoutError = null;
    });
    if (confirm != true) return;
    try {
      final receipt = await _session.checkout(_repository.checkout);
      if (mounted && receipt != null) setState(() => _receipt = receipt);
    } catch (error) {
      if (mounted) {
        setState(() {
          _checkoutError = studentError(
            error,
            'No pudimos confirmar la compra. Tu carrito sigue disponible.',
          );
        });
      }
    }
  }

  void _openMyCourses() => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => StudentGuard(
            builder: (_) => MyCoursesScreen(repository: _repository),
          ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi carrito')),
    body: AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        final cart = _session.cart;
        final busy = _checkingOwnership || _confirming || _session.checkingOut;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_receipt case final receipt?)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Compra simulada confirmada'),
                subtitle: Text(
                  'Total confirmado: ${receipt.total.toStringAsFixed(2)} MXN. '
                  'Tus cursos ya están en tu biblioteca.',
                ),
              ),
            if (_alreadyOwned && _receipt == null)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Los cursos que ya tienes están en Mis cursos.'),
              ),
            if (_receipt != null || _alreadyOwned)
              OutlinedButton.icon(
                onPressed: _openMyCourses,
                icon: const Icon(Icons.bookmark_outline),
                label: const Text('Ir a Mis cursos'),
              ),
            if (cart.isEmpty && _receipt == null) ...[
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tu carrito está vacío.',
                  textAlign: TextAlign.center,
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver a los cursos'),
              ),
            ],
            if (_checkingOwnership) const LinearProgressIndicator(),
            for (final course in cart)
              Card(
                child: ListTile(
                  title: Text(course.title),
                  subtitle: Text('${course.priceLabel} MXN'),
                  trailing: IconButton(
                    tooltip: 'Quitar ${course.title}',
                    onPressed:
                        busy
                            ? null
                            : () {
                              setState(() => _checkoutError = null);
                              _session.removeFromCart(course.id);
                            },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            if (cart.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Total estimado: ${(_session.totalCents / 100).toStringAsFixed(2)} MXN',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Compra simulada. No se realizará ningún cobro.'),
              const SizedBox(height: 16),
              if (_ownershipError != null) ...[
                Text(_ownershipError!),
                TextButton(
                  onPressed: busy ? null : _checkOwnership,
                  child: const Text('Volver a comprobar mis cursos'),
                ),
              ],
              if (_checkoutError != null) Text(_checkoutError!),
              FilledButton.icon(
                onPressed: busy || _ownershipError != null ? null : _confirm,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  _session.checkingOut
                      ? 'Confirmando compra…'
                      : 'Comprar cursos',
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

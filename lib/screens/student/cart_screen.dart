import 'package:flutter/material.dart';
import '../../services/student_session.dart';
import '../../widgets/student/student_banner.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.session});
  final StudentSession? session;
  @override
  Widget build(BuildContext context) {
    final state = session ?? StudentSession.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi carrito')),
      body: AnimatedBuilder(
        animation: state,
        builder:
            (context, _) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const StudentBanner(
                  title: 'Tu próxima meta',
                  message:
                      'Reúne los cursos que quieres aprender y revisa tu selección.',
                ),
                Text(
                  '${state.cart.length} cursos en tu carrito',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (state.cart.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tu carrito está vacío. Explora el catálogo para añadir cursos de pago.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Explorar cursos'),
                  ),
                ],
                ...state.cart.map(
                  (course) => Card(
                    child: ListTile(
                      title: Text(course.title),
                      subtitle: Text(
                        '${course.priceLabel}${course.isDemo ? ' · Demo' : ''}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Quitar ${course.title}',
                        onPressed: () => state.removeFromCart(course.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Total: \$${(state.totalCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'La pasarela de pago aún no está disponible. Guardar cursos aquí no realiza '
                      'cobros ni genera inscripciones. Tu selección se conserva durante esta sesión.',
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

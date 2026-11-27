import 'package:flutter/material.dart';
import '../../../theme/theme_controller.dart';
import '../../student/profile_avatar.dart';

class AccountMenuSheet extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarId;
  final VoidCallback onSignOut;
  final VoidCallback onSwitchAccount;
  final VoidCallback onMyCourses;
  final VoidCallback? onInformation;
  final VoidCallback? onCertificates;
  final VoidCallback? onNotifications;
  final VoidCallback? onCart;
  final VoidCallback? onOrganizations;
  final ValueChanged<int>? onHelp;
  final VoidCallback? onPrices;
  final VoidCallback? onVerify;

  const AccountMenuSheet({
    super.key,
    required this.name,
    required this.email,
    this.avatarId,
    required this.onSignOut,
    required this.onSwitchAccount,
    required this.onMyCourses,
    this.onInformation,
    this.onCertificates,
    this.onNotifications,
    this.onCart,
    this.onOrganizations,
    this.onHelp,
    this.onPrices,
    this.onVerify,
  });

  void _closeAndRun(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  void _showInformation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Mi información',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  email,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mi cuenta',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                ProfileAvatar(avatarId: avatarId, name: name, diameter: 56),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),

            _menuTile(
              context,
              icon: Icons.person_outline,
              title: 'Mi información',
              subtitle: 'Consultar y actualizar mis datos',
              onTap:
                  onInformation == null
                      ? () => _showInformation(context)
                      : () => _closeAndRun(context, onInformation!),
            ),

            _menuTile(
              context,
              icon: Icons.menu_book_outlined,
              title: 'Mis cursos',
              subtitle: 'Consultar tu aprendizaje',
              onTap: () => _closeAndRun(context, onMyCourses),
            ),

            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),

            if (onCart != null)
              _menuTile(
                context,
                icon: Icons.shopping_cart_outlined,
                title: 'Mi carrito',
                onTap: () => _closeAndRun(context, onCart!),
              ),
            if (onCertificates != null)
              _menuTile(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'Mis certificados',
                onTap: () => _closeAndRun(context, onCertificates!),
              ),
            if (onNotifications != null)
              _menuTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                onTap: () => _closeAndRun(context, onNotifications!),
              ),

            if (onOrganizations != null)
              _menuTile(
                context,
                icon: Icons.school_outlined,
                title: 'Mis organizaciones',
                onTap: () => _closeAndRun(context, onOrganizations!),
              ),

            if (onPrices != null)
              _menuTile(
                context,
                icon: Icons.payments_outlined,
                title: 'Precios',
                onTap: () => _closeAndRun(context, onPrices!),
              ),
            if (onHelp != null) ...[
              for (var i = 0; i < 3; i++)
                _menuTile(
                  context,
                  icon:
                      [
                        Icons.info_outline,
                        Icons.help_outline,
                        Icons.mail_outline,
                      ][i],
                  title: ['Nosotros', 'Preguntas', 'Contacto'][i],
                  onTap: () => _closeAndRun(context, () => onHelp!(i)),
                ),
            ],
            if (onVerify != null)
              _menuTile(
                context,
                icon: Icons.verified_outlined,
                title: 'Verificar certificado',
                onTap: () => _closeAndRun(context, onVerify!),
              ),
            _menuTile(
              context,
              icon: Icons.contrast,
              title: 'Cambiar tema claro/oscuro',
              onTap:
                  () => _closeAndRun(context, () {
                    ThemeController.toggle();
                  }),
            ),
            _menuTile(
              context,
              icon: Icons.switch_account_outlined,
              title: 'Cambiar de cuenta',
              subtitle: 'Iniciar sesión con otra cuenta',
              onTap: () => _closeAndRun(context, onSwitchAccount),
            ),

            _menuTile(
              context,
              icon: Icons.logout,
              title: 'Cerrar sesión',
              subtitle: 'Salir de Academix',
              color: Theme.of(context).colorScheme.error,
              onTap: () => _closeAndRun(context, onSignOut),
            ),
          ],
        ),
      ),
    );
  }
}

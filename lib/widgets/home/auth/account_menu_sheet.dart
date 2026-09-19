import 'package:academix/theme/academix_colors.dart';
import 'package:flutter/material.dart';

class AccountMenuSheet extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onSignOut;
  final VoidCallback onSwitchAccount;
  final VoidCallback onMyCourses;

  const AccountMenuSheet({
    super.key,
    required this.name,
    required this.email,
    required this.onSignOut,
    required this.onSwitchAccount,
    required this.onMyCourses,
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
            backgroundColor: AcademixColors.card,
            title: const Text(
              'Mi información',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                  email,
                  style: const TextStyle(color: AcademixColors.muted),
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

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AcademixColors.lavender),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle,
                style: const TextStyle(
                  color: AcademixColors.muted,
                  fontSize: 12,
                ),
              ),
      trailing: const Icon(Icons.chevron_right, color: AcademixColors.muted),
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
            const Text(
              'Mi cuenta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF442778),
                  child: Icon(
                    Icons.person,
                    color: AcademixColors.lavender,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AcademixColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            const Divider(color: AcademixColors.border),

            _menuTile(
              icon: Icons.person_outline,
              title: 'Mi información',
              subtitle: 'Consultar datos de mi cuenta',
              onTap: () => _showInformation(context),
            ),

            _menuTile(
              icon: Icons.menu_book_outlined,
              title: 'Mis cursos',
              subtitle: 'Consultar tu aprendizaje',
              onTap: () => _closeAndRun(context, onMyCourses),
            ),

            const Divider(color: AcademixColors.border),
            const SizedBox(height: 8),

            _menuTile(
              icon: Icons.switch_account_outlined,
              title: 'Cambiar de cuenta',
              subtitle: 'Iniciar sesión con otra cuenta',
              onTap: () => _closeAndRun(context, onSwitchAccount),
            ),

            _menuTile(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              subtitle: 'Salir de Academix',
              color: const Color(0xFFFB7185),
              onTap: () => _closeAndRun(context, onSignOut),
            ),
          ],
        ),
      ),
    );
  }
}

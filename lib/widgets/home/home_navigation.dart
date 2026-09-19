import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class HomeNavigation extends StatelessWidget {
  const HomeNavigation({
    super.key,
    required this.onHome,
    required this.onCourses,
    required this.onProfile,
    this.onMyCourses,
    this.isAuthenticated = false,
  });

  final VoidCallback onHome;
  final VoidCallback onCourses;
  final VoidCallback onProfile;
  final VoidCallback? onMyCourses;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AcademixColors.card,
          border: Border(top: BorderSide(color: AcademixColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavAction(icon: Icons.home_rounded,
                    label: 'Inicio', onTap: onHome),
                _NavAction(icon: Icons.auto_stories_outlined,
                    label: 'Cursos', onTap: onCourses),
                if (isAuthenticated)
                  _NavAction(icon: Icons.bookmark_outline,
                      label: 'Mis cursos',
                      onTap: onMyCourses ?? onProfile),
                _NavAction(
                  icon: isAuthenticated
                      ? Icons.person_outline_rounded
                      : Icons.login_rounded,
                  label: isAuthenticated ? 'Cuenta' : 'Acceder',
                  onTap: onProfile,
                ),
              ],
            ),
          ),
        ),
      );
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: AcademixColors.lavender),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(
                  fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import '../student/profile_avatar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onProfile,
    this.isAuthenticated = false,
    this.avatarId,
    this.profileName = "",
    this.onNotifications,
    this.unreadCount = 0,
    this.unreadCountKnown = true,
  });

  final VoidCallback onProfile;
  final bool isAuthenticated;
  final String? avatarId;
  final String profileName;
  final VoidCallback? onNotifications;
  final int unreadCount;
  final bool unreadCountKnown;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/icon/academix_icon.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Academix',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isAuthenticated && onNotifications != null)
          IconButton(
            tooltip:
                unreadCountKnown
                    ? 'Notificaciones: $unreadCount sin leer'
                    : 'Notificaciones',
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        IconButton(
          onPressed: onProfile,
          tooltip: isAuthenticated ? 'Mi cuenta' : 'Iniciar sesión',
          icon:
              isAuthenticated && avatarId != null
                  ? ProfileAvatar(
                    avatarId: avatarId,
                    name: profileName,
                    diameter: 30,
                  )
                  : Icon(
                    isAuthenticated
                        ? Icons.account_circle_outlined
                        : Icons.login_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 27,
                  ),
        ),
      ],
    ),
  );
}

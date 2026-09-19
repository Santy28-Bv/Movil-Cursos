import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onProfile,
    this.isAuthenticated = false,
  });

  final VoidCallback onProfile;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon/academix_icon.png',
                width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text('Academix',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900)),
            ),
            IconButton(
              onPressed: onProfile,
              tooltip: isAuthenticated ? 'Mi cuenta' : 'Iniciar sesión',
              icon: Icon(
                isAuthenticated
                    ? Icons.account_circle_outlined
                    : Icons.login_rounded,
                color: Colors.white70,
                size: 27,
              ),
            ),
          ],
        ),
      );
}

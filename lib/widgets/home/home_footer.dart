import 'package:flutter/material.dart';
import '../../theme/academix_colors.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 25),
        child: Column(
          children: [
            Divider(color: AcademixColors.border),
            SizedBox(height: 19),
            Text('Academix',
                style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Democratizando el acceso a la educación digital.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AcademixColors.muted, fontSize: 12)),
            SizedBox(height: 14),
            Text('© 2026 Academix. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AcademixColors.muted, fontSize: 10)),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_settings.dart';
import 'screens/home_screen.dart';
import 'theme/academix_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseSettings.url,
    publishableKey: SupabaseSettings.publishableKey,
  );

  runApp(const AcademixApp());
}

/// La portada es pública. La sesión solo controla las funciones protegidas.
/// El login se abre como ruta independiente; nunca reemplaza la ruta raíz.
class AcademixApp extends StatelessWidget {
  const AcademixApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Academix Móvil',
        debugShowCheckedModeBanner: false,
        theme: AcademixTheme.dark,
        home: const HomeScreen(),
      );
}

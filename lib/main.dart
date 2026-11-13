import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_settings.dart';
import 'screens/home_screen.dart';
import 'theme/academix_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseSettings.url,
    publishableKey: SupabaseSettings.publishableKey,
  );

  await ThemeController.load();
  runApp(const AcademixApp());
}

/// La portada es pública. La sesión solo controla las funciones protegidas.
/// El login se abre como ruta independiente; nunca reemplaza la ruta raíz.
class AcademixApp extends StatelessWidget {
  const AcademixApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeController.mode,
    builder:
        (context, mode, _) => MaterialApp(
          title: 'Academix Móvil',
          debugShowCheckedModeBanner: false,
          theme: AcademixTheme.light,
          darkTheme: AcademixTheme.dark,
          themeMode: mode,
          home: const HomeScreen(),
        ),
  );
}

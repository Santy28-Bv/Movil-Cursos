# Academix Móvil — Catálogo CursosWeb + icono

Proyecto Flutter conectado a Supabase. El Home permanece accesible sin login.

- Usuarios visitantes: portada, búsqueda y detalles públicos.
- Usuarios autenticados: acceso a pruebas de inscripción, lecciones y ejercicios **demo**.
- Catálogo: intenta leer cursos publicados en Supabase; si todavía no está configurado,
  muestra los seis ejemplos del repositorio CursosWeb claramente señalados.
- Navbar: Inicio, Cursos, Mis cursos (con sesión) y Cuenta/Acceder.
- Identidad visual: icono en `assets/icon/academix_icon.png` y launcher de Android.

## Inicio

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

El login preexistente no se reemplazó. Sigue usando Supabase Auth en
`lib/screens/services/auth_service.dart`.

**IMPORTANTE**: los seis cursos de CursosWeb son datos de ejemplo (mock). Los
botones de inscripción y entrega de tarea funcionan *como demostración en memoria*,
no graban inscripciones, pagos o tareas reales. Consulta
`INTEGRACION_SUPABASE_PENDIENTE.md` para completar la integración con las tablas
reales y las políticas RLS correspondientes.

## Archivos agregados

- `lib/data/cursos_web_demo.dart`: muestra los 6 cursos de ejemplo de CursosWeb.
- `lib/screens/courses/course_detail_screen.dart`: detalle y temario público.
- `lib/screens/courses/lesson_screen.dart`: lección y actividad demo.
- `lib/screens/courses/my_courses_screen.dart`: progreso en memoria demo.
- `lib/services/demo_learning_store.dart`: estado de demostración por sesión.
- `assets/icon/*` y `android/app/src/main/res/*`: ícono de aplicación.

## Fuente de referencia

https://github.com/MarcoAntonioDamianOrtiz/CursosWeb

La web usa `src/data/courseMocks.ts` como catálogo temporal. No se ha
copiado ningún servicio de pago ni implementado una inscripción Supabase ficticia.

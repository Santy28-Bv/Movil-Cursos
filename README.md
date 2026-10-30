# Academix Móvil (Flutter / Supabase)

Proyecto Flutter basado visualmente en CursosWeb. Arranca en Home público,
permite login y muestra un catálogo real de Supabase cuando existe la tabla
pública configurada. Si no existe o no está disponible, presenta los cursos
**DEMO** con un aviso visible.

Incluye detalle público, aula y ejercicios demo, reproductor de video HTTPS
para las lecciones reales y adaptadores para inscripciones/tareas que requieren
confirmación del esquema de base de datos antes de habilitarse.

- `INTEGRACION_SUPABASE_PENDIENTE.md`: cómo conectar tablas/videos y permisos.
- `PENDIENTES_HISTORIAS_USUARIO.md`: seguimiento por historia.

Ejecutar:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

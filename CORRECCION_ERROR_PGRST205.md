# Corrección del error PGRST205 de Academix Móvil

La pantalla «Mis cursos» antes consultaba `public.mobile_enrollments` sin
comprobar que estuviera creada en Supabase. Esto producía la excepción
`PGRST205` al abrirla.

## Qué se ha corregido

- «Mis cursos» comprueba primero la existencia del módulo `mobile_*`. Si no
  existe, muestra «Biblioteca pendiente de configuración», sin consultar
  la tabla ausente ni simular matrículas.
- El detalle de curso no intenta inscribir ni consultar el temario `mobile_*`
  antes de verificar que el módulo está disponible.
- El Home intenta leer los cursos publicados de `mobile_courses` y, si la
  tabla no existe, usa el catálogo anterior configurado en
  `lib/config/supabase_settings.dart` (`courses` por defecto).
- Si tampoco existe la tabla `courses`, se muestra un mensaje de catálogo
  sin configurar; no se generan cursos falsos.
- Se conserva el módulo de videos, evaluaciones y certificados para cuando
  se configure el esquema real o se instale la migración incluida.

## ¿Qué no hace este parche?

No crea tablas ni modifica datos en Supabase. **Tampoco habilita inscripciones,
evaluaciones o certificados reales sin el esquema SQL adecuado.**

Si quieres compartir los datos de la web y la app, primero identifica las
nombres y relaciones reales de sus tablas en Supabase. La rama principal de
CursosWeb revisada usa un catálogo de ejemplo, no un backend de aprendizaje
completo del que se pueda copiar el esquema.

## Instalación segura

1. Haz copia de tu proyecto local antes de sobrescribir archivos.
2. Extrae el ZIP. Copia el proyecto completo o solo los archivos modificados.
3. Ejecuta `flutter pub get`, `flutter analyze`, `flutter test` y `flutter run`.
4. Abre «Mis cursos». Si falta `mobile_enrollments`, ahora verás el aviso
   informativo. En el Home se intentarán cargar cursos públicos desde `courses`.
5. Si decides utilizar el módulo independiente, **revisa** los archivos SQL
   dentro de `supabase/` antes de ejecutarlos en la BD; no los ejecutes a
   ciegas ni si ya tienes tablas equivalentes de aprendizaje.

## Archivos modificados

- `lib/config/learning_schema.dart`
- `lib/repositories/learning_repository.dart`
- `lib/repositories/course_repository.dart`
- `lib/screens/courses/my_courses_screen.dart`
- `lib/screens/courses/course_detail_screen.dart`

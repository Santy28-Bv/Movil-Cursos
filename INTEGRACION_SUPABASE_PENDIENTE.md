# Academix Móvil — Integración de cursos, videos e inscripciones

## Lo comprobado en GitHub (AcademixFull/CursosWeb)

La rama `main` del repositorio `AcademixFull/CursosWeb` utiliza `src/data/courseMocks.ts` y
`src/services/courses.service.ts`, con `VITE_DATA_SOURCE=mock` o la API REST opcional.
**No existe código en esa versión que consulte un video desde Supabase Storage o desde una tabla.**
La app Flutter usa Supabase directo como decisión del proyecto móvil. No se inventó una
implementación de video web ni se copiaron identificadores de tablas no confirmados.

## Cambios incluidos en esta entrega

- Home público y listado de cursos con paginación, preservados.
- Detalle público de curso, con control de acceso a las lecciones.
- `LessonVideoPlayer`: reproduce video HTTPS MP4/HLS con `video_player` y abre YouTube/Vimeo
  mediante `url_launcher`; incluye reproducción, pausa y barra de progreso.
- `LessonVideoService`: toma `video_url` o `url_video`, o genera un enlace **temporal**
  desde `video_bucket` + `video_path`, con autenticación Supabase y RLS de Storage.
- `SupabaseLearningRepository`: adaptador para módulos, lecciones, inscripciones gratis,
  biblioteca personal y tareas escritas; permanece **deshabilitado** hasta confirmar BD/RLS.
- Entregas reales de tareas opcionales y separadas de ejercicios demo.
- Permiso Android INTERNET en la app de producción.
- Los cursos demo de CursosWeb siguen claramente identificados y NO escriben en Supabase.

## Cómo habilitar la lectura real (después de verificar el esquema)

El archivo `lib/config/learning_schema.dart` contiene los nombres adaptables.
Si el esquema y las políticas RLS coinciden, al ejecutar Flutter se puede usar:

```bash
flutter run --dart-define=ACADEMIX_REAL_LEARNING=true
```

**No ejecutes el comando anterior sin validar que existen** `course_modules`,
`course_lessons`, `course_enrollments`, las columnas `course_id`, `module_id`, `user_id`,
y los respectivos permisos RLS. Los nombres se cambian con `--dart-define`
`ACADEMIX_MODULES_TABLE`, `ACADEMIX_LESSONS_TABLE`, `ACADEMIX_ENROLLMENTS_TABLE`,
`ACADEMIX_COURSE_FK`, `ACADEMIX_MODULE_FK`, `ACADEMIX_USER_FK`.

Las tareas solo se habilitan independientemente si las tablas y columnas de tareas y
entregas coinciden y las políticas RLS restringen la escritura a miembros autorizados:

```bash
flutter run --dart-define=ACADEMIX_REAL_LEARNING=true \
  --dart-define=ACADEMIX_REAL_SUBMISSIONS=true
```

El usuario *no* debe usar estos flags todavía sin verificar la BD. Para cursos pagados,
la app no finge compras; tampoco supone que una organización habilita el acceso a otros
cursos. Esta versión solo permite inscripción real directa cuando `price == 0` y el
usuario está autenticado (y bajo las reglas RLS de la BD).

## Información necesaria de Supabase

Enviar solamente el esquema (nombres de columnas, tipos, FK, constraints y RLS) de:

1. Cursos publicados y precios (incluida organización/beneficios institucionales).
2. Módulos, lecciones, videos y recursos. Indicar si video viene de Storage, YouTube,
   un enlace externo o una referencia a la tabla de archivos.
3. Inscripciones/matrículas y estado de acceso.
4. Tareas, entregas, progreso de lección y calificaciones.
5. Membresías y roles de organización, si se usarán cursos incluidos.

Consulta SQL **solo lectura** en el editor de Supabase:

```sql
select table_schema, table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and (table_name ilike '%curso%' or table_name ilike '%course%'
    or table_name ilike '%leccion%' or table_name ilike '%lesson%'
    or table_name ilike '%video%' or table_name ilike '%tarea%'
    or table_name ilike '%task%' or table_name ilike '%entrega%'
    or table_name ilike '%submission%' or table_name ilike '%inscri%')
order by table_name, ordinal_position;
```

**No enviar** contraseña, claves `service_role`, datos personales ni tokens.

## Probar en Windows / Git Bash

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

No se ha probado la compilación Flutter en este entorno porque no está instalado el SDK.

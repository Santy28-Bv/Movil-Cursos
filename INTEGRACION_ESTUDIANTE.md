# Academix Móvil — Parche de estudiante

Base del parche: ZIP Movil-Cursos, commit `e0fb027c537ed87c6e568aa6a0a6ac4568dafe4f`.
Referencias consultadas el 3 de noviembre de 2026:

- https://github.com/AcademixFull/CursosWeb/tree/10a68aa1c40512bea32ea044b672ee096a1144be
- https://github.com/AcademixFull/academix-backend/tree/cacd25bcbe346eb85e0e87c92ffab9207f6ee48a
- Historias móviles HU-M07 a HU-M14 del documento entregado.
- ZIP notificaciones_universitarias: patrón de estado Singleton + adaptación de avisos.

La web consultada tiene catálogo mock y panel en construcción. El backend
consultado solo expone salud. No contienen el esquema ni las operaciones del
estudiante. Este parche NO crea tablas, RPC, políticas RLS ni verificador público.
Los nombres siguientes son un contrato de integración propuesto y configurable,
no una afirmación de que existan en tu Supabase.

## Qué funciona con la configuración actual

- HU-M07: consulta y edición de nombres, apellidos y teléfono en los metadatos
  de la cuenta Supabase autenticada. El correo se consulta; no se cambia.
  La actualización usa un cliente aislado para impedir cruces de sesión al guardar.
  No sincroniza una eventual tabla `profiles` de la web, porque no está definida allí.
- HU-M08: carrito compartido durante la sesión, varios cursos de pago, quitar,
  contador y total en centavos. No hay cobros ni inscripción por añadir al carrito.
  Los cursos demo se identifican; se vacía al cerrar sesión o cambiar de cuenta.
- HU-M10: panel con cursos, filtros y métricas; prácticas demo separadas de las
  inscripciones. Las métricas reales usan inscripciones y progreso del servidor
  cuando se habilita el contrato. No se cuentan prácticas como formación real.
- HU-M11: aula demo existente, video existente y avance temporal. Las rutas
  protegidas se desmontan cuando cambia la identidad de la cuenta.
- HU-M14: pantalla, contador y estado reactivo compartido; adapta `title/body`
  y también `asunto/contenido` o `tituloAviso` del ejemplo universitario.
  Sin servidor configurado informa que el centro todavía no está conectado;
  no inventa avisos de la web ni notificaciones push.

## Qué requiere conexión del servidor

- HU-M09: inscripción real gratuita o incluida, única y con permisos comprobados.
- HU-M10/11: biblioteca y progreso persistente reales, recursos protegidos.
- HU-M12: consultar reseñas visibles y publicar reseña autenticada con acceso al
  curso, 1–5 estrellas y comentario de hasta 1000 caracteres. El servidor debe
  confirmar ese límite; si utiliza otro, ajustar `CourseReview.maxCommentLength`.
- HU-M13: listar credenciales propias emitidas por el servidor, copiar su código
  y abrir un verificador web HTTPS ya existente. No se emiten certificados en el móvil.
- HU-M14: cargar avisos propios y guardar lectura individual/global. Se confirma
  la escritura antes de actualizar el contador. No sustituye una configuración push.

Estas funciones tienen interfaz y adaptadores, pero NO están operativas contra
una base real hasta validar el siguiente contrato y sus permisos. Permanecen
apagadas de forma predeterminada. No basta con activar flags para crear la BD.

## Contrato de aprendizaje existente, ampliado

`ACADEMIX_REAL_LEARNING=true` permite el adaptador de aprendizaje una vez validado:

| Tabla predeterminada | Columnas requeridas |
|---|---|
| `courses` | `id`, `title`, `price`, campos públicos del modelo Course; `organization_id` opcional |
| `course_enrollments` | `course_id`, `user_id`, `status` (`active` o `completed`) |
| `course_modules` | `id`, `course_id`, `title`, `position` |
| `course_lessons` | `id`, `course_id`, `module_id`, `title`, `position`, `duration_minutes`, campos de contenido |

Los nombres de tablas/FK se ajustan con las opciones existentes de
`LearningSchema`. La columna de estado y sus valores son configurables con
`ACADEMIX_ENROLLMENT_STATUS_COLUMN`, `ACADEMIX_ENROLLMENT_ACTIVE_STATUS` y
`ACADEMIX_ENROLLMENT_COMPLETED_STATUS`. Inscripciones pendientes/canceladas no
otorgan acceso. Debe existir unicidad `(user_id, course_id)`; la BD debe comprobar
el precio real y la elegibilidad antes de aceptar cualquier inserción gratuita.
El precio de una tarjeta o un flag del cliente jamás constituye autorización.

Para cursos institucionales de pago con beneficio incluido, configurar
`ACADEMIX_INCLUDED_ENROLL_RPC` con el nombre de una RPC existente. Recibe
`p_course_id` y utiliza `auth.uid()`; debe comprobar membresía activa, organización
y derecho al curso, y crear/reutilizar la inscripción de forma atómica. El móvil
confirma después que exista acceso. Sin esa RPC no supone acceso institucional.

## Contrato adicional de estudiante

Solo después de validar tablas y RLS, activar `ACADEMIX_REAL_STUDENT=true`.
Usar junto con `ACADEMIX_REAL_LEARNING=true` para reseñas y progreso.

| Opción de tabla | Valor predeterminado | Columnas requeridas |
|---|---|---|
| `ACADEMIX_NOTIFICATIONS_TABLE` | `notifications` | `id`, `user_id`, `title`, `body`, `created_at`, `read_at` nullable |
| `ACADEMIX_REVIEWS_TABLE` | `course_reviews` | `course_id`, `user_id`, `author_name`, `rating`, `comment`, `is_visible`, `created_at` |
| `ACADEMIX_CERTIFICATES_TABLE` | `course_certificates` | `user_id`, `course_title`, `recipient_name`, `issuer_name`, `credential_code`, `issued_at` |
| `ACADEMIX_PROGRESS_TABLE` | `lesson_progress` | `user_id`, `course_id`, `lesson_id`, `completed`, `completed_at` |

Permisos que debe aplicar el servidor:

- Avisos: leer/actualizar solo `user_id = auth.uid()`, actualizar únicamente
  `read_at`; impedir que el usuario reescriba título, destinatario o contenido.
- Reseñas: lectura pública solo `is_visible = true`. Escritura propia con
  inscripción válida, unicidad por usuario/curso, calificación 1–5 y límite del
  comentario. `author_name` debe provenir del servidor. El cliente no envía
  `is_visible`, de modo que no puede decidir su propia moderación.
- Certificados: SELECT propios; emisión y contenido solo desde servidor.
- Progreso: unicidad `(user_id, lesson_id)`; comprobar la relación lección/curso
  y la inscripción activa o completada en cada operación, no solo en Flutter.
- Aprendizaje: RLS debe proteger contenido y tareas. La consulta de temario
  público no debe exponer archivos privados o respuestas de otro estudiante.

No se usan ni se requieren claves secretas ni `service_role` en el móvil.

## Recursos y certificados

Lección privada: `resource_bucket` + `resource_path` de un bucket **privado**.
Se vuelve a comprobar la inscripción antes de firmar una URL de 300 segundos.
Las políticas de Storage deben comprobar autorización por curso. Nunca se usa
`getPublicUrl`. Los recursos externos usan `resource_url` HTTPS sin credenciales
incrustadas; se rechazan enlaces permanentes de Storage público. El navegador
del dispositivo permite previsualizar/descargar según tipo y soporte del archivo.
La revocación de acceso puede tardar hasta la expiración del enlace ya emitido.

`ACADEMIX_CERTIFICATE_VERIFY_URL` debe ser una URL HTTPS existente. Se abre con
el parámetro `code=<credential_code>`. El servidor debe implementar esa ruta y
su consulta pública mínima; este parche no crea ni valida dicha implementación.
Sin configurar la ruta, la app permite copiar el código, pero no muestra un
botón de verificación que prometa una página inexistente.

## Pruebas y ejecución

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Ejemplo **solo tras validar el contrato**:

```bash
flutter run --dart-define=ACADEMIX_REAL_LEARNING=true --dart-define=ACADEMIX_REAL_STUDENT=true
```

Las pruebas de contrato usan un servidor HTTP local y los clientes reales de
Supabase/PostgREST; no crean usuarios ni escriben en la base de producción.
Las pruebas incluyen precios inválidos, duplicados, aislamiento de cuentas,
respuestas tardías, rechazos de lectura, reseñas, progreso y pantallas de 320 px.

Este documento actualiza el alcance de estudiante de los archivos previos
`INTEGRACION_SUPABASE_PENDIENTE.md` y `PENDIENTES_HISTORIAS_USUARIO.md`.
Organizaciones, administración e instructores quedan fuera del parche.

# Academix Móvil — Alcance y validación de HU

Tablero: https://github.com/users/MDAmaury10/projects/4
Historias: https://github.com/MDAmaury10/academixMovil/issues
Código: https://github.com/Santy28-Bv/Movil-Cursos

## Alcance de esta entrega

Solo las funciones públicas y del estudiante. Las HU de creación institucional,
autoría, moderación y administración quedan fuera del alcance móvil. Deben
retirarse del tablero conservando el historial: **HU-15, HU-18 y HU-20–HU-37**.
HU-16, HU-17 y HU-19 se conservan porque afectan la pertenencia y el acceso del
estudiante a instituciones. La HU-38 se limita al menú de aprendizaje.

| HU | Implementación móvil | Evidencia / validación restante |
|---|---|---|
| 01 | Registro compatible con los datos web y confirmación por correo | Contrato local de Supabase; probar correo real |
| 02 | Login validado por Express, cierre/cambio de cuenta y recuperación web | Contratos locales de login, cuenta inactiva y recuperación; probar enlace real |
| 03 | Catálogo real, destacados, búsqueda, filtros y paginación de 10 | Lectura real de Supabase a través de Express y contrato HTTP |
| 04 | Detalle, instructor, cursos relacionados y temario | API pública real y pantalla a 320 px |
| 05 | Consulta de planes y modalidades sin compra | API pública /plans comprobada |
| 06 | Nosotros, preguntas del estudiante y formulario de contacto | No se envió un mensaje real durante las pruebas |
| 07 / M07 | Perfil canónico: nombre completo, correo, teléfono, país y bio | Guardado local de contrato, pantalla con teclado y cambio de cuenta; falta aceptación con cuenta remota |
| 08 / M08 | Carrito por cuenta, varios cursos, total, contador y quitar | Pruebas de sesión y pantalla a 320 px; sin cobros ni inscripciones ficticias |
| 09 / M09 | Inscripción compartida, idempotencia y acceso incluido verificado por servidor | Contrato HTTP; falta aceptación con curso/usuario real |
| 10 | Biblioteca y métricas desde el servidor, filtros y paginación | Pruebas de pantalla/contrato; falta aceptación remota autenticada |
| 11 | Aula compartida, recursos con JWT, video, progreso y descarga | Contratos y guardado en pantalla; falta reproducción nativa autorizada |
| 12 | Reseñas paginadas, 10–2000 caracteres y curso completado | Contratos y elegibilidad de la pantalla; falta publicar una reseña real |
| 13 | Certificados del servidor, PDF y verificación pública | Deserialización y contratos; falta validar una credencial real y PDF en dispositivo |
| 14 | Avisos propios, contador, lectura individual y general | Contratos y aislamiento de sesión; falta aceptación remota autenticada |
| 16 / 17 / 19 | Consulta, unión con matrícula y cursos de organizaciones | Operaciones servidor; falta aceptación institucional. El resumen API actual no devuelve la matrícula |
| 38 | Menú del estudiante, información pública y cambio/cierre de cuenta | Navegación y accesibilidad móvil; sin controles de administración |
| 39 | Tema de los paneles y diseño adaptable | Pruebas a 320 px; falta revisión visual nativa en ambos modos |

## Criterio para mover tarjetas

`Done` requiere cubrir los criterios de aceptación. Las operaciones académicas
que solo tienen contrato local probado se mantienen en revisión hasta la
aceptación con una cuenta real, sin crear datos remotos de prueba automáticamente.
No se debe confundir una pantalla implementada con una inscripción o certificado
confirmado en producción.

El carrito (HU-08/M08) está verificado dentro de su alcance de preparación. Las
HU públicas de catálogo/detalle cuentan además con lectura real de la API.

# Contrato de estudiante

La fuente compartida es el backend actualizado de CursosWeb(1).zip.

| Función | Endpoint |
|---|---|
| Catálogo y destacados | GET /courses, /courses/featured |
| Detalle y temario público | GET /courses/:id |
| Perfil propio | GET/PATCH /users/me |
| Inscripción | POST /courses/:id/enrollments |
| Biblioteca y métricas | GET /users/me/courses, /users/me/learning-summary |
| Aula protegida | GET /users/me/courses/:id/learning |
| Progreso | PATCH /lessons/:id/progress |
| Archivo protegido | GET /lessons/:id/resources/:resourceId/content |
| Reseñas | GET/POST /courses/:id/reviews |
| Avisos | GET /notifications; PATCH /notifications/:id/read, /notifications/read-all |
| Certificados | GET /users/me/certificates, /users/me/certificates/:id |
| Verificación pública | GET /certificates/verify/:code |
| Organizaciones del estudiante | GET /organizations; POST /organizations/join |
| Cursos institucionales | GET /organizations/:id/courses |

Todas las rutas son relativas a `/api/v1`. Las privadas reciben el JWT actual;
la identidad del propietario la resuelve Express, nunca un campo editable enviado
por Flutter. Las respuestas privadas se descartan si cambia la sesión.

Las reglas de disponibilidad, precio, membresía, reseñas, progreso y emisión de
certificados se conservan en el servidor. La app no escribe tablas académicas ni
permite editar roles. El carrito no ejecuta compras reales o simuladas.

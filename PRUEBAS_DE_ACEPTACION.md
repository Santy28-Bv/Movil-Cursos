# Pruebas de aceptación — Academix Móvil

> Ejecutar después de aplicar los dos SQL en una instancia de desarrollo de Supabase.

| ID | Acción | Resultado esperado |
|----|--------|--------------------|
| P01 | Abrir el Home sin sesión | Aparece el curso gratuito; búsqueda y detalle disponibles. |
| P02 | Abrir una lección sin inscribirse | Acceso bloqueado sin revelar video ni preguntas. |
| P03 | Iniciar sesión e inscribirse al curso gratuito | Se crea una sola matrícula `mobile_enrollments`. |
| P04 | Inscribirse por segunda vez | No se crea una matrícula duplicada. |
| P05 | Entrar en HTML | Se reproduce `01_html.mp4`; aparecen dos preguntas. |
| P06 | Enviar examen incompleto | Se solicita responder todas las preguntas. |
| P07 | Responder mal una pregunta (50 %) | Intento guardado, nota 50 y lección no aprobada. |
| P08 | Responder correctamente dos preguntas (100 %) | Lección aprobada y progreso 1/3. |
| P09 | Aprobar CSS y JavaScript | Progreso 3/3 y código de certificado en BD. |
| P10 | Abrir PDF del certificado | Datos procedentes del registro verificado, no de formulario editable. |
| P11 | Copiar código, cerrar sesión y verificarlo en el Home | Certificado válido sin autenticación. |
| P12 | Introducir código inexistente | Informa que no existe. |
| P13 | Cambiar de cuenta | No se muestra el progreso ni certificado de otra cuenta. |
| P14 | Intentar un `insert` directo en `mobile_certificates` vía cliente | RLS/grants impiden crear certificados falsos. |
| P15 | Consultar `mobile_quiz_options` vía cliente | No se pueden leer las soluciones correctas. |
| P16 | Desactivar red y enviar examen | Error, no se simula una aprobación local. |

## Comprobación adicional de PostgreSQL

Desde SQL Editor puedes contar las preguntas y los recursos del curso:

```sql
select c.title, count(distinct l.id) as lecciones,
       count(distinct q.id) as preguntas
from public.mobile_courses c
join public.mobile_modules m on m.course_id = c.id
join public.mobile_lessons l on l.module_id = m.id
join public.mobile_quiz_questions q on q.lesson_id = l.id
group by c.id, c.title;
```

Para el curso inicial debe devolver **3 lecciones y 6 preguntas**.

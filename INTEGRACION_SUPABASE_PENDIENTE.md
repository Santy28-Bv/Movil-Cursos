# Academia móvil — Integración real pendiente

El proyecto Flutter conserva Supabase Auth e intenta mostrar la tabla pública configurada
mediante `lib/config/supabase_settings.dart`. Si esta tabla no existe, tiene otros campos,
no hay cursos publicados, o RLS impide la lectura, se muestran los seis **cursos demo de
CursosWeb** con un aviso visible. Esta función es deliberada: no se han inventado tablas
ni registros para la base de datos del usuario.

## Lo que ya funciona como demostración

- Home público y búsqueda en catálogo.
- Detalles de cursos y temario sin exigir cuenta.
- Autenticación Supabase existente sin cambios.
- Botón de inscripción de demostración para usuarios autenticados.
- Biblioteca «Mis cursos» en memoria para cursos de demostración.
- Lecciones, respuestas a ejercicios de ejemplo y marcar lección como completada.
- Ícono Academix integrado en Android y en `assets/icon/`.

**Los cursos de CursosWeb son MOCKS.** Las inscripciones, respuestas y progreso del
modo demo se guardan en memoria únicamente; no persisten al reiniciar ni en Supabase.
Los ejercicios de práctica son ejemplos hechos para probar la UI; CursosWeb publica
nombres de lecciones pero no un sistema de tareas listo para consumir.

## Para convertirlo en inscripción y tareas REALES

Enviar la estructura (nombre, columna, tipo, PK, FK y restricciones) de las tablas de:

1. Cursos y su estado de publicación.
2. Inscripciones y el vínculo usuario-curso.
3. Módulos, lecciones y recursos.
4. Tareas/actividades y entregas/respuestas.
5. Progreso de lecciones (si existe).
6. Roles/membresías institucionales para cursos incluidos (si aplica).

También confirmar las políticas RLS que permiten a visitantes SELECT de cursos
publicados y a estudiantes la lectura/escritura de sus propias inscripciones,
progreso y entregas. **No enviar contraseñas, tokens, service_role ni datos personales.**

### Consulta de estructura de columnas (solo lectura)

```sql
select table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and (table_name ilike '%curso%' or table_name ilike '%course%'
    or table_name ilike '%inscri%' or table_name ilike '%matric%'
    or table_name ilike '%modul%' or table_name ilike '%lesson%'
    or table_name ilike '%leccion%' or table_name ilike '%tarea%'
    or table_name ilike '%entrega%' or table_name ilike '%progres%')
order by table_name, ordinal_position;
```

Es una consulta READ-ONLY para el SQL Editor de Supabase. Puedes compartir su
resultado ocultando cualquier dato que no desees revelar.

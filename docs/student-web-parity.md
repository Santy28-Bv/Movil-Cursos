# Academix Móvil: funciones del estudiante compartidas con la web

## Referencia y alcance

Solicitud: usar los mismos cursos, datos personales y reglas de aprendizaje que
Academix Web; conservar Flutter y limitar el producto móvil a las funciones del
estudiante. Se toma como referencia el código real del ZIP CursosWeb(1).zip,
incluidos los contratos de Express en `/api/v1`, no los mocks de la rama web.

La migración `20260811172558_secure_backend_only_data_api.sql` revoca el acceso
directo a las tablas a `anon` y `authenticated`. Por ello la app debe consultar
Express para datos académicos y perfil. Supabase Auth sigue gestionando la sesión
persistente y su renovación; Express verifica el JWT y el estado de la cuenta.
No se crearán tablas ni cursos `mobile_*`, ni un sistema de evaluación distinto.

## Resultado previsto

- Catálogo público paginado, destacados y detalle con los identificadores web.
- Perfil canónico `/users/me`: nombre completo, correo, teléfono, país y bio.
- Registro con `full_name`, contraseña de 8–72 caracteres y confirmación de correo.
- Inscripción y biblioteca a través de Express; acceso institucional decidido por
  el servidor. El carrito conserva el alcance de preparación, sin fingir compras.
- Aula con módulos, contenido, recursos protegidos y progreso de la web.
- Certificados emitidos por el servidor, consulta, PDF y verificación pública.
- Avisos y reseñas por los mismos endpoints web.
- Organización del estudiante: listar pertenencias, unirse y consultar cursos;
  sin crear organizaciones ni administrar miembros, roles o contenido.
- Colores, tarjetas, portada, temario y panel adaptados de la web a pantallas móviles.

## Validación y límites

Pruebas de contratos HTTP con servidor local, aislamiento al cambiar de cuenta,
análisis Flutter, pruebas de widgets a 320 px y compilación web. Si es posible,
comprobación de lectura del catálogo contra la configuración backend del ZIP.
No se inventará una URL pública: en desarrollo Android usa `10.0.2.2:3000` y
otros destinos usan `ACADEMIX_API_URL` con la misma base que `VITE_API_URL` web.
No se aplicarán migraciones ni se modificarán datos de estudiantes en las pruebas.

## Tablero

Tablero: MDAmaury10/projects/4; HU: MDAmaury10/academixMovil. Retirar del tablero
(archivar, para conservar el historial) HU-15, HU-18, HU-20–HU-37. Conservar
HU-16, HU-17 y HU-19 porque describen acceso y pertenencia del estudiante.
HU-38 se limita al menú de aprendizaje. Done requiere criterios completos y
verificación; una integración pendiente de prueba remota queda In Review.

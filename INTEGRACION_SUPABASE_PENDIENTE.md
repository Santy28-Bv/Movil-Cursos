# Integración compartida con Academix Web

El catálogo, el aula y los datos del estudiante se consumen por Express
`/api/v1`, igual que en la web. Supabase Auth mantiene la sesión y renueva el JWT.
Las migraciones de la web revocan el acceso directo a las tablas para las claves
públicas y de usuarios. Por ello, cambiar nombres de tablas o habilitar flags
`ACADEMIX_REAL_*` no resuelve la integración anterior.

No crees tablas `mobile_*`. Configura `ACADEMIX_API_URL` y ejecuta el backend
actualizado que acompaña al ZIP de la web. Consulta `README.md`.

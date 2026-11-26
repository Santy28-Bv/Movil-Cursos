# Academix Móvil

Aplicación Flutter para las funciones del estudiante. Comparte los cursos,
inscripciones, perfil, aula, progreso, reseñas, avisos y certificados de Academix Web.

## Ejecutar

Utiliza el backend actualizado incluido en `CursosWeb(1).zip` (carpeta
`academix-backend`), con la configuración de Supabase que ya usa la web:

```bash
npm ci
npm run dev
```

En **otra terminal**, dentro del proyecto Flutter:

```bash
flutter pub get
flutter run --dart-define=ACADEMIX_API_URL=http://10.0.2.2:3000/api/v1
```

La dirección anterior corresponde al emulador Android. Para un teléfono real,
usa la IP local de la computadora que ejecuta Express, en la misma red, por
ejemplo `http://192.168.1.20:3000/api/v1`. Para Flutter en escritorio o web:

```bash
flutter run -d chrome --web-port=5173 --dart-define=ACADEMIX_API_URL=http://localhost:3000/api/v1
```

Usa el mismo valor base que `VITE_API_URL` de CursosWeb; debe incluir `/api/v1`.
El backend debe permitir el origen web utilizado. Para una compilación de
producción proporciona la URL **HTTPS** del backend publicado. El permiso HTTP
local de Android solo está en las variantes debug/profile.

Los repositorios remotos web y backend se revisaron; el ZIP proporcionado contiene
la implementación más avanzada utilizada como contrato de esta integración.
Si `/api/v1/courses` devuelve 404, comprueba que estés ejecutando ese backend
actualizado. No es necesario crear tablas `mobile_*` ni ejecutar SQL desde Flutter.

## Autenticación y perfil

Supabase Auth conserva y renueva la sesión. Express recibe el JWT del usuario
para las operaciones privadas y verifica el estado de su cuenta. El registro
utiliza `full_name` y contraseñas de 8–72 caracteres; si se exige confirmación,
se informa al usuario que debe revisar su correo. La recuperación utiliza el
mismo endpoint y enlace de correo que la web; la contraseña se actualiza mediante
la página web de recuperación configurada en el backend.

El perfil se lee y modifica en `/users/me`: nombre completo, correo, teléfono,
país y biografía. No se sustituye el perfil por metadatos locales de autenticación.

## Funciones del estudiante

- Catálogo y destacados reales, búsqueda, categoría, nivel y paginación de 10.
- Detalle público, instructor, cursos relacionados, objetivos, requisitos y temario.
- Inscripción gratuita/institucional comprobada por el mismo servidor que la web.
- Biblioteca paginada, métricas y aula con progreso compartido.
- Recursos privados a través de Express y JWT, sin enlaces públicos permanentes.
- Reseñas públicas paginadas y publicación con las validaciones web.
- Notificaciones propias y actualización de lectura individual o general.
- Certificados emitidos por el servidor, PDF, código y verificación pública.
- Consulta de organizaciones, unión con código/matrícula y cursos institucionales.
- Perfil, carrito por cuenta, cierre/cambio de cuenta, información, preguntas,
  contacto, precios y tema de los paneles.

El carrito prepara una selección de cursos, sin realizar cobros ni conceder
inscripciones pagadas. La autoría, moderación y administración no forman parte
de la aplicación móvil. No se creó un módulo de exámenes ni entregas distinto
al de la web: los contenidos y recursos se muestran tal como los entrega su API.

La API actual de organizaciones no devuelve la matrícula en su resumen público;
la app no inventa ese dato ni consulta otros miembros para obtenerlo.

## Verificación

```bash
flutter analyze
flutter test
flutter build web --release
```

Las pruebas de contratos usan un servidor HTTP local; las de pantallas comprueban
el diseño y los flujos a 320 px. La reproducción y descarga nativa requieren
una comprobación adicional en Android/iOS con una cuenta real inscrita. No se
crean usuarios, inscripciones ni certificados remotos durante las pruebas locales.


### APK para un teléfono físico

El APK se conecta a `https://academix-api-eioa.onrender.com/api/v1` de forma
predeterminada. Puedes usar `--dart-define=ACADEMIX_API_URL=...` si cambias de
servidor.

```bash
flutter build apk --release
```

Instala `build/app/outputs/flutter-apk/app-release.apk`. También puedes descargar
`Academix-Android` desde el apartado Actions del repositorio cuando se complete
la compilación de `main`. Abre la app con Internet para guardar los destacados,
las categorías y los diez primeros cursos. El APK funciona sin conexión USB.

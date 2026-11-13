# Academix Student Web Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Compartir el catálogo y las funciones del estudiante con Academix Web.

**Architecture:** Flutter conserva Supabase Auth y consume Express `/api/v1` para
todos los datos académicos. Los modelos deserializan los contratos camelCase web.
Las pantallas eliminan demos y operaciones directas a tablas inventadas.

**Tech Stack:** Flutter, Dart, Supabase Auth, HTTP, video_player, PDF/printing.

**Spec:** `docs/student-web-parity.md`

## Global Constraints

- Solo funciones del estudiante. Sin cambios remotos de esquema ni datos de prueba.
- Nunca enviar JWT a dominios de recursos externos ni conservar datos de otra cuenta.
- No presentar mocks ante un error o un catálogo vacío.
- Pruebas locales no demuestran el acceso remoto de una cuenta real.

## Review Focus

- Cambio de cuenta durante peticiones o reproducción de material privado.
- Respuestas paginadas vacías, errores y resultados sin duplicados.
- Recursos binarios con autenticación y rutas ajenas al origen de la API.
- Inscripción duplicada, acceso expirado y cursos institucionales.
- Formularios, temario y tarjetas en pantallas de 320 px.

### Task 1: Contratos compartidos y transporte

**Files:** `lib/services/academix_api.dart`, `lib/config/api_settings.dart`,
repositorios y modelos existentes; `test/web_api_contract_test.dart`.

**Interfaces:** Produce AcademixApi(client, baseUrl, transport), get/post/patch
con sobre `{success,data,pagination}` y JWT actual. Produce Course.fromJson con
campos web, EnrolledCourse y LearningResource. Los repositorios consumen esa API.

- [ ] Añadir casos de contrato y observar fallos de mapeo/consultas directas.
- [ ] Implementar transporte con timeout, errores públicos y descarte de respuesta
  de otra cuenta; adaptar catálogo, biblioteca, perfil, avisos, reseñas y certificados.
- [ ] Ejecutar pruebas de contrato, incluyendo errores sin fallback a mocks.

### Task 2: Recorrido estudiantil y diseño web

**Files:** pantallas de auth/cursos/estudiante, Home y navegación.
**Interfaces:** Consume los repositorios de Task 1. Los recursos protegidos usan
el mismo origen con Authorization; los enlaces externos nunca reciben ese header.

- [ ] Cubrir perfil canónico, registro y detalle/temario a 320 px con widgets.
- [ ] Implementar las pantallas, retirar demos y formularios de tareas inventadas.
- [ ] Conectar recursos, progreso, certificados/PDF y organizaciones del estudiante.
- [ ] Ejecutar suite de widgets y contratos.

### Task 3: Verificación, entrega y HU

**Files:** documentación de ejecución, seguimiento HU y CI.
**Interfaces:** Consume el resultado verificado de Tasks 1–2.

- [ ] Ejecutar flutter analyze, flutter test y flutter build web.
- [ ] Comprobar catálogo real en modo lectura si la conexión lo permite.
- [ ] Revisión del diff completo y corrección de hallazgos materiales.
- [ ] Publicar en main con fast-forward; entregar parche y pasos de configuración.
- [ ] Archivar las tarjetas fuera de alcance y actualizar solo estados justificados,
  o documentar el bloqueo concreto de acceso si no puede modificarse Projects.

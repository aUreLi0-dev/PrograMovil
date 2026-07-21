# Migración: Eliminación de Datos JSON Locales en Login y Calculadora

## Objetivo

Eliminar toda dependencia de archivos JSON locales (`assets/data/`) en los flujos de **Login** y **Calculadora de Notas**, migrando completamente al backend API.

## Archivos Modificados

| Archivo | Líneas | Cambio |
|---------|--------|--------|
| `lib/services/auth_service.dart` | 230 | Eliminada lógica de autenticación local con `users.json` y `user_especialidades.json`. Login solo usa API. |
| `lib/pages/calculadora/calculadora_controller.dart` | 253 | Eliminados 4 servicios de datos locales y el fallback completo a JSON. Todo se obtiene de la API. |
| `lib/main.dart` | 76 | Eliminadas precargas de datos locales de sílabo y cursos. |

---

## Detalle de Cambios por Archivo

### 1. `lib/services/auth_service.dart` — Servicio de Autenticación

**Rol en el sistema:** Gestiona el ciclo de vida del usuario: login, restauración de sesión, logout, configuración de carrera/especialidades.

**Qué se eliminó:**

| Elemento Eliminado | Líneas (originales) | ¿Por qué? |
|-------------------|---------------------|-----------|
| `import 'notas_service.dart'` | 7 | Solo se usaba para guardar el ID del estudiante localmente (`guardarIdEstudianteActual`), innecesario con API. |
| Campo `_users` | 15 | Lista de usuarios cargada de `users.json`. Ya no se usa. |
| Campo `_userEspecialidades` | 19-20 | Lista de relaciones usuario-especialidad cargada de `user_especialidades.json`. Ya no se usa. |
| Carga de `users.json` | 50-57 | Buscaba coincidencia local para login sin API. |
| Carga de `user_especialidades.json` | 77-84 | Datos de especialidades por usuario. Ya no relevante. |
| `NotasService().guardarIdEstudianteActual(code)` en `tryAutoLogin()` | 104 | Persistía el ID del estudiante en SharedPreferences para que la calculadora local lo encontrara. |
| Fallback local completo en `tryRestoreSession()` | 126-136 | Buscaba el usuario en `_users` por código, creaba el `UserModel` manualmente, y guardaba el ID en `NotasService`. |
| `NotasService().guardarIdEstudianteActual(userCode)` en `login()` | 175 | Ídem anterior, pero en el flujo de login. |
| `await _ensureLoaded()` en `login()` | 177 | Ya no necesita asegurar carga de JSONs para login. |

**Qué se conservó:**

| Elemento Conservado | ¿Por qué? |
|--------------------|-----------|
| `_carreras` y `_especialidades` | Se usan como fallback local en `setup_carrera_controller.dart` (líneas 47-53 y 80-82) y en `perfil_controller.dart` (líneas 20, 27). |
| Carga desde `carreras.json` y `especialidades.json` en `_ensureLoaded()` | El método aún existe y se invoca desde `onInit()` al crear el servicio. |
| `getCareerName()` y `getEspecialidadName()` | Usados por `perfil_controller.dart` y `malla_service.dart`. |

**Flujo actual de inicio de sesión:**

```
Usuario ingresa código + contraseña
         ↓
login() → POST /api/sign-in
         ↓
         Recibe JWT + user data
         ↓
         GET /api/me (para refrescar datos completos)
         ↓
         Guarda JWT en StorageService
         ↓
         refreshDelegateStatus()
         ↓
Devuelve null (éxito) o mensaje de error
```

**Flujo actual de restauración de sesión:**

```
App inicia
    ↓
tryRestoreSession()
    ↓
tryAutoLogin()
    ↓
Lee JWT de StorageService
    ↓
GET /api/me (con JWT)
    ↓
Si éxito → usuario logueado
Si falla → limpia JWT y redirige a login
```

---

### 2. `lib/pages/calculadora/calculadora_controller.dart` — Controlador de la Calculadora

**Rol en el sistema:** Obtiene los cursos del estudiante, sus notas simuladas y el sílabo (evaluaciones y pesos) desde la API, y expone métodos para agregar/eliminar notas simuladas y calcular promedios.

**Qué se eliminó:**

| Elemento Eliminado | Líneas (originales) | ¿Por qué? |
|-------------------|---------------------|-----------|
| `import '../../services/evaluations_service.dart'` | 6 | Servicio que cargaba sílabos desde `evaluations.json`. |
| `import '../../services/notas_service.dart'` | 7 | Servicio que guardaba/cargaba notas locales en SharedPreferences. |
| `import '../../services/enrollment_service.dart'` | 9 | Servicio que cargaba matrículas desde `enrollments.json`. |
| `import '../../services/seccion_service.dart'` | 10 | Servicio que cargaba secciones desde `secciones.json`. |
| Campos `_syllabusService`, `_notasService`, `_seccionService` | 18-20 | Instancias de servicios locales ya eliminados. |
| Inicialización de servicios locales en `onInit()` | 25-27 | Creación de los servicios eliminados. |
| Método `_cargarDatosSyllabus()` | 42-51 | Cargaba todos los sílabos desde `evaluations_service.dart` (JSON). |
| Llamada a `_cargarDatosSyllabus()` desde `_init()` | 32 | Ya no hay datos locales que cargar. |
| Bloque `else` completo (fallback local) | 141-188 | Cuando la API no respondía, cargaba `EnrollmentService`, `SeccionService` y `NotasService` para reconstruir cursos desde JSONs. |
| Fallback `if (syllabus == null) { syllabus = syllabusData[courseId]; }` | 118-120 | Buscaba el syllabus en datos cargados localmente si la API no lo devolvía. Ahora el syllabus siempre viene del API. |
| Llamadas a `_guardarNotasLocal()` | 259, 289 | Persistía notas en SharedPreferences para recargarlas offline. |
| Método `_guardarNotasLocal()` | 297-316 | Guardaba el estado local de las notas. |

**Flujo actual de carga de la calculadora:**

```
Usuario abre la calculadora
         ↓
_init() → _inicializarCursos()
         ↓
GET /api/v1/calculator/student/{userId}/courses
         ↓
Por cada curso:
  GET /api/v1/calculator/enrollment/{enrollmentId}
      ↓
  Obtiene:
    • notas (assessments con value)
    • sílabo (evaluaciones con id, nombre, peso)
      ↓
  syllabusData[cursoId] = syllabus (para calcular promedios)
```

**Flujo actual al agregar nota:**

```
Usuario ingresa valor en evaluación X
         ↓
agregarNota(cursoIndex, titulo, peso, valor, evaluacionId, assessmentId)
         ↓
POST /api/v1/calculator/simulated-grades
  body: { enrollment_id, assessment_id, value }
         ↓
Agrega nota a la lista local (cursos[cursoIndex].notas)
         ↓
cursos.refresh() → UI se actualiza
```

**Flujo actual al eliminar nota:**

```
eliminarNota(cursoIndex, notaIndex)
         ↓
POST /api/v1/calculator/simulated-grades
  body: { enrollment_id, assessment_id, value: null }
         ↓
removeAt(notaIndex) de la lista local
         ↓
cursos.refresh() → UI se actualiza
```

---

### 3. `lib/main.dart` — Punto de Entrada

**Rol en el sistema:** Inicializa servicios globales, decide la ruta inicial (login vs home) y arranca la app.

**Qué se eliminó:**

| Elemento Eliminado | Líneas (originales) | ¿Por qué? |
|-------------------|---------------------|-----------|
| `import '/services/courses_service.dart'` | 8 | Solo se usaba para precargar datos de cursos locales. |
| `import 'services/evaluations_service.dart'` | 9 | Solo se usaba para precargar datos de sílabos locales. |
| `EvaluationSyllabusService().loadEvaluationData()` | 37 | Precargaba todos los sílabos desde JSON al iniciar la app. |
| `CoursesService().loadCoursesData()` | 38 | Precargaba todos los cursos desde JSON al iniciar la app. |

**Antes** (precargaba datos locales para que la calculadora los usara):

```dart
await Future.wait([
  EvaluationSyllabusService().loadEvaluationData(),
  CoursesService().loadCoursesData(),
  MallaService.to.load(),
]);
```

**Después** (solo carga la malla, que sí la necesitan otras pantallas):

```dart
await MallaService.to.load();
```

La calculadora ahora carga sus datos bajo demanda cuando el usuario abre la pantalla, mediante llamadas API.

---

## Archivos JSON que ya no se usan en estos flujos

Los siguientes archivos en `assets/data/` ya no son necesarios para login ni calculadora, pero **se mantienen** porque `carreras.json` y `especialidades.json` aún son usados como fallback por `setup_carrera` y `perfil`:

| JSON | Ya no lo usa | Sigue siendo usado por |
|------|-------------|----------------------|
| `users.json` | Login | Nadie (candidato a eliminación futura) |
| `user_especialidades.json` | Login | Nadie (candidato a eliminación futura) |
| `carreras.json` | — | `setup_carrera_controller.dart` (fallback), `perfil_controller.dart` (getCareerName) |
| `especialidades.json` | — | `setup_carrera_controller.dart` (fallback), `perfil_controller.dart` (getEspecialidadName) |
| `evaluations.json` | Calculadora | Nadie (candidato a eliminación futura) |
| `cursos.json` | Calculadora | Nadie (candidato a eliminación futura) |
| `enrollments.json` | Calculadora | Nadie (candidato a eliminación futura) |
| `secciones.json` | Calculadora | Nadie (candidato a eliminación futura) |

---

## Servicios que ya no se usan en el flujo principal

| Servicio | Dependiente anterior | Estado actual |
|----------|---------------------|---------------|
| `evaluations_service.dart` | `calculadora_controller.dart`, `main.dart` | Ya no se importa ni usa |
| `courses_service.dart` | `main.dart` | Ya no se importa ni usa |
| `enrollment_service.dart` | `calculadora_controller.dart` | Ya no se importa ni usa |
| `seccion_service.dart` | `calculadora_controller.dart` | Ya no se importa ni usa |
| `notas_service.dart` | `auth_service.dart`, `calculadora_controller.dart` | Ya no se importa ni usa |

> **Nota:** `notas_service.dart` y los demás servicios de datos locales no fueron eliminados del proyecto porque podrían ser reutilizados en el futuro. Ya no son referenciados por ningún archivo en los flujos activos.

---

## Diagrama de Comunicación Entre Componentes

### Antes (con datos locales)

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌───────────────┐
│   main.dart  │────→│EvaluationsService│────→│ evaluations.json│     │               │
│             │────→│ CoursesService   │────→│ cursos.json     │     │               │
│             │     └──────────────────┘     └─────────────────┘     │               │
│             │                                                       │               │
│ auth_service│────→│ users.json       │←────│ _ensureLoaded()  │     │   Login      │
│   .dart     │────→│ user_especialida.│     └──────────────────┘     │               │
└──────┬──────┘                                                       │               │
       │                                                              │               │
       │  ┌───────────────────┐                                       │   App        │
       │  │ calculadora_ctrl  │                                       │               │
       │  │   .dart           │                                       │               │
       │  │                   │                                       │               │
       │  │ ┌─────────────┐  │                                       │               │
       │  │ │ Enrollment  │──│──→ enrollments.json                   │               │
       │  │ │ Service     │  │                                       │               │
       │  │ ├─────────────┤  │                                       │               │
       │  │ │ Seccion     │──│──→ secciones.json                     │               │
       │  │ │ Service     │  │                                       │               │
       │  │ ├─────────────┤  │                                       │               │
       │  │ │ NotasService│──│──→ SharedPreferences                  │               │
       │  │ └─────────────┘  │                                       │               │
       │  │                   │                                       │               │
       │  │ ┌─────────────┐  │                                       │               │
       │  │ │ Evaluations │──│──→ evaluations.json                   │               │
       │  │ │ SyllabusSvc │  │                                       │               │
       │  │ └─────────────┘  │                                       │               │
       │  └──────────────────┘                                       │               │
       │                                                              └───────────────┘
       │
       │  ┌─────────────┐
       │  │ MallaService│────→ malla.json
       │  └─────────────┘

       Leyenda:
       ───→ Datos locales (JSON / SharedPreferences)
       - - → API (backend)
```

### Después (solo API)

```
┌─────────────┐
│   main.dart  │──→ MallaService.to.load() (sigue siendo JSON local)
│             │
│ auth_service│
│   .dart     │
│             │
│ onInit() ──→│ _ensureLoaded() → carreras.json / especialidades.json
│             │                  (solo como fallback para setup_carrera/perfil)
│             │
│ login() ───→│ POST /api/sign-in ──────────────────────────────────┐
│             │                                                     │
│ tryAutoLogin│ GET /api/me (con JWT) ────────────────────────────┐ │
│             │                                                  │ │
└─────────────┘                                                  │ │
                                                                 │ │
┌──────────────────┐                                            │ │
│calculadora_ctrl  │                                            │ │
│  .dart           │                                            │ │
│                  │                                            │ │
│ _inicializarCursos()                                          │ │
│                  │                                            │ │
│ GET /api/v1/calculator/student/{id}/courses ──────────────────┼─┤
│                  │                                            │ │
│ (por cada curso) │                                            │ │
│ GET /api/v1/calculator/enrollment/{id} ───────────────────────┼─┤
│                  │                                            │ │
│ agregarNota()    │                                            │ │
│ POST /api/v1/calculator/simulated-grades ─────────────────────┼─┤
│                  │                                            │ │
│ eliminarNota()   │                                            │ │
│ POST /api/v1/calculator/simulated-grades (value: null) ───────┼─┤
│                  │                                            │ │
└──────────────────┘                                            │ │
                                                                 │ │
                                     ┌───────────────────────────┘ │
                                     │                             │
                                     ▼                             ▼
                            ┌──────────────────┐     ┌──────────────────────┐
                            │  API Backend      │     │ Auth Service Externo │
                            │  (Ruby Sinatra)   │     │ (OAuth 2.0 / JWT)    │
                            │                   │     │                      │
                            │  MySQL            │     │  Valida credenciales │
                            │  Redis (caché)    │     │  Emite JWT           │
                            └──────────────────┘     └──────────────────────┘
```

---

## Resumen Visual de lo que Cambió

### Login — `auth_service.dart`

| Método | Antes | Después |
|--------|-------|---------|
| `login()` | POST `/api/sign-in` → guardaba JWT → cargaba `user.json` local via `_ensureLoaded()` → guardaba ID en `NotasService` | POST `/api/sign-in` → guarda JWT → GET `/api/me` → actualiza `currentUser` |
| `tryAutoLogin()` | GET `/api/me` con JWT → guardaba ID en `NotasService` | GET `/api/me` con JWT (sin `NotasService`) |
| `tryRestoreSession()` | Buscaba JWT → API → fallback: buscar en `users.json` local → crear usuario manualmente | Solo `tryAutoLogin()` |

### Calculadora — `calculadora_controller.dart`

| Acción | Antes | Después |
|--------|-------|---------|
| Cargar cursos | API + fallback a `EnrollmentService` + `SeccionService` + `NotasService` (JSONs) | Solo API |
| Obtener sílabo | API + precarga desde `evaluations.json` | Solo API (viene en el detalle de matrícula) |
| Guardar nota | API + `_guardarNotasLocal()` (SharedPreferences) | Solo API |
| Eliminar nota | API + `_guardarNotasLocal()` | Solo API |

### main.dart

| Acción | Antes | Después |
|--------|-------|---------|
| Precarga | `evaluations.json` + `cursos.json` + `malla.json` | Solo `malla.json` |

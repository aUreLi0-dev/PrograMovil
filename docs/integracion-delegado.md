# Integración Front–Back: Módulo Delegado

> Documento vivo. Voy anotando cada cambio, por qué se hizo y cómo funciona.
> Así, al final, tienes el mapa completo de la integración sin perderte.

---

## 🎯 Objetivo

Reemplazar los datos **mock** (archivos JSON en `assets/` y `SharedPreferences`)
del módulo de Delegado por llamadas **reales** al backend Flask, usando el JWT
que el login ya guarda.

Endpoints del backend que vamos a consumir:

| # | Método | Ruta | Para qué |
|---|--------|------|----------|
| 1 | GET  | `/api/v1/delegate/sections` | Cursos donde soy delegado |
| 2 | GET  | `/api/v1/sections/{id}/announcements` | Anuncios de una sección |
| 3 | POST | `/api/v1/delegate/announcements` | Publicar un anuncio |
| 4 | GET  | `/api/v1/sections/{id}/statistics` | Estadísticas del salón (gráfico) |

---

## ✅ Progreso

- [x] **Paso 1 — Modelos con `fromJson`** *(hecho)*
- [x] **Paso 2 — `delegate_service.dart`** *(hecho)*
- [x] **Paso 3 — Conectar `delegado_cursos_controller`** *(hecho)*
- [x] **Paso 4 — Conectar `delegado_anuncios_controller`** *(hecho)*
- [x] **Paso 5 — Lista de anuncios real en `descrip_cursos_controller`** *(hecho)*
- [ ] **Paso 6 — Estado de delegado real en `auth_service`** *(opcional)*
- [ ] **Paso 7 — Probar en el celular** *(siguiente)*

---

## 🧩 Cómo se conecta tu parte (front ↔ back)

La cadena completa, de arriba a abajo:

```
[Pantalla / Page]         →  muestra los datos (widgets reactivos con GetX)
       ↑ obs()
[Controller]              →  pide datos y guarda el resultado en variables .obs
       ↓ llama
[DelegateService]         →  1 método por endpoint  ← ARCHIVO NUEVO
       ↓ usa
[ApiClient]               →  arma la petición HTTP y le pega el JWT
       ↓ HTTP + "Authorization: Bearer <jwt>"
========================  (red WiFi / cable)  ========================
[Flask: delegate.py]      →  lee el JWT, saca g.user_id, consulta la BD
       ↓
[SQLite: app.db]          →  devuelve las filas reales
```

Punto clave: **el JWT es el que "te identifica"**. El login ya lo guardó en
`StorageService`. `ApiClient` lo adjunta automáticamente en cada llamada
(cabecera `Authorization: Bearer ...`). El backend lo lee y saca tu `user_id`,
así que **el front nunca manda tu id a mano** → no hay forma de suplantar a otro.

---

## 📄 Paso 1 — Modelos con `fromJson`

Un `fromJson` es una "fábrica" que convierte el JSON del backend en un objeto
Dart. Las claves del backend ya coincidían 1 a 1 con los campos del modelo, así
que quedó de pocas líneas.

**`lib/models/curso_delegado_model.dart`** — se agregó:

```dart
factory CursoDelegado.fromJson(Map<String, dynamic> json) {
  return CursoDelegado(
    idCurso: json['idCurso'].toString(),
    nombreCurso: json['nombreCurso'].toString(),
    idSeccion: json['idSeccion'].toString(),
    codigoSeccion: json['codigoSeccion'].toString(),
    rol: json['rol'].toString(),
    alumnosMatriculados: (json['alumnosMatriculados'] as num?)?.toInt() ?? 0,
  );
}
```

**`lib/models/estadisticas_seccion_model.dart`** — se agregó un `fromJson`
equivalente para `promedioGeneral`, `porcentajeAprobados` y los 4 rangos.

> El modelo `Anuncio` **ya tenía** `fromJson` con las claves correctas
> (`titulo`, `mensaje`, `fecha`, `autorCode`...), así que no se tocó.

---

## 📄 Paso 2 — `delegate_service.dart` (NUEVO)

Archivo: `lib/services/delegate_service.dart`. Es el "traductor" entre tu app y
el backend: un método por endpoint, y nada más. Sigue el mismo molde que
`schedule_service.dart` (el que hizo tu compañero), para mantener consistencia.

Decisiones para que quede **simple**:

1. **No repite manejo de errores.** Si algo falla, `ApiClient` lanza una
   `ApiException`. El *controller* la atrapa una sola vez y muestra el mensaje.
   Así el servicio no tiene un `try/catch` gigante en cada método.
2. **No manda el token a mano.** `getJson`/`postJson` usan `authenticated: true`
   por defecto y agarran el JWT solos.
3. **`publicarAnuncio` no devuelve nada.** Si no lanza excepción, se publicó.
   Después el controller simplemente vuelve a pedir la lista de anuncios.

Los 4 métodos:

| Método del servicio | Endpoint | Devuelve |
|---------------------|----------|----------|
| `fetchMisCursos()` | GET `/delegate/sections` | `List<CursoDelegado>` |
| `fetchAnuncios(sectionId)` | GET `/sections/{id}/announcements` | `List<Anuncio>` |
| `publicarAnuncio(...)` | POST `/delegate/announcements` | `void` (éxito = sin error) |
| `fetchEstadisticas(sectionId)` | GET `/sections/{id}/statistics` | `EstadisticasSeccion` |

---

## 📄 Paso 3 — `delegado_cursos_controller.dart` (CONECTADO)

Este es el controller de la primera pantalla (lista de "mis cursos como delegado").

**Antes:** importaba 3 servicios mock (`SectionRepresentativeService`,
`EnrollmentService`, `SeccionService`) + `AuthService`, y cruzaba a mano ~50
líneas: buscaba los cargos de representante, los enlazaba con matrículas,
filtraba por el alumno logueado, contaba alumnos por sección, etc.

**Ahora:** todo ese cruce lo hace el backend. El controller quedó así de corto:

```dart
cursosDelegado.value = await _delegateService.fetchMisCursos();
```

Detalles de cómo funciona:

- **Se conserva la misma "interfaz pública"** (`cargarCursos()`, `abrirGestionCurso()`,
  `cursosDelegado`, `cargando`), así que **la pantalla (`.page`) no se tocó**.
- **Manejo de error en un solo lugar:** se atrapa `ApiException` (la que lanza
  `ApiClient`) y se muestra un `snackbar`. Si hay 401 (sin token) o el servidor
  falla, el usuario ve un aviso claro en vez de una pantalla congelada.
- **`cargando`** controla el `CircularProgressIndicator`; **la lista vacía**
  ya no significa "error", significa "no eres delegado de ningún curso".

> Nota: al conectar este controller, los 3 servicios mock quedaron **sin usarse
> desde aquí**. No los borro todavía porque otras pantallas podrían usarlos;
> eso se limpia al final, cuando toda la integración esté probada.

---

## 📄 Paso 4 — `delegado_anuncios_controller.dart` (CONECTADO)

Controller de la segunda pantalla del delegado (formulario para publicar +
gráfico de estadísticas del salón). Ojo: **esta pantalla no lista anuncios**,
solo publica y muestra estadísticas.

**Antes:**
- Las estadísticas eran **inventadas con un `if`** que adivinaba según el código
  de sección (`if codigoSeccion.contains('854') ...`). Números fijos, mentira.
- Publicar armaba un `Anuncio` con `AuthService.currentUser` y lo guardaba en
  `SharedPreferences` (solo en ese teléfono; nadie más lo veía).

**Ahora:**
- `cargarCurso()` llama a `_cargarEstadisticas()`, que pide los números **reales**
  del backend con `fetchEstadisticas(sectionId)`.
- `publicarAnuncio()` manda el anuncio al backend con `publicarAnuncio(...)`.
  **Ya no usa `AuthService`**: el backend saca al autor del JWT. Menos código.

Detalles:

- **El `idSeccion` llega como texto** ("1") desde la pantalla anterior, y el
  servicio necesita un `int`, así que se convierte con `int.tryParse`. Si no es
  un número válido, se avisa y no se llama al backend.
- **Errores traducidos al usuario:** si el backend responde `403` (no eres
  delegado de esa sección) o `401` (sin token), se muestra el mensaje en un
  `snackbar` rojo, en vez de fallar en silencio.
- **`estadisticas` es `null` mientras carga o si falla** → la UI ya estaba
  preparada para eso (muestra un espacio vacío), así que **la pantalla no se tocó**.

> Recordatorio del backend: hoy `get_section_statistics` devuelve números de
> relleno (14.5, 75%...) si la sección no tiene notas cargadas. Si quieres que
> el gráfico muestre ceros reales en salones sin notas, hay que quitar ese
> "fallback" en `delegate.py` (te lo marqué en la revisión inicial).

---

## 📄 Paso 5 — Lista de anuncios real (`descrip_cursos_controller.dart`) (CONECTADO)

Este controller arma la pantalla **"Detalles de Curso"** (la vista del alumno con
las pestañas *Anuncios / Asesorías / Contactos*). Solo la parte de **anuncios** es
tuya; asesorías y contactos son de otros mocks y **no se tocaron**.

**Antes:** `fetchAnuncios` usaba el mock `AnuncioService` (leía `anuncios.json`
de assets + lo guardado en `SharedPreferences`).

**Ahora:** usa `DelegateService().fetchAnuncios(sectionId)` → los anuncios
**reales** del backend. Con esto se **cierra el círculo**: lo que publica el
delegado en el Paso 4 aparece aquí de verdad.

Detalles:

- Se reemplazó el campo `_anuncioService` por `_delegateService` (el mock ya no se
  usa en este archivo).
- **`idSeccion` es texto → se convierte a `int`** con `int.tryParse`. Si no es
  número válido, la lista queda vacía sin reventar.
- **El error se atrapa DENTRO de `fetchAnuncios`** (no se relanza). ¿Por qué?
  Porque esta pantalla carga 3 cosas en paralelo (`Future.wait`); si un fallo de
  anuncios se propagara, el `catch` de arriba llamaría a `limpiarDatos()` y
  borraría **también** asesorías y contactos. Aislándolo aquí, si fallan los
  anuncios el resto de la pantalla sigue viva.

> ⚠️ Detalle de datos a vigilar al probar: el `idSeccion` que llega a esta
> pantalla debe ser el **id real de la sección en el backend**. Si viene de un
> mock con ids distintos, los anuncios saldrán vacíos aunque existan. Es el mismo
> ojo de siempre: front y back deben hablar de la misma sección.

---

## ⏭️ Pasos siguientes (lo que falta)

### Paso 6 (opcional) — `auth_service.refreshDelegateStatus()`
Hoy calcula si eres delegado leyendo el JSON local. Se puede cambiar por:
"eres delegado si `fetchMisCursos()` devuelve al menos 1 curso".

### Paso 7 — Probar en el celular

**Backend: ✅ verificado end-to-end.** Se probaron los 4 endpoints por HTTP y
todos responden correcto (login → JWT → sections → publicar → listar → stats).

**Dato importante:** la BD **no tenía ningún delegado** (`section_representative`
estaba en 0 filas). Se sembró uno de prueba:

```sql
-- Jefferson (student 1) delegado de la sección 1 (Ing. de Software II)
INSERT INTO section_representative (section_id, enrollment_id, position, is_active)
VALUES (1, 1, 'delegate', 1);
```

**Credenciales de prueba:** código `20235218`, contraseña `ulima123`
(existe en el backend Y en `users.json`, así que el login híbrido pasa).

#### Cómo correrlo (checklist)

1. **Backend** (una terminal, dejarla abierta):
   ```powershell
   cd PrograMovilBackend
   .\venv\Scripts\python.exe app.py
   ```
   Debe decir: `Running on http://192.168.0.173:5000`.

2. **Firewall** (una sola vez, en PowerShell **como Administrador**):
   ```powershell
   New-NetFirewallRule -DisplayName "Flask Dev 5000" -Direction Inbound `
     -LocalPort 5000 -Protocol TCP -Action Allow -Profile Private
   ```

3. **Celular:** desbloquéalo, conéctalo por USB y acepta "¿Permitir depuración
   USB?". Confirma que aparece:
   ```powershell
   flutter devices
   ```

4. **Front** (otra terminal):
   ```powershell
   cd PrograMovil
   flutter run --dart-define=API_BASE_URL=http://192.168.0.173:5000
   ```
   > La IP `192.168.0.173` es la de esta PC en WiFi. Si cambias de red, vuelve
   > a sacarla con `ipconfig` (campo "Dirección IPv4" de Wi-Fi).

5. **En la app:** entra con `20235218` / `ulima123` → pestaña **DELEGADO** →
   debe salir "Ingeniería de Software II" (sección 856). Entra, publica un
   anuncio y míralo aparecer en "Detalles de Curso".

---

## ⚠️ Cosas a tener presentes al probar

- **Sin JWT → error 401.** El login es híbrido: si el backend falla, te logueas
  local pero *sin* token, y estos endpoints darán 401. Verifica que el login
  real haya respondido (que `StorageService.to.savedJwt` no sea null).
- **El usuario debe existir en el backend** (`seed.sql`) y ser delegado de
  alguna sección, si no `fetchMisCursos()` viene vacío (no es error, es que no
  eres delegado de nada).

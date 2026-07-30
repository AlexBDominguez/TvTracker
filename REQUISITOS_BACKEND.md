# Backend "TvTime Clone" — Especificación técnica para desarrollo asistido por IA

> **Nota para el agente (Claude Code):** este documento es la fuente de verdad del proyecto. Léelo completo antes de generar código. Si algo es ambiguo, pregunta antes de asumir. El desarrollo se hace **100% en local** en esta fase; todo lo relacionado con VPS/producción está marcado como `[FUTURO]` y no debe implementarse todavía, solo dejarse preparado (variables de entorno, configuración desacoplada, etc.).

---

## 0. Contexto del proyecto

- **Producto:** clon simplificado de TvTime — tracking de series y películas.
- **Reparto de trabajo:**
  - Backend (este documento) → yo, en Python.
  - Frontend → una compañera, en Flutter (móvil/web). Consume esta API vía REST/JSON.
- **Rol del backend:** API Gateway / orquestador entre el frontend, una base de datos MySQL y una
  API externa:
  - **TMDB** → metadatos e imágenes (pósters, sinopsis, temporadas, episodios).
  - El estado de tracking por usuario (visto/pendiente, historial, watchlist) vive **100% en la
    MySQL local** — no depende de ningún servicio externo. (Ver nota de arquitectura más abajo.)

```
[Frontend Flutter] <---> [Backend API Python] <---> [MySQL local]  (tracking por usuario)
                                 |
                                 +---> [TMDB API]      (metadatos/imágenes)
```

> **Nota de arquitectura (revisión posterior):** el diseño original de este documento delegaba el
> tracking por usuario en Trakt.tv vía OAuth2 (ver antigua sección 4.2, ya eliminada). Al probar
> el flujo real se detectó que el frontend Flutter nunca implementó pantalla ni lógica para
> conectar una cuenta Trakt, así que cualquier usuario nuevo quedaba bloqueado permanentemente. Se
> decidió que los usuarios finales solo tienen cuenta en esta app, nunca en Trakt, y se migró todo
> el tracking a tablas locales (`watched_episode`, y `series_tracking` reutilizada para la
> watchlist). TMDB sigue siendo la única fuente externa, y solo para metadatos.

### Filosofía de esta fase (Fase 1 — Local)

- Todo corre en `localhost`: base de datos MySQL en Docker local, backend levantado con `uvicorn` (recarga en caliente) o en su propio contenedor Docker local.
- **No** hace falta integrar nada con el VPS ni con el `docker-compose` de producción todavía. Eso es una tarea `[FUTURO]` de despliegue, no de desarrollo.
- Todo lo sensible (API keys, secretos, cadenas de conexión) se lee de variables de entorno desde el minuto uno, aunque hoy vivan en un `.env` local. Esto es lo que hace que el "subir al VPS más adelante" sea solo un cambio de infraestructura, no de código.

---

## 1. Stack tecnológico

| Capa | Elección | Motivo |
|---|---|---|
| Lenguaje/Framework | **Python + FastAPI** | Async nativo, ideal para llamadas concurrentes a TMDB, generación automática de OpenAPI/Swagger (facilita el trabajo de tu compañera de frontend). |
| ORM | **SQLAlchemy 2.0 (async) + Alembic** | Migraciones versionadas del esquema desde el día 1. |
| Base de datos | **MySQL 8** (contenedor Docker local en esta fase) | Pedido explícito; mismo motor que se usará en el VPS más adelante. |
| Validación | **Pydantic v2** | Ya viene con FastAPI, define contratos de entrada/salida claros para el frontend. |
| Autenticación | **JWT** (`python-jose` o `pyjwt`) + `passlib[bcrypt]` o `argon2-cffi` | Login 100% local, independiente de cualquier proveedor externo. |
| Cliente HTTP externo | **httpx (async)** | Para llamar a TMDB sin bloquear el event loop. |
| Cache | **`cachetools` en memoria** para Fase 1 (opcional migrar a Redis en `[FUTURO]`) | Evitar quemar el rate limit de TMDB. |
| Contenedor | **Docker + docker-compose** (solo local en esta fase) | Un `docker-compose.yml` de desarrollo con dos servicios: `backend` y `mysql`. |

---

## 2. Estructura de proyecto recomendada

> Nota: en el repo real este árbol vive bajo `backend/` (monorepo, con `frontend/` reservado para la app Flutter más adelante).

```
backend/
├── app/
│   ├── main.py                  # instancia FastAPI, monta routers, middlewares
│   ├── core/
│   │   ├── config.py            # Settings (pydantic-settings) que lee .env
│   │   ├── security.py          # hashing, creación/verificación JWT
│   │   └── exceptions.py        # manejo uniforme de errores (ver sección 6)
│   ├── db/
│   │   ├── session.py           # engine + sessionmaker async
│   │   └── base.py              # Base declarativa
│   ├── models/
│   │   ├── user.py              # tabla users
│   │   ├── series_tracking.py   # tabla series_tracking (estado por serie, incl. watchlist)
│   │   └── watched_episode.py   # tabla watched_episode (episodios vistos)
│   ├── schemas/                 # DTOs Pydantic (request/response)
│   │   ├── auth.py
│   │   ├── tracking.py
│   │   └── content.py
│   ├── api/
│   │   └── v1/
│   │       ├── auth.py          # /auth/register, /auth/login
│   │       ├── content.py       # /search, /shows/{id}
│   │       ├── library.py       # /library/my-series, watchlist incluida
│   │       └── tracking.py      # /tracking/watch, /unwatch, /pending, /last-watched
│   ├── services/
│   │   ├── tmdb_client.py       # wrapper httpx sobre TMDB
│   │   └── cache.py             # cache en memoria con TTL
│   └── dependencies.py          # get_db, get_current_user, etc.
├── alembic/                     # migraciones
├── tests/
├── .env.example                 # plantilla de variables, SIN valores reales
├── docker-compose.yml           # backend + mysql, SOLO local
├── Dockerfile
├── requirements.txt / pyproject.toml
└── README.md
```

---

## 3. Modelo de datos (MySQL)

El tracking por usuario (visto/pendiente/historial/watchlist) vive entero en estas tablas locales
— no hay credenciales ni estado de ningún servicio externo que persistir.

### `users`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | |
| `username` | VARCHAR(50), UNIQUE, NOT NULL | |
| `email` | VARCHAR(255), UNIQUE, NOT NULL | |
| `password_hash` | VARCHAR(255), NOT NULL | bcrypt/argon2, nunca texto plano |
| `created_at` | TIMESTAMP, DEFAULT CURRENT_TIMESTAMP | |

### `series_tracking`
Estado por serie y usuario: viendo/pendiente/finalizada/en pausa/abandonada. `PLAN_TO_WATCH` es,
además, la watchlist (no hay tabla de watchlist aparte).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | |
| `user_id` | INT, FK → `users.id`, NOT NULL | |
| `tmdb_id` | INT, NOT NULL | id de la serie en TMDB |
| `status` | ENUM (`watching`, `planToWatch`, `completed`, `paused`, `dropped`) | |
| `created_at` / `updated_at` | TIMESTAMP | |

`UNIQUE(user_id, tmdb_id)`.

### `watched_episode`
Un episodio marcado como visto por un usuario. "Último visto" = fila con `watched_at` más
reciente; "historial" (si hiciera falta) es esta tabla ordenada por `watched_at`.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | |
| `user_id` | INT, FK → `users.id`, NOT NULL | |
| `series_tmdb_id` | INT, NOT NULL | id de la serie en TMDB |
| `season_number` | INT, NOT NULL | |
| `episode_number` | INT, NOT NULL | |
| `episode_tmdb_id` | INT, NOT NULL | id del episodio en TMDB |
| `watched_at` | DATETIME, DEFAULT CURRENT_TIMESTAMP | |

`UNIQUE(user_id, series_tmdb_id, season_number, episode_number)`.

---

## 4. Endpoints de la API (`/api/v1`)

Todas las respuestas en JSON. Documentar cada endpoint con Pydantic para que salga bien en `/docs` (Swagger UI), que será la referencia de contrato para el frontend Flutter.

### 4.1 Autenticación local
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/register` | Crea usuario (username, email, password). Hashea password. |
| POST | `/auth/login` | Verifica credenciales, devuelve JWT (access token) para el frontend. |

### 4.3 Contenido (proxy TMDB)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/search?query=...` | Busca series/películas en TMDB, devuelve lista unificada y simplificada. |
| GET | `/shows/{id}` | Detalle de una serie: temporadas, episodios, sinopsis, imágenes (TMDB). |

### 4.4 Tracking (local)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/tracking/watch` | Marca un episodio como visto (upsert en `watched_episode`, idempotente). |
| POST | `/tracking/unwatch` | Desmarca un episodio (borra la fila de `watched_episode`). |
| GET | `/tracking/pending` | Episodios ya emitidos y no vistos de las series en estado `watching`. |
| GET | `/tracking/last-watched` | Último episodio visto por el usuario (o `null`). |
| GET | `/library/my-series` | Series del usuario con su `status`; filtrando por `planToWatch` es la watchlist. |
| PUT | `/library/series/{tmdb_id}/status` | Cambia el `status` de una serie para el usuario. |

Todos los endpoints de 4.3 y 4.4 requieren JWT válido (usuario logueado), salvo el propio `/auth/login` y `/auth/register`.

---

## 5. Gestión de secretos

- Nunca hardcodear: `TMDB_API_KEY`, `JWT_SECRET_KEY`, `DATABASE_URL`.
- Todas se leen vía `pydantic-settings` desde variables de entorno.
- En local: fichero `.env` (añadido a `.gitignore`) + `.env.example` con las claves vacías/documentadas, versionado en el repo.
- `[FUTURO]` En VPS: las mismas variables se inyectan vía el `docker-compose.yml` de producción (no se toca el código, solo el método de inyección).

---

## 6. Requisitos no funcionales

### 6.1 Manejo de errores uniforme
Cualquier fallo (TMDB caído, rate limit, timeout) debe capturarse y devolver siempre el mismo formato, por ejemplo:
```json
{ "error": "Servicio externo no disponible", "code": 503 }
```
Centralizar esto con un exception handler global de FastAPI (`core/exceptions.py`), no repetir try/except en cada endpoint.

### 6.2 Caching
- Cachear en memoria (TTL 24h) las respuestas de `/shows/{id}` y `/search`, ya que el metadato de una serie antigua no cambia.
- Empezar simple (`cachetools.TTLCache`); dejar la interfaz desacoplada para poder cambiar a Redis en `[FUTURO]` sin tocar los endpoints.

### 6.3 CORS
- Configurar CORS en FastAPI para permitir peticiones desde el entorno de desarrollo de Flutter (web) y desde la app móvil. Dejarlo parametrizado por variable de entorno (`ALLOWED_ORIGINS`), no hardcodeado.

### 6.4 `[FUTURO]` Despliegue en VPS
- No implementar ahora. Solo tener en cuenta que:
  - El `Dockerfile` del backend debe funcionar igual en local que integrado en el `docker-compose` del VPS.
  - La base de datos pasará de "contenedor MySQL local" a "base de datos `tvtime_clone` dentro del MySQL ya existente en el VPS" — por eso `DATABASE_URL` debe ser 100% configurable por entorno.
  - Nada de rutas absolutas, IPs fijas o puertos hardcodeados en el código.

---

## 7. Plan de trabajo por fases (para ir dando prompts a Claude Code)

1. **Fase 0 — Bootstrap del proyecto** ✅ hecho
   Estructura de carpetas, `pyproject.toml`/`requirements.txt`, `main.py` mínimo con FastAPI arrancando, `docker-compose.yml` local con `mysql` + `backend`, `.env.example`, README con instrucciones de arranque.

2. **Fase 1 — Modelo de datos y migraciones** ✅ hecho
   Modelos SQLAlchemy `User` y (originalmente) `TraktCredentials`, configuración de Alembic, primera migración aplicada contra el MySQL local.

3. **Fase 2 — Autenticación local** ✅ hecho
   `POST /auth/register`, `POST /auth/login`, hashing de contraseñas, emisión y verificación de JWT, dependencia `get_current_user`.

4. ~~**Fase 3 — Integración Trakt OAuth2**~~ ❌ revertida
   Se implementó (`GET /auth/trakt/connect`, `GET /auth/trakt/callback`, guardado y refresco de
   tokens) pero se eliminó por completo: el frontend nunca llegó a construir la pantalla de
   conexión, así que ningún usuario podía completar el flujo. Ver la nota de arquitectura en la
   sección 0.

5. **Fase 4 — Proxy TMDB** ✅ hecho
   `GET /search`, `GET /shows/{id}`, con capa de caché en memoria.

6. ~~**Fase 5 — Sync con Trakt**~~ ❌ revertida
   `GET /sync/watchlist`, `POST /sync/history`, `DELETE /sync/history` proxeaban a Trakt; se
   eliminaron junto con la Fase 3 (sin consumidor en el frontend).

7. **Fase 6 — Endurecimiento** ✅ hecho
   Manejo uniforme de errores, CORS, logging, tests básicos de cada endpoint, revisión de que no haya secretos ni configuración hardcodeada.

8. **Fase 7 — Tracking 100% local** ✅ hecho
   Se sustituyó Trakt por tablas propias: `watched_episode` (episodios vistos) y `series_tracking`
   reutilizada para la watchlist (`status == planToWatch`). `POST/GET /tracking/*` reescritos
   sobre estas tablas; `EpisodeRef` ampliado con `series_id`/`season_number`/`episode_number`
   (TMDB no resuelve un episodio solo por id, a diferencia de Trakt).

9. **Fase 8 `[FUTURO]`— Preparación de despliegue**
   Ajustes finales de `Dockerfile`/`docker-compose` para integrarse en el VPS existente. No se aborda hasta que el resto esté validado en local.

---

## 8. Referencias externas necesarias

- TMDB API docs: https://developer.themoviedb.org/docs
- Habrá que registrar la app en TMDB para obtener una `API key` antes de empezar la fase de proxy TMDB.

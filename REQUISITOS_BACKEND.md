# Backend "TvTime Clone" — Especificación técnica para desarrollo asistido por IA

> **Nota para el agente (Claude Code):** este documento es la fuente de verdad del proyecto. Léelo completo antes de generar código. Si algo es ambiguo, pregunta antes de asumir. El desarrollo se hace **100% en local** en esta fase; todo lo relacionado con VPS/producción está marcado como `[FUTURO]` y no debe implementarse todavía, solo dejarse preparado (variables de entorno, configuración desacoplada, etc.).

---

## 0. Contexto del proyecto

- **Producto:** clon simplificado de TvTime — tracking de series y películas.
- **Reparto de trabajo:**
  - Backend (este documento) → yo, en Python.
  - Frontend → una compañera, en Flutter (móvil/web). Consume esta API vía REST/JSON.
- **Rol del backend:** API Gateway / orquestador entre el frontend, una base de datos MySQL y dos APIs externas:
  - **Trakt.tv** → estado de tracking (visto/pendiente, historial, watchlist).
  - **TMDB** → metadatos e imágenes (pósters, sinopsis, temporadas, episodios).

```
[Frontend Flutter] <---> [Backend API Python] <---> [MySQL local]
                                 |
                                 +---> [Trakt.tv API]  (estado de usuario)
                                 |
                                 +---> [TMDB API]      (metadatos/imágenes)
```

### Filosofía de esta fase (Fase 1 — Local)

- Todo corre en `localhost`: base de datos MySQL en Docker local, backend levantado con `uvicorn` (recarga en caliente) o en su propio contenedor Docker local.
- **No** hace falta integrar nada con el VPS ni con el `docker-compose` de producción todavía. Eso es una tarea `[FUTURO]` de despliegue, no de desarrollo.
- Todo lo sensible (API keys, secretos, cadenas de conexión) se lee de variables de entorno desde el minuto uno, aunque hoy vivan en un `.env` local. Esto es lo que hace que el "subir al VPS más adelante" sea solo un cambio de infraestructura, no de código.

---

## 1. Stack tecnológico

| Capa | Elección | Motivo |
|---|---|---|
| Lenguaje/Framework | **Python + FastAPI** | Async nativo, ideal para llamadas concurrentes a Trakt/TMDB, generación automática de OpenAPI/Swagger (facilita el trabajo de tu compañera de frontend). |
| ORM | **SQLAlchemy 2.0 (async) + Alembic** | Migraciones versionadas del esquema desde el día 1. |
| Base de datos | **MySQL 8** (contenedor Docker local en esta fase) | Pedido explícito; mismo motor que se usará en el VPS más adelante. |
| Validación | **Pydantic v2** | Ya viene con FastAPI, define contratos de entrada/salida claros para el frontend. |
| Autenticación | **JWT** (`python-jose` o `pyjwt`) + `passlib[bcrypt]` o `argon2-cffi` | Login local propio, independiente de Trakt. |
| Cliente HTTP externo | **httpx (async)** | Para llamar a Trakt y TMDB sin bloquear el event loop. |
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
│   │   └── trakt_credentials.py # tabla trakt_credentials
│   ├── schemas/                 # DTOs Pydantic (request/response)
│   │   ├── auth.py
│   │   ├── trakt.py
│   │   └── content.py
│   ├── api/
│   │   └── v1/
│   │       ├── auth.py          # /auth/register, /auth/login
│   │       ├── trakt_auth.py    # /auth/trakt/connect, /auth/trakt/callback
│   │       ├── content.py       # /search, /shows/{id}
│   │       └── sync.py          # /sync/watchlist, /sync/history
│   ├── services/
│   │   ├── tmdb_client.py       # wrapper httpx sobre TMDB
│   │   ├── trakt_client.py      # wrapper httpx sobre Trakt (incl. refresh token)
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

Esquema mínimo para Fase 1. El tracking real (visto/pendiente) se delega en Trakt; aquí solo guardamos identidad local y credenciales.

### `users`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | |
| `username` | VARCHAR(50), UNIQUE, NOT NULL | |
| `email` | VARCHAR(255), UNIQUE, NOT NULL | |
| `password_hash` | VARCHAR(255), NOT NULL | bcrypt/argon2, nunca texto plano |
| `created_at` | TIMESTAMP, DEFAULT CURRENT_TIMESTAMP | |

### `trakt_credentials`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | INT, PK, AUTO_INCREMENT | |
| `user_id` | INT, FK → `users.id`, UNIQUE, NOT NULL | 1:1 con el usuario |
| `access_token` | VARCHAR(255), NOT NULL | **cifrado en reposo si es posible** (ver 6.3) |
| `refresh_token` | VARCHAR(255), NOT NULL | |
| `expires_at` | TIMESTAMP, NOT NULL | Trakt caduca tokens ~cada 3 meses; usar para disparar refresh automático |

> Implementar con Alembic desde el primer commit: `alembic init`, primera migración con estas dos tablas.

---

## 4. Endpoints de la API (`/api/v1`)

Todas las respuestas en JSON. Documentar cada endpoint con Pydantic para que salga bien en `/docs` (Swagger UI), que será la referencia de contrato para el frontend Flutter.

### 4.1 Autenticación local
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/auth/register` | Crea usuario (username, email, password). Hashea password. |
| POST | `/auth/login` | Verifica credenciales, devuelve JWT (access token) para el frontend. |

### 4.2 Integración Trakt (OAuth2)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/auth/trakt/connect` | Devuelve al frontend la URL de autorización de Trakt (con `client_id`, `redirect_uri`, `state`). |
| GET | `/auth/trakt/callback` | Recibe `code` de Trakt, lo intercambia por `access_token`/`refresh_token`, los guarda en `trakt_credentials` asociados al usuario autenticado. |

### 4.3 Contenido (proxy TMDB)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/search?query=...` | Busca series/películas en TMDB, devuelve lista unificada y simplificada. |
| GET | `/shows/{id}` | Detalle de una serie: temporadas, episodios, sinopsis, imágenes (TMDB). |

### 4.4 Tracking (proxy Trakt)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/sync/watchlist` | Trae del Trakt del usuario lo pendiente de ver ("Up Next" / calendario). |
| POST | `/sync/history` | Marca episodio/película como visto (recupera token de MySQL, llama a Trakt). |
| DELETE | `/sync/history` | Desmarca un episodio/película (borra del historial en Trakt). |

Todos los endpoints de 4.2, 4.3 y 4.4 requieren JWT válido (usuario logueado), salvo el propio `/auth/login` y `/auth/register`.

---

## 5. Gestión de secretos

- Nunca hardcodear: `TMDB_API_KEY`, `TRAKT_CLIENT_ID`, `TRAKT_CLIENT_SECRET`, `TRAKT_REDIRECT_URI`, `JWT_SECRET_KEY`, `DATABASE_URL`.
- Todas se leen vía `pydantic-settings` desde variables de entorno.
- En local: fichero `.env` (añadido a `.gitignore`) + `.env.example` con las claves vacías/documentadas, versionado en el repo.
- `[FUTURO]` En VPS: las mismas variables se inyectan vía el `docker-compose.yml` de producción (no se toca el código, solo el método de inyección).

---

## 6. Requisitos no funcionales

### 6.1 Manejo de errores uniforme
Cualquier fallo (Trakt caído, TMDB caído, rate limit, timeout) debe capturarse y devolver siempre el mismo formato, por ejemplo:
```json
{ "error": "Servicio externo no disponible", "code": 503 }
```
Centralizar esto con un exception handler global de FastAPI (`core/exceptions.py`), no repetir try/except en cada endpoint.

### 6.2 Caching
- Cachear en memoria (TTL 24h) las respuestas de `/shows/{id}` y `/search`, ya que el metadato de una serie antigua no cambia.
- Empezar simple (`cachetools.TTLCache`); dejar la interfaz desacoplada para poder cambiar a Redis en `[FUTURO]` sin tocar los endpoints.

### 6.3 Seguridad de tokens Trakt
- Considerar cifrar `access_token`/`refresh_token` en la base de datos (p. ej. con `cryptography.Fernet` y una clave en variable de entorno) en vez de guardarlos en texto plano, ya que dan acceso a la cuenta Trakt del usuario.
- Implementar lógica de refresco automático: si `expires_at` está próximo/pasado, refrescar el token contra Trakt antes de usarlo.

### 6.4 CORS
- Configurar CORS en FastAPI para permitir peticiones desde el entorno de desarrollo de Flutter (web) y desde la app móvil. Dejarlo parametrizado por variable de entorno (`ALLOWED_ORIGINS`), no hardcodeado.

### 6.5 `[FUTURO]` Despliegue en VPS
- No implementar ahora. Solo tener en cuenta que:
  - El `Dockerfile` del backend debe funcionar igual en local que integrado en el `docker-compose` del VPS.
  - La base de datos pasará de "contenedor MySQL local" a "base de datos `tvtime_clone` dentro del MySQL ya existente en el VPS" — por eso `DATABASE_URL` debe ser 100% configurable por entorno.
  - Nada de rutas absolutas, IPs fijas o puertos hardcodeados en el código.

---

## 7. Plan de trabajo por fases (para ir dando prompts a Claude Code)

1. **Fase 0 — Bootstrap del proyecto** ✅ hecho
   Estructura de carpetas, `pyproject.toml`/`requirements.txt`, `main.py` mínimo con FastAPI arrancando, `docker-compose.yml` local con `mysql` + `backend`, `.env.example`, README con instrucciones de arranque.

2. **Fase 1 — Modelo de datos y migraciones** ✅ hecho
   Modelos SQLAlchemy `User` y `TraktCredentials`, configuración de Alembic, primera migración aplicada contra el MySQL local.

3. **Fase 2 — Autenticación local** ✅ hecho
   `POST /auth/register`, `POST /auth/login`, hashing de contraseñas, emisión y verificación de JWT, dependencia `get_current_user`.

4. **Fase 3 — Integración Trakt OAuth2** ✅ hecho
   `GET /auth/trakt/connect`, `GET /auth/trakt/callback`, guardado y refresco de tokens.

5. **Fase 4 — Proxy TMDB**
   `GET /search`, `GET /shows/{id}`, con capa de caché en memoria.

6. **Fase 5 — Sync con Trakt**
   `GET /sync/watchlist`, `POST /sync/history`, `DELETE /sync/history`.

7. **Fase 6 — Endurecimiento**
   Manejo uniforme de errores, CORS, logging, tests básicos de cada endpoint, revisión de que no haya secretos ni configuración hardcodeada.

8. **Fase 7 `[FUTURO]`— Preparación de despliegue**
   Ajustes finales de `Dockerfile`/`docker-compose` para integrarse en el VPS existente. No se aborda hasta que el resto esté validado en local.

---

## 8. Referencias externas necesarias

- Trakt API docs (OAuth2 device/web flow, endpoints de history/watchlist): https://trakt.docs.apiary.io/
- TMDB API docs: https://developer.themoviedb.org/docs
- Habrá que registrar la app en ambas plataformas para obtener `client_id`/`client_secret` (Trakt) y `API key` (TMDB) antes de empezar la Fase 3/4.

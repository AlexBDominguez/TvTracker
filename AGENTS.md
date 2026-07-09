# AGENTS.md — Guía para agentes de IA

> Este documento es la fuente de verdad operativa para cualquier agente de IA (Claude Code, Cursor, Copilot, etc.) que trabaje en este repositorio. Léelo completo antes de generar código. Si algo es ambiguo, pregunta antes de asumir.

## Qué es este proyecto

Backend de un clon simplificado de **TvTime** (tracking de series y películas). Es un **API Gateway / orquestador** en Python entre:

- Un **frontend Flutter** (móvil/web), desarrollado por otra persona del equipo, que consume esta API vía REST/JSON.
- Una base de datos **MySQL** local.
- Dos APIs externas: **Trakt.tv** (estado de tracking: visto/pendiente, historial, watchlist) y **TMDB** (metadatos e imágenes: pósters, sinopsis, temporadas, episodios).

```
[Frontend Flutter] <---> [Backend API Python] <---> [MySQL local]
                                 |
                                 +---> [Trakt.tv API]  (estado de usuario)
                                 |
                                 +---> [TMDB API]      (metadatos/imágenes)
```

La especificación técnica completa vive en [REQUISITOS_BACKEND.md](./REQUISITOS_BACKEND.md). Este documento no la duplica; la resume y añade convenciones de trabajo. **Ante cualquier duda de detalle (modelo de datos, endpoints, formato de errores), consulta REQUISITOS_BACKEND.md — es la fuente de verdad.**

## Filosofía de esta fase (Fase 1 — Local)

- Todo corre en `localhost`: MySQL en Docker local, backend con `uvicorn --reload` o en su propio contenedor.
- **No** implementar nada relacionado con el VPS/producción. Todo lo marcado `[FUTURO]` en REQUISITOS_BACKEND.md se deja preparado (variables de entorno, configuración desacoplada) pero no se construye todavía.
- Todo lo sensible se lee de variables de entorno desde el minuto uno (aunque hoy vivan en un `.env` local), para que subir a VPS más adelante sea solo un cambio de infraestructura, no de código.

## Stack tecnológico

| Capa | Elección |
|---|---|
| Lenguaje/Framework | Python + FastAPI (async) |
| ORM | SQLAlchemy 2.0 (async) + Alembic |
| Base de datos | MySQL 8 (Docker local) |
| Validación | Pydantic v2 |
| Autenticación | JWT (`python-jose`) + `passlib[bcrypt]` |
| Cliente HTTP externo | httpx (async) |
| Cache | `cachetools` en memoria (TTL), interfaz desacoplada de cara a Redis en `[FUTURO]` |
| Contenedor | Docker + docker-compose (solo local en esta fase) |

## Estructura de proyecto

```
app/
├── main.py                  # instancia FastAPI, monta routers, middlewares
├── core/
│   ├── config.py            # Settings (pydantic-settings) que lee .env
│   ├── security.py          # hashing, creación/verificación JWT
│   └── exceptions.py        # manejo uniforme de errores
├── db/
│   ├── session.py           # engine + sessionmaker async
│   └── base.py               # Base declarativa
├── models/                  # tablas SQLAlchemy (user, trakt_credentials, ...)
├── schemas/                  # DTOs Pydantic (request/response)
├── api/v1/                   # routers: auth, trakt_auth, content, sync
├── services/                  # tmdb_client, trakt_client, cache
└── dependencies.py           # get_db, get_current_user, etc.
alembic/                      # migraciones
tests/
```

## Convenciones y reglas de trabajo

- **Secretos**: nunca hardcodear `TMDB_API_KEY`, `TRAKT_CLIENT_ID`, `TRAKT_CLIENT_SECRET`, `TRAKT_REDIRECT_URI`, `JWT_SECRET_KEY`, `DATABASE_URL`. Siempre vía `pydantic-settings` desde variables de entorno (`app/core/config.py`). `.env` está en `.gitignore`; `.env.example` se mantiene actualizado con las claves (sin valores reales) cuando se añade una nueva variable.
- **Errores**: cualquier fallo de servicio externo (Trakt/TMDB caídos, rate limit, timeout) se captura de forma centralizada en `core/exceptions.py` (exception handler global de FastAPI), no con try/except repetido en cada endpoint. Formato uniforme, p. ej. `{ "error": "...", "code": 503 }`.
- **Caching**: respuestas de `/shows/{id}` y `/search` se cachean en memoria (TTL 24h) vía `cachetools.TTLCache`, con interfaz desacoplada para poder migrar a Redis sin tocar endpoints.
- **Tokens de Trakt**: sensibles (dan acceso a la cuenta del usuario). Considerar cifrado en reposo (`cryptography.Fernet`). Implementar refresco automático cuando `expires_at` esté próximo/pasado.
- **CORS**: parametrizado por variable de entorno (`ALLOWED_ORIGINS`), nunca hardcodeado, para permitir el entorno de desarrollo Flutter (web y móvil).
- **Migraciones**: todo cambio de esquema pasa por Alembic (`alembic revision --autogenerate` + revisión manual del script), nunca se modifica el esquema a mano contra la base de datos.
- **Contrato con el frontend**: cada endpoint se documenta con Pydantic para que Swagger UI (`/docs`) sirva de referencia de contrato fiable para la compañera de Flutter. No romper compatibilidad de un endpoint ya consumido sin avisar.
- **Nada de rutas absolutas, IPs fijas o puertos hardcodeados** en el código — todo configurable por entorno, pensando en el despliegue `[FUTURO]` en VPS.
- **No implementar tareas `[FUTURO]`** (despliegue en VPS, Redis, etc.) salvo que se pida explícitamente.

El plan de trabajo por fases vive en la sección 7 de [REQUISITOS_BACKEND.md](./REQUISITOS_BACKEND.md) — no se duplica aquí. Antes de empezar una fase nueva, confirma con la persona qué fase toca — no asumas ni saltes fases.

## Comandos habituales

```bash
# Arranque completo con Docker
docker compose up --build

# Solo MySQL (para correr el backend fuera de Docker)
docker compose up mysql

# Backend sin Docker
uvicorn app.main:app --reload

# Migraciones
alembic revision --autogenerate -m "mensaje"
alembic upgrade head

# Tests
pytest

# Lint
ruff check .
```

## Convenciones de commits

- Los commits **no** deben incluir la firma `Co-Authored-By: Claude` (ni de ningún otro agente de IA).
- Mensajes de commit **en inglés**.

## Referencias externas

- Trakt API docs: https://trakt.docs.apiary.io/
- TMDB API docs: https://developer.themoviedb.org/docs

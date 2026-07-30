# TvTime Clone — Backend

API Gateway en Python/FastAPI entre el frontend Flutter, MySQL (que guarda el tracking por
usuario) y la API de TMDB.
Ver [REQUISITOS_BACKEND.md](../REQUISITOS_BACKEND.md) para la especificación completa.

Este directorio (`backend/`) contiene únicamente el backend; es parte de un monorepo que más
adelante también tendrá una carpeta `frontend/` para la app Flutter.

## Fase actual

Ver el checklist de fases en la sección 7 de [REQUISITOS_BACKEND.md](../REQUISITOS_BACKEND.md).

## Requisitos

- Python 3.12+
- Docker y Docker Compose

## Arranque en local con Docker (recomendado)

```bash
cp .env.example .env
# Rellena TMDB_API_KEY, JWT_SECRET_KEY, etc.

docker compose up --build
```

- API disponible en http://localhost:8000
- Swagger UI (contrato para el frontend) en http://localhost:8000/docs
- Healthcheck: http://localhost:8000/health
- MySQL expuesto en `localhost:3306` (usuario/clave/DB definidos en `.env`)

## Arranque en local sin Docker

Requiere un MySQL accesible en `localhost:3306` (puedes levantar solo ese servicio con
`docker compose up mysql`).

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# En este modo, DATABASE_URL debe apuntar a host=localhost (ya es el default en .env.example)

uvicorn app.main:app --reload
```

## Variables de entorno

Ver `.env.example` para la lista completa y comentada. Nunca se commitea un `.env` real
(está en `.gitignore`); solo `.env.example` con claves vacías.

## Estructura del proyecto

Ver sección 2 de [REQUISITOS_BACKEND.md](../REQUISITOS_BACKEND.md).

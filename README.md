# TvTracker

Clon simplificado de [TvTime](https://www.tvtime.com/): tracking de series y películas vistas/pendientes.

## Arquitectura

```
[Frontend Flutter] <---> [Backend API Python] <---> [MySQL]
                                 |
                                 +---> [Trakt.tv API]  (estado de usuario)
                                 |
                                 +---> [TMDB API]      (metadatos/imágenes)
```

- **Backend** (`backend/`): API en Python/FastAPI, actúa como gateway entre el cliente, MySQL y las APIs
  de Trakt.tv (tracking) y TMDB (metadatos e imágenes). Ver [backend/README.md](./backend/README.md)
  para arrancarlo en local.
- **Frontend** (`frontend/`): app Flutter (móvil/web), pendiente de empezar.

## Estado actual

- ✅ Autenticación local (registro/login con JWT)
- ✅ Modelo de datos y migraciones (usuarios, credenciales de Trakt)
- ⏳ Integración OAuth2 con Trakt.tv
- ⏳ Proxy/caché de contenido vía TMDB
- ⏳ Sincronización de watchlist/historial con Trakt

## Stack

Python + FastAPI · SQLAlchemy (async) + Alembic · MySQL 8 · JWT · Docker

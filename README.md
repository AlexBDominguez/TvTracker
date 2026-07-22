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
- **Frontend** (`frontend/`): app Flutter (móvil/web). Tema oscuro con navegación inferior de 5
  secciones: Inicio, Biblioteca, Descubrir, Estadísticas y Perfil.

## Estado actual

### Backend

- ✅ Autenticación local (registro/login con JWT)
- ✅ Integración OAuth2 con Trakt.tv (tokens cifrados en reposo, refresco automático)
- ✅ Proxy/caché de contenido vía TMDB (búsqueda, series populares, detalle, temporadas)
- ✅ Sincronización de watchlist/historial con Trakt
- ✅ Seguimiento por usuario: episodios pendientes, último episodio visto, y estado de cada serie
  en la biblioteca (viendo / pendiente / finalizada / en pausa / abandonada)
- ✅ Endurecimiento: errores uniformes, logging, tests automáticos, sin secretos hardcodeados

### Frontend

- ✅ Interfaz completa de las 5 secciones (diseño en `frontend/README.md` y ficheros del propio
  proyecto Flutter)
- ✅ Conectado a la API real: autenticación, búsqueda/ficha de series, biblioteca y marcar
  episodios como vistos
- ⏳ Estadísticas, logros/racha, notas y valoraciones por episodio, y recomendaciones todavía sin
  datos reales (pendiente de backend, ver [REQUISITOS_PENDIENTES.md](./REQUISITOS_PENDIENTES.md))

## Stack

- **Backend**: Python + FastAPI · SQLAlchemy (async) + Alembic · MySQL 8 · JWT · Docker
- **Frontend**: Flutter · Riverpod · Dio

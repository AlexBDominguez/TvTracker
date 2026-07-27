# Requisitos pendientes — backend

> Funcionalidades descritas en el diseño de la interfaz (documento de producto del frontend) que
> **no** tienen todavía soporte en el backend. No es un plan de fases con orden fijo; es un
> inventario para decidir qué se aborda y cuándo. Agrupado por cuánto trabajo nuevo implica.

## Proxy TMDB directo (sin BD nueva)

Datos que TMDB ya expone; solo falta un endpoint que los sirva en el formato que use el frontend.

- **Reparto** (ficha de serie, pestaña "Reparto"): `GET /tv/{id}/credits` de TMDB.
- **Imágenes** (pestaña "Imágenes"): `GET /tv/{id}/images`.
- **Trailers** (pestaña "Trailers"): `GET /tv/{id}/videos`.
- **Recomendaciones** (ficha de serie y pantalla Descubrir): `GET /tv/{id}/recommendations`.
- **Estrenos** (carrusel "Estrenos" en Descubrir): `GET /tv/on_the_air` o `airing_today`.
- **Tendencias** (pantalla Descubrir): `GET /trending/tv/{window}` — endpoint distinto de
  "populares" (`/tv/popular`, ya implementado en `/content/popular/series`).
- **Géneros** (accesos rápidos en Descubrir, filtro por género en Biblioteca): `GET /genre/tv/list`
  para el catálogo; el género de cada serie ya viene en el detalle de TMDB.

## Ya hay integración con Trakt, falta el endpoint

- **Actividad reciente** (Perfil): agregación sobre `/sync/history` de Trakt (ya integrado en
  `trakt_client.get_history`), sin dato nuevo que guardar.
- **Racha de días** (Perfil, "18 días consecutivos viendo series"): se calcula recorriendo fechas
  de `watched_at` en el historial de Trakt. Solo hace falta el endpoint que lo calcule.
- **Resumen de estadísticas** (series vistas, episodios vistos, horas totales): episodios y series
  vistas salen de Trakt; las horas requieren la duración de cada episodio (TMDB la da por
  temporada, no siempre por episodio) — revisar precisión antes de mostrarla como dato exacto.

## Requiere tabla(s) nuevas en MySQL

Nada de esto lo modela Trakt ni TMDB; hay que diseñar el esquema y las migraciones.

- **Notas y valoraciones por episodio** (ficha de serie, al marcar un episodio): tabla
  `episode_review` (user_id, tmdb_episode_id, rating, nota, fecha).
- **Favoritos** (filtro "Favoritos" en Biblioteca): flag por serie, podría vivir en la tabla
  `series_tracking` ya creada (columna `is_favorite`) en vez de una tabla nueva.
- **Plataforma** (dónde se ve cada serie: Netflix, HBO...; usado en filtro de Biblioteca y en la
  estadística "Tiempo por plataforma"): campo libre o catálogo cerrado, a decidir con la persona
  de frontend. También vive bien en `series_tracking`.
- **Gamificación — logros y experiencia** (Perfil: nivel, XP, insignias como "Primer episodio",
  "100 episodios vistos", "Maratón de fin de semana"): necesita catálogo de logros, tabla de
  progreso por usuario, y disparar la comprobación en `/tracking/watch`. Es el bloque más grande
  de este documento.
- **Gráficos de estadísticas** (distribución por géneros, episodios vistos por mes, evolución
  anual, días de mayor actividad): una vez estén las tablas de arriba (o combinando Trakt +
  TMDB), son endpoints de agregación sobre esos datos. Depende de tener "plataforma" para el
  gráfico de "tiempo por plataforma".
- **Avatar de usuario** (Perfil): subida/almacenamiento de imagen. Si no hay VPS/S3 todavía, se
  puede dejar como URL externa (ej. Gravatar) para no depender de almacenamiento propio.

## Notas de alcance

- El estado de serie (viendo/pendiente/finalizada/en pausa/abandonada) y la biblioteca
  (`GET /library/my-series`) **ya están implementados** vía la tabla `series_tracking`.
- "Al día" (biblioteca) no es un estado guardado: se calcula en el momento a partir de
  `watching` + progreso al 100% frente a los episodios emitidos.
- Cualquier bloque de arriba que implique una tabla nueva debe pasar por una migración de
  Alembic, según la convención del proyecto (ver `AGENTS.md`).

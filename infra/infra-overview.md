# Infraestructura y Despliegue — Módulo D

Esta carpeta centraliza la documentación técnica, guías de aprovisionamiento y configuraciones de entorno para la ejecución del módulo en local y producción.

## 1. Qué existe hoy

| Documento | Contenido |
|---|---|
| [bd/base-de-datos-ventas-postventa.md](bd/base-de-datos-ventas-postventa.md) | Aprovisionamiento real en Supabase (PostgreSQL 17): migración aplicada, pruebas realizadas, conexión con el backend y pendientes operativos. Cubre lo que originalmente se planeaba como `base-de-datos-supabase.md`. |
| [bd/ventas_postventa_schema.sql](bd/ventas_postventa_schema.sql) | Script DDL que crea los 2 esquemas (`ventas`, `postventa`) y sus 11 tablas. |

## 2. Documentos todavía por crear

Nadie los ha subido aún — no describen nada real todavía, solo quedan como pendientes hasta que exista contenido que documentar:

- **`backend-microservicios.md`**: despliegue de `api-gateway`, `servicio-ventas` y `servicio-postventa` en Render — variables de entorno, puertos y empaquetado en contenedores. Ver `arquitectura/c4-nivel-2-contenedores-ventas-postventa.md` para la arquitectura de referencia.
- **`frontend-portal.md`**: despliegue de la consola del Gestor (Backoffice) en Vercel, configuración de build y conexión con el API Gateway.
- **`variables-entorno.md`**: plantilla de variables (`.env.example`), secrets compartidos y configuración de tokens JWT/OAuth2 para comunicación entre módulos.
- **`redes-y-seguridad.md`**: mapeo de puertos, configuración de CORS, reglas de firewall y políticas de red para la integración con los demás módulos (Despacho, Pagos y Canales).

## 3. Otros documentos relacionados

- [specs/modelo-datos.md](../specs/modelo-datos.md) — índice del modelo de datos (conceptual, lógico, físico), que enlaza de vuelta a esta carpeta.
- [arquitectura/c4-nivel-2-contenedores-ventas-postventa.md](../arquitectura/c4-nivel-2-contenedores-ventas-postventa.md) — arquitectura de despliegue propuesta (Vercel, Render, Supabase).

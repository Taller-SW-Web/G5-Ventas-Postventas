# Estructura del frontend - Módulo D Ventas y Postventa

El esqueleto (Fase 0) ya está creado en `G5-Ventas-Postventas-Frontend` (2026-10-13) siguiendo esta guía. React 19, TypeScript 7, Vite 8, Mantine 9.7.2 (ver `specs/stack-frontend.md`; `diseno/guia_ux_ui/*` ya corregido a esta versión). Una sola aplicación (no hay separación por microservicio como en el backend): el frontend consume tanto M1 (`api-ventas`) como M2 (`api-postventa`) desde el mismo portal del Gestor.

Convención de carpetas: cada componente y cada página tiene su propia carpeta con `Nombre.tsx` + `index.ts`. Las páginas se nombran `XxxPage.tsx` (ej. `pages/Devoluciones/DevolucionesPage.tsx`).

```text
G5-Ventas-Postventas-Frontend/             repositorio del frontend
├── package.json
├── vite.config.ts
├── tsconfig.json                           referencia a tsconfig.app.json y tsconfig.node.json
├── tsconfig.app.json
├── tsconfig.node.json
├── postcss.config.cjs                      lo exige Mantine (postcss-preset-mantine)
├── index.html                              carga Oswald e Inter desde Google Fonts
├── .env.example                            plantilla; cada uno crea su .env (no se sube)
├── .gitignore
├── README.md
│
└── src/
    ├── main.tsx
    ├── App.tsx                             rutas (React Router) y layout general
    ├── vite-env.d.ts                       tipos de las variables de entorno
    ├── theme/
    │   ├── index.ts                        theme de Mantine (colores, radios, tipografía — derivados de Figma)
    │   └── global.css                      estilos que el theme no cubre (fondo cloud, mayúsculas en H1-H3, foco de teclado con signal)
    ├── components/                         UI Kit reutilizable (sección 3 de stack-frontend.md)
    │   ├── EstadoBadge/                     badges de pedido, devolución, reclamo, reembolso
    │   ├── TablaPaginada/
    │   ├── ModalConfirmacion/
    │   ├── EstadoCarga/                     loading / vacío / error, reutilizable en toda pantalla
    │   ├── LayoutGestor/                    barra lateral Dashboard / Pedidos / Postventa / Reportes
    │   ├── RutaProtegida/                   protege /admin/* exigiendo rol ADMIN_VENTAS
    │   ├── PaginaEnConstruccion/             marcador temporal — se borra cuando estén todas las pantallas
    │   └── ...
    ├── pages/                               una carpeta por pantalla (Mockup 01 a 09) + páginas de sistema
    │   ├── Dashboard/                       Mockup 01 — Fabrizio (F6) — /admin/dashboard
    │   ├── Pedidos/                         Mockup 02 — Michael (F1) — /admin/pedidos
    │   ├── DetallePedido/                   Mockup 03 — Michael (F1) — /admin/pedidos/:pedidoId
    │   ├── Anulaciones/                     Mockup 04 — Luis Arroyo (F2) — /admin/anulaciones
    │   ├── HubPostventa/                    Mockup 05 — compartida, ver guía 1.1 — /admin/postventa
    │   ├── Devoluciones/                    Mockup 06 — Joseph (F3) — /admin/postventa/devoluciones
    │   ├── Reclamos/                        Mockup 07 — Fabrizio (F6) — /admin/postventa/reclamos
    │   ├── Reembolsos/                      Mockup 08 — Luis Alejandro (F4) — /admin/postventa/reembolsos
    │   ├── CalificacionesReportes/          Mockup 09 — Johan (F5) + Fabrizio (reportes, F6) — /admin/reportes
    │   ├── AccesoDenegado/                  rol sin permiso — /acceso-denegado
    │   └── NoEncontrado/                     ruta inexistente — catch-all
    ├── services/                            integración con endpoints, una carpeta por funcionalidad
    │   ├── api.ts                           cliente HTTP central (interceptor de JWT, manejo de errores)
    │   ├── auth.ts                          lee el JWT y sus roles (rol del portal: ADMIN_VENTAS); VITE_AUTH_DESACTIVADA solo en dev
    │   ├── pedidos.ts                       1.1 a 1.6, 1.10 (api-ventas.md)
    │   ├── anulaciones.ts                   1.7 a 1.9 (api-ventas.md)
    │   ├── devoluciones.ts                  2.1 a 2.5 (api-postventas.md)
    │   ├── reembolsos.ts                    2.6
    │   ├── calificaciones.ts                2.7
    │   └── reclamos.ts                      2.8 a 2.12 (incluye las métricas del dashboard, 2.12)
    ├── types/                               interfaces TypeScript, un archivo por contrato
    │   ├── comun.ts                         tipos compartidos: Paginado<T>, ErrorResponse, Canal, Moneda, Rol
    │   ├── pedido.ts                        F1 + F2 (anulaciones) — no tienen archivo propio, van aquí
    │   ├── devolucion.ts
    │   ├── reembolso.ts
    │   ├── calificacion.ts
    │   └── reclamo.ts                       incluye las métricas del dashboard (2.12) — no tienen archivo propio
    └── hooks/
        ├── useConsulta.ts                   maneja loading / error / datos
        └── usePaginacion.ts                 pagina desde 0 y tamano, como el contrato
```

## Variables de entorno

`.env.example` (plantilla, cada uno crea su propio `.env`, nunca se sube):

```bash
VITE_API_VENTAS_URL=http://localhost:8081
VITE_API_POSTVENTA_URL=http://localhost:8082
VITE_GATEWAY_URL=http://localhost:8080
VITE_SEGURIDAD_LOGIN_URL=

# Solo desarrollo: salta la validación de token/rol mientras G7 no entregue el login.
# Se ignora en el build de producción (import.meta.env.DEV).
VITE_AUTH_DESACTIVADA=false
```

## Rutas

| Ruta | Pantalla |
|---|---|
| `/admin/dashboard` | Mockup 01 |
| `/admin/pedidos` | Mockup 02 |
| `/admin/pedidos/:pedidoId` | Mockup 03 |
| `/admin/anulaciones` | Mockup 04 |
| `/admin/postventa` | Mockup 05 |
| `/admin/postventa/devoluciones` | Mockup 06 |
| `/admin/postventa/reclamos` | Mockup 07 |
| `/admin/postventa/reembolsos` | Mockup 08 |
| `/admin/reportes` | Mockup 09 |
| `/acceso-denegado` | Acceso denegado (rol sin `ADMIN_VENTAS`) |

Todo `/admin/*` está protegido por `RutaProtegida` (exige rol `ADMIN_VENTAS`). Las vistas públicas (encuesta CSAT, consulta de reclamo) van fuera de `/admin/*` — todavía no tienen ruta asignada.

## Colores — todavía provisionales

Los tokens `volt`, `signal`, `ink` y `cloud` del theme (`src/theme/index.ts`) tienen 10 tonos armados alrededor del HEX oficial de cada uno, igual que los colores de estado en `EstadoBadge` — hay que reemplazarlos cuando Figma entregue las tonalidades definitivas. No hardcodear los 5 colores de KPI del Dashboard mientras tanto.

## Reparto por pantalla

| Mockup | Pantalla | Funcionalidad | Responsable | Endpoints que consume |
|---|---|---|---|---|
| 01 | Dashboard | F6 | Fabrizio | `GET /api/v2/dashboard/metricas` (2.12) |
| 02 | Pedidos (bandeja) | F1 | Michael | `GET /api/v1/pedidos` (1.4, admin) |
| 03 | Detalle del pedido | F1 | Michael | `GET /api/v1/pedidos/{id}` (1.3) |
| 04 | Anulaciones | F2 | Luis Arroyo | `POST .../anulaciones` (1.7), `GET .../anulaciones/pendientes` (1.8), `PATCH .../anulaciones/{id}` (1.9) |
| 05 | Hub Postventa | — | Joseph (asignado 2026-10-12 — pantalla "pegamento" entre F3, F4 y F6, ver 1.1 de la guía) | Agrega indicadores de F3 a F6, no tiene endpoint propio |
| 06 | Devoluciones y cambios | F3 | Joseph | 2.1 a 2.5 |
| 07 | Reclamos | F6 | Fabrizio | 2.8 a 2.11 |
| 08 | Reembolsos | F4 | Luis Alejandro | 2.6 |
| 09 | Calificaciones y reportes | F5 + F6 | Johan (calificaciones) + Fabrizio (reportes) | 2.7 (CSAT), 2.12 (métricas) |

Detalle de cada pantalla (controles, interacciones, datos de ejemplo) en `diseno/mockups/Mockup 0N - *.md`. El recorrido completo entre pantallas está en `diseno/mockups/Contexto y Flujo - Mockup.md` — léanlo antes de empezar, explica cómo se conectan las 9 pantallas entre sí.

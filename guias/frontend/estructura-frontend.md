# Estructura del frontend - Módulo D Ventas y Postventa

El repositorio `G5-Ventas-Postventas-Frontend` está vacío todavía (2026-10-12) — esta es la estructura que debe tener desde el primer commit, para que nadie empiece a programar en carpetas distintas. React 18+, TypeScript, Vite, Mantine UI (ver `specs/stack-frontend.md`). Una sola aplicación (no hay separación por microservicio como en el backend): el frontend consume tanto M1 (`api-ventas`) como M2 (`api-postventa`) desde el mismo portal del Gestor.

```text
G5-Ventas-Postventas-Frontend/             repositorio del frontend
├── package.json
├── vite.config.ts
├── tsconfig.json
├── .env.example                            plantilla; cada uno crea su .env (no se sube)
├── .gitignore
├── README.md
│
└── src/
    ├── main.tsx
    ├── App.tsx                             rutas (React Router) y layout general
    ├── theme/
    │   └── index.ts                        theme de Mantine (colores, radios, tipografía — derivados de Figma)
    ├── components/                         UI Kit reutilizable (sección 3 de stack-frontend.md)
    │   ├── EstadoBadge/                     badges de pedido, devolución, reclamo, reembolso
    │   ├── TablaPaginada/
    │   ├── ModalConfirmacion/
    │   ├── EstadoCarga/                     loading / vacío / error, reutilizable en toda pantalla
    │   └── ...
    ├── pages/                               una carpeta por pantalla (Mockup 01 a 09)
    │   ├── Dashboard/                       Mockup 01 — Fabrizio (F6)
    │   ├── Pedidos/                         Mockup 02 — Michael (F1)
    │   ├── DetallePedido/                   Mockup 03 — Michael (F1)
    │   ├── Anulaciones/                     Mockup 04 — Luis Arroyo (F2)
    │   ├── HubPostventa/                    Mockup 05 — compartida, ver guía 1.1
    │   ├── Devoluciones/                    Mockup 06 — Joseph (F3)
    │   ├── Reclamos/                        Mockup 07 — Fabrizio (F6)
    │   ├── Reembolsos/                      Mockup 08 — Luis Alejandro (F4)
    │   └── CalificacionesReportes/          Mockup 09 — Johan (F5) + Fabrizio (reportes, F6)
    ├── services/                            integración con endpoints, una carpeta por funcionalidad
    │   ├── api.ts                           cliente HTTP central (interceptor de JWT, manejo de errores)
    │   ├── pedidos.ts                       1.1 a 1.6, 1.10 (api-ventas.md)
    │   ├── anulaciones.ts                   1.7 a 1.9 (api-ventas.md)
    │   ├── devoluciones.ts                  2.1 a 2.5 (api-postventas.md)
    │   ├── reembolsos.ts                    2.6
    │   ├── calificaciones.ts                2.7
    │   └── reclamos.ts                      2.8 a 2.12
    ├── types/                               interfaces TypeScript, un archivo por contrato
    │   ├── pedido.ts
    │   ├── devolucion.ts
    │   ├── reembolso.ts
    │   ├── calificacion.ts
    │   └── reclamo.ts
    └── hooks/                               lógica reutilizable (paginación, confirmación, polling de estado)
```

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

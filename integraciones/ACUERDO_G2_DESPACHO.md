# Acuerdo con G2 — Despacho y Logística

Confirmado con el equipo de Despacho. Última actualización: 2026-10-13.

## Qué consumimos de ellos

- `POST /api/v1/despachos` — creamos el despacho cuando el paquete está físicamente preparado y sellado en el centro de despacho (no apenas el pedido pasa a `EN_PREPARACION`).
- `POST /api/v1/despachos/pedidos/{idPedido}/cancelacion` — pedimos la cancelación del envío cuando se confirma una anulación (F2) sobre un pedido con despacho ya programado.
- `GET /api/v1/seguimientos/pedidos/{idPedido}` (scope `seguimientos:leer`) — disponible si necesitamos consultar hitos históricos del despacho.

## Qué consumen ellos de nosotros

`POST /api/v1/integraciones/despachos/eventos` — webhook genérico donde Despacho nos notifica cada evento del ciclo logístico.

## Decisiones confirmadas

| # | Qué se acordó | Dónde quedó documentado |
|---|---|---|
| D1 | **Momento del disparo de `POST /api/v1/despachos`:** cuando el paquete está físicamente preparado y sellado, listo para entrega — no apenas `EN_PREPARACION`. Si se llamara antes, Despacho lo coloca en `PENDIENTE_ASIGNACION` y correría el riesgo de asignarse a ruta un paquete aún no armado. | `api-ventas.md` 1.5 (pendientes de implementación); `guia-backend.md` 5.6/5.7 |
| D2 | **Webhook genérico de eventos** (`POST /api/v1/integraciones/despachos/eventos`), reemplaza el `PATCH .../estado` y `POST .../eventos-logistica` anteriores. Mapeo completo de los 7 tipos de evento confirmado tal cual lo propusimos: `DESPACHO_ASIGNADO` (sin cambio de estado), `DESPACHO_EN_CAMINO` (`EN_PREPARACION → DESPACHADO`), `DESPACHO_ENTREGADO` (`DESPACHADO → ENTREGADO`), `DESPACHO_FALLIDO` (sin cambio, solo auditoría, máx. 2 intentos de política de Despacho), `DESPACHO_DEVUELTO_A_ORIGEN` (`DESPACHADO → ANULADO`, motivo `ENTREGA_FALLIDA_DEFINITIVA`, origina reembolso a M2). | `api-ventas.md` 1.5 |
| D3 | **`DESPACHO_REPROGRAMADO` no se ignora:** trae `datos.nuevaFechaProgramada`, necesaria para actualizar la fecha estimada de entrega en el portal del cliente y en los canales. Falta agregar la columna `pedido.fecha_estimada_entrega` al modelo de datos (tarea nuestra, no bloquea el acuerdo). | `api-ventas.md` 1.5; `AGENTS.md` sección 4 |
| D4 | **`DESPACHO_CANCELADO`** es el acuse idempotente de que una cancelación que nosotros solicitamos ya se aplicó en Despacho — no reabre nada si ya estaba `ANULADO` de nuestro lado. | `api-ventas.md` 1.5 |
| D5 | **`guiaRemision` se retira** de nuestros contratos — Despacho no emite ni gestiona guías de remisión. `datos.motivoCierre` de `DESPACHO_DEVUELTO_A_ORIGEN` (ej. `MAXIMO_INTENTOS_ALCANZADO`, `ANULACION_SOLICITADA_POR_VENTAS`, `PAQUETE_DANADO`) es suficiente para la auditoría de la anulación y el reembolso. | `api-ventas.md` 1.5 |
| D6 | **Ruta del webhook:** `/api/v1/integraciones/despachos/eventos`, tal cual la propusimos. | `api-ventas.md` 1.5 |
| D7 | **Scope del token:** reusamos `ventas:pedidos:estado`, ya concedido a `modulo-despacho` para el diseño anterior — decisión nuestra, no pedimos el `despachos:eventos:recibir` que propuso Despacho, porque ya está concedido, es semánticamente correcto y evita otro registro con Seguridad (G7). | `api-ventas.md` 1.5; `AGENTS.md` sección 2 punto 13 |
| D8 | **`409 Conflict` al cancelar un despacho ya `EN_CAMINO`** (condición de carrera: la orden de cancelación de Ventas llega después de que el repartidor ya inició el traslado): no se reintenta esa misma llamada; la anulación se marca como improcedente comercialmente (no como falla técnica), se notifica al cliente que su pedido ya está en camino. Si luego se entrega, el cliente usa el flujo de devolución (F3); si el cliente lo rechaza en puerta y Despacho lo marca `DESPACHO_FALLIDO`, Ventas sí vuelve a invocar la cancelación (el pedido ya está anulado de nuestro lado) — Despacho responde `202 Accepted`, registra `pedidoAnulado=true` y cierra directo como `DEVUELTO_A_ORIGEN` sin reprogramar. | ESP-06 CA-06 (nuevo) |
| D9 | **`Idempotency-Key: <UUID-v4>`** (máximo 128 caracteres), obligatoria en `POST /api/v1/despachos` y `POST /api/v1/despachos/pedidos/{idPedido}/cancelacion` — misma convención H-02 ya vigente con Marketplace. | `api-ventas.md` 1.5 |

## Pendiente — tareas de implementación nuestras (ya no hay nada que preguntarle a Despacho)

- Definir qué acción concreta de nuestro lado marca "paquete sellado y listo" para disparar `POST /api/v1/despachos` (D1) — diseño de F1/frontend (¿confirmación del Gestor en el centro de despacho?, ¿checklist?).
- Agregar `pedido.fecha_estimada_entrega` al modelo de datos (D3) y aplicar la migración en Supabase.
- Implementar ESP-06 CA-06 (D8) en el orquestador de F2.
- `LISTO_PARA_RECOJO` como sub-estado de Despacho (pregunta original de Retail, ver `ACUERDO_G4_RETAIL.md` R10) sigue sin confirmar — no es parte de esta consulta, es un hilo aparte con G2.
- **Nota (2026-10-16, no requiere nada de G2):** el cambio de producto de F3 (`CAMBIO`) se resolvió con Productos (issue G6 #100) como una orden de reemplazo que M1 despacha por su flujo normal — Despacho recibe y procesa ese despacho exactamente igual que cualquier pedido, sin distinguir que es un reemplazo. No hace falta ningún acuerdo nuevo con G2 por esto.

## Historial

- 2026-10-10: Se envía `CONSULTA_G2_DESPACHO.md` con 6 preguntas (momento del disparo de `POST /despachos`, mapeo de eventos del webhook, suficiencia de `motivoCierre`, ruta y scope del webhook, manejo del `409 Conflict` en cancelación, convención de `Idempotency-Key`).
- 2026-10-12: Despacho responde las 6 preguntas (`RESPUESTA_COORDINACION_VENTAS_DESPACHO.md`). Confirman el webhook genérico completo, incluyendo que `DESPACHO_REPROGRAMADO` no se ignora y el manejo de negocio del `409 Conflict`; proponen un scope nuevo (`despachos:eventos:recibir`).
- 2026-10-13: Decidimos reusar `ventas:pedidos:estado` en vez de pedir el scope nuevo (D7). Se actualiza `api-ventas.md`, `guia-backend.md`, `ESP-06` (CA-06 nuevo) y `AGENTS.md`. Acuerdo cerrado; quedan solo tareas de implementación de nuestro lado, no preguntas a G2.

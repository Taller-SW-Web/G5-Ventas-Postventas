# Acuerdo con G6 — Productos y Ofertas

Confirmado con el equipo de Productos y Ofertas. Última actualización: 2026-10-11.

## Qué consumimos de ellos

Precio y disponibilidad por ítem al crear el pedido; reserva, confirmación y liberación de stock; reposición física por devolución; consumo y restauración de cupón (por eventos).

## Qué consumen ellos de nosotros

Nada directamente — Productos no consume ninguna API de Ventas/Postventa.

## Decisiones confirmadas

| # | Fecha | Qué se acordó | Dónde quedó documentado |
|---|---|---|---|
| — | 2026-10-11 | `customer_ref` = UUID del claim `sub` de Seguridad, confirmado y alineado con la migración que ya hicimos. | `AGENTS.md` sección 2, punto 10 |
| — | 2026-10-11 | **Reserva de inventario:** `POST /api/v1/inventario/reservas` al crear el pedido (`202 Accepted` = comando admitido, no reserva concretada; el resultado definitivo llega asíncrono). | `ESP-01-creacion-pedido.md`, regla 5 |
| — | 2026-10-11 | **Confirmación de consumo:** `POST /api/v1/inventario/{reservaId}/confirmar` al pasar el pedido a `PAGADO`. | `F1-Ciclo de vida del pedido.md`, CA-07 |
| — | 2026-10-11 | **Liberación de reserva:** `POST /api/v1/inventario/{reservaId}/liberar` en anulaciones pre-consumo (`CREADO`/`PAGADO`, tanto por solicitud de F2 como por `PAGO_NO_COMPLETADO`). | `ESP-06-coordinacion-stock-despacho.md`, CA-01 y CA-02 |
| — | 2026-10-11 | **Reintegro por devolución física:** `POST /api/v1/inventario/reintegros` (no `/liberar`, corrección sobre nuestra consulta original), disparado cuando el Gestor aprueba la resolución (`CAMBIO` o `REEMBOLSO`) en ESP-08 — no existe un paso de recepción física separado en nuestro flujo, la aprobación del Gestor (basada en la evidencia de ESP-07) hace de confirmación. Admite reintegros parciales por línea/cantidad. | `ESP-08-resolucion-cambio-reembolso.md`, flujos B y D |
| — | 2026-10-11 | **Decisión de equipo: M1 se conecta directo al broker RabbitMQ de Productos**, sin pedir un adaptador HTTP propio — no quedaba claro que Productos lo fuera a construir por nosotros, así que no ahorraba trabajo real. Su topología sigue en versión candidata (`0.6.0-rc.1`); no la consideran operativa todavía. | `AGENTS.md` sección 2, punto 12 |
| — | 2026-10-11 | **Consumo de cupón es exclusivamente por evento** (no existe endpoint HTTP, usa la conexión RabbitMQ del punto anterior): M1 publica `promotions.coupon.consumption.requested` a `po.commands.x` (routing key homónimo); Productos responde `completed`/`rejected` por `po.results.x`. Requiere correlación de operación, reserva ya confirmada y referencia del snapshot comercial. Contempla restauración ante cancelaciones. | `AGENTS.md` sección 2, punto 12 |
| — | 2026-10-11, mecanismo confirmado 2026-10-12 | **Conciliación offline de Retail:** Productos recibe `POST /api/v1/inventario/conciliaciones-offline` con `offline_sale_id` y líneas de SKU/cantidad, aplica sin generar stock negativo y registra lo no resuelto para revisión. **Quién la llama:** Retail directo, no Ventas — confirmado con G4 que el stock de tienda es el mismo pool central, pero que M1 no reserva, confirma ni concilia nada; el POS descuenta al momento de la venta y Retail concilia las ventas offline directo con Productos (ver `ACUERDO_G4_RETAIL.md`, R9). M1 nunca llama a este endpoint. | `ACUERDO_G4_RETAIL.md`, R9 |

## Pendiente de confirmar / resolver

- **Confirmar con Productos que aceptan la llamada directo de Retail:** Productos construyó `conciliaciones-offline` probablemente esperando que la llamara `modulo-ventas` (su contraparte habitual). Ahora que se confirmó que es Retail quien la invoca directo (ver fila anterior), falta avisarle a Productos para que registre/autorice la credencial de servicio de Retail para ese endpoint, no la de Ventas.

## Historial

- 2026-10-10: Se envía `integraciones/CONSULTA_G6_PRODUCTOS.md` con 5 puntos (UUID, reserva/confirmación/liberación, consumo de cupón, RabbitMQ, conciliación offline de Retail).
- 2026-10-11: Productos responde los 5 puntos. Confirma UUID y los tres comandos de inventario, corrige que la devolución física usa `/reintegros` y no `/liberar`, confirma que el consumo de cupón es solo por evento (sin alternativa HTTP salvo que construyamos un adaptador), aclara que su topología RabbitMQ sigue en versión candidata, y confirma el endpoint de conciliación offline. Se actualizan `ESP-01`, `F1-Ciclo de vida del pedido.md`, `ESP-06` y `ESP-08` con los comandos HTTP confirmados.
- 2026-10-11: El equipo decide conectar M1 directo al broker RabbitMQ en vez de pedir un adaptador HTTP propio, tras evaluar que no estaba claro quién construiría ese adaptador.
- 2026-10-12: Al cerrar el acuerdo con Retail (G4), se confirma que es Retail quien llama directo a `conciliaciones-offline`, no Ventas — M1 no reserva, confirma ni concilia stock para pedidos `RETAIL` en ningún caso. Falta avisarle a Productos para que autorice la credencial de servicio de Retail en ese endpoint.

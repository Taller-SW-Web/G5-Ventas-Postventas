# Respuestas a consultas de integración — G1 Marketplace

Entre: Joseph (PO, G5 — Módulo D: Ventas y Postventa) y Jim Bryan Segovia Valencia (PO, G1 — Marketplace).

Registro formal y acumulativo de las consultas que Marketplace envía sobre su integración con `G5-Ventas-Postventas`, y la respuesta punto por punto de G5 a cada una. Cada consulta nueva se agrega como una sección fechada, sin reemplazar las anteriores. El estado de los acuerdos ya confirmados se mantiene aparte, en [`ACUERDO_G1_MARKETPLACE.md`](ACUERDO_G1_MARKETPLACE.md).

## Índice

- [2026-10-10 — Confirmaciones H-02 a H-05](#2026-10-10--confirmaciones-h-02-a-h-05)
- [2026-10-10 — Homologación de pago simulado (checkout)](#2026-10-10--homologación-de-pago-simulado-checkout)

---

## 2026-10-10 — Confirmaciones H-02 a H-05

Respuesta formal a `Confirmaciones formales de cada punto (H-02, H-03, H-04 y H-05)`. El repo de specs (`G5-Ventas-Postventas`) ya refleja los 4 puntos. Detalle de qué cambió y qué queda pendiente:

### H-02 — Idempotencia al crear pedidos

**Estado: Implementado en specs, sin pendientes.**

Todo lo que confirmamos quedó tal cual en el contrato:
- `Idempotency-Key` (UUID v4, máx. 128 caracteres) obligatoria en `POST /api/v1/pedidos`.
- Mismo titular + misma clave + mismo payload → `200`/`201` con el pedido ya creado, sin reservar stock de nuevo.
- Misma clave + payload distinto → `409 Conflict`, `IDEMPOTENCY_KEY_REUSED`.
- Concurrencia: primer hilo bloquea, los demás reciben el mismo resultado sin duplicar.
- Error de validación (`400`): la clave no se persiste, se puede reintentar.
- Reserva de stock retenida y ligada a la clave.

**Qué cambió en el repo:**
- `specs/api/api-ventas.md`, sección 1.1 — cabecera, comportamiento completo, errores `CABECERA_FALTANTE` (400) e `IDEMPOTENCY_KEY_REUSED` (409).
- `specs/especificaciones/funcionales/ESP-01-creacion-pedido.md` — precondición, regla de negocio 11, tabla de validaciones.
- `diseno/diagramas/bd/diagrama-logico.md` y `diagrama-fisico.md` — columna nueva `pedido.idempotency_key` (única).
- `specs/api/catalogo-errores.md` — los 2 códigos nuevos.

**Pendiente:** nada de nuestro lado. Implementación en código, a cargo de Michael (F1), todavía no iniciada (el endpoint 1.1 sigue sin programar según la guía de implementación del backend).

### H-03 — Historial de pedidos autorizado

**Estado: Implementado en specs, sin pendientes.**

- `GET /api/v1/pedidos/me` adoptado tal cual lo propusiste: identidad por JWT (`sub`/`customerId`), sin `clienteId` en query string, scope `ventas:pedidos:leer`.
- Sin compras previas → `200 OK` con `{ "items": [], "total": 0, "page": 1, "pageSize": 10 }`.
- Paginación `page` (default 1) / `pageSize` (default 10, máx. 50).
- Filtro `estado` con los 6 valores públicos que ya coinciden con los que ya manejábamos.
- Errores `401`/`403` tal cual.

**Decisión adicional que tomamos de este lado (no cambia nada de lo que pediste):** mantuvimos el endpoint existente `GET /api/v1/pedidos` (con `clienteId`) para uso exclusivo del Gestor en el backoffice — no es parte de lo que Marketplace consume, es solo para que el panel administrativo no pierda la forma de buscar pedidos de un cliente específico. Lo hablamos con Michael (dueño de F1) antes de implementarlo, porque su código ya estaba usando `clienteId` para ese otro caso de uso.

**Qué cambió en el repo:**
- `specs/api/api-ventas.md` — nueva sección 1.4b (`/pedidos/me`), con nota explícita de que su formato de paginación (`items`/`total`/`page`/`pageSize`) es una excepción deliberada al patrón del resto de la API.
- `specs/especificaciones/funcionales/ESP-02-consulta-listado-pedidos.md` — nuevo flujo 7.2b, regla 5, parámetros y ejemplo de ruta.

**Pendiente:** nada de nuestro lado. Implementación en código, a cargo de Michael, todavía no iniciada — ahora programará `/pedidos/me` según lo acordado.

### H-04 — Encuesta posterior a entrega CSAT

**Estado: Implementado en specs, sin pendientes.**

- `POST /api/v2/csat` recibe `puntuacion` `1`/`3`/`5` (el mapeo a `sentiment` queda de tu lado, nosotros no lo guardamos, solo la `puntuacion` numérica).
- `comentario` acepta temporalmente el prefijo `"Motivos: [...] - "` como texto libre, sin parseo de nuestro lado.
- Titularidad: `pedidoId` debe pertenecer al `sub` del JWT → `403 Forbidden`.
- Pedido no `ENTREGADO` → `422 Unprocessable Entity`, `ORDER_NOT_DELIVERED` (usamos literalmente tu código y status, no el `409`/`PEDIDO_NO_ENTREGADO` que usamos en el resto de nuestra API — quedó anotado como excepción).
- Ya calificado → `409 Conflict`, `CSAT_ALREADY_SUBMITTED` (ídem, excepción literal para este endpoint).

**Qué cambió en el repo:**
- `specs/api/api-postventas.md`, sección 2.7 — nota del acuerdo completa y las 4 respuestas de error con los códigos exactos.
- `specs/especificaciones/funcionales/ESP-11-captura-de-encuesta-CSAT.md` — precondición de titularidad.
- `specs/api/catalogo-errores.md` — `ORDER_NOT_DELIVERED` y `CSAT_ALREADY_SUBMITTED`, con nota de que son la excepción de este endpoint.

**Pendiente:** nada de nuestro lado.

### H-05 — Estados de despacho para notificaciones

**Estado: Contrato implementado en specs. Mecanismo de entrega sigue pendiente — este sí tiene algo abierto.**

- Webhook `pedidos.envio.estado_actualizado` (v1.0.0), con exactamente el payload que propusiste (`eventId`, `eventType`, `version`, `timestamp`, `emitter`, `data` con `orderId`/`publicStatus`/`trackingNumber`/`estimatedDeliveryDate`).
- Deduplicación por `eventId` de tu lado, confirmado.
- Privacidad (sin datos sensibles ni direcciones), confirmado.

**Qué cambió en el repo:**
- `specs/api/api-ventas.md` — nueva sección 1.10 con el contrato completo.
- `integraciones/ACUERDO_G1_MARKETPLACE.md` — registro formal del acuerdo.

**Pendiente — avisamos apenas se resuelva:**
1. El mecanismo técnico de entrega (reintentos, backoff, cola de salida) todavía no está diseñado.
2. Todavía no está asignado quién lo construye dentro de nuestro equipo — lo estamos coordinando.

Mientras tanto, mantenlo como dependencia abierta, tal como dijiste.

---

## 2026-10-10 — Homologación de pago simulado (checkout)

Respuesta formal a `Consulta-homologacion-pago-simulado-Marketplace-Ventas.md`. Homologación aparte del acuerdo de idempotencia de H-02, tal como aclaraste — no lo modifica.

**Aparte, sobre el formato de `orderId`:** confirmado, el identificador de pedido es siempre texto, formato `PED-YYYY-NNNNN` (ej. `PED-2026-00981`) — igual en creación, consulta y en el webhook de envío (1.1, 1.3, 1.4b, 1.10). El `1042` numérico que viste en el ejemplo del webhook era un resto de plantilla genérica, nunca una decisión real; ya lo corregimos en el repo.

**Resumen de la solución:** Ventas (M1) es quien invoca al simulador de pasarela para iniciar el cobro, inmediatamente después de crear el pedido con la reserva de stock y el cupón ya confirmados. Marketplace no necesita invocar nada de pago — ni el simulador ni el endpoint reservado a la pasarela (`1.2`, `pagos/notificacion`). Solo crean el pedido y consultan su estado hasta ver `PAGADO`. Esto ya era consistente con cómo está diseñado el simulador (solo habla con M1, nunca queda expuesto a canales externos); lo que faltaba era dejarlo explícito en las specs, y ya quedó.

Respuesta punto por punto:

1. **Creación y preparación.** Sí: la reserva de stock y la aplicación/validación del cupón ya están confirmadas en el mismo `201 Created` — no quedan pendientes (`ESP-01`, regla de negocio 11; `api-ventas.md` 1.1). Ese mismo `201 Created` es la señal de que el pedido está apto para continuar. El dueño del precio/descuento final es M1; el `total` autoritativo llega en el campo `total` de esa misma respuesta.
2. **Confirmación simulada autorizada.** M1 invoca al simulador de pasarela por su cuenta, apenas termina de responder la creación (`F1-Ciclo de vida del pedido.md`, CA-01b; `ESP-01`, regla 12). Marketplace no participa en esa llamada, no necesita credenciales ni scope para ella, y no debe invocar `1.2` bajo ningún escenario — sigue reservado a la pasarela/simulador.
3. **Identidad e idempotencia.** Deja de aplicarles directamente: como no llaman al simulador, no gestionan ninguna referencia de esa operación. El único identificador que les importa es el `pedidoId` que ya reciben en el `201 Created` (H-02). La idempotencia de la llamada interna M1 → simulador es responsabilidad nuestra.
4. **Resultado verificable.** La fuente autoritativa es `GET /api/v1/pedidos/{pedidoId}` (1.3, detalle con `historialEstados` completo) o `GET /api/v1/pedidos/me` (1.4b, H-03, listado con el campo `estado` por ítem, sin historial detallado). Para el checkout, con el campo `estado` de cualquiera de los dos endpoints les basta. No muestren compra confirmada hasta que ese `estado` sea literalmente `PAGADO`.
5. **Timeout y recuperación.** Si se pierde la respuesta tras crear el pedido, consulten por `pedidoId` con 1.3/1.4b las veces que necesiten — es de solo lectura e idempotente por naturaleza. Si el estado sigue en `CREADO` más tiempo del esperado, es algo nuestro (del simulador o de la orquestación M1 → simulador) que deben reportarnos, no algo que deban compensar ustedes.
6. **Fallos, expiración y compensaciones.** Si el simulador rechaza el cobro, M1 transiciona el pedido directo a `ANULADO` con motivo `PAGO_NO_COMPLETADO` y repone el stock automáticamente, sin intervención del Gestor y sin pasar por reembolso (nunca hubo pago confirmado). Esto ya estaba cubierto para el abandono/timeout iniciado por el canal; lo extendimos explícitamente al rechazo iniciado por la pasarela (`api-ventas.md` 1.2; `F1-Ciclo de vida del pedido.md`, CA-07b). Nota honesta: la liberación del cupón ante Productos y Ofertas no tiene integración documentada en nuestro repo todavía — es un gap preexistente (afecta también al caso de abandono por timeout, que ya existía antes de tu consulta), no algo nuevo de esta homologación. Lo marcamos para resolver aparte. Un resultado tardío sobre un pedido que ya está `ANULADO` o `PAGADO` se rechaza por la máquina de estados — no hay arista para eso, así que nunca lo reabre.
7. **Coordinación con Productos.** No cambia respecto a lo que ya sabían: M1 valida precio y disponibilidad contra Productos (F) al crear el pedido (1.1); si falla, responde `409 Conflict` sin persistir nada. No necesitan inferir stock ni recalcular importes — el `total` del `201 Created` ya es el autoritativo.

**Qué cambió en el repo:**
- `specs/api/api-ventas.md` — nota de orquestación en 1.1, corrección del `orderId` en el ejemplo de 1.10, nota de reposición de stock/cupón en la tabla de 1.2.
- `specs/funcionalidades/F1-Ciclo de vida del pedido.md` — nuevo CA-01b (disparo del cobro) y CA-07b (anulación por rechazo de la pasarela), ajustes de alcance y dependencias.
- `specs/especificaciones/funcionales/ESP-01-creacion-pedido.md` — paso 14 del flujo y regla de negocio 12.
- `arquitectura/c4-nivel-2` y `c4-nivel-3` — interacción y flecha M1 → simulador.
- `AGENTS.md` — decisión cerrada (sección 2, punto 8), para que no se reabra.

**Pendiente:** nada de nuestro lado para homologar el flujo. Igual que H-02 a H-05, la implementación en código (orquestar la llamada al simulador desde M1) está a cargo de Michael (F1) y todavía no ha comenzado.

---

## Resumen general (todas las consultas)

| Punto | Specs al día | Pendiente real |
|---|---|---|
| H-02 | ✅ | Solo implementación de código (no iniciada) |
| H-03 | ✅ | Solo implementación de código (no iniciada) |
| H-04 | ✅ | Solo implementación de código (no iniciada) |
| H-05 | ✅ contrato | Mecanismo de entrega + responsable, por definir |
| Pago simulado (checkout) | ✅ | Solo implementación de código (no iniciada) |

Cualquier cosa que no cuadre al revisar el repo, avísame directo.

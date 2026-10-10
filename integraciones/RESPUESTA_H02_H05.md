# Respuesta a confirmaciones H-02 a H-05 — Módulo D (Ventas y Postventa)

Para: Jim (Marketplace) · De: Joseph (G5) · Fecha: 2026-10-10

Respuesta formal a `Confirmaciones formales de cada punto (H-02, H-03, H-04 y H-05)`. El repo de specs (`G5-Ventas-Postventas`) ya refleja los 4 puntos. Detalle de qué cambió y qué queda pendiente:

---

## H-02 — Idempotencia al crear pedidos

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

---

## H-03 — Historial de pedidos autorizado

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

---

## H-04 — Encuesta posterior a entrega CSAT

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

---

## H-05 — Estados de despacho para notificaciones

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

## Resumen para contrastar

| Punto | Specs al día | Pendiente real |
|---|---|---|
| H-02 | ✅ | Solo implementación de código (no iniciada) |
| H-03 | ✅ | Solo implementación de código (no iniciada) |
| H-04 | ✅ | Solo implementación de código (no iniciada) |
| H-05 | ✅ contrato | Mecanismo de entrega + responsable, por definir |

El repo ya está actualizado y pusheado a `main` (`G5-Ventas-Postventas`, carpeta `integraciones/` y `specs/api/`). Cualquier cosa que no cuadre al hacer `fetch`, avísame directo.

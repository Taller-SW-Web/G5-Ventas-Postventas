# Acuerdo con G1 — Marketplace (Canal A)

Confirmado con el equipo de Marketplace (contacto: Jim). Última actualización: 2026-10-10.

## Qué consumimos de ellos

Nada todavía formalizado en este documento — Marketplace es quien consume nuestra API (ver abajo). Si en el futuro Marketplace expone algo que nosotros necesitemos (por ejemplo, validación de sesión del lado de ellos), se agrega aquí.

## Qué consumen ellos de nosotros

Marketplace consume los endpoints de M1 (`api-ventas.md`) y M2 (`api-postventas.md`) para: creación y consulta de pedidos, historial de compras del cliente, encuesta CSAT, y recibe un webhook de M1 con los cambios de estado de envío.

## Decisiones confirmadas

| # | Fecha | Qué se acordó | Dónde quedó documentado |
|---|---|---|---|
| H-02 | 2026-10-10 | `POST /api/v1/pedidos` exige cabecera `Idempotency-Key` (UUID v4). Mismo titular + misma clave + mismo payload devuelve el pedido ya creado; misma clave con payload distinto responde `409 IDEMPOTENCY_KEY_REUSED`; error de validación no persiste la clave. | `api-ventas.md` 1.1; `ESP-01`, reglas 11 y validaciones; `diagrama-fisico.md`/`diagrama-logico.md` (columna `pedido.idempotency_key`) |
| H-03 | 2026-10-10 | Se adopta `GET /api/v1/pedidos/me` para que el cliente autenticado consulte su propio historial, identidad tomada del JWT (`sub`/`customerId`), sin `clienteId` en la URL. Paginación `page`/`pageSize` (default 1/10, máx. 50) y respuesta `{ items, total, page, pageSize }` — formato distinto al resto de la API, por acuerdo explícito con Marketplace. El endpoint existente `GET /api/v1/pedidos` (con `clienteId`) se mantiene para uso del Gestor en el backoffice. | `api-ventas.md` 1.4 y 1.4b; `ESP-02`, secciones 7.2b, 9 y 12 |
| H-04 | 2026-10-10 | `POST /api/v2/csat`: Marketplace traduce su escala de 3 botones (Mal/Regular/Bien) a `puntuacion` `1`/`3`/`5` (`sentiment` NEGATIVE/NEUTRAL/POSITIVE queda solo de su lado). Validaciones: titularidad del `pedidoId` vs `sub` del JWT → `403 Forbidden`; pedido no `ENTREGADO` → `422 Unprocessable Entity` (`ORDER_NOT_DELIVERED`); ya calificado → `409 Conflict` (`CSAT_ALREADY_SUBMITTED`). Mientras consolidan su tabla de motivos estructurados, pueden incluir motivos concatenados dentro de `comentario` con el prefijo `"Motivos: [...] - "`. No requiere cambio de esquema de nuestro lado. | `api-postventas.md` 2.7; `ESP-11`, precondiciones; `catalogo-errores.md` |
| H-05 | 2026-10-10 | M1 expone el webhook `pedidos.envio.estado_actualizado` (v1.0.0) hacia Marketplace, como intermediario de los eventos internos de Despacho (Módulo E). Marketplace deduplica por `eventId`. Payload no incluye datos sensibles, solo tracking y estado público. | `api-ventas.md` 1.10 |
| — | 2026-10-10 | Homologación del pago simulado: M1 invoca al simulador de pasarela por su cuenta, inmediatamente tras crear el pedido con reserva/cupón confirmados. Marketplace no invoca el simulador ni el endpoint `1.2` (reservado a la pasarela) — solo crea el pedido y consulta su estado (1.3/1.4b) hasta ver `PAGADO`. Si el simulador rechaza, M1 anula directo (`PAGO_NO_COMPLETADO`) y repone stock, sin reembolso (la liberación del cupón ante Productos queda como gap pendiente, ver AGENTS.md sección 4). Formato de `orderId` confirmado como texto (`PED-YYYY-NNNNN`) en todos los contratos, incluido el webhook de H-05. | `api-ventas.md` 1.1, 1.2, 1.10; `F1-Ciclo de vida del pedido.md` CA-01b/CA-07b; `ESP-01` reglas 12 |

## Pendiente de confirmar / resolver

- **H-05 — mecanismo de entrega:** el contrato del webhook ya está cerrado, pero el mecanismo técnico (reintentos, backoff, cola de salida) todavía no está diseñado. Queda a cargo de quien construya F1 (ver `AGENTS.md`, sección 4).
- **Quién construye H-05:** no está asignado formalmente a nadie en la guía de implementación del backend — hay que confirmarlo con el equipo.
- Confirmar con Marketplace si las solicitudes de postventa (F3 a F6) siempre les llegan a través de ellos, o si puede haber otro origen (ver `arquitectura/c4-nivel-1-contexto-ventas-postventa.md`, sección 5).

## Historial

- 2026-10-10: Joseph envía el primer documento de confirmaciones (H-02 a H-05) a Jim. El repo de specs todavía no reflejaba estos acuerdos.
- 2026-10-10: Se detecta el desfase (el repo no tenía H-02 a H-05), se resuelve con Michael la contradicción de H-03 (`/pedidos/me` vs `clienteId`, ya estaba en desarrollo con `clienteId`), y se actualizan los contratos y especificaciones correspondientes.
- 2026-10-10: Jim envía una consulta aparte sobre homologación del pago simulado del checkout (ver `RESPUESTAS_G1_MARKETPLACE.md`). Se detecta que el repo nunca definió quién dispara el cobro simulado tras crear un pedido — vacío autocontenido en G5 (M1 + simulador), no dependía de ningún otro módulo del curso. Se cierra el diseño (M1 orquesta, Marketplace no toca pago) y se actualizan specs y arquitectura.

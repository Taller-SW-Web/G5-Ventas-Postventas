# Catálogo de Eventos — Módulo D: Ventas y Postventa

## 1. Propósito

Consolidar en un solo lugar los eventos de dominio que M1 publica hacia M2 y hacia Productos y Ofertas (F), ya definidos en [ESP-04 — Publicación de eventos](../especificaciones/funcionales/ESP-04-publicacion-eventos.md). Este documento no define eventos nuevos: solo los reúne en un formato plano, consistente con [ADR-004](../../arquitectura/adr/ADR-004-fuente-verdad-contratos-api.md) (Markdown como fuente de verdad mientras no haga falta una herramienta formal).

No se usa **AsyncAPI** a propósito: ese formato describe sistemas con broker (canales, tópicos, colas), y el módulo decidió explícitamente no usar uno (ver sección 2).

---

## 2. Mecanismo de entrega (sin broker de mensajería)

Según `arquitectura/c4-nivel-2-contenedores-ventas-postventa.md`, sección 4.1:

- M1 registra cada evento en su **bandeja de salida (outbox)**, dentro de la misma transacción del cambio de estado.
- Un proceso posterior entrega el evento a los consumidores y reintenta conservando el mismo `eventoId`, para que un reintento no duplique el efecto.
- Los consumidores descartan los identificadores ya procesados (idempotencia, ver RNF-08).

Si en algún momento el equipo adopta un broker real (Kafka, RabbitMQ, etc.), recién ahí tendría sentido migrar este catálogo a un `asyncapi.yaml` formal — igual que ADR-004 prevé para los contratos REST con OpenAPI.

---

## 3. Estructura común del evento

Todos los eventos comparten esta forma (ver ESP-04, sección 8.1):

| Campo | Tipo | Obligatorio | Descripción |
|---|---|:---:|---|
| `eventoId` | UUID | Sí | Identificador único del evento (clave de idempotencia para reintentos). |
| `tipo` | Enumeración | Sí | `pedido.pagado` \| `pedido.anulado` \| `pedido.entregado`. |
| `pedidoId` | UUID | Sí | Pedido asociado. |
| `estadoAnterior` | Enumeración | Sí | Estado previo a la transición. |
| `estadoNuevo` | Enumeración | Sí | Estado resultante. |
| `actor` | Texto | Sí | Quién/qué disparó la transición (ver valores reales en [ESP-03](../especificaciones/funcionales/ESP-03-transiciones-historial.md)). |
| `motivo` | Texto | Condicional | Presente solo en `pedido.anulado`. |
| `fechaHora` | Fecha/hora | Sí | Momento de la transición, en UTC. |

---

## 4. Eventos publicados

| Evento | Disparador | Consumidores | ¿Incluye `motivo`? |
|---|---|---|---|
| `pedido.pagado` | Transición `CREADO → PAGADO` | M2 (agregados), F6 | No |
| `pedido.anulado` | Transición `→ ANULADO` (por `PAGO_NO_COMPLETADO` o por F2) | Productos y Ofertas — F (reposición de stock), F4 (si hubo pago), F6 | Sí, obligatorio — permite a F4 y a Productos saber si hubo pago que reembolsar |
| `pedido.entregado` | Transición `→ ENTREGADO` (confirmado por Despacho) | F5 (encuesta CSAT), F6 (agregados) | No |

---

## 5. Reglas de negocio (resumen de ESP-04)

1. Todo evento se publica en la misma operación que aplica la transición de estado — nunca de forma separada o diferida sin garantía.
2. Ninguna transición rechazada genera evento.
3. Los consumidores deben ser idempotentes: reprocesar un evento no debe duplicar su efecto (los agregados no se cuentan dos veces).
4. `pedido.anulado` siempre incluye `motivo`.

---

## 6. Pendientes

- El mecanismo de publicación concreto (qué tecnología implementa la bandeja de salida, cómo se entrega a cada consumidor) todavía no está definido — ESP-04 lo deja abierto explícitamente ("se define en `specs/api-contract.md` junto con el resto de la integración entre módulos"), y `specs/api-contract.md` tampoco lo detalla aún.
- La lógica de qué hace cada consumidor al recibir el evento no es parte de este catálogo — ver la especificación de cada consumidor (ESP-11 para F5, ESP-15 para F6, etc.).

---

## 7. Otros documentos relacionados

- [ESP-04 — Publicación de eventos](../especificaciones/funcionales/ESP-04-publicacion-eventos.md) — especificación completa, flujos alternativos y criterios de aceptación.
- [ESP-03 — Transiciones de estado e historial](../especificaciones/funcionales/ESP-03-transiciones-historial.md) — valores reales de `actor`.
- [arquitectura/c4-nivel-2-contenedores-ventas-postventa.md](../../arquitectura/c4-nivel-2-contenedores-ventas-postventa.md) — mecanismo de bandeja de salida.
- [../api-contract.md](../api-contract.md) — índice de contratos de API.

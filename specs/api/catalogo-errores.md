# Catálogo de Errores — Módulo D: Ventas y Postventa

## 1. Propósito

Consolidar en un solo lugar los errores de los dos contratos de API ([api-ventas.md](api-ventas.md) y [api-postventas.md](api-postventas.md)) y los `codigo` de negocio ya definidos en la guía de implementación del backend, en vez de dejarlos repartidos entre ambos. Este documento **no inventa errores nuevos**: todo lo que trae viene de uno de esos dos lugares. Cuando una fila viene solo de la guía (y todavía no está en el contrato correspondiente), queda marcado en la sección 6, Pendientes.

---

## 2. Formato estándar de error (igual en M1 y M2)

```json
{
  "codigo": "RECURSO_NO_ENCONTRADO",
  "mensaje": "Descripción legible del error",
  "timestamp": "2026-09-23T00:05:00Z",
  "detalles": []
}
```

---

## 3. Códigos de error de negocio formalizados

Definidos en la guía de implementación del backend (sección 3.3), además de `DOCUMENTO_INVALIDO` y `RECURSO_NO_ENCONTRADO` que ya venían de los contratos. Algunas condiciones (ver secciones 4 y 5) todavía no tienen código propio asignado — ver sección 6, Pendientes.

| Código | Significado |
|---|---|
| `RECURSO_NO_ENCONTRADO` | Ejemplo genérico del formato estándar de error, usado como ilustración en ambos contratos. |
| `PEDIDO_NO_ENCONTRADO` | El `pedidoId` indicado no existe. |
| `CODIGO_INVALIDO` | Un código público (`PED-...`, `ANUL-...`, `DEV-...`, `REEM-...`, `REC-...`) está mal formado al intentar extraer su `id` numérico. |
| `MOTIVO_REQUERIDO` | Falta el motivo al transicionar un pedido a `ANULADO` (ESP-03). |
| `TRANSICION_NO_PERMITIDA` | El par (estado actual, estado solicitado) no está en la matriz de ESP-03, o el actor no está autorizado para esa transición. |
| `DOCUMENTO_INVALIDO` | El número de documento no cumple el formato esperado para el `tipoDocumento` indicado (DNI, RUC, CE, PASAPORTE). |
| `ITEM_SIN_DISPONIBILIDAD` | Algún ítem del pedido no tiene stock disponible en Productos (F). |
| `MOTIVO_INVALIDO` | El motivo de anulación está ausente, fuera del catálogo `MotivoAnulacion`, o no aplica al estado actual del pedido. |
| `PEDIDO_NO_ANULABLE` | El pedido ya está `DESPACHADO` o `ENTREGADO`; corresponde iniciar una devolución (F3). |
| `PEDIDO_NO_ENTREGADO` | El pedido no está en estado `ENTREGADO` (requerido para devolución o calificación CSAT). |
| `PLAZO_VENCIDO` | La devolución se solicita más de 7 días naturales después de la entrega. |
| `EVIDENCIA_REQUERIDA` | El motivo de devolución exige evidencia y no se adjuntó ninguna. |
| `SIN_STOCK` | No hay stock disponible en Productos (F) para resolver una devolución como `CAMBIO`. |
| `ORIGEN_NO_PERMITIDO` | El reembolso se solicita con un `origen` distinto de `ANULACION` o `DEVOLUCION`. |
| `CLAVE_IDEMPOTENCIA_EN_CONFLICTO` | La `X-Idempotency-Key` ya existe para un reembolso con datos distintos (origen, monto, moneda). |
| `SALDO_INSUFICIENTE` | El monto del reembolso, sumado a los ya `EXITOSO`/`PENDIENTE` del mismo pedido, supera el total pagado. |
| `CALIFICACION_DUPLICADA` | Ya existe una encuesta CSAT registrada para ese pedido. |
| `RECLAMO_NO_ENCONTRADO` | El `codigoSeguimiento` o `reclamoId` indicado no existe. |
| `RESPUESTA_VACIA` | `respuestaVisibleCliente` está vacío o ausente al intentar cerrar un reclamo. |
| `CABECERA_FALTANTE` | Falta una cabecera obligatoria, por ejemplo `Idempotency-Key` en `POST /api/v1/pedidos`. |
| `IDEMPOTENCY_KEY_REUSED` | La `Idempotency-Key` ya se usó para crear un pedido con un payload distinto (acuerdo H-02 con Marketplace). |
| `ORDER_NOT_DELIVERED` | Equivalente a `PEDIDO_NO_ENTREGADO`, pero con `422` en vez de `409` — nombre y status code literales acordados con Marketplace en H-04, exclusivo de `POST /api/v2/csat`. |
| `CSAT_ALREADY_SUBMITTED` | Equivalente a `CALIFICACION_DUPLICADA` — nombre literal acordado con Marketplace en H-04, exclusivo de `POST /api/v2/csat`. |

---

## 4. Errores HTTP por endpoint — M1 (Ventas)

| Endpoint | HTTP | Condición | Código de negocio |
|---|---|---|---|
| `POST /api/v1/pedidos` | `400` | El número de documento no cumple el formato requerido para el tipo indicado. | `DOCUMENTO_INVALIDO` |
| `POST /api/v1/pedidos` | `400` | Cabecera `Idempotency-Key` ausente o con formato inválido. | `CABECERA_FALTANTE` |
| `POST /api/v1/pedidos` | `409` | Fallo de validación de catálogo o stock con el módulo de Productos (F). | `ITEM_SIN_DISPONIBILIDAD` |
| `POST /api/v1/pedidos` | `409` | `Idempotency-Key` ya usada con un payload distinto. | `IDEMPOTENCY_KEY_REUSED` |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `400` | Inconsistencia de montos o datos de transacción. | — |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `404` | El pedido indicado no existe. | `PEDIDO_NO_ENCONTRADO` |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `409` | El pedido no se encuentra en estado `CREADO`. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `401` | Token ausente o inválido. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `403` | El cliente autenticado no es el titular de la orden. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `404` | El pedido solicitado no existe. | `PEDIDO_NO_ENCONTRADO` |
| `PATCH /api/v1/pedidos/{pedidoId}/estado` | `409` | Transición no permitida por la máquina de estados. | `TRANSICION_NO_PERMITIDA` |
| `POST /api/v1/pedidos/{pedidoId}/anulaciones` | `400` | Motivo ausente o no tipificado. | `MOTIVO_INVALIDO` |
| `POST /api/v1/pedidos/{pedidoId}/anulaciones` | `409` | Pedido ya en `DESPACHADO` o `ENTREGADO` (derivar al microservicio M2). | `PEDIDO_NO_ANULABLE` |
| `GET /api/v1/pedidos/me` | `401` | Token ausente o inválido. | — |
| `GET /api/v1/pedidos/me` | `403` | El token no tiene el scope `ventas:pedidos:leer`. | — |
| `GET /api/v1/pedidos/anulaciones/pendientes` | — | Sin errores de negocio propios (solo `401`/`403` genéricos de autenticación/autorización). | — |
| `PATCH /api/v1/pedidos/{pedidoId}/anulaciones/{anulacionId}` | `409` | La anulación no está `PENDIENTE_AUTORIZACION`, o el pedido ya no está `EN_PREPARACION`. | — |

---

## 5. Errores HTTP por endpoint — M2 (Postventa)

| Endpoint | HTTP | Condición | Código de negocio |
|---|---|---|---|
| `POST /api/v2/devoluciones/evidencias/upload` | `400` | Formato no admitido o tamaño mayor a 5 MB. | — |
| `POST /api/v2/devoluciones` | `400` | Evidencias visuales faltantes (motivo que exige evidencia). | `EVIDENCIA_REQUERIDA` |
| `POST /api/v2/devoluciones` | `400` | Plazo excedido (> 7 días naturales desde la entrega). | `PLAZO_VENCIDO` |
| `POST /api/v2/devoluciones` | `409` | El pedido no se encuentra en estado `ENTREGADO`. | `PEDIDO_NO_ENTREGADO` |
| `GET /api/v2/devoluciones/{devolucionId}` | `404` | El expediente solicitado no existe. | — |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `400` | Rechazo sin fundamento explicativo. | — |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `404` | Expediente no encontrado. | — |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `409` | Cambio aprobado sin stock disponible en Productos (F). | `SIN_STOCK` |
| `POST /api/v2/reembolsos` | `400` | Monto fuera de rango o estructura inválida. | — |
| `POST /api/v2/reembolsos` | `403` | Solicitud con origen no permitido (distinto de `ANULACION` o `DEVOLUCION`). | `ORIGEN_NO_PERMITIDO` |
| `POST /api/v2/reembolsos` | `409` | La `X-Idempotency-Key` ya existe con datos distintos. | `CLAVE_IDEMPOTENCIA_EN_CONFLICTO` |
| `POST /api/v2/reembolsos` | `409` | El monto supera el saldo reembolsable del pedido. | `SALDO_INSUFICIENTE` |
| `POST /api/v2/csat` | `400` | Puntuación fuera de rango (1 al 5). | — |
| `POST /api/v2/csat` | `403` | El `pedidoId` no pertenece al `sub` del usuario autenticado. | — |
| `POST /api/v2/csat` | `422` | Pedido no está en estado terminal `ENTREGADO`. | `ORDER_NOT_DELIVERED` |
| `POST /api/v2/csat` | `409` | Encuesta ya registrada para ese pedido. | `CSAT_ALREADY_SUBMITTED` |
| `POST /api/v2/reclamos` | `400` | Datos incompletos del consumidor o motivo no tipificado. | — |
| `GET /api/v2/reclamos/{codigoSeguimiento}` | `401` | Token ausente o inválido. | — |
| `GET /api/v2/reclamos/{codigoSeguimiento}` | `404` | Reclamo no encontrado con ese código de seguimiento. | `RECLAMO_NO_ENCONTRADO` |
| `PATCH /api/v2/reclamos/{reclamoId}/respuesta` | `400` | Campo `respuestaVisibleCliente` vacío o nulo. | `RESPUESTA_VACIA` |
| `PATCH /api/v2/reclamos/{reclamoId}/respuesta` | `409` | El reclamo ya está `ATENDIDO`. | — |
| `POST /api/v2/eventos` | `400` | `tipo` de evento desconocido. | — |

---

## 6. Pendientes

- Algunas condiciones (marcadas `—` en las tablas 4 y 5) todavía no tienen un `codigo` de negocio propio ni en los contratos ni en la guía — por ejemplo, datos de pago inconsistentes, token ausente/inválido, rechazo de devolución sin fundamento, o estructura de reembolso inválida. Asignarles un código es una decisión de equipo que no corresponde inventar en este documento.

---

## 7. Otros documentos relacionados

- [api-ventas.md](api-ventas.md) — contrato completo de M1.
- [api-postventas.md](api-postventas.md) — contrato completo de M2.
- [../api-contract.md](../api-contract.md) — índice de contratos de API.

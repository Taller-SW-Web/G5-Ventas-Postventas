# Catálogo de Errores — Módulo D: Ventas y Postventa

## 1. Propósito

Consolidar en un solo lugar los errores que ya están definidos en los dos contratos de API ([api-ventas.md](api-ventas.md) y [api-postventas.md](api-postventas.md)), en vez de dejarlos repartidos endpoint por endpoint. Este documento **no define errores nuevos**: solo reorganiza lo que ya existe en ambos contratos.

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

## 3. Códigos de error de negocio ya formalizados

Solo dos códigos de error aparecen como valor literal de `codigo` en los contratos actuales. El resto de las condiciones de error están descritas en texto, pero sin un `codigo` propio asignado (ver sección 6, Pendientes).

| Código | Significado | Dónde aparece |
|---|---|---|
| `RECURSO_NO_ENCONTRADO` | Ejemplo genérico del formato estándar de error, usado como ilustración en ambos contratos. | Convenciones generales de api-ventas.md y api-postventas.md |
| `DOCUMENTO_INVALIDO` | El número de documento no cumple el formato esperado para el `tipoDocumento` indicado (DNI, RUC, CE, PASAPORTE). | api-ventas.md, 1.1 Crear Pedido (`400 Bad Request`) |

---

## 4. Errores HTTP por endpoint — M1 (Ventas)

| Endpoint | HTTP | Condición | Código de negocio |
|---|---|---|---|
| `POST /api/v1/pedidos` | `400` | El número de documento no cumple el formato requerido para el tipo indicado. | `DOCUMENTO_INVALIDO` |
| `POST /api/v1/pedidos` | `409` | Fallo de validación de catálogo o stock con el módulo de Productos (F). | — |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `400` | Inconsistencia de montos o datos de transacción. | — |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `404` | El pedido indicado no existe. | — |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `409` | El pedido no se encuentra en estado `CREADO`. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `401` | Token ausente o inválido. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `403` | El cliente autenticado no es el titular de la orden. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `404` | El pedido solicitado no existe. | — |
| `PATCH /api/v1/pedidos/{pedidoId}/estado` | `409` | Transición no permitida por la máquina de estados. | — |
| `POST /api/v1/pedidos/{pedidoId}/anulaciones` | `400` | Motivo ausente o no tipificado. | — |
| `POST /api/v1/pedidos/{pedidoId}/anulaciones` | `409` | Pedido ya en `DESPACHADO` o `ENTREGADO` (derivar al microservicio M2). | — |

---

## 5. Errores HTTP por endpoint — M2 (Postventa)

| Endpoint | HTTP | Condición | Código de negocio |
|---|---|---|---|
| `POST /api/v2/devoluciones/evidencias/upload` | `400` | Formato no admitido o tamaño mayor a 5 MB. | — |
| `POST /api/v2/devoluciones` | `400` | Evidencias visuales faltantes o plazo excedido (> 7 días naturales). | — |
| `POST /api/v2/devoluciones` | `409` | El pedido no se encuentra en estado `ENTREGADO`. | — |
| `GET /api/v2/devoluciones/{devolucionId}` | `404` | El expediente solicitado no existe. | — |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `400` | Rechazo sin fundamento explicativo. | — |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `404` | Expediente no encontrado. | — |
| `POST /api/v2/reembolsos` | `400` | Monto fuera de rango o estructura inválida. | — |
| `POST /api/v2/reembolsos` | `403` | Solicitud con origen no permitido (distinto de `ANULACION` o `DEVOLUCION`). | — |
| `POST /api/v2/reembolsos` | `409` | Conflicto de idempotencia o fallo de pasarela. | — |
| `POST /api/v2/csat` | `400` | Puntuación fuera de rango (1 al 5). | — |
| `POST /api/v2/csat` | `409` | Encuesta ya registrada para ese pedido. | — |
| `POST /api/v2/reclamos` | `400` | Datos incompletos del consumidor o motivo no tipificado. | — |
| `GET /api/v2/reclamos/{codigoSeguimiento}` | `401` | Token ausente o inválido. | — |
| `GET /api/v2/reclamos/{codigoSeguimiento}` | `404` | Reclamo no encontrado con ese código de seguimiento. | — |
| `PATCH /api/v2/reclamos/{reclamoId}/respuesta` | `400` | Campo `respuestaVisibleCliente` vacío o nulo. | — |

---

## 6. Pendientes

- La mayoría de condiciones de error (tabla 4 y 5) no tienen un `codigo` de negocio propio en los contratos actuales — solo la descripción en texto asociada al código HTTP. Asignar códigos como `ERR_...` para cada una es una decisión de equipo que no corresponde inventar en este documento; mientras no se defina, el campo `codigo` de la respuesta puede repetir la condición en mayúsculas o quedar genérico.
- `pago.estado`, `devolucion.estado` y `anulacion.estado` tampoco tienen lista de valores cerrada (ver "Pendientes" en [diagrama-logico.md](../../diseno/diagramas/bd/diagrama-logico.md)), lo que afecta a varias de las condiciones 409 de esta tabla.

---

## 7. Otros documentos relacionados

- [api-ventas.md](api-ventas.md) — contrato completo de M1.
- [api-postventas.md](api-postventas.md) — contrato completo de M2.
- [../api-contract.md](../api-contract.md) — índice de contratos de API.

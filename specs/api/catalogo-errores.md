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

## 3. Códigos de error de negocio ya formalizados

Códigos que ya aparecen como valor literal de `codigo` en los contratos. Los de 1.1 y 1.2 son los que devuelve `servicio-ventas`. El resto de condiciones están descritas en texto, sin `codigo` propio (ver sección 6, Pendientes).

| Código | Significado | Dónde aparece |
|---|---|---|
| `RECURSO_NO_ENCONTRADO` | Ejemplo genérico del formato estándar de error, usado como ilustración en ambos contratos. | Convenciones generales de api-ventas.md y api-postventas.md |
| `DOCUMENTO_INVALIDO` | El número de documento no cumple el formato esperado para el `tipoDocumento` indicado (DNI, RUC, CE, PASAPORTE). | api-ventas.md, 1.1 (`400`) |
| `DATOS_INVALIDOS` | Campo obligatorio ausente o con formato inválido; `detalles` indica cuál. | Todos los endpoints de M1 con cuerpo (`400`) |
| `FORMATO_INVALIDO` | JSON mal formado o valor fuera de catálogo (por ejemplo, un `canal` o `resultado` desconocido). | Todos los endpoints de M1 con cuerpo (`400`) |
| `CABECERA_FALTANTE` | Falta la cabecera `Idempotency-Key` o no es un UUID v4 (acuerdo H-02). | api-ventas.md, 1.1 (`400`) |
| `MONTOS_INCONSISTENTES` | Los montos no cuadran: subtotal o total del pedido, montos de pago `MIXTO`, o el monto notificado por la pasarela. | api-ventas.md, 1.1 y 1.2 (`400`) |
| `FECHA_VENTA_FUERA_DE_RANGO` | Retail: `fechaVenta` futura o con más de 72 horas (acuerdo G4). | api-ventas.md, 1.1 (`400`) |
| `IDEMPOTENCY_KEY_REUSED` | La `Idempotency-Key` ya se usó con un pedido distinto. | api-ventas.md, 1.1 (`409`) |
| `ITEM_SIN_DISPONIBILIDAD` | Productos (F) no confirma el stock de uno o más ítems. | api-ventas.md, 1.1 (`409`) |
| `PEDIDO_NO_ENCONTRADO` | El pedido indicado no existe. | api-ventas.md, 1.2 (`404`) |
| `ESTADO_NO_PERMITE_PAGO` | La notificación de pago llega para un pedido que ya no está en `CREADO`. | api-ventas.md, 1.2 (`409`) |
| `TRANSACCION_DE_OTRO_PEDIDO` | La `transaccionId` ya se registró en otro pedido. | api-ventas.md, 1.2 (`409`) |
| `TRANSICION_NO_PERMITIDA` | El cambio de estado no está en la matriz de ESP-03. | ESP-03; 1.5 y 1.7 (`409`) |
| `TOKEN_INVALIDO` / `ACCESO_DENEGADO` | Token ausente o inválido (`401`) / sin el rol o scope que exige el endpoint (`403`). | Todos los endpoints de M1 |

---

## 4. Errores HTTP por endpoint — M1 (Ventas)

| Endpoint | HTTP | Condición | Código de negocio |
|---|---|---|---|
| `POST /api/v1/pedidos` | `400` | El número de documento no cumple el formato requerido para el tipo indicado. | `DOCUMENTO_INVALIDO` |
| `POST /api/v1/pedidos` | `400` | Falta `Idempotency-Key` o no es UUID v4. | `CABECERA_FALTANTE` |
| `POST /api/v1/pedidos` | `400` | Campo obligatorio ausente o inválido (incluye reglas de Retail). | `DATOS_INVALIDOS` |
| `POST /api/v1/pedidos` | `400` | Subtotal o total no cuadran. | `MONTOS_INCONSISTENTES` |
| `POST /api/v1/pedidos` | `400` | Retail: `fechaVenta` fuera de las 72 horas. | `FECHA_VENTA_FUERA_DE_RANGO` |
| `POST /api/v1/pedidos` | `409` | Fallo de validación de catálogo o stock con el módulo de Productos (F). | `ITEM_SIN_DISPONIBILIDAD` |
| `POST /api/v1/pedidos` | `409` | `Idempotency-Key` repetida con otro cuerpo. | `IDEMPOTENCY_KEY_REUSED` |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `400` | Inconsistencia de montos o datos de transacción. | `MONTOS_INCONSISTENTES` / `DATOS_INVALIDOS` |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `404` | El pedido indicado no existe. | `PEDIDO_NO_ENCONTRADO` |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `409` | El pedido no se encuentra en estado `CREADO`. | `ESTADO_NO_PERMITE_PAGO` |
| `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | `409` | La `transaccionId` ya pertenece a otro pedido. | `TRANSACCION_DE_OTRO_PEDIDO` |
| `GET /api/v1/pedidos/me` | `401` | Token ausente o inválido. | `TOKEN_INVALIDO` |
| `GET /api/v1/pedidos/me` | `403` | El token no tiene el rol `CLIENTE`. | `ACCESO_DENEGADO` |
| `GET /api/v1/pedidos/{pedidoId}` | `401` | Token ausente o inválido. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `403` | El cliente autenticado no es el titular de la orden. | — |
| `GET /api/v1/pedidos/{pedidoId}` | `404` | El pedido solicitado no existe. | — |
| `PATCH /api/v1/pedidos/{pedidoId}/estado` | `409` | Transición no permitida por la máquina de estados. | `TRANSICION_NO_PERMITIDA` |
| `POST /api/v1/pedidos/{pedidoId}/anulaciones` | `400` | Motivo ausente o no tipificado. | — |
| `POST /api/v1/pedidos/{pedidoId}/anulaciones` | `409` | Pedido ya en `DESPACHADO` o `ENTREGADO` (derivar al microservicio M2). | — |
| `POST /api/v1/pedidos/reemplazos` | `400` | Un `sku` no está en el pedido original. | `ITEM_NO_PERTENECE_AL_PEDIDO` |
| `POST /api/v1/pedidos/reemplazos` | `400` | Se pide reponer más unidades de ese `sku` de las que se compraron. | `CANTIDAD_EXCEDE_COMPRADA` |
| `POST /api/v1/pedidos/reemplazos` | `404` | `pedidoOrigenId` no existe. | `PEDIDO_NO_ENCONTRADO` |
| `POST /api/v1/pedidos/reemplazos` | `409` | El pedido original no está `ENTREGADO`. | `PEDIDO_NO_ENTREGADO` |
| `POST /api/v1/pedidos/reemplazos` | `409` | El pedido original es del canal `RETAIL` (esos cambios se hacen en tienda). | `REEMPLAZO_NO_APLICA` |
| `POST /api/v1/pedidos/reemplazos` | `409` | La `devolucionId` ya tiene un reemplazo vigente de otro pedido origen. | `REEMPLAZO_YA_EXISTE` |

---

## 5. Errores HTTP por endpoint — M2 (Postventa)

| Endpoint | HTTP | Condición | Código de negocio |
|---|---|---|---|
| `POST /api/v2/devoluciones/evidencias/upload` | `400` | No se envió el archivo. | `ARCHIVO_REQUERIDO` |
| `POST /api/v2/devoluciones/evidencias/upload` | `400` | Formato no admitido, tamaño mayor a 5 MB, o contenido que no corresponde al formato declarado. | `ARCHIVO_INVALIDO` |
| `POST /api/v2/devoluciones/evidencias/upload` | `503` | Supabase Storage no responde. | `ALMACEN_NO_DISPONIBLE` |
| `POST /api/v2/devoluciones` | `400` | Evidencias visuales faltantes (motivo que exige evidencia). | `EVIDENCIA_REQUERIDA` |
| `POST /api/v2/devoluciones` | `400` | Plazo excedido (> 7 días naturales desde la entrega). | `PLAZO_VENCIDO` |
| `POST /api/v2/devoluciones` | `400` | Alguna `url` de `evidencias` no salió de 2.1. | `EVIDENCIA_INVALIDA` |
| `POST /api/v2/devoluciones` | `400` | Ítem fuera del pedido, o más unidades de las compradas. | `ITEM_INVALIDO` |
| `POST /api/v2/devoluciones` | `403` | El pedido pertenece a otro cliente. | `ACCESO_DENEGADO` |
| `POST /api/v2/devoluciones` | `404` | El pedido indicado no existe. | `PEDIDO_NO_ENCONTRADO` |
| `POST /api/v2/devoluciones` | `409` | El pedido no se encuentra en estado `ENTREGADO`. | `PEDIDO_NO_ENTREGADO` |
| `POST /api/v2/devoluciones` | `409` | Ya existe una devolución no rechazada sobre esas unidades. | `DEVOLUCION_EN_CURSO` |
| `POST /api/v2/devoluciones` | `503` | M1 no responde la consulta del pedido (1.3). | `VENTAS_NO_DISPONIBLE` |
| `GET /api/v2/devoluciones` (2.4) | `400` | Falta `clienteId`. | `PARAMETRO_FALTANTE` |
| `GET /api/v2/devoluciones` / `/me` (2.4, 2.4b) | `400` | Paginación fuera de rango o no numérica. | `PAGINACION_INVALIDA` |
| `GET /api/v2/devoluciones/{devolucionId}` | `404` | El expediente solicitado no existe. | `DEVOLUCION_NO_ENCONTRADA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `400` | Rechazo sin fundamento explicativo. | `FUNDAMENTO_REQUERIDO` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `400` | `tipoResolucion` incompatible con el expediente. | `RESOLUCION_INVALIDA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `404` | Expediente no encontrado. | `DEVOLUCION_NO_ENCONTRADA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `409` | Ya resuelto, o resuelto al mismo tiempo por otro Gestor. | `DEVOLUCION_NO_RESOLUBLE` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `409` | El pedido asociado ya no es compatible con la resolución. | `PEDIDO_INCONSISTENTE` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `409` | Cambio aprobado sin stock disponible en Productos (F). | `SIN_STOCK` |
| `PATCH /api/v2/devoluciones/{devolucionId}/resolucion` | `503` | Productos (F) no responde la validación de disponibilidad. | `PRODUCTOS_NO_DISPONIBLE` |
| `PATCH /api/v2/devoluciones/{devolucionId}/recepcion` | `400` | `cantidadApta` mayor que `cantidadRecibida`, o el SKU no pertenece al pedido original. | `CANTIDAD_INVALIDA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/recepcion` | `404` | Expediente no encontrado. | `DEVOLUCION_NO_ENCONTRADA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/recepcion` | `409` | El expediente no está `APROBADA`, o no requiere devolución física. | `RESOLUCION_NO_APROBADA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/recepcion` | `409` | Ya existe una confirmación de recepción para esas líneas — evita duplicar el reintegro. | `RECEPCION_YA_CONFIRMADA` |
| `PATCH /api/v2/devoluciones/{devolucionId}/recepcion` | `503` | Productos (F) no responde la solicitud de reintegro. | `PRODUCTOS_NO_DISPONIBLE` |
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

- Varias condiciones de error de M1 (tabla 4, 1.3 y 1.7) todavía no tienen un `codigo` de negocio propio en el contrato — solo la descripción en texto asociada al código HTTP. Asignarlos es una decisión de quien construya esos endpoints (F1, F2), no corresponde inventarlos en este documento.
- F3 (tabla 5) ya tiene todos sus códigos asignados (2026-10-12, contrato v1.5.0) — faltan F4 a F6.

---

## 7. Otros documentos relacionados

- [api-ventas.md](api-ventas.md) — contrato completo de M1.
- [api-postventas.md](api-postventas.md) — contrato completo de M2.
- [../api-contract.md](../api-contract.md) — índice de contratos de API.

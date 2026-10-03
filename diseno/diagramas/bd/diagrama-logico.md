# Modelo lógico - Ventas y Postventa

Pasa las entidades del [modelo conceptual](diagrama-conceptual.md) a tablas, con columnas, tipos, claves y campos obligatorios. Los nombres son los mismos del script [ventas_postventa_schema.sql](../../../infra/bd/ventas_postventa_schema.sql).

| Esquema | Microservicio | Tablas |
|---|---|---|
| ventas | M1 | pedido, detalle_pedido, pago, historial_estado, anulacion |
| postventa | M2 | devolucion, evidencia_devolucion, reembolso, reclamo, calificacion, agregado_ventas |

## 1. Diagrama

![Modelo lógico](diagrama-logico.png)

Archivo editable: [diagrama-logico.drawio](diagrama-logico.drawio)

## 2. Notación

| Marca | Significado |
|---|---|
| PK | Clave primaria |
| FK | Clave foránea dentro del mismo esquema |
| UK | Valor único |
| R | Referencia a otro microservicio o módulo, sin clave foránea |
| NN | Obligatorio (NOT NULL) |

Los tipos DECIMAL y TIMESTAMP se implementan en PostgreSQL como numeric y timestamptz.

## 3. Esquema relacional

PK entre [ ], FK con →, referencia sin FK con ⇢.

ventas (M1):

```text
pedido           ([id], codigo UK, canal, fecha, estado, moneda, subtotal, descuento, total,
                  nombre_contacto, tipo_documento, numero_documento, telefono, email,
                  modalidad_envio, costo_envio, destinatario, distrito, direccion, codigo_cupon,
                  creado_en, id_cliente ⇢ G, id_vendedor ⇢ G, id_direccion_entrega ⇢ E)

detalle_pedido   ([id], id_pedido → pedido.id, id_producto ⇢ F, sku, descripcion, cantidad,
                  precio_unitario, descuento, importe)

pago             ([id], id_pedido → pedido.id, metodo, referencia, monto, estado, fecha_proceso)

historial_estado ([id], id_pedido → pedido.id, estado_anterior, estado_nuevo, actor, motivo,
                  fecha_hora)

anulacion        ([id], id_pedido → pedido.id UK, motivo, id_solicitante, id_autorizador,
                  estado, fecha)
```

postventa (M2):

```text
devolucion           ([id], id_pedido ⇢ M1.pedido, tipo, motivo, estado, resolucion,
                      id_autorizador, fundamento_rechazo, fecha)

evidencia_devolucion ([id], id_devolucion → devolucion.id, url, tipo, fecha)

reembolso            ([id], id_origen ⇢ M1.anulacion | devolucion, tipo_origen,
                      idempotency_key UK, monto, moneda, id_transaccion, estado,
                      id_autorizador, fecha)            UK (tipo_origen, id_origen)

reclamo              ([id], codigo UK, id_pedido ⇢ M1.pedido, tipo, motivo, detalle,
                      nombre_consumidor, documento, email, telefono, estado,
                      plazo_dias_habiles, fecha_limite_respuesta, respuesta_visible_cliente)

calificacion         ([id], id_pedido ⇢ M1.pedido UK, puntaje, comentario, canal, fecha)

agregado_ventas      ([periodo, canal, id_vendedor, id_producto], unidades, monto, actualizado_en)
```

## 4. Relaciones

Con clave foránea:

| Padre | Hija | Columna | Cardinalidad | Al borrar el padre |
|---|---|---|---|---|
| pedido | detalle_pedido | id_pedido | 1 a 1..N | Se borran los detalles |
| pedido | pago | id_pedido | 1 a 0..N | Se borran los pagos |
| pedido | historial_estado | id_pedido | 1 a 1..N | Se borra el historial |
| pedido | anulacion | id_pedido (UK) | 1 a 0..1 | Se borra la anulación |
| devolucion | evidencia_devolucion | id_devolucion | 1 a 0..N | Se borran las evidencias |

El mínimo de 1 en detalle_pedido e historial_estado viene de ESP-01. La base no lo puede exigir; lo controla M1 al crear el pedido.

Sin clave foránea:

| Columna | Apunta a | Motivo |
|---|---|---|
| devolucion.id_pedido | ventas.pedido | Está en otro microservicio; se valida con la API de M1 |
| reclamo.id_pedido | ventas.pedido | Igual que el anterior; es opcional |
| calificacion.id_pedido | ventas.pedido | Igual que el anterior; es único |
| reembolso.id_origen | ventas.anulacion o postventa.devolucion | Depende de tipo_origen y una de las tablas está en M1 |
| pedido.id_cliente, pedido.id_vendedor | Módulo G | Usuarios de Seguridad y Usuarios |
| pedido.id_direccion_entrega | Módulo E | Dato de Despacho y Entrega |
| detalle_pedido.id_producto | Módulo F | Catálogo de Productos y Ofertas |

## 5. Reglas

M1:

1. pedido.codigo es único.
2. pedido.estado solo admite CREADO, PAGADO, EN_PREPARACION, DESPACHADO, ENTREGADO y ANULADO. Las transiciones las controla M1 (ESP-03).
3. Un pedido tiene como máximo una anulación.
4. detalle_pedido.cantidad es mayor que cero y los montos no pueden ser negativos.
5. historial_estado solo recibe inserciones.

M2:

1. Solo se registra una devolución para un pedido ENTREGADO; M2 lo consulta a M1.
2. devolucion.resolucion es cambio, reembolso o rechazo.
3. reembolso.tipo_origen solo admite ANULACION o DEVOLUCION, y (tipo_origen, id_origen) es único.
4. reembolso.idempotency_key es única para que un reintento no genere otro pago (ESP-09).
5. reembolso.estado solo admite PENDIENTE, EXITOSO o FALLIDO.
6. reclamo.codigo es único. El reclamo pasa de REGISTRADO a EN_PROCESO y llega a ATENDIDO solo con respuesta visible al cliente (ESP-13, ESP-14).
7. reclamo.plazo_dias_habiles es 15 por defecto.
8. calificacion.puntaje va de 1 a 5, con una calificación por pedido.
9. agregado_ventas se actualiza con eventos.

## 6. Tablas por funcionalidad

| Funcionalidad | Tablas |
|---|---|
| F1 Ciclo de vida del pedido | pedido, detalle_pedido, pago, historial_estado |
| F2 Anulación de pedidos | anulacion, pedido, historial_estado |
| F3 Devoluciones y cambios | devolucion, evidencia_devolucion |
| F4 Reembolsos y extornos | reembolso |
| F5 Calificación de experiencia | calificacion |
| F6 Reclamos, dashboard y reportes | reclamo, agregado_ventas |

## 7. Pendientes

- Valores de historial_estado.actor: la base acepta CLIENTE, GESTOR, CANAL_CHATBOT, PASARELA_PAGOS y SISTEMA_LOGISTICA, pero ESP-03 usa PASARELA, CANAL, DESPACHO, GESTOR y SISTEMA. Hay que unificarlos.
- pago.estado, devolucion.estado, anulacion.estado y pedido.canal no tienen lista de valores definida.
- anulacion está en M1 porque cambia el estado del pedido, pero el C4 nivel 2 pone F2 en M2. Hay que alinear ambos documentos.

## 8. Otros modelos

| Modelo | Archivo |
|---|---|
| Conceptual | [diagrama-conceptual.md](diagrama-conceptual.md) |
| Físico | [ventas_postventa_schema.sql](../../../infra/bd/ventas_postventa_schema.sql) |

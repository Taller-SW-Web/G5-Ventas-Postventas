# Modelo físico - Ventas y Postventa

Implementación del [modelo lógico](diagrama-logico.md) en PostgreSQL 17 sobre Supabase (proyecto `nsfrwxrjidyckgfriyhv`). Incluye los tipos reales, valores por defecto, restricciones, índices y la configuración de seguridad. El script que crea todo es [ventas_postventa_schema.sql](../../../infra/bd/ventas_postventa_schema.sql), aplicado como la migración `crear_esquemas_ventas_postventa`.

> **Pendiente de aplicar en Supabase:** `pedido.tienda_id` y `pago.monto_efectivo`/`monto_tarjeta`/`fecha_venta` son columnas del acuerdo con Retail (G4, 2026-10-12 — ver `integraciones/ACUERDO_G4_RETAIL.md`): el pedido `RETAIL` nace `PAGADO` y transiciona a `ENTREGADO` en la misma operación, sin envío. Este documento y el script ya las reflejan; falta la migración real. **Ya aplicado en código (`Pedido.java`/`Pago.java`), falta confirmar si ya se aplicó sobre la Supabase real.**
>
> **Aplicado en Supabase el 2026-10-12** y en uso por la entidad `Devolucion` de F3: `devolucion.fecha_registro`, `fecha_resolucion` y `referencia_operacion` cierran el hueco entre lo que `ESP-07` (8.3) y `ESP-08` (8.3) ya prometen devolver (`fechaCreacion`, `fechaResolucion`, `referenciaOperacion`) y lo que la tabla física podía persistir hasta ahora.

## 1. Diagrama

Esquema ventas (M1):

```mermaid
erDiagram
    PEDIDO ||--|{ DETALLE_PEDIDO : contiene
    PEDIDO ||--o{ PAGO : registra
    PEDIDO ||--|{ HISTORIAL_ESTADO : audita
    PEDIDO ||--o| ANULACION : "puede tener"
    PEDIDO ||--o{ OUTBOX_EVENTO : publica
    PEDIDO {
        bigint id PK "identity, not null"
        varchar(30) codigo UK "not null"
        varchar(30) canal "not null"
        date fecha "not null, default current_date"
        varchar(20) estado "not null, default CREADO"
        char(3) moneda "not null, default PEN"
        numeric(12-2) subtotal "not null"
        numeric(12-2) descuento "not null"
        numeric(12-2) total "not null"
        varchar(150) nombre_contacto "null"
        varchar(20) tipo_documento "null"
        varchar(20) numero_documento "null"
        varchar(20) telefono "null"
        varchar(150) email "null"
        varchar(30) modalidad_envio "null"
        numeric(12-2) costo_envio "not null"
        varchar(150) destinatario "null"
        varchar(80) distrito "null"
        varchar(255) direccion "null"
        varchar(40) codigo_cupon "null"
        varchar(128) idempotency_key UK "null, cabecera Idempotency-Key de 1.1"
        varchar(100) reserva_id "null, reservaId de Productos (G6)"
        timestamptz creado_en "not null, default now()"
        uuid id_cliente "referencia sin FK, null"
        uuid id_vendedor "referencia sin FK, null"
        bigint id_direccion_entrega "referencia sin FK, null"
        varchar(40) tienda_id "null, solo RETAIL"
    }
    DETALLE_PEDIDO {
        bigint id PK "identity, not null"
        bigint id_pedido FK "not null"
        varchar(64) id_producto "referencia sin FK, null — era bigint, corregido (ver H12)"
        varchar(50) sku "not null"
        varchar(255) descripcion "null"
        integer cantidad "not null"
        numeric(12-2) precio_unitario "not null"
        numeric(12-2) descuento "not null"
        numeric(12-2) importe "not null"
    }
    PAGO {
        bigint id PK "identity, not null"
        bigint id_pedido FK "not null"
        varchar(30) metodo "not null"
        varchar(100) referencia "null, también referenciaOperacion del POS en RETAIL"
        numeric(12-2) monto "not null"
        varchar(20) estado "not null"
        timestamptz fecha_proceso "null"
        numeric(12-2) monto_efectivo "null, solo RETAIL con metodo MIXTO"
        numeric(12-2) monto_tarjeta "null, solo RETAIL con metodo MIXTO"
        timestamptz fecha_venta "null, solo RETAIL, venta sin conexión hasta 72h atrás"
    }
    HISTORIAL_ESTADO {
        bigint id PK "identity, not null"
        bigint id_pedido FK "not null"
        varchar(20) estado_anterior "null"
        varchar(20) estado_nuevo "not null"
        varchar(30) actor "not null"
        varchar(60) motivo "null"
        timestamptz fecha_hora "not null, default now()"
    }
    ANULACION {
        bigint id PK "identity, not null"
        bigint id_pedido FK,UK "not null"
        varchar(255) motivo "not null"
        uuid id_solicitante "null"
        uuid id_autorizador "null"
        varchar(20) estado "not null"
        date fecha "not null"
    }
    OUTBOX_EVENTO {
        uuid id_evento PK "not null, lo genera M1"
        bigint id_pedido FK "not null"
        varchar(40) tipo "not null"
        jsonb payload "not null"
        timestamptz creado_en "not null, default now()"
        timestamptz enviado_en "null"
        integer intentos "not null, default 0"
    }
    EVENTO_RECIBIDO {
        varchar(100) id_evento PK "not null"
        varchar(30) origen "not null"
        timestamptz recibido_en "not null, default now()"
    }
```

Esquema postventa (M2):

```mermaid
erDiagram
    DEVOLUCION ||--o{ EVIDENCIA_DEVOLUCION : adjunta
    DEVOLUCION ||--|{ DEVOLUCION_ITEM : contiene
    DEVOLUCION ||--o{ DEVOLUCION_RECEPCION : recibe
    DEVOLUCION ||--o{ HISTORIAL_DEVOLUCION : audita
    REEMBOLSO ||--|{ REEMBOLSO_INTENTO : registra
    DEVOLUCION {
        bigint id PK "identity, not null"
        bigint id_pedido "referencia sin FK, not null"
        uuid id_cliente "referencia sin FK, null"
        varchar(20) tipo "not null"
        varchar(255) motivo "not null"
        text descripcion "null"
        varchar(20) estado "not null"
        varchar(30) resolucion "null"
        uuid id_autorizador "null"
        text fundamento_rechazo "null"
        date fecha "not null"
        timestamptz fecha_registro "not null, default now(), hora real de creación (ESP-07 8.3)"
        timestamptz fecha_resolucion "null, hora de la decisión del Gestor (ESP-08 8.3)"
        varchar(100) referencia_operacion "null, reembolsoId de F4 o referencia de Despacho según la resolución (ESP-08 8.3)"
        boolean requiere_devolucion_fisica "not null, default true — false en REEMBOLSO cuando no hay devolución física (ESP-08 8.2b, regla 16)"
    }
    DEVOLUCION_ITEM {
        bigint id PK "identity, not null"
        bigint id_devolucion FK "not null"
        varchar(64) id_producto "referencia sin FK, not null — era bigint, corregido (ver H12)"
        integer cantidad "not null"
    }
    DEVOLUCION_RECEPCION {
        bigint id PK "identity, not null"
        bigint id_devolucion FK "not null"
        uuid operation_id "not null, el mismo para todas las líneas de una misma confirmación y para el reintegro en Productos (ESP-08 8.2b, G6 P-05)"
        varchar(50) sku "not null"
        varchar(64) id_producto "not null"
        integer cantidad_recibida "not null"
        integer cantidad_apta "not null, solo esto se reintegra (ESP-08 regla 15)"
        varchar(20) reintegro_estado "not null, PENDIENTE o COMPLETADO"
        varchar(500) evidencia "null"
        varchar(60) id_actor "null, sub de quien recibió (Gestor o almacén, rol ADMIN_VENTAS)"
        timestamptz fecha_hora "not null"
    }
    HISTORIAL_DEVOLUCION {
        bigint id PK "identity, not null"
        bigint id_devolucion FK "not null"
        varchar(20) estado_anterior "null, null en el registro inicial (SOLICITADA)"
        varchar(20) estado_nuevo "not null"
        varchar(20) actor "not null, CHECK: CLIENTE, CANAL, GESTOR, SISTEMA"
        varchar(60) id_actor "null, sub del cliente/Gestor o módulo del canal"
        text detalle "null"
        timestamptz fecha_hora "not null"
    }
    EVIDENCIA_DEVOLUCION {
        bigint id PK "identity, not null"
        bigint id_devolucion FK "not null"
        varchar(500) url "not null"
        varchar(30) tipo "null"
        date fecha "not null"
    }
    REEMBOLSO {
        bigint id PK "identity, not null"
        bigint id_origen "referencia sin FK, not null"
        varchar(20) tipo_origen "not null"
        bigint id_pedido "referencia sin FK, null"
        varchar(100) idempotency_key UK "not null"
        numeric(12-2) monto "not null"
        char(3) moneda "not null, default PEN"
        varchar(100) id_transaccion "null"
        varchar(20) estado "not null, default PENDIENTE"
        uuid id_autorizador "null"
        date fecha "not null"
    }
    REEMBOLSO_INTENTO {
        bigint id PK "identity, not null"
        bigint id_reembolso FK "not null"
        integer numero_intento "not null"
        varchar(20) estado "not null"
        varchar(100) id_transaccion "null"
        text resultado "null"
        timestamptz fecha_hora "not null, default now()"
    }
    RECLAMO {
        bigint id PK "identity, not null"
        varchar(30) codigo UK "not null"
        bigint id_pedido "referencia sin FK, null"
        uuid id_cliente "referencia sin FK, null"
        varchar(20) tipo "not null"
        varchar(60) motivo "not null"
        text detalle "not null"
        varchar(150) nombre_consumidor "not null"
        varchar(20) documento "not null"
        varchar(150) email "null"
        varchar(20) telefono "null"
        varchar(20) estado "not null"
        integer plazo_dias_habiles "not null, default 15"
        timestamptz fecha_registro "not null, default now()"
        date fecha_limite_respuesta "not null"
        timestamptz fecha_atencion "null"
        varchar(50) atendido_por "null"
        text respuesta_visible_cliente "null"
        varchar(20) canal "not null"
    }
    CALIFICACION {
        bigint id PK "identity, not null"
        bigint id_pedido UK "referencia sin FK, not null"
        integer puntaje "not null"
        text comentario "null"
        varchar(30) canal "not null"
        date fecha "not null"
    }
    AGREGADO_VENTAS {
        varchar(7) periodo PK "not null"
        varchar(30) canal PK "not null"
        uuid id_vendedor PK "not null"
        varchar(64) id_producto PK "not null — era bigint, corregido (ver H12)"
        integer unidades "not null"
        numeric(14-2) monto "not null"
        timestamptz actualizado_en "not null, default now()"
    }
    AGREGADO_METRICAS {
        date fecha PK "not null"
        varchar(20) canal PK "not null"
        integer pedidos_pagados "not null, default 0"
        integer pedidos_anulados "not null, default 0"
        integer pedidos_entregados "not null, default 0"
        integer devoluciones_aprobadas "not null, default 0"
        numeric(14-2) monto_reembolsado_pen "not null, default 0"
        integer csat_suma "not null, default 0"
        integer csat_cantidad "not null, default 0"
        integer reclamos_registrados "not null, default 0"
        integer reclamos_atendidos "not null, default 0"
        timestamptz actualizado_en "not null, default now()"
    }
    EVENTO_RECIBIDO {
        uuid id_evento PK "not null, el idEvento de M1"
        varchar(40) tipo "not null"
        timestamptz recibido_en "not null, default now()"
    }
```

Los tipos numéricos se escriben como numeric(12-2) porque Mermaid no admite comas; en la base son numeric(12,2).

Archivo editable: [diagrama-fisico.drawio](diagrama-fisico.drawio)

## 2. Esquemas

| Esquema | Microservicio | Tablas |
|---|---|---|
| ventas | M1 | pedido, detalle_pedido, pago, historial_estado, anulacion, outbox_evento, evento_recibido |
| postventa | M2 | devolucion, devolucion_item, evidencia_devolucion, reembolso, reembolso_intento, reclamo, calificacion, agregado_ventas, agregado_metricas, evento_recibido |

No hay claves foráneas entre los dos esquemas.

## 3. Tipos de datos

| Lógico | PostgreSQL | Uso |
|---|---|---|
| BIGINT (PK) | bigint generated always as identity | Identificadores; la base genera el valor |
| BIGINT | bigint | Claves foráneas y referencias a otros módulos |
| INTEGER | integer | cantidad, puntaje, unidades, plazo_dias_habiles |
| DECIMAL(12,2) | numeric(12,2) | Montos (agregado_ventas.monto usa numeric(14,2)) |
| VARCHAR(n) | varchar(n) | Códigos, estados y textos cortos |
| CHAR(3) | char(3) | moneda (código ISO, por ejemplo PEN) |
| TEXT | text | Textos largos: detalle, comentario, fundamento_rechazo, respuesta |
| DATE | date | Fechas sin hora |
| TIMESTAMP | timestamptz | Fecha y hora con zona horaria |
| UUID | uuid | Identificador de evento de dominio (outbox_evento.id_evento, postventa.evento_recibido.id_evento) y de usuario: claim `sub` de Seguridad (id_cliente, id_vendedor, id_solicitante, id_autorizador) |
| JSONB | jsonb | outbox_evento.payload: el cuerpo del evento tal como se envía a M2 |

## 4. Valores por defecto

| Tabla | Columna | Valor |
|---|---|---|
| pedido | fecha | current_date |
| pedido | estado | 'CREADO' |
| pedido | moneda | 'PEN' |
| pedido | subtotal, descuento, total, costo_envio | 0 |
| pedido | creado_en | now() |
| detalle_pedido | descuento | 0 |
| historial_estado | fecha_hora | now() |
| anulacion, devolucion, evidencia_devolucion, calificacion, reembolso | fecha | current_date |
| reembolso | moneda | 'PEN' |
| reembolso | estado | 'PENDIENTE' |
| reclamo | plazo_dias_habiles | 15 |
| reclamo | fecha_registro | now() |
| agregado_ventas | unidades, monto | 0 |
| agregado_ventas | actualizado_en | now() |
| outbox_evento | creado_en | now() |
| outbox_evento | intentos | 0 |
| evento_recibido (ventas y postventa) | recibido_en | now() |
| reembolso_intento | fecha_hora | now() |
| agregado_metricas | todos los contadores y el monto | 0 |
| agregado_metricas | actualizado_en | now() |

## 5. Restricciones

Claves primarias: todas las tablas usan `id`, salvo agregado_ventas (clave compuesta periodo, canal, id_vendedor, id_producto), agregado_metricas (clave compuesta fecha, canal) y las tablas de eventos (`ventas.outbox_evento`, `ventas.evento_recibido` y `postventa.evento_recibido`), cuya clave primaria es `id_evento`.

Claves foráneas (todas con `ON DELETE CASCADE`):

| Tabla | Columna | Referencia |
|---|---|---|
| ventas.detalle_pedido | id_pedido | ventas.pedido(id) |
| ventas.pago | id_pedido | ventas.pedido(id) |
| ventas.historial_estado | id_pedido | ventas.pedido(id) |
| ventas.anulacion | id_pedido | ventas.pedido(id) |
| ventas.outbox_evento | id_pedido | ventas.pedido(id) |
| postventa.evidencia_devolucion | id_devolucion | postventa.devolucion(id) |
| postventa.devolucion_item | id_devolucion | postventa.devolucion(id) |
| postventa.reembolso_intento | id_reembolso | postventa.reembolso(id) |

Valores únicos:

| Nombre | Tabla | Columnas |
|---|---|---|
| pedido_codigo_key | ventas.pedido | codigo |
| pedido_idempotency_key_key | ventas.pedido | idempotency_key (admite null) |
| anulacion_id_pedido_key | ventas.anulacion | id_pedido |
| reclamo_codigo_key | postventa.reclamo | codigo |
| reembolso_idempotency_key_key | postventa.reembolso | idempotency_key |
| uq_reembolso_origen | postventa.reembolso | tipo_origen, id_origen |
| uq_reembolso_intento | postventa.reembolso_intento | id_reembolso, numero_intento |
| calificacion_id_pedido_key | postventa.calificacion | id_pedido |

CHECK:

| Nombre | Tabla | Condición |
|---|---|---|
| ck_pedido_estado | ventas.pedido | estado IN (CREADO, PAGADO, EN_PREPARACION, DESPACHADO, ENTREGADO, ANULADO) |
| ck_pedido_canal | ventas.pedido | canal IN (MARKETPLACE, CHATBOT, RETAIL) |
| ck_pedido_montos | ventas.pedido | subtotal, descuento, total y costo_envio ≥ 0 |
| ck_detalle_cantidad | ventas.detalle_pedido | cantidad > 0 |
| ck_detalle_montos | ventas.detalle_pedido | precio_unitario, descuento e importe ≥ 0 |
| ck_pago_monto | ventas.pago | monto ≥ 0 |
| ck_pago_estado | ventas.pago | estado IN (PENDIENTE, CONFIRMADO, RECHAZADO) |
| ck_historial_actor | ventas.historial_estado | actor IN (CLIENTE, GESTOR, CANAL_CHATBOT, PASARELA_PAGOS, SISTEMA_LOGISTICA, SISTEMA_PRODUCTOS) |
| ck_anulacion_estado | ventas.anulacion | estado IN (PENDIENTE_AUTORIZACION, EJECUTADA, RECHAZADA) |
| ck_outbox_tipo | ventas.outbox_evento | tipo IN (pedido.pagado, pedido.anulado, pedido.entregado) |
| ck_evento_recibido_origen | ventas.evento_recibido | origen IN (PASARELA_PAGOS, SISTEMA_LOGISTICA, SISTEMA_PRODUCTOS) |
| ck_devolucion_estado | postventa.devolucion | estado IN (SOLICITADA, EN_EVALUACION, APROBADA, RECHAZADA, COMPLETADA) |
| ck_devolucion_item_cantidad | postventa.devolucion_item | cantidad > 0 |
| ck_reembolso_tipo_origen | postventa.reembolso | tipo_origen IN (ANULACION, DEVOLUCION) |
| ck_reembolso_estado | postventa.reembolso | estado IN (PENDIENTE, EXITOSO, FALLIDO) |
| ck_reembolso_monto | postventa.reembolso | monto > 0 |
| ck_reembolso_intento_estado | postventa.reembolso_intento | estado IN (PENDIENTE, EXITOSO, FALLIDO) |
| ck_reclamo_plazo | postventa.reclamo | plazo_dias_habiles > 0 |
| ck_reclamo_estado | postventa.reclamo | estado IN (REGISTRADO, EN_PROCESO, ATENDIDO, DERIVADO) |
| ck_reclamo_canal | postventa.reclamo | canal IN (MARKETPLACE, CHATBOT, RETAIL) |
| ck_calificacion_puntaje | postventa.calificacion | puntaje entre 1 y 5 |
| ck_calificacion_canal | postventa.calificacion | canal IN (MARKETPLACE, CHATBOT, RETAIL) |
| ck_agregado_metricas_canal | postventa.agregado_metricas | canal IN (MARKETPLACE, CHATBOT, RETAIL) |


## 6. Índices

Además de los que PostgreSQL crea para las claves primarias y únicas:

| Índice | Tabla | Columna |
|---|---|---|
| ix_detalle_pedido_id_pedido | ventas.detalle_pedido | id_pedido |
| ix_pago_id_pedido | ventas.pago | id_pedido |
| ix_historial_estado_id_pedido | ventas.historial_estado | id_pedido |
| ix_evidencia_id_devolucion | postventa.evidencia_devolucion | id_devolucion |
| ix_devolucion_id_pedido | postventa.devolucion | id_pedido |
| ix_reclamo_id_pedido | postventa.reclamo | id_pedido |
| ix_outbox_pendientes | ventas.outbox_evento | creado_en, solo filas con enviado_en null (índice parcial) |
| ix_devolucion_id_cliente | postventa.devolucion | id_cliente |
| ix_reembolso_id_pedido | postventa.reembolso | id_pedido |
| ix_devolucion_item_id_devolucion | postventa.devolucion_item | id_devolucion |

Los tres primeros sirven para buscar por pedido en M2 aunque esas columnas no sean claves foráneas. `ix_outbox_pendientes` sirve al `EnvioEventosScheduler` para traer los eventos no enviados más antiguos. `ix_reembolso_id_pedido` sirve para calcular el saldo reembolsable de un pedido (ESP-09).

## 7. Seguridad

- RLS (Row Level Security) activo en las 17 tablas (7 en `ventas`, 10 en `postventa`), sin políticas. La API pública de Supabase no puede leer ni escribir en ellas.
- El backend se conecta directamente a PostgreSQL con su propia credencial.
- Pendiente: crear un usuario de base de datos para M1 y otro para M2, cada uno con permisos solo sobre su esquema.

## 8. Pendientes

- El `.drawio` de este diagrama todavía no incluye `outbox_evento`, `evento_recibido` (ambos esquemas), `devolucion_item`, `reembolso_intento` ni `agregado_metricas`, ni las columnas nuevas de `devolucion` y `reclamo`, ni sus índices y CHECK (sí tiene los `uuid` y `pedido.idempotency_key`) — pendiente de que quien lo mantiene lo actualice y reexporte las imágenes.

## 9. Otros modelos

| Modelo | Archivo |
|---|---|
| Conceptual | [diagrama-conceptual.md](diagrama-conceptual.md) |
| Lógico | [diagrama-logico.md](diagrama-logico.md) |

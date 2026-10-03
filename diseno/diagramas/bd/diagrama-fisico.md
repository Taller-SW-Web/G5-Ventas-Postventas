# Modelo físico - Ventas y Postventa

Implementación del [modelo lógico](diagrama-logico.md) en PostgreSQL 17 sobre Supabase (proyecto `nsfrwxrjidyckgfriyhv`). Incluye los tipos reales, valores por defecto, restricciones, índices y la configuración de seguridad. El script que crea todo es [ventas_postventa_schema.sql](../../../infra/bd/ventas_postventa_schema.sql), aplicado como la migración `crear_esquemas_ventas_postventa`.

## 1. Diagrama

Esquema ventas (M1):

```mermaid
erDiagram
    PEDIDO ||--|{ DETALLE_PEDIDO : contiene
    PEDIDO ||--o{ PAGO : registra
    PEDIDO ||--|{ HISTORIAL_ESTADO : audita
    PEDIDO ||--o| ANULACION : "puede tener"
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
        timestamptz creado_en "not null, default now()"
        bigint id_cliente "referencia sin FK, null"
        bigint id_vendedor "referencia sin FK, null"
        bigint id_direccion_entrega "referencia sin FK, null"
    }
    DETALLE_PEDIDO {
        bigint id PK "identity, not null"
        bigint id_pedido FK "not null"
        bigint id_producto "referencia sin FK, null"
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
        varchar(100) referencia "null"
        numeric(12-2) monto "not null"
        varchar(20) estado "not null"
        timestamptz fecha_proceso "null"
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
        bigint id_solicitante "null"
        bigint id_autorizador "null"
        varchar(20) estado "not null"
        date fecha "not null"
    }
```

Esquema postventa (M2):

```mermaid
erDiagram
    DEVOLUCION ||--o{ EVIDENCIA_DEVOLUCION : adjunta
    DEVOLUCION {
        bigint id PK "identity, not null"
        bigint id_pedido "referencia sin FK, not null"
        varchar(20) tipo "not null"
        varchar(255) motivo "not null"
        varchar(20) estado "not null"
        varchar(30) resolucion "null"
        bigint id_autorizador "null"
        text fundamento_rechazo "null"
        date fecha "not null"
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
        varchar(100) idempotency_key UK "not null"
        numeric(12-2) monto "not null"
        char(3) moneda "not null, default PEN"
        varchar(100) id_transaccion "null"
        varchar(20) estado "not null, default PENDIENTE"
        bigint id_autorizador "null"
        date fecha "not null"
    }
    RECLAMO {
        bigint id PK "identity, not null"
        varchar(30) codigo UK "not null"
        bigint id_pedido "referencia sin FK, null"
        varchar(20) tipo "not null"
        varchar(60) motivo "not null"
        text detalle "not null"
        varchar(150) nombre_consumidor "not null"
        varchar(20) documento "not null"
        varchar(150) email "null"
        varchar(20) telefono "null"
        varchar(20) estado "not null"
        integer plazo_dias_habiles "not null, default 15"
        date fecha_limite_respuesta "not null"
        text respuesta_visible_cliente "null"
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
        bigint id_vendedor PK "not null"
        bigint id_producto PK "not null"
        integer unidades "not null"
        numeric(14-2) monto "not null"
        timestamptz actualizado_en "not null, default now()"
    }
```

Los tipos numéricos se escriben como numeric(12-2) porque Mermaid no admite comas; en la base son numeric(12,2).

Archivo editable: [diagrama-fisico.drawio](diagrama-fisico.drawio)

## 2. Esquemas

| Esquema | Microservicio | Tablas |
|---|---|---|
| ventas | M1 | pedido, detalle_pedido, pago, historial_estado, anulacion |
| postventa | M2 | devolucion, evidencia_devolucion, reembolso, reclamo, calificacion, agregado_ventas |

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
| agregado_ventas | unidades, monto | 0 |
| agregado_ventas | actualizado_en | now() |

## 5. Restricciones

Claves primarias: todas las tablas usan `id`, salvo agregado_ventas, que tiene clave compuesta (periodo, canal, id_vendedor, id_producto).

Claves foráneas (todas con `ON DELETE CASCADE`):

| Tabla | Columna | Referencia |
|---|---|---|
| ventas.detalle_pedido | id_pedido | ventas.pedido(id) |
| ventas.pago | id_pedido | ventas.pedido(id) |
| ventas.historial_estado | id_pedido | ventas.pedido(id) |
| ventas.anulacion | id_pedido | ventas.pedido(id) |
| postventa.evidencia_devolucion | id_devolucion | postventa.devolucion(id) |

Valores únicos:

| Nombre | Tabla | Columnas |
|---|---|---|
| pedido_codigo_key | ventas.pedido | codigo |
| anulacion_id_pedido_key | ventas.anulacion | id_pedido |
| reclamo_codigo_key | postventa.reclamo | codigo |
| reembolso_idempotency_key_key | postventa.reembolso | idempotency_key |
| uq_reembolso_origen | postventa.reembolso | tipo_origen, id_origen |
| calificacion_id_pedido_key | postventa.calificacion | id_pedido |

CHECK:

| Nombre | Tabla | Condición |
|---|---|---|
| ck_pedido_estado | ventas.pedido | estado IN (CREADO, PAGADO, EN_PREPARACION, DESPACHADO, ENTREGADO, ANULADO) |
| ck_pedido_montos | ventas.pedido | subtotal, descuento, total y costo_envio ≥ 0 |
| ck_detalle_cantidad | ventas.detalle_pedido | cantidad > 0 |
| ck_detalle_montos | ventas.detalle_pedido | precio_unitario, descuento e importe ≥ 0 |
| ck_pago_monto | ventas.pago | monto ≥ 0 |
| ck_historial_actor | ventas.historial_estado | actor IN (CLIENTE, GESTOR, CANAL_CHATBOT, PASARELA_PAGOS, SISTEMA_LOGISTICA) |
| ck_reembolso_tipo_origen | postventa.reembolso | tipo_origen IN (ANULACION, DEVOLUCION) |
| ck_reembolso_estado | postventa.reembolso | estado IN (PENDIENTE, EXITOSO, FALLIDO) |
| ck_reembolso_monto | postventa.reembolso | monto > 0 |
| ck_reclamo_plazo | postventa.reclamo | plazo_dias_habiles > 0 |
| ck_calificacion_puntaje | postventa.calificacion | puntaje entre 1 y 5 |

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

Los tres últimos sirven para buscar por pedido en M2 aunque esas columnas no sean claves foráneas.

## 7. Seguridad

- RLS (Row Level Security) activo en las 11 tablas, sin políticas. La API pública de Supabase no puede leer ni escribir en ellas.
- El backend se conecta directamente a PostgreSQL con su propia credencial.
- Pendiente: crear un usuario de base de datos para M1 y otro para M2, cada uno con permisos solo sobre su esquema.

## 8. Pendientes

- `ck_historial_actor` usa los valores del ER original y no coincide con ESP-03 (PASARELA, CANAL, DESPACHO, GESTOR, SISTEMA). Se corrige con una migración cuando el equipo decida qué lista usar.
- pago.estado, devolucion.estado, anulacion.estado y pedido.canal no tienen CHECK porque sus valores aún no están definidos.

## 9. Otros modelos

| Modelo | Archivo |
|---|---|
| Conceptual | [diagrama-conceptual.md](diagrama-conceptual.md) |
| Lógico | [diagrama-logico.md](diagrama-logico.md) |

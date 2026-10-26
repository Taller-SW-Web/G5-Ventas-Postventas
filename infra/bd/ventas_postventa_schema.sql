-- =====================================================================
-- Módulo D — Ventas y Postventa
-- Traducción a PostgreSQL del "Diagrama ER - VentasPostventas.drawio"
-- Actualizado el 12/10/2026 para reflejar exactamente lo que hay en Supabase
-- (migraciones crear_esquemas_ventas_postventa, decisiones_estados_canal_eventos,
-- huecos_h2_h3_h5_h6_postventa, ids_usuario_a_uuid, pedido_idempotency_key
-- y pedido_reserva_productos).
--
-- VERIFICADO EN SUPABASE EL 2026-10-26 (consulta directa a information_schema):
-- ya están aplicados todos los cambios que este encabezado daba como pendientes —
-- columnas de Retail (G4: pedido.tienda_id, pago.monto_efectivo/monto_tarjeta/fecha_venta),
-- H12 (id_producto varchar), recepción física de F3 (devolucion.requiere_devolucion_fisica,
-- devolucion_recepcion, historial_devolucion), orden de reemplazo (pedido.tipo,
-- id_pedido_origen, devolucion_id), pedido.fecha_estimada_entrega y las tablas
-- ventas.notificacion_envio y ventas.solicitud_reembolso. Los ids de usuario ya son uuid.
--
-- Historial:
-- Acuerdo con Retail (G4, 2026-10-12, ver integraciones/ACUERDO_G4_RETAIL.md):
-- el pedido RETAIL nace PAGADO y transiciona a ENTREGADO en la misma operación, sin envío.
--
-- Aplicado en Supabase el 2026-10-12 (H11, F3): postventa.devolucion.fecha_registro,
-- fecha_resolucion y referencia_operacion cierran el hueco entre lo que ESP-07 8.3
-- y ESP-08 8.3 ya prometen devolver y lo que la tabla física podía persistir.
--
-- H12 (detectado 2026-10-16 revisando el código real, ya aplicado):
-- id_producto era bigint en ventas.detalle_pedido, postventa.devolucion_item y
-- postventa.agregado_ventas, pero Productos (G6) identifica sus SKUs con texto
-- (ej. "PROD-101"), nunca un número — DetallePedido.java y DevolucionItem.java ya
-- usan String/varchar(64). Este archivo ya refleja varchar(64); falta la migración
-- real (ALTER COLUMN) si la base todavía tiene bigint.
--
-- F3, rediseño de recepción física (ya aplicado; 2026-10-13/16,
-- issue G6 #51 P-02 y ESP-08 8.2b): postventa.devolucion.requiere_devolucion_fisica,
-- y las tablas nuevas postventa.devolucion_recepcion y postventa.historial_devolucion.
-- Ya implementado en el código (RecepcionService, HistorialDevolucion); este archivo
-- ya las refleja, falta confirmar que la migración real se aplicó en Supabase.
--
-- Esquema ventas    = M1 (Ventas)
-- Esquema postventa = M2 (Postventa)
-- Ninguna clave foránea cruza de un esquema al otro (Database-per-Service).
-- Las referencias a otro esquema o a otro módulo son columnas simples.
-- =====================================================================

create schema if not exists ventas;
create schema if not exists postventa;

comment on schema ventas    is 'M1 - Ventas: pedido, detalle, pago, historial de estados, anulación y eventos.';
comment on schema postventa is 'M2 - Postventa: devolución, evidencia, reclamo, reembolso, calificación, agregados y eventos.';

-- =====================================================================
-- ESQUEMA M1 — VENTAS
-- =====================================================================

create table ventas.pedido (
    id                    bigint generated always as identity primary key,
    codigo                varchar(30)   not null unique,
    canal                 varchar(30)   not null,
    fecha                 date          not null default current_date,
    estado                varchar(20)   not null default 'CREADO',
    moneda                char(3)       not null default 'PEN',
    subtotal              numeric(12,2) not null default 0,
    descuento             numeric(12,2) not null default 0,
    total                 numeric(12,2) not null default 0,
    nombre_contacto       varchar(150),
    tipo_documento        varchar(20),
    numero_documento      varchar(20),
    telefono              varchar(20),
    email                 varchar(150),
    modalidad_envio       varchar(30),
    costo_envio           numeric(12,2) not null default 0,
    destinatario          varchar(150),
    distrito              varchar(80),
    direccion             varchar(255),
    codigo_cupon          varchar(40),
    idempotency_key       varchar(128)  unique,   -- cabecera Idempotency-Key de 1.1 (acuerdo H-02)
    reserva_id            varchar(100),           -- reservaId de Productos (G6); null pendiente o RETAIL
    creado_en             timestamptz   not null default now(),
    id_cliente            uuid,     -- referencia externa: módulo G (Seguridad y Usuarios)
    id_vendedor           uuid,     -- referencia externa: módulo G (Seguridad y Usuarios)
    id_direccion_entrega  bigint,   -- referencia externa: módulo E (Despacho y Entrega)
    tienda_id             varchar(40),   -- solo RETAIL: código de tienda (ej. TIENDA-MIRAFLORES), reemplaza a envío
    tipo                  varchar(20)   not null default 'VENTA',  -- VENTA o REEMPLAZO (F3, api-ventas.md 1.11, acuerdo G6 #100)
    id_pedido_origen      bigint references ventas.pedido(id),    -- solo REEMPLAZO: pedido original que se cambia
    devolucion_id         varchar(30),                             -- solo REEMPLAZO: devolución de M2 (DEV-AAAA-NNNN)
    fecha_estimada_entrega timestamptz,                            -- la fija Despacho con DESPACHO_REPROGRAMADO (api-ventas.md 1.5)
    constraint ck_pedido_canal check (canal in ('MARKETPLACE','CHATBOT','RETAIL')),
    constraint ck_pedido_estado check (estado in
        ('CREADO','PAGADO','EN_PREPARACION','DESPACHADO','ENTREGADO','ANULADO')),
    constraint ck_pedido_tipo check (tipo in ('VENTA','REEMPLAZO')),
    constraint ck_pedido_montos check (
        subtotal >= 0 and descuento >= 0 and total >= 0 and costo_envio >= 0)
);

comment on column ventas.pedido.id_cliente           is 'Referencia externa - módulo G (sin FK física). UUID del claim sub';
comment on column ventas.pedido.id_vendedor          is 'Referencia externa - módulo G (sin FK física). UUID del claim sub';
comment on column ventas.pedido.id_direccion_entrega is 'Referencia externa - módulo E (sin FK física)';

create table ventas.detalle_pedido (
    id               bigint generated always as identity primary key,
    id_pedido        bigint        not null references ventas.pedido(id) on delete cascade,
    id_producto      varchar(64),  -- referencia externa: módulo F (Productos y Ofertas) — texto, no bigint (H12)
    sku              varchar(50)   not null,
    descripcion      varchar(255),
    cantidad         integer       not null,
    precio_unitario  numeric(12,2) not null,
    descuento        numeric(12,2) not null default 0,
    importe          numeric(12,2) not null,
    constraint ck_detalle_cantidad check (cantidad > 0),
    constraint ck_detalle_montos   check (precio_unitario >= 0 and descuento >= 0 and importe >= 0)
);

comment on column ventas.detalle_pedido.id_producto is 'Referencia externa - módulo F (sin FK física)';

create table ventas.pago (
    id              bigint generated always as identity primary key,
    id_pedido       bigint        not null references ventas.pedido(id) on delete cascade,
    metodo          varchar(30)   not null,
    referencia      varchar(100),   -- también usado como referenciaOperacion del POS en RETAIL
    monto           numeric(12,2) not null,
    estado          varchar(20)   not null,
    fecha_proceso   timestamptz,
    monto_efectivo  numeric(12,2),   -- solo RETAIL con metodo MIXTO
    monto_tarjeta   numeric(12,2),   -- solo RETAIL con metodo MIXTO
    fecha_venta     timestamptz,     -- solo RETAIL: fecha real de una venta sin conexión, hasta 72h atrás
    constraint ck_pago_monto  check (monto >= 0),
    constraint ck_pago_estado check (estado in ('PENDIENTE','CONFIRMADO','RECHAZADO')),
    constraint ck_pago_montos_mixto check (monto_efectivo is null or monto_efectivo >= 0),
    constraint ck_pago_montos_mixto2 check (monto_tarjeta is null or monto_tarjeta >= 0)
);

create table ventas.historial_estado (
    id               bigint generated always as identity primary key,
    id_pedido        bigint       not null references ventas.pedido(id) on delete cascade,
    estado_anterior  varchar(20),
    estado_nuevo     varchar(20)  not null,
    actor            varchar(30)  not null,
    motivo           varchar(60),
    fecha_hora       timestamptz  not null default now(),
    constraint ck_historial_actor check (actor in
        ('CLIENTE','GESTOR','CANAL_CHATBOT','PASARELA_PAGOS','SISTEMA_LOGISTICA','SISTEMA_PRODUCTOS'))
);

comment on column ventas.historial_estado.motivo is 'Incluye valores como PAGO_NO_COMPLETADO';

create table ventas.anulacion (
    id              bigint generated always as identity primary key,
    id_pedido       bigint       not null unique references ventas.pedido(id) on delete cascade,
    motivo          varchar(255) not null,
    id_solicitante  uuid,
    id_autorizador  uuid,
    estado          varchar(20)  not null,
    fecha           date         not null default current_date,
    constraint ck_anulacion_estado check (estado in ('PENDIENTE_AUTORIZACION','EJECUTADA','RECHAZADA'))
);

-- Eventos de M1 (ESP-04): se guardan en la misma transacción del cambio de estado
-- y EnvioEventosScheduler los envía a M2.
create table ventas.outbox_evento (
    id_evento   uuid         primary key,   -- lo genera M1 y viaja como idEvento en el payload
    tipo        varchar(40)  not null,
    id_pedido   bigint       not null references ventas.pedido(id) on delete cascade,
    payload     jsonb        not null,
    creado_en   timestamptz  not null default now(),
    enviado_en  timestamptz,                -- null mientras no se envíe a M2
    intentos    integer      not null default 0,
    constraint ck_outbox_tipo check (tipo in ('pedido.pagado','pedido.anulado','pedido.entregado'))
);

-- Avisos de estado de envío para Marketplace (api-ventas.md 1.10, acuerdo H-05): se guardan en la
-- misma transacción del cambio de estado y EnvioNotificacionesScheduler los envía. Independiente de
-- outbox_evento, que solo va a M2.
create table ventas.notificacion_envio (
    id_evento       uuid         primary key,   -- viaja como eventId; Marketplace deduplica con él
    id_pedido       bigint       not null references ventas.pedido(id) on delete cascade,
    estado_publico  varchar(20)  not null,
    payload         jsonb        not null,
    creado_en       timestamptz  not null default now(),
    enviado_en      timestamptz,                -- null mientras Marketplace no lo acepte
    intentos        integer      not null default 0
);

-- Solicitud de reembolso que M1 envía a M2 (F4) al anular un pedido ya cobrado (F2, ESP-06).
-- ReintentoReembolsosScheduler reenvía las PENDIENTE si M2 no respondió.
create table ventas.solicitud_reembolso (
    id              bigint generated always as identity primary key,
    id_anulacion    bigint        not null unique references ventas.anulacion(id) on delete cascade,
    id_pedido       bigint        not null references ventas.pedido(id) on delete cascade,
    monto           numeric(12,2) not null check (monto > 0),
    moneda          char(3)       not null,
    motivo          varchar(255)  not null,
    estado          varchar(20)   not null default 'PENDIENTE',
    reembolso_id    varchar(30),               -- REEM-NNNNN que devuelve M2
    intentos        integer       not null default 0,
    ultimo_error    varchar(255),
    creado_en       timestamptz   not null default now(),
    actualizado_en  timestamptz   not null default now(),
    constraint ck_solicitud_reembolso_estado check (estado in ('PENDIENTE','ENVIADA','RECHAZADA'))
);

-- Notificaciones externas ya procesadas (idempotencia de 1.2, 1.5 y de los resultados de Productos)
create table ventas.evento_recibido (
    id_evento    varchar(100) primary key,  -- transaccionId de la pasarela, G2:idEvento de Despacho o id de Productos
    origen       varchar(30)  not null,
    recibido_en  timestamptz  not null default now(),
    constraint ck_evento_recibido_origen check (origen in ('PASARELA_PAGOS','SISTEMA_LOGISTICA','SISTEMA_PRODUCTOS'))
);

-- Índices para las claves foráneas de M1
create index ix_detalle_pedido_id_pedido   on ventas.detalle_pedido(id_pedido);
create index ix_pago_id_pedido             on ventas.pago(id_pedido);
create index ix_historial_estado_id_pedido on ventas.historial_estado(id_pedido);
create index ix_outbox_pendientes          on ventas.outbox_evento(creado_en) where enviado_en is null;
create index ix_notificacion_envio_pendiente on ventas.notificacion_envio(creado_en) where enviado_en is null;
create index ix_notificacion_envio_pedido  on ventas.notificacion_envio(id_pedido);
create index ix_solicitud_reembolso_pendiente on ventas.solicitud_reembolso(creado_en) where estado = 'PENDIENTE';
create index ix_solicitud_reembolso_pedido on ventas.solicitud_reembolso(id_pedido);
-- Una devolución solo puede tener un reemplazo vigente (no ANULADO) a la vez (api-ventas.md 1.11, idempotencia).
create unique index ux_pedido_reemplazo_vigente on ventas.pedido(devolucion_id) where estado <> 'ANULADO' and devolucion_id is not null;

-- =====================================================================
-- ESQUEMA M2 — POSTVENTA
-- =====================================================================

create table postventa.devolucion (
    id                     bigint generated always as identity primary key,
    id_pedido              bigint       not null,  -- referencia API: el pedido vive en M1
    tipo                   varchar(20)  not null,
    motivo                 varchar(255) not null,
    estado                 varchar(20)  not null,
    resolucion             varchar(30),
    id_autorizador         uuid,
    fundamento_rechazo     text,
    fecha                  date         not null default current_date,
    descripcion            text,
    id_cliente             uuid,        -- referencia externa: módulo G
    fecha_registro         timestamptz  not null default now(),   -- ESP-07 8.3, fechaCreacion
    fecha_resolucion       timestamptz,                           -- ESP-08 8.3, fechaResolucion
    referencia_operacion   varchar(100),                          -- ESP-08 8.3, referenciaOperacion
    requiere_devolucion_fisica boolean not null default true,     -- ESP-08 8.2b, regla 16
    constraint ck_devolucion_estado check (estado in
        ('SOLICITADA','EN_EVALUACION','APROBADA','RECHAZADA','COMPLETADA'))
);

comment on column postventa.devolucion.referencia_operacion is
    'reembolsoId de F4 o referencia de Despacho, según la resolución';

comment on column postventa.devolucion.id_pedido is 'Referencia API - el pedido vive en M1, sin FK física';

comment on column postventa.devolucion.requiere_devolucion_fisica is
    'false solo en REEMBOLSO sin devolución física (ESP-08 regla 16); en CAMBIO siempre true';

create table postventa.devolucion_item (
    id             bigint generated always as identity primary key,
    id_devolucion  bigint       not null references postventa.devolucion(id) on delete cascade,
    id_producto    varchar(64)  not null,   -- referencia externa: módulo F — texto, no bigint (H12)
    cantidad       integer      not null,
    constraint ck_devolucion_item_cantidad check (cantidad > 0)
);

create table postventa.evidencia_devolucion (
    id             bigint generated always as identity primary key,
    id_devolucion  bigint       not null references postventa.devolucion(id) on delete cascade,
    url            varchar(500) not null,
    tipo           varchar(30),
    fecha          date         not null default current_date
);

-- F3, 2.5b (ESP-08 8.2b, issue G6 #51 P-02 y P-05): una fila por línea de una confirmación de recepción física.
-- Las líneas de una misma confirmación comparten operation_id, que es el del reintegro en Productos.
create table postventa.devolucion_recepcion (
    id                bigint generated always as identity primary key,
    id_devolucion     bigint       not null references postventa.devolucion(id) on delete cascade,
    operation_id      uuid         not null,
    sku               varchar(50)  not null,
    id_producto       varchar(64)  not null,  -- referencia externa: módulo F
    cantidad_recibida integer      not null,
    cantidad_apta     integer      not null,  -- solo esto se reintegra (ESP-08 regla 15)
    reintegro_estado  varchar(20)  not null,
    evidencia         varchar(500),
    id_actor          varchar(60),            -- sub de quien recibió (Gestor o almacén, rol ADMIN_VENTAS)
    fecha_hora        timestamptz  not null default now(),
    constraint ck_devolucion_recepcion_cantidad check (cantidad_apta >= 0 and cantidad_apta <= cantidad_recibida),
    constraint ck_devolucion_recepcion_estado check (reintegro_estado in ('PENDIENTE','COMPLETADO'))
);

create index ix_devolucion_recepcion_id_devolucion on postventa.devolucion_recepcion(id_devolucion);
create index ix_devolucion_recepcion_operation_id  on postventa.devolucion_recepcion(operation_id);

-- RNF-03: un registro por cada cambio de estado del expediente de devolución. Nunca se edita ni se borra.
create table postventa.historial_devolucion (
    id               bigint generated always as identity primary key,
    id_devolucion    bigint      not null references postventa.devolucion(id) on delete cascade,
    estado_anterior  varchar(20),            -- null en el registro inicial (SOLICITADA)
    estado_nuevo     varchar(20) not null,
    actor            varchar(20) not null,
    id_actor         varchar(60),            -- sub del cliente/Gestor, o módulo del canal
    detalle          text,
    fecha_hora       timestamptz not null default now(),
    constraint ck_historial_devolucion_actor check (actor in ('CLIENTE','CANAL','GESTOR','SISTEMA'))
);

create index ix_historial_devolucion_id_devolucion on postventa.historial_devolucion(id_devolucion);

create table postventa.reclamo (
    id                          bigint generated always as identity primary key,
    codigo                      varchar(30)  not null unique,
    id_pedido                   bigint,      -- referencia API opcional: el pedido vive en M1
    tipo                        varchar(20)  not null,
    motivo                      varchar(60)  not null,
    detalle                     text         not null,
    nombre_consumidor           varchar(150) not null,
    documento                   varchar(20)  not null,
    email                       varchar(150),
    telefono                    varchar(20),
    estado                      varchar(20)  not null,
    plazo_dias_habiles          integer      not null default 15,
    fecha_limite_respuesta      date         not null,
    respuesta_visible_cliente   text,
    canal                       varchar(20)  not null,
    id_cliente                  uuid,        -- referencia externa: módulo G
    fecha_registro              timestamptz  not null default now(),
    fecha_atencion              timestamptz,
    atendido_por                varchar(50),
    constraint ck_reclamo_plazo  check (plazo_dias_habiles > 0),
    constraint ck_reclamo_canal  check (canal in ('MARKETPLACE','CHATBOT','RETAIL')),
    constraint ck_reclamo_estado check (estado in ('REGISTRADO','EN_PROCESO','ATENDIDO','DERIVADO'))
);

comment on column postventa.reclamo.id_pedido is 'Referencia API opcional - el pedido vive en M1, sin FK física';

create table postventa.reembolso (
    id               bigint generated always as identity primary key,
    id_origen        bigint        not null,  -- referencia API: anulación (M1) o devolución (M2)
    tipo_origen      varchar(20)   not null,
    idempotency_key  varchar(100)  not null unique,
    monto            numeric(12,2) not null,
    moneda           char(3)       not null default 'PEN',
    id_transaccion   varchar(100),
    estado           varchar(20)   not null default 'PENDIENTE',
    id_autorizador   uuid,
    fecha            date          not null default current_date,
    id_pedido        bigint,       -- referencia API: el pedido vive en M1 (control de saldo)
    constraint ck_reembolso_tipo_origen check (tipo_origen in ('ANULACION','DEVOLUCION')),
    constraint ck_reembolso_estado      check (estado in ('PENDIENTE','EXITOSO','FALLIDO')),
    constraint ck_reembolso_monto       check (monto > 0),
    constraint uq_reembolso_origen      unique (tipo_origen, id_origen)
);

comment on column postventa.reembolso.id_origen is 'Referencia API - anulación (M1) o devolución (M2), sin FK física';

-- Historial de intentos de cada reembolso (ESP-10). Nunca se edita ni se borra un intento.
create table postventa.reembolso_intento (
    id              bigint generated always as identity primary key,
    id_reembolso    bigint       not null references postventa.reembolso(id) on delete cascade,
    numero_intento  integer      not null,
    estado          varchar(20)  not null,
    id_transaccion  varchar(100),
    resultado       text,
    fecha_hora      timestamptz  not null default now(),
    constraint ck_reembolso_intento_estado check (estado in ('PENDIENTE','EXITOSO','FALLIDO')),
    constraint uq_reembolso_intento unique (id_reembolso, numero_intento)
);

create table postventa.calificacion (
    id          bigint generated always as identity primary key,
    id_pedido   bigint       not null unique,  -- referencia API: el pedido vive en M1
    puntaje     integer      not null,
    comentario  text,
    canal       varchar(30)  not null,
    fecha       date         not null default current_date,
    constraint ck_calificacion_puntaje check (puntaje between 1 and 5),
    constraint ck_calificacion_canal   check (canal in ('MARKETPLACE','CHATBOT','RETAIL'))
);

comment on column postventa.calificacion.id_pedido is 'Referencia API - el pedido vive en M1, sin FK física';

create table postventa.agregado_ventas (
    periodo          varchar(7)    not null,  -- formato AAAA-MM
    canal            varchar(30)   not null,
    id_vendedor      uuid          not null,
    id_producto      varchar(64)   not null,  -- texto, no bigint (H12)
    unidades         integer       not null default 0,
    monto            numeric(14,2) not null default 0,
    actualizado_en   timestamptz   not null default now(),
    primary key (periodo, canal, id_vendedor, id_producto)
);

-- Métricas del dashboard por día y canal (ESP-15, ESP-16). Se actualiza con upsert.
create table postventa.agregado_metricas (
    fecha                   date          not null,
    canal                   varchar(20)   not null,
    pedidos_pagados         integer       not null default 0,
    pedidos_anulados        integer       not null default 0,
    pedidos_entregados      integer       not null default 0,
    devoluciones_aprobadas  integer       not null default 0,
    monto_reembolsado_pen   numeric(14,2) not null default 0,
    csat_suma               integer       not null default 0,
    csat_cantidad           integer       not null default 0,
    reclamos_registrados    integer       not null default 0,
    reclamos_atendidos      integer       not null default 0,
    actualizado_en          timestamptz   not null default now(),
    primary key (fecha, canal),
    constraint ck_agregado_metricas_canal check (canal in ('MARKETPLACE','CHATBOT','RETAIL'))
);

-- Eventos de M1 ya aplicados a los agregados (idempotencia del receptor 2.13)
create table postventa.evento_recibido (
    id_evento    uuid         primary key,  -- el mismo idEvento que genera M1
    tipo         varchar(40)  not null,
    recibido_en  timestamptz  not null default now()
);

-- Índices de M2
create index ix_evidencia_id_devolucion on postventa.evidencia_devolucion(id_devolucion);
create index ix_devolucion_id_pedido    on postventa.devolucion(id_pedido);
create index ix_reclamo_id_pedido       on postventa.reclamo(id_pedido);
create index ix_devolucion_id_cliente   on postventa.devolucion(id_cliente);
create index ix_devolucion_item_id_devolucion on postventa.devolucion_item(id_devolucion);
create index ix_reembolso_id_pedido     on postventa.reembolso(id_pedido);

-- =====================================================================
-- Seguridad en Supabase
-- RLS activado sin políticas: la API pública de Supabase no puede leer
-- ni escribir estas tablas. Solo el backend (Spring Boot), conectado con
-- su propia credencial de base de datos, accede a ellas.
-- =====================================================================

alter table ventas.pedido                  enable row level security;
alter table ventas.detalle_pedido          enable row level security;
alter table ventas.pago                    enable row level security;
alter table ventas.historial_estado        enable row level security;
alter table ventas.anulacion               enable row level security;
alter table ventas.outbox_evento           enable row level security;
alter table ventas.evento_recibido         enable row level security;
alter table postventa.devolucion           enable row level security;
alter table postventa.evidencia_devolucion enable row level security;
alter table postventa.reclamo              enable row level security;
alter table postventa.reembolso            enable row level security;
alter table postventa.calificacion         enable row level security;
alter table postventa.agregado_ventas      enable row level security;
alter table postventa.devolucion_item      enable row level security;
alter table postventa.devolucion_recepcion enable row level security;
alter table postventa.historial_devolucion enable row level security;
alter table postventa.reembolso_intento    enable row level security;
alter table postventa.agregado_metricas    enable row level security;
alter table postventa.evento_recibido      enable row level security;

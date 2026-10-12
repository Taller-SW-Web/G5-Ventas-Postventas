-- =====================================================================
-- Módulo D — Ventas y Postventa
-- Traducción a PostgreSQL del "Diagrama ER - VentasPostventas.drawio"
-- Actualizado el 12/10/2026 para reflejar exactamente lo que hay en Supabase
-- (migraciones crear_esquemas_ventas_postventa, decisiones_estados_canal_eventos,
-- huecos_h2_h3_h5_h6_postventa, ids_usuario_a_uuid y pedido_idempotency_key).
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
    creado_en             timestamptz   not null default now(),
    id_cliente            uuid,     -- referencia externa: módulo G (Seguridad y Usuarios)
    id_vendedor           uuid,     -- referencia externa: módulo G (Seguridad y Usuarios)
    id_direccion_entrega  bigint,   -- referencia externa: módulo E (Despacho y Entrega)
    constraint ck_pedido_canal check (canal in ('MARKETPLACE','CHATBOT','RETAIL')),
    constraint ck_pedido_estado check (estado in
        ('CREADO','PAGADO','EN_PREPARACION','DESPACHADO','ENTREGADO','ANULADO')),
    constraint ck_pedido_montos check (
        subtotal >= 0 and descuento >= 0 and total >= 0 and costo_envio >= 0)
);

comment on column ventas.pedido.id_cliente           is 'Referencia externa - módulo G (sin FK física). UUID del claim sub';
comment on column ventas.pedido.id_vendedor          is 'Referencia externa - módulo G (sin FK física). UUID del claim sub';
comment on column ventas.pedido.id_direccion_entrega is 'Referencia externa - módulo E (sin FK física)';

create table ventas.detalle_pedido (
    id               bigint generated always as identity primary key,
    id_pedido        bigint        not null references ventas.pedido(id) on delete cascade,
    id_producto      bigint,       -- referencia externa: módulo F (Productos y Ofertas)
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
    id             bigint generated always as identity primary key,
    id_pedido      bigint        not null references ventas.pedido(id) on delete cascade,
    metodo         varchar(30)   not null,
    referencia     varchar(100),
    monto          numeric(12,2) not null,
    estado         varchar(20)   not null,
    fecha_proceso  timestamptz,
    constraint ck_pago_monto  check (monto >= 0),
    constraint ck_pago_estado check (estado in ('PENDIENTE','CONFIRMADO','RECHAZADO'))
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
        ('CLIENTE','GESTOR','CANAL_CHATBOT','PASARELA_PAGOS','SISTEMA_LOGISTICA'))
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

-- Notificaciones externas ya procesadas (idempotencia de 1.2 y 1.6)
create table ventas.evento_recibido (
    id_evento    varchar(100) primary key,  -- transaccionId de la pasarela o guiaRemision:evento
    origen       varchar(30)  not null,
    recibido_en  timestamptz  not null default now(),
    constraint ck_evento_recibido_origen check (origen in ('PASARELA_PAGOS','SISTEMA_LOGISTICA'))
);

-- Índices para las claves foráneas de M1
create index ix_detalle_pedido_id_pedido   on ventas.detalle_pedido(id_pedido);
create index ix_pago_id_pedido             on ventas.pago(id_pedido);
create index ix_historial_estado_id_pedido on ventas.historial_estado(id_pedido);
create index ix_outbox_pendientes          on ventas.outbox_evento(creado_en) where enviado_en is null;

-- =====================================================================
-- ESQUEMA M2 — POSTVENTA
-- =====================================================================

create table postventa.devolucion (
    id                  bigint generated always as identity primary key,
    id_pedido           bigint       not null,  -- referencia API: el pedido vive en M1
    tipo                varchar(20)  not null,
    motivo              varchar(255) not null,
    estado              varchar(20)  not null,
    resolucion          varchar(30),
    id_autorizador      uuid,
    fundamento_rechazo  text,
    fecha               date         not null default current_date,
    descripcion         text,
    id_cliente          uuid,        -- referencia externa: módulo G
    constraint ck_devolucion_estado check (estado in
        ('SOLICITADA','EN_EVALUACION','APROBADA','RECHAZADA','COMPLETADA'))
);

comment on column postventa.devolucion.id_pedido is 'Referencia API - el pedido vive en M1, sin FK física';

create table postventa.devolucion_item (
    id             bigint generated always as identity primary key,
    id_devolucion  bigint  not null references postventa.devolucion(id) on delete cascade,
    id_producto    bigint  not null,   -- referencia externa: módulo F
    cantidad       integer not null,
    constraint ck_devolucion_item_cantidad check (cantidad > 0)
);

create table postventa.evidencia_devolucion (
    id             bigint generated always as identity primary key,
    id_devolucion  bigint       not null references postventa.devolucion(id) on delete cascade,
    url            varchar(500) not null,
    tipo           varchar(30),
    fecha          date         not null default current_date
);

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
    id_producto      bigint        not null,
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
alter table postventa.reembolso_intento    enable row level security;
alter table postventa.agregado_metricas    enable row level security;
alter table postventa.evento_recibido      enable row level security;

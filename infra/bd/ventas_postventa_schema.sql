-- =====================================================================
-- Módulo D — Ventas y Postventa
-- Traducción a PostgreSQL del "Diagrama ER - VentasPostventas.drawio"
--
-- Esquema ventas    = M1 (Ventas)
-- Esquema postventa = M2 (Postventa)
-- Ninguna clave foránea cruza de un esquema al otro (Database-per-Service).
-- Las referencias a otro esquema o a otro módulo son columnas simples.
-- =====================================================================

create schema if not exists ventas;
create schema if not exists postventa;

comment on schema ventas    is 'M1 - Ventas: pedido, detalle, pago, historial de estados y anulación.';
comment on schema postventa is 'M2 - Postventa: devolución, evidencia, reclamo, reembolso, calificación y agregados.';

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
    creado_en             timestamptz   not null default now(),
    id_cliente            bigint,   -- referencia externa: módulo G (Seguridad y Usuarios)
    id_vendedor           bigint,   -- referencia externa: módulo G (Seguridad y Usuarios)
    id_direccion_entrega  bigint,   -- referencia externa: módulo E (Despacho y Entrega)
    constraint ck_pedido_estado check (estado in
        ('CREADO','PAGADO','EN_PREPARACION','DESPACHADO','ENTREGADO','ANULADO')),
    constraint ck_pedido_montos check (
        subtotal >= 0 and descuento >= 0 and total >= 0 and costo_envio >= 0)
);

comment on column ventas.pedido.id_cliente           is 'Referencia externa - módulo G (sin FK física)';
comment on column ventas.pedido.id_vendedor          is 'Referencia externa - módulo G (sin FK física)';
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
    constraint ck_pago_monto check (monto >= 0)
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
    id_solicitante  bigint,
    id_autorizador  bigint,
    estado          varchar(20)  not null,
    fecha           date         not null default current_date
);

-- Índices para las claves foráneas de M1
create index ix_detalle_pedido_id_pedido   on ventas.detalle_pedido(id_pedido);
create index ix_pago_id_pedido             on ventas.pago(id_pedido);
create index ix_historial_estado_id_pedido on ventas.historial_estado(id_pedido);

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
    id_autorizador      bigint,
    fundamento_rechazo  text,
    fecha               date         not null default current_date
);

comment on column postventa.devolucion.id_pedido is 'Referencia API - el pedido vive en M1, sin FK física';

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
    constraint ck_reclamo_plazo check (plazo_dias_habiles > 0)
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
    id_autorizador   bigint,
    fecha            date          not null default current_date,
    constraint ck_reembolso_tipo_origen check (tipo_origen in ('ANULACION','DEVOLUCION')),
    constraint ck_reembolso_estado      check (estado in ('PENDIENTE','EXITOSO','FALLIDO')),
    constraint ck_reembolso_monto       check (monto > 0),
    constraint uq_reembolso_origen      unique (tipo_origen, id_origen)
);

comment on column postventa.reembolso.id_origen is 'Referencia API - anulación (M1) o devolución (M2), sin FK física';

create table postventa.calificacion (
    id          bigint generated always as identity primary key,
    id_pedido   bigint       not null unique,  -- referencia API: el pedido vive en M1
    puntaje     integer      not null,
    comentario  text,
    canal       varchar(30)  not null,
    fecha       date         not null default current_date,
    constraint ck_calificacion_puntaje check (puntaje between 1 and 5)
);

comment on column postventa.calificacion.id_pedido is 'Referencia API - el pedido vive en M1, sin FK física';

create table postventa.agregado_ventas (
    periodo          varchar(7)    not null,  -- formato AAAA-MM
    canal            varchar(30)   not null,
    id_vendedor      bigint        not null,
    id_producto      bigint        not null,
    unidades         integer       not null default 0,
    monto            numeric(14,2) not null default 0,
    actualizado_en   timestamptz   not null default now(),
    primary key (periodo, canal, id_vendedor, id_producto)
);

-- Índices de M2
create index ix_evidencia_id_devolucion on postventa.evidencia_devolucion(id_devolucion);
create index ix_devolucion_id_pedido    on postventa.devolucion(id_pedido);
create index ix_reclamo_id_pedido       on postventa.reclamo(id_pedido);

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
alter table postventa.devolucion           enable row level security;
alter table postventa.evidencia_devolucion enable row level security;
alter table postventa.reclamo              enable row level security;
alter table postventa.reembolso            enable row level security;
alter table postventa.calificacion         enable row level security;
alter table postventa.agregado_ventas      enable row level security;

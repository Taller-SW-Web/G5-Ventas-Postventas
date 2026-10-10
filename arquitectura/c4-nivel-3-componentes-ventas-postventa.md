# Arquitectura C4: Diagrama de Componentes

> **Estado:** Propuesta para discusión del equipo, alineada con [specs/overview.md](../specs/overview.md) y los contratos de API. No reemplaza las especificaciones funcionales vigentes.

Este documento presenta el nivel 3 del modelo C4. Muestra los componentes internos de los dos microservicios descritos en [c4-nivel-2-contenedores-ventas-postventa.md](c4-nivel-2-contenedores-ventas-postventa.md) y la especificación que implementa cada uno.

## 1. Componentes de M1 — Ventas

```mermaid
flowchart TB
    classDef api fill:#EA580C,color:#FFFFFF,stroke:#9A3412,stroke-width:2px
    classDef servicio fill:#2563EB,color:#FFFFFF,stroke:#1E3A8A,stroke-width:2px
    classDef datos fill:#059669,color:#FFFFFF,stroke:#065F46,stroke-width:2px
    classDef externo fill:#F8FAFC,color:#0F172A,stroke:#64748B,stroke-width:2px

    GW["API Gateway"]:::externo
    PAS["Pasarela de pagos (simulador)"]:::externo
    DESP["Despacho y Logística (E)"]:::externo

    subgraph M1["M1 — Ventas"]
        direction TB
        API["API de Pedidos<br/>/api/v1/pedidos"]:::api
        NOT["Receptor de notificaciones<br/>Pago, estados y eventos logísticos"]:::api
        CRE["Creación de pedido<br/>F1 · ESP-01"]:::servicio
        CON["Consulta de pedidos<br/>F1 · ESP-02"]:::servicio
        EST["Máquina de estados e historial<br/>F1 · ESP-03"]:::servicio
        EVT["Publicador de eventos<br/>F1 · ESP-04"]:::servicio
        ANU["Anulación<br/>F2 · ESP-05"]:::servicio
        EFE["Coordinación de efectos de la anulación<br/>F2 · ESP-06"]:::servicio
        REP["Repositorio del esquema ventas"]:::datos
    end

    BD1[("PostgreSQL · esquema ventas")]:::datos
    PRO["Productos y Ofertas (F)"]:::externo
    M2["M2 — Postventa"]:::externo

    GW --> API
    PAS -->|"Resultado del cobro"| NOT
    DESP -->|"Estados y entrega fallida"| NOT

    API --> CRE
    API --> CON
    API --> ANU
    NOT --> EST
    NOT -->|"Entrega fallida definitiva"| ANU

    CRE -->|"Precio y disponibilidad"| PRO
    ANU --> EST
    ANU --> EFE
    EFE -->|"Reposición de stock"| PRO
    EFE -->|"Cancela despacho"| DESP
    EFE -->|"Solicita reembolso ANULACION"| M2
    EST --> EVT
    EVT -.->|"pedido.pagado · anulado · entregado"| M2
    M2 -->|"Consulta pedido"| API

    CRE --> REP
    CON --> REP
    EST --> REP
    ANU --> REP
    EVT --> REP
    REP --> BD1
```

| Componente | Responsabilidad | Especificación |
|---|---|---|
| API de Pedidos | Expone creación, consulta, listado y anulación del pedido; atiende las consultas internas de M2 | ESP-01, ESP-02, ESP-05 |
| Receptor de notificaciones | Recibe la notificación de pago, los cambios de estado y los eventos logísticos de Despacho; descarta duplicados | ESP-03, ESP-05 |
| Creación de pedido | Valida los bloques `canal`, `items`, `cupon`, `envio`, `contacto` y `pago`, y registra el pedido `CREADO` | ESP-01 |
| Consulta de pedidos | Detalle por identificador y listado por cliente, con control de propiedad | ESP-02 |
| Máquina de estados e historial | Único componente que cambia el estado; valida la matriz de transiciones y registra actor, motivo y fecha | ESP-03 |
| Publicador de eventos | Registra los eventos en la bandeja de salida y los entrega a M2 con reintentos | ESP-04 |
| Anulación | Valida el motivo tipificado; anula directo en `CREADO` o `PAGADO` y deja la solicitud pendiente del Gestor en `EN_PREPARACION` | ESP-05 |
| Coordinación de efectos de la anulación | Repone stock, cancela el despacho si existe y, si el pedido estaba pagado, solicita exactamente un reembolso a M2 | ESP-06 |
| Repositorio del esquema ventas | Acceso a pedido, detalle_pedido, pago, historial_estado, anulacion y bandeja de salida | ESP-01 a ESP-06 |

## 2. Componentes de M2 — Postventa

```mermaid
flowchart TB
    classDef api fill:#EA580C,color:#FFFFFF,stroke:#9A3412,stroke-width:2px
    classDef servicio fill:#2563EB,color:#FFFFFF,stroke:#1E3A8A,stroke-width:2px
    classDef datos fill:#059669,color:#FFFFFF,stroke:#065F46,stroke-width:2px
    classDef externo fill:#F8FAFC,color:#0F172A,stroke:#64748B,stroke-width:2px

    GW["API Gateway"]:::externo
    M1["M1 — Ventas"]:::externo

    subgraph M2["M2 — Postventa"]
        direction TB
        API["API de Postventa<br/>/api/v2"]:::api
        REC["Receptor de eventos de M1"]:::api
        DEV["Devoluciones y cambios<br/>F3 · ESP-07, ESP-08"]:::servicio
        REE["Reembolsos<br/>F4 · ESP-09, ESP-10"]:::servicio
        CAL["Calificación CSAT<br/>F5 · ESP-11, ESP-12"]:::servicio
        RCL["Reclamos<br/>F6 · ESP-13, ESP-14"]:::servicio
        DSH["Dashboard y reportes<br/>F6 · ESP-15, ESP-16"]:::servicio
        REP["Repositorio del esquema postventa"]:::datos
    end

    BD2[("PostgreSQL · esquema postventa")]:::datos
    STO[("Storage de evidencias")]:::datos
    PAS["Pasarela de pagos (simulador)"]:::externo
    PRO["Productos y Ofertas (F)"]:::externo
    DESP["Despacho y Logística (E)"]:::externo
    SEG["Seguridad y Usuarios (G)"]:::externo

    GW --> API
    M1 -->|"Reembolso ANULACION"| API
    M1 -.->|"Eventos"| REC

    API --> DEV
    API --> REE
    API --> CAL
    API --> RCL
    API --> DSH

    DEV -->|"Consulta pedido ENTREGADO"| M1
    DEV -->|"Evidencias"| STO
    DEV -->|"Disponibilidad para cambio"| PRO
    DEV -->|"Logística del cambio"| DESP
    DEV -->|"Reembolso DEVOLUCION"| REE
    REE -->|"Extorno idempotente"| PAS

    REC -->|"pedido.entregado"| CAL
    CAL -->|"Contacto del cliente"| SEG
    REC --> DSH
    REE -->|"Reembolso exitoso"| DSH

    DEV --> REP
    REE --> REP
    CAL --> REP
    RCL --> REP
    DSH --> REP
    REP --> BD2
```

| Componente | Responsabilidad | Especificación |
|---|---|---|
| API de Postventa | Expone devoluciones, evidencias, reembolsos, CSAT, reclamos y métricas | ESP-07 a ESP-16 |
| Receptor de eventos de M1 | Recibe los eventos de M1 y descarta los ya procesados | ESP-11, ESP-15 |
| Devoluciones y cambios | Verifica con M1 que el pedido esté `ENTREGADO`, registra la solicitud con evidencias y dicta cambio, reembolso o rechazo | ESP-07, ESP-08 |
| Reembolsos | Acepta solo orígenes `ANULACION` (M1) y `DEVOLUCION` (F3), exige `X-Idempotency-Key`, controla el saldo reembolsable y registra cada intento | ESP-09, ESP-10 |
| Calificación CSAT | Genera la encuesta al recibir `pedido.entregado`, registra el puntaje y actualiza el CSAT | ESP-11, ESP-12 |
| Reclamos | Registra el reclamo con código de seguimiento y plazo de 15 días hábiles, y la respuesta visible al cliente | ESP-13, ESP-14 |
| Dashboard y reportes | Mantiene tablas agregadas a partir de eventos y sirve indicadores y exportaciones | ESP-15, ESP-16 |
| Repositorio del esquema postventa | Acceso a devolucion, evidencia_devolucion, reembolso, reclamo, calificacion y agregado_ventas | ESP-07 a ESP-16 |

## 3. Reglas de dependencia

- Solo la máquina de estados de M1 modifica el estado del pedido, incluida la anulación.
- M2 no accede al esquema `ventas`; consulta el pedido por la API de M1.
- Reembolsos solo se activa desde la anulación de M1 (`ANULACION`) o desde Devoluciones (`DEVOLUCION`).
- El dashboard lee tablas agregadas, nunca las tablas transaccionales.

## 4. Regla de lectura

Este diagrama responde únicamente a la pregunta **cómo se organiza cada microservicio por dentro**. Las clases, entidades y endpoints detallados pertenecen a las especificaciones funcionales, a los contratos de API y al código fuente.

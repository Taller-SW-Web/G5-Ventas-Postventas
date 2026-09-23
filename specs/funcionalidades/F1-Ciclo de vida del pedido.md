# Especificación F1: Ciclo de vida del pedido

**Responsable:** Michael  
**Estado:** En especificación  
**Actor principal:** Canales A/B/C (Marketplace, Chatbot, Retail) y Gestor  
**Microservicio:** M1 — Pedidos  
**Lineamiento del curso:** "Todos los canales gestionan el ciclo de vida del pedido en este módulo" (Módulo D — Ventas y Postventa)

## 1. Contexto

El Módulo D (Ventas y Postventa) recibe pedidos desde tres canales distintos — Marketplace (A), Chatbot (B) y Retail (C) — que llegan a él de forma indirecta, sin acceso al panel del Gestor. F1 es el núcleo transaccional del módulo: es la única funcionalidad autorizada a crear, leer y modificar el estado de un pedido, y **M1 es su dueño exclusivo** (M2 nunca actualiza las tablas de pedido directamente; solo puede solicitarle cambios a M1 por API).

Esta funcionalidad opera sobre sus propias tablas de pedido, detalle de pedido, pago e historial de estados. No decide anulaciones (F2), devoluciones (F3), reembolsos (F4), calificaciones (F5) ni reclamos (F6) — esas funcionalidades le solicitan transiciones de estado a F1, pero la lógica y la validación de cada transición vive únicamente aquí.

## 2. Propósito

Registrar y controlar el pedido desde que un canal lo crea hasta que llega a un estado final, garantizando que las transiciones de estado sean siempre válidas y auditables, y notificando mediante eventos a los módulos que dependen de esos cambios.

## 3. Alcance

Esta funcionalidad incluye:

- Creación del pedido a partir de una solicitud de un canal (A/B/C), con snapshot estructurado de `canal`, datos de `contacto`, ítems, `cupon`, datos de `envio` y condiciones de `pago`.
- Consulta del pedido por identificador y por cliente (listado con filtros).
- Aplicación de las transiciones de estado permitidas por la máquina de estados:
  
  ```
               [CREADO] ──────(Fallo/Timeout: PAGO_NO_COMPLETADO)─────► [ANULADO]
                  │                                                        ▲
                  ▼ (Pago confirmado)                                      │
               [PAGADO] ──────────(Anulación F2: directa)──────────────────┤
                  │                                                        │
                  ▼                                                        │
           [EN PREPARACIÓN] ───(Anulación F2: requiere Gestor)─────────────┘
                  │
                  ▼
            [DESPACHADO] ──────(Entrega fallida / Logística E)────────► [ANULADO]
                  │
                  ▼
            [ENTREGADO] ───────(Post-entrega: Deriva a F3 Devolución)
  ```

- Registro de cada cambio de estado en un historial auditable (actor, motivo, fecha/hora en UTC).
- Publicación de eventos de dominio (`pedido creado`, `pedido pagado`, `pedido anulado`, `pedido entregado`) para que otros módulos reaccionen sin acoplamiento síncrono.

Esta funcionalidad **no incluye**: carrito/checkout de los canales (responsabilidad de A/B/C), ni la operación logística del despacho en sí (responsabilidad del módulo externo Despacho y Entrega — ver sección 9).

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- El canal que origina la solicitud debe estar identificado y autenticado (token/rol válido emitido por Seguridad — G).
- El pedido debe incluir al menos un ítem, con producto y cantidad válidos.
- Estructura obligatoria de payload de creación: debe contener los bloques `canal`, `contacto`, `envio`, `pago` y opcionalmente `cupon`.
- El precio y la disponibilidad de cada ítem deben validarse contra Productos (F) antes de confirmar la creación.
- Toda transición de estado solicitada debe corresponder a una arista existente en la máquina de estados; cualquier salto no dibujado se rechaza con `409 Conflict`.
- Las operaciones administrativas (consulta general, forzar un estado) requieren token JWT con rol `GESTOR` o `ADMIN`.

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| Seguridad y Usuarios (G) | Emitir el token JWT, validar rol y aportar datos de contacto del cliente. |
| Productos y Ofertas (F) | Confirmar precio/disponibilidad al crear el pedido y recibir aviso de movimientos de stock al anular. |
| Despacho y Entrega (E) | Recibir la solicitud de despacho cuando el pedido pasa a `EN PREPARACIÓN`/`DESPACHADO`, y notificar por evento/endpoint cuando el pedido fue `ENTREGADO` o falló la entrega. F1 **nunca** asigna repartidor, ruta ni zona — solo consume el evento. |
| Pasarela de Pagos (Externa) | Emitir la notificación de cobro exitoso (`CREADO → PAGADO`) o fallo. |
| Canales A/B/C | Crear y consultar pedidos; solicitar anulación directa de pedidos `CREADO` por abandono o timeout de pago. |
| F2 — Anulación de pedidos | Orquestar y solicitar a F1 la transición a `ANULADO` en estados pagados o en preparación. |
| F3 — Devoluciones y cambios | Consulta a F1 que el pedido esté `ENTREGADO` antes de aceptar una solicitud de devolución/cambio. |
| F5 — Calificación de experiencia | Se activa a partir del evento `pedido entregado` que publica F1. |
| F6 — Reclamos, dashboard y reportes | Consume los eventos de F1 (pagado, anulado, entregado) para actualizar sus agregados. |

### 4.3. Resultados

- Un pedido válido se guarda con identificador único, estado `CREADO` y su primer registro de historial.
- Cada transición válida actualiza el estado del pedido y agrega una entrada al historial con actor, motivo y fecha/hora en UTC.
- Cada transición relevante (pagado, anulado, entregado) publica un evento de dominio para los consumidores acordados.
- Una transición inválida no modifica el pedido ni genera evento.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Creación del pedido

El sistema DEBE permitir crear un pedido a partir de una solicitud de un canal, validando la estructura obligatoria (`canal`, `contacto`, `envio`, `pago`, `items` y `cupon`), referencias y disponibilidad antes de persistir.

#### CA-01. Creación exitosa de un pedido con estructura completa

- **DADO** que un canal (Marketplace, Chatbot o Retail) envía un pedido con datos de `contacto`, ítems válidos, bloque de `envio`, condiciones de `pago` y cupón de descuento opcional.
- **CUANDO** se confirma la solicitud.
- **ENTONCES** el sistema consulta precio/disponibilidad a Productos (F), persiste el pedido con estado `CREADO`, calcula totales netos y registra el primer historial.

#### CA-02. Rechazo por datos incompletos

- **DADO** un pedido que carece de bloque de `contacto`, ítems, datos de `envio` o condiciones de `pago`.
- **CUANDO** se envía la solicitud de creación.
- **ENTONCES** el sistema responde `400 Bad Request` y no persiste el pedido.

#### CA-03. Rechazo por producto sin disponibilidad

- **DADO** un pedido que incluye un ítem sin stock disponible según Productos (F).
- **CUANDO** se confirma la solicitud.
- **ENTONCES** el sistema responde `409 Conflict` y no persiste el pedido.

### RF-02. Consulta del pedido

El sistema DEBE permitir consultar un pedido por identificador y listar pedidos de un cliente con filtro por estado.

#### CA-04. Consulta exitosa por identificador (Canales / Chatbot)

- **DADO** un pedido existente.
- **CUANDO** un canal (ej. Chatbot) o el Gestor consulta por su identificador (`pedidoId`).
- **ENTONCES** el sistema retorna `200 OK` con el detalle, el estado actual, totales, datos de contacto/envío y el historial de estados completo.

#### CA-05. Consulta de pedido inexistente

- **DADO** un identificador que no corresponde a ningún pedido.
- **CUANDO** se realiza la consulta.
- **ENTONCES** el sistema responde `404 Not Found`.

#### CA-06. Listado filtrado por cliente y estado

- **DADO** un cliente con varios pedidos en distintos estados.
- **CUANDO** un canal o cliente solicita el listado filtrando por `clienteId` y opcionalmente por `estado`.
- **ENTONCES** el sistema retorna solo los pedidos de ese cliente que cumplen con el filtro indicado.

### RF-03. Transición de estados según la máquina de estados

El sistema DEBE aplicar únicamente las transiciones dibujadas en la máquina de estados (`CREADO → PAGADO → EN PREPARACIÓN → DESPACHADO → ENTREGADO`, con ramas hacia `ANULADO`) y registrar cada cambio.

#### CA-07. Transición válida (pago confirmado)

- **DADO** un pedido en estado `CREADO`.
- **CUANDO** se recibe la notificación de pago exitoso desde la pasarela o webhook de pagos.
- **ENTONCES** el sistema transiciona el pedido a `PAGADO`, registra el historial con actor `PASARELA_PAGOS` y publica el evento `pedido pagado`.

#### CA-08. Transición inválida (salto de estado)

- **DADO** un pedido en estado `CREADO`.
- **CUANDO** se solicita la transición directa a `DESPACHADO`.
- **ENTONCES** el sistema responde `409 Conflict`, no modifica el pedido y no publica evento.

#### CA-09. Transición disparada por Despacho (E)

- **DADO** un pedido en estado `DESPACHADO`.
- **CUANDO** el módulo Despacho y Entrega notifica la entrega exitosa mediante su llamada a la API de F1.
- **ENTONCES** el sistema transiciona el pedido a `ENTREGADO`, registra el actor como "Despacho y Entrega" en el historial y publica el evento `pedido entregado`.

#### CA-10. Reintento de evento (idempotencia)

- **DADO** que el evento `pedido entregado` ya fue procesado para un pedido.
- **CUANDO** el mismo evento se reintenta (por ejemplo, por una falla de red del emisor).
- **ENTONCES** el sistema reconoce el reintento y no duplica la transición ni el historial.

#### CA-12. Anulación directa desde CREADO por abandono o fallo de pago (A9 / SPEC-15)

- **DADO** un pedido en estado `CREADO`.
- **CUANDO** el Canal (Chatbot / Web) envía la solicitud de anulación con motivo tipificado `PAGO_NO_COMPLETADO` tras agotarse el tiempo límite de espera (timeout) o producirse el rechazo definitivo del cobro.
- **ENTONCES** el sistema transiciona el pedido de forma directa a `ANULADO` sin requerir autorización ni intervención del rol Gestor, registra el historial con actor `CANAL` y motivo `PAGO_NO_COMPLETADO`, libera el stock en Productos (F) y no genera ninguna orden de reembolso hacia F4.

### RF-04. Historial y trazabilidad

El sistema DEBE registrar toda transición de estado con actor, motivo (cuando aplique) y fecha/hora.

#### CA-11. Historial completo y ordenado

- **DADO** un pedido que pasó por varias transiciones.
- **CUANDO** se consulta su detalle.
- **ENTONCES** el historial se retorna ordenado cronológicamente, con actor y fecha/hora de cada cambio en formato UTC.

## 6. Frontend

F1 no tiene una interfaz propia orientada al cliente (los canales A/B/C tienen las suyas); su superficie visible es la consola del Gestor dentro del panel del Módulo D:

| Elemento | Responsabilidad |
|---|---|
| Listado de pedidos | Tabla paginada con filtros por canal, cliente, estado y fecha; acceso al detalle. |
| Detalle del pedido | Datos completos (`contacto`, `cupon`, `envio`, `pago`), ítems, historial de estados y acciones disponibles según el estado actual. |
| Línea de tiempo de estados | Visualización del historial (`HistorialEstado`) en orden cronológico, con actor, motivo y timestamps UTC. |
| Retroalimentación | Mensajes claros ante transición inválida, pedido no encontrado o error de red. |

La interfaz debe impedir acciones que ya se sabe que son inválidas según el estado actual (por ejemplo, no mostrar "Despachar" si el pedido no está `PAGADO`), pero toda regla se revalida siempre en el backend.

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Gestión de pedidos | CRUD de creación y consulta, con validación de estructura (`canal`, `contacto`, `envio`, `pago`, `cupon`). |
| Motor de máquina de estados | Validar y aplicar únicamente las transiciones permitidas; procesar la rama directa `CREADO → ANULADO` por `PAGO_NO_COMPLETADO` y rechazar cualquier salto no dibujado. |
| Servicio de historial | Registrar cada transición con actor, motivo y fecha/hora en UTC. |
| Publicador de eventos | Emitir `pedido creado`, `pedido pagado`, `pedido anulado` y `pedido entregado` a los consumidores acordados (M2, F5, F6). |
| Consumidor de eventos externos | Recibir la notificación de entrega/fallo desde Despacho (E) y confirmación de cobro desde la pasarela de forma idempotente. |

Las rutas, cuerpos, respuestas y códigos específicos se centralizan en `specs/api-contract.md` (recurso `Pedido`).

## 8. Requisitos no funcionales

- **Rendimiento (RNF-01):** consulta de pedido en menos de 500 ms.
- **Seguridad (RNF-02):** endpoints protegidos con rol; se valida que el actor pueda acceder al pedido solicitado, no solo que esté autenticado.
- **Trazabilidad (RNF-03):** toda transición queda registrada con actor, fecha/hora y motivo cuando aplique.
- **Disponibilidad (RNF-05):** si Productos (F) no responde al crear el pedido, la operación se rechaza de forma controlada (`409 Conflict`) — nunca se asume disponibilidad por defecto.
- **Aislamiento (RNF-07):** M1 es el único que lee/escribe las tablas de pedido; M2 y los demás módulos solo acceden por API.
- **Idempotencia (RNF-08):** los eventos consumidos desde Despacho (E) o pasarelas de pago deben poder reintentarse sin duplicar la transición.

## 9. Fuera de alcance

- **Carrito y checkout:** corresponden a cada canal (A/B/C), no a F1.
- **Simulación/procesamiento bancario del pago:** el cobro en sí ocurre en la pasarela externa; F1 solo recibe el webhook o notificación de resultado.
- **Asignación de repartidor, rutas y zonas de despacho:** corresponden al módulo externo Despacho y Entrega.
- **Decisión de anulación condicional, devolución, reembolso, calificación y reclamos:** cada uno tiene su propia funcionalidad (F2 a F6); F1 solo expone el endpoint de transición que ellas consumen.

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 a CA-03 | Crear pedidos válidos con payload completo (`contacto`, `envio`, `pago`), con datos incompletos y sin stock. | Unitaria e integración | Pedido `CREADO` con historial; `400`/`409` según corresponda. |
| CA-04 a CA-06 | Consultar por id existente/inexistente y listar filtrando por cliente/estado. | Integración | `200` con detalle completo; `404` para inexistente; listado correctamente filtrado. |
| CA-07 y CA-08 | Ejecutar una transición válida y una inválida (salto de estado). | Unitaria e integración | Transición aplicada con evento publicado; `409` sin cambios para la inválida. |
| CA-09 y CA-10 | Simular el evento de entrega de Despacho, incluyendo un reintento del mismo evento. | Integración | Transición a `ENTREGADO` una sola vez, sin duplicar historial ni evento. |
| CA-11 | Consultar el historial tras varias transiciones. | Integración | Historial ordenado cronológicamente con actor y fecha/hora UTC. |
| CA-12 | Simular cancelación por abandono en canal enviando `PAGO_NO_COMPLETADO` sobre pedido `CREADO`. | Integración | Transición directa a `ANULADO` sin generar aprobaciones para Gestor ni reembolso a F4. |

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-12` están implementados y cuentan con pruebas automatizadas exitosas.
- El recorrido funcional completo (creación → pago → entrega) y las ramas alternas de anulación directa fueron verificadas de extremo a extremo.
- Ninguna transición fuera de la máquina de estados es posible, ni siquiera con permisos de `ADMIN`.
- El historial es consultable y completo para cualquier pedido.
- M2 y los demás módulos solo modifican el pedido a través del endpoint de transición de F1 — nunca escriben directamente sobre sus tablas.
- La evidencia de pruebas puede trazarse hacia cada criterio de aceptación.
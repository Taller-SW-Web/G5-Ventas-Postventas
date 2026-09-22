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

- Creación del pedido a partir de una solicitud de un canal (A/B/C), con snapshot de productos, precios y datos descriptivos al momento de la venta.
- Consulta del pedido por identificador y por cliente (listado con filtros).
- Aplicación de las transiciones de estado permitidas por la máquina de estados: `CREADO → PAGADO → EN PREPARACIÓN → DESPACHADO → ENTREGADO`, con la rama alterna `→ ANULADO` (ver F2).
- Registro de cada cambio de estado en un historial auditable (actor, motivo, fecha/hora).
- Publicación de eventos de dominio (`pedido pagado`, `pedido anulado`, `pedido entregado`) para que otros módulos reaccionen sin acoplamiento síncrono.

Esta funcionalidad **no incluye**: carrito/checkout de los canales (responsabilidad de A/B/C), ni la operación logística del despacho en sí (responsabilidad del módulo externo Despacho y Entrega — ver sección 9).

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- El canal que origina la solicitud debe estar identificado y autenticado (token/rol válido emitido por Seguridad — G).
- El pedido debe incluir al menos un ítem, con producto y cantidad válidos.
- El precio y la disponibilidad de cada ítem deben validarse contra Productos (F) antes de confirmar la creación.
- Toda transición de estado solicitada debe corresponder a una arista existente en la máquina de estados; cualquier salto no dibujado se rechaza.
- Las operaciones administrativas (consulta general, forzar un estado) requieren token JWT con rol `GESTOR` o `ADMIN`.

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| Seguridad y Usuarios (G) | Emitir el token JWT, validar rol y aportar datos de contacto del cliente. |
| Productos y Ofertas (F) | Confirmar precio/disponibilidad al crear el pedido y recibir aviso de movimientos de stock al anular. |
| Despacho y Entrega (E) | Recibir la solicitud de despacho cuando el pedido pasa a `EN PREPARACIÓN`/`DESPACHADO`, y notificar por evento cuando el pedido fue `ENTREGADO` o falló la entrega. F1 **nunca** asigna repartidor, ruta ni zona — solo consume el evento. |
| Canales A/B/C | Crear y consultar pedidos; enviar la solicitud inicial del cliente/vendedor. |
| F2 — Anulación de pedidos | Solicita a F1 la transición a `ANULADO` cuando corresponde. |
| F3 — Devoluciones y cambios | Consulta a F1 que el pedido esté `ENTREGADO` antes de aceptar una solicitud de devolución/cambio. |
| F5 — Calificación de experiencia | Se activa a partir del evento `pedido entregado` que publica F1. |
| F6 — Reclamos, dashboard y reportes | Consume los eventos de F1 (pagado, anulado, entregado) para actualizar sus agregados. |

### 4.3. Resultados

- Un pedido válido se guarda con identificador único, estado `CREADO` y su primer registro de historial.
- Cada transición válida actualiza el estado del pedido y agrega una entrada al historial con actor, motivo (si aplica) y fecha/hora en UTC.
- Cada transición relevante (pagado, anulado, entregado) publica un evento de dominio para los consumidores acordados.
- Una transición inválida no modifica el pedido ni genera evento.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Creación del pedido

El sistema DEBE permitir crear un pedido a partir de una solicitud de un canal, validando estructura, referencias y disponibilidad antes de persistir.

#### CA-01. Creación exitosa de un pedido

- **DADO** que el Canal Marketplace envía un pedido con cliente identificado, dos ítems válidos y dirección de entrega.
- **CUANDO** se confirma la solicitud.
- **ENTONCES** el sistema consulta precio/disponibilidad a Productos (F), persiste el pedido con estado `CREADO` y registra el primer historial.

#### CA-02. Rechazo por datos incompletos

- **DADO** un pedido sin ítems o sin dirección de entrega.
- **CUANDO** se envía la solicitud de creación.
- **ENTONCES** el sistema responde `400 Bad Request` y no persiste el pedido.

#### CA-03. Rechazo por producto sin disponibilidad

- **DADO** un pedido que incluye un ítem sin stock disponible según Productos (F).
- **CUANDO** se confirma la solicitud.
- **ENTONCES** el sistema responde `409 Conflict` y no persiste el pedido.

### RF-02. Consulta del pedido

El sistema DEBE permitir consultar un pedido por identificador y listar pedidos de un cliente con filtro por estado.

#### CA-04. Consulta exitosa por identificador

- **DADO** un pedido existente.
- **CUANDO** un canal o el Gestor consulta por su identificador.
- **ENTONCES** el sistema retorna `200 OK` con el detalle, el estado actual y el historial completo.

#### CA-05. Consulta de pedido inexistente

- **DADO** un identificador que no corresponde a ningún pedido.
- **CUANDO** se realiza la consulta.
- **ENTONCES** el sistema responde `404 Not Found`.

#### CA-06. Listado filtrado por cliente y estado

- **DADO** un cliente con varios pedidos en distintos estados.
- **CUANDO** un canal solicita el listado filtrando por `estado=ENTREGADO`.
- **ENTONCES** el sistema retorna solo los pedidos de ese cliente que están `ENTREGADO`.

### RF-03. Transición de estados según la máquina de estados

El sistema DEBE aplicar únicamente las transiciones dibujadas en la máquina de estados (`CREADO → PAGADO → EN PREPARACIÓN → DESPACHADO → ENTREGADO`, y `→ ANULADO` desde los estados permitidos) y registrar cada cambio.

#### CA-07. Transición válida (pago confirmado)

- **DADO** un pedido en estado `CREADO`.
- **CUANDO** se confirma el pago.
- **ENTONCES** el sistema transiciona el pedido a `PAGADO`, registra el historial y publica el evento `pedido pagado`.

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

### RF-04. Historial y trazabilidad

El sistema DEBE registrar toda transición de estado con actor, motivo (cuando aplique) y fecha/hora.

#### CA-11. Historial completo y ordenado

- **DADO** un pedido que pasó por varias transiciones.
- **CUANDO** se consulta su detalle.
- **ENTONCES** el historial se retorna ordenado cronológicamente, con actor y fecha/hora de cada cambio.

## 6. Frontend

F1 no tiene una interfaz propia orientada al cliente (los canales A/B/C tienen las suyas); su superficie visible es la consola del Gestor dentro del panel del Módulo D:

| Elemento | Responsabilidad |
|---|---|
| Listado de pedidos | Tabla paginada con filtros por canal, estado y fecha; acceso al detalle. |
| Detalle del pedido | Datos del pedido, ítems, pago, historial de estados y acciones disponibles según el estado actual. |
| Línea de tiempo de estados | Visualización del historial (`HistorialEstado`) en orden cronológico, con actor y motivo. |
| Retroalimentación | Mensajes claros ante transición inválida, pedido no encontrado o error de red. |

La interfaz debe impedir acciones que ya se sabe que son inválidas según el estado actual (por ejemplo, no mostrar "Despachar" si el pedido no está `PAGADO`), pero toda regla se revalida siempre en el backend.

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Gestión de pedidos | CRUD de creación y consulta, con validación de estructura y referencias. |
| Motor de máquina de estados | Validar y aplicar únicamente las transiciones permitidas; rechazar cualquier salto no dibujado. |
| Servicio de historial | Registrar cada transición con actor, motivo y fecha/hora en UTC. |
| Publicador de eventos | Emitir `pedido pagado`, `pedido anulado` y `pedido entregado` a los consumidores acordados (M2, F5, F6). |
| Consumidor de eventos de Despacho | Recibir la notificación de entrega/fallo desde E y aplicar la transición correspondiente de forma idempotente. |

Las rutas, cuerpos, respuestas y códigos específicos se centralizan en `specs/api-contract.md` (recurso `Pedido`).

## 8. Requisitos no funcionales

- **Rendimiento (RNF-01):** consulta de pedido en menos de 500 ms.
- **Seguridad (RNF-02):** endpoints protegidos con rol; se valida que el actor pueda acceder al pedido solicitado, no solo que esté autenticado.
- **Trazabilidad (RNF-03):** toda transición queda registrada con actor, fecha/hora y motivo cuando aplique.
- **Disponibilidad (RNF-05):** si Productos (F) no responde al crear el pedido, la operación se rechaza de forma controlada — nunca se asume disponibilidad por defecto.
- **Aislamiento (RNF-07):** M1 es el único que lee/escribe las tablas de pedido; M2 y los demás módulos solo acceden por API.
- **Idempotencia (RNF-08):** los eventos consumidos desde Despacho (E) deben poder reintentarse sin duplicar la transición.

## 9. Fuera de alcance

- **Carrito y checkout:** corresponden a cada canal (A/B/C), no a F1.
- **Simulación/procesamiento del pago:** el "pago confirmado" que dispara `CREADO → PAGADO` se recibe como notificación; el procesamiento del cobro en sí no es parte de F1.
- **Asignación de repartidor, rutas y zonas de despacho:** corresponden al módulo externo Despacho y Entrega.
- **Anulación, devolución, reembolso, calificación y reclamos:** cada uno tiene su propia funcionalidad (F2 a F6); F1 solo expone el endpoint de transición que ellas consumen.

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 a CA-03 | Crear pedidos válidos, con datos incompletos y sin stock. | Unitaria e integración | Pedido `CREADO` con historial; `400`/`409` según corresponda. |
| CA-04 a CA-06 | Consultar por id existente/inexistente y listar filtrando por cliente/estado. | Integración | `200` con detalle completo; `404` para inexistente; listado correctamente filtrado. |
| CA-07 y CA-08 | Ejecutar una transición válida y una inválida (salto de estado). | Unitaria e integración | Transición aplicada con evento publicado; `409` sin cambios para la inválida. |
| CA-09 y CA-10 | Simular el evento de entrega de Despacho, incluyendo un reintento del mismo evento. | Integración | Transición a `ENTREGADO` una sola vez, sin duplicar historial ni evento. |
| CA-11 | Consultar el historial tras varias transiciones. | Integración | Historial ordenado cronológicamente con actor y fecha/hora. |

Además, se ejecutará un recorrido funcional completo: creación del pedido → pago → preparación → despacho → notificación de entrega desde Despacho (E) → publicación de evento `pedido entregado` → consumo por F5 (encuesta).

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-11` están implementados y cuentan con pruebas automatizadas exitosas.
- El recorrido funcional completo (creación → entrega) fue verificado de extremo a extremo, incluyendo la integración con el evento de Despacho.
- Ninguna transición fuera de la máquina de estados es posible, ni siquiera con permisos de `ADMIN`.
- El historial es consultable y completo para cualquier pedido.
- M2 y los demás módulos solo modifican el pedido a través del endpoint de transición de F1 — nunca escriben directamente sobre sus tablas.
- La evidencia de pruebas puede trazarse hacia cada criterio de aceptación.

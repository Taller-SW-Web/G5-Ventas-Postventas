# ESP-05: Registro de anulación y motivo

**Responsable:** Luis Arroyo
**Funcionalidad:** F2 — Anulación de pedidos
**Estado:** En especificación
**Actor principal:** Cliente (solicitante), Canal (sistema iniciador) y Gestor (autoriza condicionalmente)
**Microservicio:** M1 — Pedidos
**Lineamiento del curso:** "Anulación de pedidos según reglas de negocio (con autorización)" (Módulo D — Ventas y Postventa)

## 1. Contexto

ESP-05 cubre la primera mitad de F2: **recibir la solicitud de anulación, validar el motivo tipificado y decidir si se ejecuta de forma directa o si requiere autorización explícita del Gestor**, según el estado del pedido. La coordinación de los efectos secundarios (stock, despacho, origen del reembolso) queda documentada en ESP-06.

F2 nunca escribe directamente sobre las tablas de pedido: una vez tomada la decisión, delega la transición real a `ANULADO` al endpoint de F1 (`PATCH /api/v1/pedidos/{id}/estado`).

## 2. Propósito

Registrar y validar toda solicitud de anulación —ya sea iniciada por el Cliente, por el Canal (automáticamente) o resuelta por el Gestor— garantizando que:

- Todo pedido `DESPACHADO` o `ENTREGADO` quede bloqueado (409) y derivado a Devoluciones (F3).
- Toda solicitud sin motivo tipificado sea rechazada (400).
- Las anulaciones en `CREADO`/`PAGADO` se ejecuten sin intervención humana, y las de `EN PREPARACIÓN` queden condicionadas a la aprobación del Gestor.

## 3. Alcance

Incluye:

- Endpoint `POST /api/v1/pedidos/{pedidoId}/anulaciones`.
- Validación de estado anulable (`CREADO`, `PAGADO`, `EN PREPARACIÓN`).
- Validación de motivo tipificado obligatorio (`PAGO_NO_COMPLETADO`, `ERROR_SELECCION_PRODUCTO`, `ARREPENTIMIENTO_COMPRA`, `SOLICITUD_CLIENTE`, entre otros definidos en el catálogo del equipo).
- Matriz de autorización según estado y actor disparador (ver tabla 3.1).
- Bandeja de autorizaciones pendientes para el Gestor cuando el pedido está `EN PREPARACIÓN`.
- Registro del solicitante, autorizador (si aplica), motivo y resultado en el historial de la anulación.

**No incluye:** la coordinación de reposición de stock, cancelación de despacho ni el origen de la solicitud de reembolso a F4 (eso es ESP-06); la ejecución de la transición de estado en sí (la ejecuta F1); el procesamiento contable del reembolso (F4).

### 3.1. Matriz de autorización según estado y actor

| Estado Origen | Actor Disparador | Motivo Típico | Requiere Gestor | Resultado inmediato |
|---|---|---|---|---|
| `CREADO` | **Canal** (Chatbot / Marketplace / Retail) | `PAGO_NO_COMPLETADO` | **NO** (automática e inmediata) | `200 OK` → `ANULADO` |
| `CREADO` | Cliente | `ERROR_SELECCION_PRODUCTO`, `ARREPENTIMIENTO_COMPRA` | **NO** (directa) | `200 OK` → `ANULADO` |
| `PAGADO` | Cliente / Gestor | Motivo tipificado de anulación | **NO** (directa) | `200 OK` → `ANULADO` |
| `EN PREPARACIÓN` | Cliente | Motivo tipificado de anulación | **SÍ** (bandeja de aprobación) | `202 Accepted` → pendiente |
| `DESPACHADO` / `ENTREGADO` | Cualquiera | Cualquiera | Bloqueado | `409 Conflict` → deriva a F3 |

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- El pedido existe y está en un estado anulable (`CREADO`, `PAGADO` o `EN PREPARACIÓN`).
- El solicitante está identificado (cliente autenticado, sistema del canal, o Gestor autenticado con rol administrativo).
- El motivo de anulación es obligatorio y pertenece al catálogo tipificado.

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| F1 — Ciclo de vida del pedido | Ejecuta la transición real a `ANULADO` vía `PATCH /api/v1/pedidos/{id}/estado`; ESP-05 nunca escribe directamente sobre las tablas de pedido. |
| Canales A/B/C | Inician la anulación automática sobre pedidos `CREADO` cuando el checkout se abandona o la pasarela rechaza el cobro definitivamente. |
| Gestor | Autoriza o rechaza la anulación exclusivamente cuando el pedido está `EN PREPARACIÓN`. |
| Seguridad (G) | Provee el token JWT y el rol del solicitante para validar identidad y permisos. |

### 4.3. Resultados

- Una anulación válida deja registrado el solicitante, el motivo y (si aplica) el autorizador, y dispara la solicitud de transición a F1.
- Una anulación en `EN PREPARACIÓN` sin resolución del Gestor queda en estado pendiente, sin modificar el pedido.
- Una solicitud inválida (motivo faltante o estado no anulable) no genera ningún efecto ni transición.

## 5. Requisitos y criterios de aceptación

### RF-01. Solicitud y validación de estado

El sistema DEBE validar que el pedido esté en un estado anulable antes de procesar cualquier anulación, y ejecutar directamente aquellas que no requieran aprobación administrativa.

#### CA-01. Anulación directa desde CREADO/PAGADO por el cliente

- **DADO** un pedido en estado `CREADO` o `PAGADO`.
- **CUANDO** el cliente solicita la anulación con un motivo tipificado válido.
- **ENTONCES** el sistema ejecuta la anulación sin requerir autorización adicional de un Gestor y transiciona a `ANULADO`.

#### CA-02. Anulación automática por fallo o timeout de pago (PAGO_NO_COMPLETADO)

- **Precondición:** el pedido está en estado `CREADO`.
- **Disparador:** el Canal detecta abandono del checkout o rechazo definitivo de la pasarela de pago.
- **Comportamiento:** el Canal invoca `POST /api/v1/pedidos/{pedidoId}/anulaciones` indicando el motivo tipificado `PAGO_NO_COMPLETADO`. El sistema transiciona el pedido **directamente a `ANULADO`**, sin generar una solicitud pendiente ni requerir firma/aprobación de un Gestor.
- **Efecto secundario (detallado en ESP-06):** libera de inmediato el stock reservado en el módulo de Productos (F). **No genera solicitud de reembolso en F4**, porque el pedido nunca llegó a cobrarse.
- **DADO** un pedido en estado `CREADO`.
- **CUANDO** el Canal envía la anulación con motivo `PAGO_NO_COMPLETADO` tras detectar abandono de checkout o fallo definitivo de cobro.
- **ENTONCES** el sistema ejecuta de forma inmediata y automática la anulación (`200 OK`), registra al Canal como actor en el historial, y omite cualquier interacción con F4.

#### CA-03. Rechazo por estado no anulable

- **DADO** un pedido en estado `DESPACHADO` o `ENTREGADO`.
- **CUANDO** se solicita su anulación.
- **ENTONCES** el sistema rechaza la solicitud con `409 Conflict` e indica que corresponde iniciar una devolución (F3).

#### CA-04. Rechazo por motivo faltante o no tipificado

- **DADO** una solicitud de anulación sin motivo tipificado o con un valor fuera del catálogo.
- **CUANDO** se envía.
- **ENTONCES** el sistema responde `400 Bad Request` y no ejecuta la anulación.

### RF-02. Autorización condicional del Gestor

El sistema DEBE exigir autorización explícita del Gestor cuando el pedido está `EN PREPARACIÓN`.

#### CA-05. Autorización requerida y aprobada

- **DADO** un pedido en estado `EN PREPARACIÓN`.
- **CUANDO** el Gestor aprueba la anulación desde su bandeja.
- **ENTONCES** el sistema ejecuta la transición a `ANULADO` y registra al Gestor como autorizador en el historial.

#### CA-06. Autorización requerida y rechazada

- **DADO** un pedido en estado `EN PREPARACIÓN`.
- **CUANDO** el Gestor rechaza la solicitud.
- **ENTONCES** el pedido conserva su estado operativo anterior y se registra la decisión de rechazo con su motivo.

## 6. Frontend

| Elemento | Responsabilidad |
|---|---|
| Acción "Anular pedido" | Disponible solo cuando el estado del pedido lo permite; exige motivo tipificado obligatorio. |
| Bandeja de autorizaciones pendientes | Lista exclusivamente los pedidos `EN PREPARACIÓN` con solicitud de anulación esperando decisión del Gestor. |
| Detalle de la anulación | Muestra motivo, solicitante (cliente, canal o gestor), autorizador (si aplica) y resultado. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Validador de elegibilidad | Verifica que el estado actual del pedido permita anulación. |
| Validador de motivo | Verifica que el motivo pertenezca al catálogo tipificado. |
| Motor de autorización | Discrimina solicitudes directas (incluyendo `CREADO` con `PAGO_NO_COMPLETADO` por canal) frente a condicionales que exigen aprobación del Gestor. |
| Cliente hacia F1 | Ejecuta la transición de estado a través de `PATCH /api/v1/pedidos/{id}/estado`. |

## 8. Requisitos no funcionales relacionados

- **Trazabilidad (RNF-03):** toda anulación registra solicitante, autorizador (si aplica), motivo y timestamp UTC.
- **Seguridad (RNF-02):** solo el Cliente dueño del pedido, el Canal autenticado o un Gestor con rol administrativo pueden invocar el endpoint.
- **Aislamiento (RNF-07):** ESP-05 no modifica directamente las tablas de pedido; toda transición pasa por F1.

## 9. Fuera de alcance

- Coordinación de stock, despacho y origen del reembolso hacia F4 (ESP-06).
- Ejecución de la transición de estado en la base de datos de pedidos (F1).
- Procesamiento contable del extorno (F4).

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 y CA-02 | Anular directamente desde `CREADO` (cliente y canal con `PAGO_NO_COMPLETADO`) y desde `PAGADO`. | Unitaria e integración | Transición inmediata a `ANULADO`, sin tareas pendientes de aprobación. |
| CA-03 y CA-04 | Intentar anular sobre `DESPACHADO`/`ENTREGADO`, o enviar solicitud sin motivo. | Unitaria e integración | `409 Conflict` y `400 Bad Request` respectivamente. |
| CA-05 y CA-06 | Simular aprobación y rechazo del Gestor sobre un pedido `EN PREPARACIÓN`. | Integración | Transición aplicada solo si se aprueba; estado conservado si se rechaza. |

## 11. Criterio de completitud

ESP-05 se considera completo cuando:

- Los criterios `CA-01` a `CA-06` están implementados y cuentan con pruebas automatizadas exitosas.
- Ninguna anulación puede ejecutarse sobre un pedido `DESPACHADO` o `ENTREGADO`.
- Las anulaciones en `CREADO` por el Canal con motivo `PAGO_NO_COMPLETADO` se ejecutan sin intervención humana ni generan solicitud de reembolso.
- Toda anulación en `EN PREPARACIÓN` sin autorización explícita del Gestor queda bloqueada.

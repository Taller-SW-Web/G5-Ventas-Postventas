# Especificación F2: Anulación de pedidos

**Responsable:** Luis Arroyo  
**Estado:** En especificación  
**Actor principal:** Cliente (solicitante), Canal (sistema iniciador) y Gestor (autoriza condicionalmente)  
**Microservicio:** M1 — Pedidos  
**Lineamiento del curso:** "Anulación de pedidos según reglas de negocio (con autorización)" (Módulo D — Ventas y Postventa)

## 1. Contexto

F2 permite cancelar un pedido **antes** de que llegue al cliente, deshaciendo lo que corresponda (stock, despacho, dinero si ya hubo pago). Se apoya sobre F1 (M1 es quien ejecuta la transición real de estado; F2 valida y decide, F1 aplica). A partir de `DESPACHADO` ya no es posible anular — el camino pasa a ser una devolución (F3).

## 2. Propósito

Cancelar un pedido respetando el estado actual, coordinando los efectos secundarios sobre stock, despacho y, cuando existe pago, el origen del reembolso — sin ejecutar el mismo extorno más de una vez.

## 3. Alcance

Incluye:
- Solicitud de anulación con motivo tipificado obligatorio.
- **Matriz de autorización según estado y actor:**

| Estado Origen | Actor Disparador | Motivo Típico | Requiere Gestor | Efectos Secundarios |
|---|---|---|---|---|
| `CREADO` | **Canal (Chatbot / Web / Retail)** | `PAGO_NO_COMPLETADO` | **NO** (Automática e inmediata) | Reposición de stock en F. **Sin reembolso en F4**. |
| `CREADO` | Cliente | `ERROR_SELECCION_PRODUCTO`, `ARREPENTIMIENTO_COMPRA` | **NO** (Directa) | Reposición de stock en F. **Sin reembolso en F4**. |
| `PAGADO` | Cliente / Gestor | Motivo tipificado de anulación | **NO** (Directa) | Reposición de stock en F, cancelación despacho en E y **solicitud única de reembolso a F4**. |
| `EN PREPARACIÓN` | Cliente | Motivo tipificado de anulación | **SÍ** (Condicional - bandeja de aprobación) | Si se aprueba: reposición en F, cancelación en E y **solicitud a F4**. Si se rechaza: conserva estado. |
| `DESPACHADO` / `ENTREGADO` | Cualquiera | Cualquiera | **Bloqueado (409 Conflict)** | No anulable. Debe gestionarse como Devolución (F3). |

- Ejecución de la transición a `ANULADO` (vía F1) y su registro en el historial.
- Coordinación de acciones derivadas: reposición de stock (F) y cancelación de despacho (E).
- Origen de la solicitud de reembolso hacia F4 **únicamente** cuando existe pago confirmado.

**No incluye:** la devolución de un pedido ya despachado (eso es F3), ni el procesamiento del extorno en sí (eso es F4).

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- El pedido existe y está en un estado anulable (`CREADO`, `PAGADO` o `EN PREPARACIÓN`).
- El solicitante está identificado (cliente desde su canal, sistema del canal o Gestor).
- El motivo de anulación es obligatorio y tipificado (ej. `PAGO_NO_COMPLETADO`, `ERROR_SELECCION_PRODUCTO`, `SOLICITUD_CLIENTE`).
- Si el pedido está `EN PREPARACIÓN`, existe una decisión de autorización expresa del Gestor antes de ejecutar.

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| F1 — Ciclo de vida del pedido | Ejecuta la transición real a `ANULADO` y registra el historial; F2 nunca escribe directamente sobre las tablas de pedido. |
| Productos y Ofertas (F) | Repone el stock liberado de los ítems del pedido anulado. |
| Despacho y Entrega (E) | Cancela el envío si ya estaba programado. |
| F4 — Reembolsos y extornos | Recibe el origen de la solicitud de reembolso cuando el pedido ya tenía pago confirmado; F2 nunca ejecuta el extorno directamente. Si el pedido estaba en `CREADO`, F2 no invoca a F4. |
| Canales A/B/C | Inician la anulación automática directa sobre pedidos `CREADO` cuando vence el tiempo de pago o falla la pasarela. |
| Gestor | Autoriza o rechaza la anulación exclusivamente cuando el pedido está `EN PREPARACIÓN`. |

### 4.3. Resultados

- Una anulación válida deja el pedido en `ANULADO`, con motivo y actor registrados en el historial.
- Se genera la solicitud de reposición de stock hacia F y, si aplica, de cancelación de despacho hacia E.
- Si el pedido tenía pago confirmado (`PAGADO` o `EN PREPARACIÓN` aprobada), se origina exactamente una solicitud hacia F4 (idempotente). Si estaba en `CREADO`, no se genera solicitud a F4.
- Una anulación rechazada o inválida no modifica el pedido.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Solicitud y validación de estado

El sistema DEBE validar que el pedido esté en un estado anulable antes de procesar cualquier anulación y ejecutar directamente aquellas que no requieran aprobación administrativa.

#### CA-01. Anulación directa desde CREADO/PAGADO por cliente

- **DADO** un pedido en estado `CREADO` o `PAGADO`.
- **CUANDO** el cliente solicita la anulación con un motivo tipificado válido.
- **ENTONCES** el sistema ejecuta la anulación sin requerir autorización adicional de un Gestor y transiciona a `ANULADO`.

#### CA-01b. Anulación iniciada por el Canal por PAGO_NO_COMPLETADO (A9 / SPEC-15)

- **DADO** un pedido en estado `CREADO`.
- **CUANDO** el Canal (Chatbot, Marketplace o Retail) envía la anulación indicando el motivo tipificado `PAGO_NO_COMPLETADO` tras detectar abandono de checkout o fallo definitivo de cobro.
- **ENTONCES** el sistema ejecuta de forma inmediata y automática la anulación sin generar solicitud pendiente ni requerir intervención del Gestor, registrando al Canal como actor en el historial, reponiendo el stock en F y omitiendo cualquier interacción con F4.

#### CA-02. Rechazo por estado no anulable

- **DADO** un pedido en estado `DESPACHADO` o `ENTREGADO`.
- **CUANDO** se solicita su anulación.
- **ENTONCES** el sistema rechaza la solicitud con `409 Conflict` e indica que corresponde iniciar una devolución (F3).

#### CA-03. Rechazo por motivo faltante

- **DADO** una solicitud de anulación sin motivo tipificado.
- **CUANDO** se envía.
- **ENTONCES** el sistema responde `400 Bad Request` y no ejecuta la anulación.

### RF-02. Autorización condicional

El sistema DEBE exigir autorización explícita del Gestor cuando el pedido está `EN PREPARACIÓN`.

#### CA-04. Autorización requerida y aprobada

- **DADO** un pedido en estado `EN PREPARACIÓN`.
- **CUANDO** el Gestor aprueba la anulación desde su bandeja.
- **ENTONCES** el sistema ejecuta la transición a `ANULADO`, registra al Gestor como autorizador en el historial y dispara los efectos secundarios (stock, despacho y reembolso).

#### CA-05. Autorización requerida y rechazada

- **DADO** un pedido en estado `EN PREPARACIÓN`.
- **CUANDO** el Gestor rechaza la solicitud.
- **ENTONCES** el pedido conserva su estado operativo anterior (`EN PREPARACIÓN`) y se registra la decisión de rechazo con su motivo.

### RF-03. Coordinación de efectos secundarios

El sistema DEBE coordinar la reposición de stock, la cancelación de despacho (si aplica) y el origen del reembolso (únicamente si hubo pago), sin duplicar ninguna de estas acciones.

#### CA-06. Reposición de stock y cancelación de despacho

- **DADO** un pedido anulado que ya tenía una solicitud de despacho programada.
- **CUANDO** se confirma la anulación.
- **ENTONCES** el sistema solicita a Productos (F) la reposición del stock y a Despacho (E) la cancelación del envío.

#### CA-07. Origen de reembolso sin duplicar

- **DADO** un pedido `PAGADO` que se anula.
- **CUANDO** se ejecuta la anulación.
- **ENTONCES** el sistema origina exactamente una solicitud hacia F4; un reintento de la misma anulación no genera una segunda solicitud de reembolso.

#### CA-08. Falla parcial visible

- **DADO** que la anulación se ejecutó pero la cancelación de despacho falló (por ejemplo, E no respondió).
- **CUANDO** ocurre la falla.
- **ENTONCES** el sistema registra la inconsistencia de forma visible para el Gestor y deja evidencia para reintento — nunca la oculta como si todo hubiese salido bien.

## 6. Frontend

Superficie visible dentro del panel del Gestor:

| Elemento | Responsabilidad |
|---|---|
| Acción "Anular pedido" | Disponible solo cuando el estado del pedido lo permite; pide motivo tipificado obligatorio. |
| Bandeja de autorizaciones pendientes | Lista exclusivamente los pedidos `EN PREPARACIÓN` con solicitud de anulación esperando decisión del Gestor. |
| Detalle de la anulación | Muestra motivo, solicitante, autorizador (si aplica) y el resultado de las acciones derivadas (stock, despacho, reembolso). |
| Alertas de inconsistencia | Resalta visualmente cuando una acción derivada falló y necesita reintento manual/automático. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Validador de elegibilidad | Verifica que el estado actual del pedido permita anulación (`CREADO`, `PAGADO`, `EN PREPARACIÓN`). |
| Motor de autorización | Discrimina solicitudes directas (incluyendo `CREADO` con `PAGO_NO_COMPLETADO` por canal) frente a condicionales que exigen aprobación del Gestor (`EN PREPARACIÓN`). |
| Orquestador de efectos secundarios | Solicita reposición de stock (F), cancelación de despacho (E) y origina la solicitud a F4 solo si el pedido fue pagado. |
| Cliente hacia F1 | Ejecuta la transición de estado a través del endpoint `PATCH /api/v1/pedidos/{id}/estado` de F1 — F2 nunca escribe directamente sobre las tablas de pedido. |

## 8. Requisitos no funcionales

- **Trazabilidad (RNF-03):** toda anulación registra solicitante (canal, cliente o gestor), autorizador (si aplica), motivo y timestamp UTC.
- **Idempotencia (RNF-08):** un reintento de la misma anulación no debe generar una segunda solicitud de reembolso hacia F4 ni duplicar el historial.
- **Visibilidad de fallas:** ninguna falla parcial de una acción derivada (stock/despacho) se oculta; siempre queda registrada en auditoría.
- **Aislamiento (RNF-07):** F2 no modifica directamente las tablas de pedido; toda transición pasa por F1.

## 9. Fuera de alcance

- **Devolución de un pedido ya despachado:** corresponde a F3.
- **Ejecución contable del extorno en pasarela:** corresponde a F4; F2 solo origina la solicitud.
- **Reasignación de repartidor o reprogramación de despacho:** corresponde al módulo externo Despacho y Entrega (E).

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 y CA-01b | Anular directamente desde `CREADO` (por cliente o por canal con `PAGO_NO_COMPLETADO`) y desde `PAGADO`. | Unitaria e integración | Transición aplicada de inmediato sin crear tareas pendientes de aprobación ni solicitud a F4 en pedidos `CREADO`. |
| CA-02 y CA-03 | Intentar anular sobre `DESPACHADO`/`ENTREGADO`, o enviar solicitud sin motivo. | Unitaria e integración | Códigos de error `409 Conflict` y `400 Bad Request` respectivamente. |
| CA-04 y CA-05 | Simular aprobación y rechazo del Gestor en un pedido `EN PREPARACIÓN`. | Integración | Transición aplicada solo si se aprueba; estado conservado si se rechaza. |
| CA-06 y CA-07 | Anular un pedido con despacho programado y con pago confirmado, incluyendo un reintento. | Integración | Stock repuesto, despacho cancelado, una sola solicitud de reembolso generada hacia F4. |
| CA-08 | Simular una falla de Despacho (E) durante la anulación. | Integración | Inconsistencia registrada y visible para el Gestor. |

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-08` (incluyendo `CA-01b`) están implementados y cuentan con pruebas automatizadas exitosas.
- Ninguna anulación puede ejecutarse sobre un pedido `DESPACHADO` o `ENTREGADO`.
- Toda anulación en `EN PREPARACIÓN` sin autorización explícita del Gestor queda bloqueada.
- Las anulaciones en `CREADO` por el Canal con motivo `PAGO_NO_COMPLETADO` se ejecutan sin intervención humana.
- Los reintentos no duplican reembolsos ni historial.
- Las fallas parciales de stock/despacho quedan siempre visibles, nunca ocultas.
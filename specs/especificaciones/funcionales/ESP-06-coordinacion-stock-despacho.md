# ESP-06: Coordinación con stock/despacho

**Responsable:** Luis Arroyo
**Funcionalidad:** F2 — Anulación de pedidos
**Estado:** En especificación
**Actor principal:** Sistema (orquestador de F2), Productos (F), Despacho (E), F4 — Reembolsos
**Microservicio:** M1 — Pedidos
**Lineamiento del curso:** "Anulación de pedidos según reglas de negocio (con autorización)" (Módulo D — Ventas y Postventa)

## 1. Contexto

ESP-06 cubre la segunda mitad de F2: **una vez que ESP-05 confirma una anulación** (directa o autorizada por el Gestor), este documento especifica cómo se orquestan los efectos secundarios derivados: reposición de stock, cancelación de despacho y el origen —o no— de una solicitud de reembolso hacia F4, todo de forma idempotente.

## 2. Propósito

Coordinar de manera confiable e idempotente las acciones que dependen de otros módulos ante una anulación confirmada, asegurando que ningún reintento duplique efectos y que ninguna falla parcial quede oculta.

## 3. Alcance

Incluye:

- Solicitud de reposición de stock hacia Productos y Ofertas (F).
- Solicitud de cancelación de envío hacia Despacho y Entrega (E), cuando ya existía un despacho programado.
- Origen de la solicitud de reembolso hacia F4, **únicamente cuando el pedido tenía pago confirmado** (`PAGADO` o `EN PREPARACIÓN` con pago ya registrado).
- Registro visible de inconsistencias cuando un servicio externo (F o E) falla al responder.

**No incluye:** la validación de motivo ni la decisión de autorización (eso es ESP-05); la ejecución contable del reembolso en sí (F4); la reasignación de repartidor o reprogramación logística (E).

### 3.1. Reglas de efectos secundarios por origen de la anulación

| Anulación confirmada desde | Reposición de stock | Cancelación de despacho | Solicitud a F4 |
|---|---|---|---|
| `CREADO` (canal, `PAGO_NO_COMPLETADO`) | Sí, inmediata | No aplica (nunca se despachó) | **No** (nunca se cobró) |
| `CREADO` (cliente) | Sí, inmediata | No aplica | **No** (nunca se cobró) |
| `PAGADO` | Sí | No aplica (aún no se programó despacho) | **Sí**, exactamente una solicitud |
| `EN PREPARACIÓN` (aprobada por Gestor) | Sí | Sí, si ya había despacho programado | **Sí**, exactamente una solicitud |

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- ESP-05 ya confirmó la anulación (directa o aprobada por el Gestor) y el pedido transicionó a `ANULADO` en F1.
- Se conoce el estado de pago del pedido al momento de la anulación (para decidir si corresponde invocar a F4).

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| ESP-05 | Entrega la anulación ya confirmada (motivo, actor, estado origen) como disparador de este flujo. |
| Productos y Ofertas (F) | Repone el stock liberado de los ítems del pedido anulado. |
| Despacho y Entrega (E) | Cancela el envío si ya estaba programado. |
| F4 — Reembolsos y extornos | Recibe el origen de la solicitud de reembolso cuando el pedido tenía pago confirmado; ESP-06 nunca ejecuta el extorno directamente. |

### 4.3. Resultados

- Se genera la solicitud de reposición de stock hacia F y, si aplica, la de cancelación de despacho hacia E.
- Si el pedido tenía pago confirmado, se origina exactamente una solicitud hacia F4 (idempotente). Si el pedido estaba en `CREADO`, no se genera solicitud a F4 bajo ninguna circunstancia.
- Cualquier falla de F o E durante la coordinación queda registrada como inconsistencia visible, nunca oculta ni revertida silenciosamente.

## 5. Requisitos y criterios de aceptación

### RF-01. Reposición de stock y cancelación de despacho

El sistema DEBE coordinar la reposición de stock y, cuando corresponda, la cancelación de despacho ante toda anulación confirmada.

#### CA-01. Reposición de stock y cancelación de despacho programado

- **DADO** un pedido anulado que ya tenía una solicitud de despacho programada.
- **CUANDO** se confirma la anulación.
- **ENTONCES** el sistema solicita a Productos (F) la reposición del stock y a Despacho (E) la cancelación del envío.

#### CA-02. Reposición inmediata de stock por PAGO_NO_COMPLETADO

- **DADO** un pedido en `CREADO` anulado por el canal con motivo `PAGO_NO_COMPLETADO`.
- **CUANDO** se confirma la anulación.
- **ENTONCES** el sistema libera de inmediato el stock reservado en Productos (F), sin invocar a Despacho (E), ya que el pedido nunca llegó a programarse para envío.

### RF-02. Origen del reembolso sin duplicar

El sistema DEBE originar exactamente una solicitud de reembolso hacia F4 cuando el pedido anulado tenía pago confirmado, y ninguna cuando no lo tenía.

#### CA-03. Origen de reembolso para pedido PAGADO

- **DADO** un pedido `PAGADO` que se anula.
- **CUANDO** se ejecuta la anulación.
- **ENTONCES** el sistema origina exactamente una solicitud hacia F4; un reintento de la misma anulación no genera una segunda solicitud de reembolso.

#### CA-04. Sin solicitud de reembolso para pedido nunca cobrado

- **DADO** un pedido en `CREADO` anulado por `PAGO_NO_COMPLETADO` (o cualquier otro motivo, mientras nunca se haya confirmado el pago).
- **CUANDO** se confirma la anulación.
- **ENTONCES** el sistema **no genera ninguna solicitud hacia F4**, porque no existe dinero cobrado que extornar.

### RF-03. Visibilidad ante fallas parciales

El sistema DEBE registrar de forma visible cualquier falla de un servicio externo durante la coordinación, sin ocultarla ni revertir la anulación ya confirmada.

#### CA-05. Falla parcial visible

- **DADO** que la anulación se ejecutó pero la cancelación de despacho falló (por ejemplo, E no respondió).
- **CUANDO** ocurre la falla.
- **ENTONCES** el sistema registra la inconsistencia de forma visible para el Gestor, con evidencia suficiente para reintento manual o automático — nunca la oculta como si todo hubiese salido bien.

## 6. Frontend

| Elemento | Responsabilidad |
|---|---|
| Detalle de la anulación | Muestra el estado de cada efecto derivado: reposición de stock, cancelación de despacho y solicitud de reembolso (si aplica). |
| Alertas de inconsistencia | Resalta visualmente cuando una acción derivada (F o E) falló y necesita reintento. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Orquestador de efectos secundarios | Solicita reposición de stock (F), cancelación de despacho (E, si aplica) y origina la solicitud a F4 solo si el pedido fue pagado. |
| Motor de idempotencia | Garantiza que reintentos de la misma anulación no dupliquen la solicitud de reembolso ni las llamadas a F/E. |
| Registro de inconsistencias | Persiste y expone al Gestor las fallas de servicios externos ocurridas durante la coordinación. |

## 8. Requisitos no funcionales relacionados

- **Idempotencia (RNF-08):** un reintento de la misma anulación no debe generar una segunda solicitud de reembolso hacia F4 ni duplicar llamadas a F/E.
- **Disponibilidad (RNF-05):** ante fallas de F o E, el sistema no pierde la operación; la encola o deja evidencia clara para reintento.
- **Trazabilidad (RNF-03):** cada efecto derivado (stock, despacho, reembolso) queda registrado con su resultado y timestamp.

## 9. Fuera de alcance

- Validación de motivo y decisión de autorización del Gestor (ESP-05).
- Ejecución contable del extorno en pasarela (F4).
- Reasignación de repartidor o reprogramación de despacho (módulo externo Despacho y Entrega, E).

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 y CA-02 | Anular un pedido con despacho programado, y un pedido `CREADO` por `PAGO_NO_COMPLETADO`. | Integración | Stock repuesto en ambos casos; despacho cancelado solo cuando existía. |
| CA-03 y CA-04 | Anular un pedido `PAGADO` (incluyendo reintento) y un pedido `CREADO` sin pago. | Integración | Una sola solicitud de reembolso en el primer caso; ninguna en el segundo. |
| CA-05 | Simular una falla de Despacho (E) durante la coordinación. | Integración | Inconsistencia registrada y visible para el Gestor. |

## 11. Criterio de completitud

ESP-06 se considera completo cuando:

- Los criterios `CA-01` a `CA-05` están implementados y cuentan con pruebas automatizadas exitosas.
- Ningún pedido anulado sin pago confirmado genera solicitud de reembolso hacia F4.
- Los reintentos no duplican reembolsos, reposiciones de stock ni cancelaciones de despacho.
- Las fallas parciales de stock/despacho quedan siempre visibles, nunca ocultas.

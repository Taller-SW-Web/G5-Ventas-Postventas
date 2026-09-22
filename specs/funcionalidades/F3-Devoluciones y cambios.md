# Especificación F3: Devoluciones y cambios

**Responsable:** Joseph
**Estado:** En especificación
**Actor principal:** Cliente (inicia) y Gestor (evalúa)
**Microservicio:** M2 — Postventa
**Lineamiento del curso:** "Solicitud de devolución o cambio de productos" (Módulo D — Ventas y Postventa)

## 1. Contexto

F3 atiende lo que el cliente pide **después** de haber recibido el pedido: cambiarlo o devolverlo con reembolso. A diferencia de F1/F2 (que viven en M1), F3 vive en M2 — Postventa, y **nunca modifica directamente las tablas de pedido de M1**; solo puede solicitarle cambios a través de su API. Su resolución puede derivar en dos caminos distintos: coordinar un cambio logístico, o generar el origen de un reembolso hacia F4.

## 2. Propósito

Gestionar solicitudes posteriores a la entrega y resolverlas como cambio, devolución con reembolso o rechazo, conservando evidencia y trazabilidad completa del expediente.

## 3. Alcance

Incluye:
- Registro de la solicitud (`SOLICITADA`) asociada a un pedido entregado.
- Validación de elegibilidad: estado de entrega, motivo, plazo y evidencia.
- Evaluación por el Gestor (`EN EVALUACIÓN` → `APROBADA`/`RECHAZADA`).
- Coordinación de un cambio logístico (disponibilidad + nuevo despacho) o del origen de un reembolso hacia F4.

**No incluye:** la ejecución directa del extorno (eso es F4), ni la modificación directa del pedido en M1 (F3 solo se lo solicita a F1 por API).

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- El pedido debe estar en estado `ENTREGADO` (confirmado por F1/M1).
- La solicitud debe estar dentro del plazo de negocio definido por el proyecto.
- El motivo debe ser tipificado; si el motivo es "defecto", se exige evidencia (por ejemplo, fotos).

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| F1 — Ciclo de vida del pedido (M1) | Confirma que el pedido está `ENTREGADO`; F3 solo lee este dato, nunca lo modifica directamente. |
| Productos y Ofertas (F) | Confirma disponibilidad para un cambio y recibe aviso de reposición si aplica. |
| Despacho y Entrega (E) | Coordina la logística inversa (recojo) y el nuevo despacho cuando la resolución es un cambio. |
| F4 — Reembolsos y extornos | Recibe el origen de la solicitud cuando la resolución es devolución con dinero; F3 nunca ejecuta el extorno. |
| Gestor | Evalúa el expediente y decide `APROBADA`/`RECHAZADA`. |

### 4.3. Resultados

- Una solicitud válida queda registrada con estado `SOLICITADA` y trazabilidad completa.
- Una resolución `APROBADA` deriva en una coordinación de cambio logístico o en un origen de reembolso hacia F4 (nunca ambos a la vez).
- Una resolución `RECHAZADA` queda registrada con su fundamento.
- El expediente completo (estado, evidencia, resolución) es siempre consultable.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Registro y elegibilidad de la solicitud

El sistema DEBE registrar la solicitud solo si el pedido es elegible (entregado, dentro de plazo, con motivo y evidencia cuando corresponda).

#### CA-01. Registro exitoso

- **DADO** un pedido `ENTREGADO` dentro del plazo permitido.
- **CUANDO** el cliente registra una solicitud de devolución con motivo válido.
- **ENTONCES** el sistema crea el expediente en estado `SOLICITADA` y lo asocia al pedido.

#### CA-02. Rechazo por pedido no entregado

- **DADO** un pedido que aún no está `ENTREGADO`.
- **CUANDO** se intenta registrar una solicitud sobre él.
- **ENTONCES** el sistema rechaza la solicitud como no elegible (`409 Conflict`).

#### CA-03. Rechazo por evidencia faltante en motivo "defecto"

- **DADO** una solicitud con motivo "defecto" y sin evidencia adjunta.
- **CUANDO** se registra.
- **ENTONCES** el sistema la marca como pendiente de evidencia o la rechaza, según la política acordada por el equipo — en ningún caso la aprueba automáticamente sin evidencia.

### RF-02. Evaluación y resolución

El sistema DEBE permitir que el Gestor evalúe el expediente y lo resuelva como `APROBADA` o `RECHAZADA`, dejando fundamento.

#### CA-04. Transición a evaluación

- **DADO** una solicitud en estado `SOLICITADA`.
- **CUANDO** el Gestor la abre para revisión.
- **ENTONCES** el sistema la transiciona a `EN EVALUACIÓN`.

#### CA-05. Resolución aprobada

- **DADO** una solicitud `EN EVALUACIÓN`.
- **CUANDO** el Gestor la aprueba.
- **ENTONCES** el sistema la transiciona a `APROBADA` y determina el camino (cambio o devolución) según lo indicado.

#### CA-06. Resolución rechazada

- **DADO** una solicitud `EN EVALUACIÓN`.
- **CUANDO** el Gestor la rechaza.
- **ENTONCES** el sistema la transiciona a `RECHAZADA`, exigiendo un fundamento no vacío.

### RF-03. Derivación según tipo de resolución

El sistema DEBE derivar correctamente una resolución aprobada hacia un cambio logístico o hacia un origen de reembolso — nunca ambos a la vez sobre el mismo expediente.

#### CA-07. Derivación a cambio

- **DADO** una solicitud aprobada de tipo "cambio" con disponibilidad confirmada en Productos (F).
- **CUANDO** se ejecuta la resolución.
- **ENTONCES** el sistema coordina con Despacho (E) el nuevo envío y transiciona el expediente a `COMPLETADA` al finalizar.

#### CA-08. Derivación a devolución con reembolso

- **DADO** una solicitud aprobada de tipo "devolución con dinero".
- **CUANDO** se ejecuta la resolución.
- **ENTONCES** el sistema origina la solicitud hacia F4 y marca el expediente como `COMPLETADA` cuando F4 confirma el resultado.

#### CA-09. Sin stock para cambio

- **DADO** una solicitud aprobada de tipo "cambio" sin disponibilidad en Productos (F).
- **CUANDO** se intenta ejecutar.
- **ENTONCES** el sistema ofrece resolver como devolución/reembolso o rechazo, según la política definida por el equipo — nunca deja el expediente indefinidamente sin resolución.

## 6. Frontend

Superficie visible dentro del panel del Gestor (más un formulario simple accesible al cliente desde su canal):

| Elemento | Responsabilidad |
|---|---|
| Formulario de solicitud (cliente) | Captura motivo, tipo (cambio/devolución) y evidencia si aplica. |
| Bandeja de expedientes (Gestor) | Lista solicitudes por estado (`SOLICITADA`, `EN EVALUACIÓN`, etc.), con acceso al detalle. |
| Detalle del expediente | Motivo, evidencia, historial de decisiones y resultado de la derivación (cambio/reembolso). |
| Acciones de resolución | Aprobar/Rechazar, con campo de fundamento obligatorio al rechazar. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Validador de elegibilidad | Verifica entrega confirmada (vía F1), plazo, motivo y evidencia. |
| Motor de estados del expediente | Gestiona `SOLICITADA → EN EVALUACIÓN → APROBADA/RECHAZADA → COMPLETADA`. |
| Orquestador de derivación | Coordina con Productos (F) y Despacho (E) para un cambio, u origina la solicitud a F4 para un reembolso. |
| Cliente hacia F1 | Consulta el estado `ENTREGADO` del pedido — F3 nunca escribe directamente sobre las tablas de M1. |

## 8. Requisitos no funcionales

- **Aislamiento:** M2 no actualiza el estado del pedido directamente; toda verificación pasa por la API de F1.
- **Trazabilidad:** el motivo debe ser tipificado y la evidencia debe conservar una referencia verificable.
- **Consistencia de resolución:** cambio y devolución con reembolso son resoluciones mutuamente excluyentes y deben quedar explícitas en el expediente.
- **Auditabilidad:** todo rechazo exige un fundamento registrado, nunca queda sin justificación.

## 9. Fuera de alcance

- **Ejecución del extorno en sí:** corresponde a F4; F3 solo origina la solicitud.
- **Modificación directa del pedido en M1:** F3 solo consulta y solicita, nunca escribe.
- **Anulación antes de la entrega:** corresponde a F2.

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 a CA-03 | Registrar solicitudes elegibles, no elegibles y con evidencia faltante. | Unitaria e integración | Expediente creado o rechazado según corresponda. |
| CA-04 a CA-06 | Simular el flujo completo de evaluación (aprobar y rechazar). | Integración | Transiciones de estado correctas, fundamento exigido al rechazar. |
| CA-07 y CA-08 | Resolver un expediente como cambio y otro como devolución con reembolso. | Integración | Coordinación correcta con E/F o con F4 según el tipo. |
| CA-09 | Resolver un cambio sin stock disponible. | Integración | Expediente redirigido a devolución/rechazo, nunca indefinido. |

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-09` están implementados y cuentan con pruebas automatizadas exitosas.
- Ningún expediente puede registrarse sobre un pedido no entregado.
- Toda resolución rechazada tiene un fundamento registrado.
- Cambio y devolución con reembolso nunca se aplican simultáneamente sobre el mismo expediente.
- M2 nunca escribe directamente sobre las tablas de pedido de M1 en todo el flujo.
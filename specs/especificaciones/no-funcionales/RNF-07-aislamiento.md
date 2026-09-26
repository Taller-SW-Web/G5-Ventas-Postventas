# RNF-07 — Aislamiento

**Módulo:** D — Ventas y Postventa  
**Tipo:** Requisito no funcional  
**Ámbito:** M1 — Pedidos / M2 — Postventa  
**Estado:** En especificación  
**Responsable:** Johan Solano

---

## 1. Objetivo

Definir las reglas de aislamiento entre los componentes internos del Módulo D, evitando que una funcionalidad modifique directamente información que pertenece a otra responsabilidad

El objetivo principal es conservar límites claros entre M1 — Pedidos y M2 — Postventa, de manera que cada microservicio opere únicamente sobre los datos y procesos que le corresponden

En particular, M1 es el propietario exclusivo del estado y de las tablas del pedido. Las funcionalidades de postventa no deben escribir directamente sobre dichas tablas y cualquier cambio relacionado con el pedido debe solicitarse mediante las APIs o eventos definidos por el proyecto

---

## 2. Principio de aislamiento

El Módulo D se divide funcionalmente en:

- **M1 — Pedidos:** responsable del ciclo de vida del pedido y de sus transiciones de estado
- **M2 — Postventa:** responsable de devoluciones/cambios, reembolsos, calificaciones, reclamos y procesos posteriores a la venta

Esta separación implica que una funcionalidad puede consultar información de otra o solicitar una operación, pero no debe modificar directamente sus datos internos

El principio general es:

`Funcionalidad solicitante → API / evento definido → funcionalidad propietaria → persistencia`

Nunca:

`Funcionalidad solicitante → escritura directa en tablas ajenas`

---

## 3. Reglas de aislamiento

### RN-07.1 — Propiedad exclusiva del pedido

M1 es el único componente autorizado a crear, consultar y modificar directamente las tablas relacionadas con:

- Pedido
- Detalle del pedido
- Pago
- Historial de estados

M2 y las demás funcionalidades deben acceder a dicha información únicamente a través de los contratos definidos por M1

---

### RN-07.2 — Transiciones de estado centralizadas en F1

Toda modificación del estado de un pedido debe ser validada y aplicada por F1 — Ciclo de vida del pedido

Ninguna otra funcionalidad puede ejecutar una transición de estado escribiendo directamente sobre la persistencia

Por ejemplo:

- F2 puede decidir que una anulación procede, pero F1 aplica la transición real a `ANULADO`
- F3 puede verificar que un pedido se encuentre `ENTREGADO`, pero no puede cambiar ese estado directamente
- F5 puede reaccionar ante el evento de entrega, pero una calificación nunca modifica el estado del pedido

---

### RN-07.3 — Anulaciones a través de F1

F2 — Anulación de pedidos debe solicitar cualquier transición a `ANULADO` mediante la interfaz expuesta por F1

Cuando corresponda, la transición se realiza a través del endpoint:

`PATCH /api/v1/pedidos/{id}/estado`

F2 conserva su responsabilidad sobre la validación de la anulación, motivo, autorización y efectos secundarios, pero no modifica directamente las tablas del pedido

---

### RN-07.4 — Devoluciones y cambios sin escritura sobre M1

F3 — Devoluciones y cambios puede consultar a F1 para verificar que un pedido se encuentre en estado `ENTREGADO`

F3 administra su propio expediente de postventa y su propia máquina de estados:

`SOLICITADA → EN EVALUACIÓN → APROBADA / RECHAZADA → COMPLETADA`

Estos estados pertenecen al expediente de devolución/cambio y no sustituyen ni modifican directamente el estado del pedido gestionado por M1

---

### RN-07.5 — Reembolsos con origen controlado

F4 — Reembolsos y extornos no debe originar una devolución de dinero por iniciativa propia

Solo procesa solicitudes provenientes de:

- F2, cuando una anulación válida involucra un pedido con pago confirmado
- F3, cuando una devolución aprobada requiere reembolso

F4 mantiene la trazabilidad de la operación monetaria y notifica el resultado al flujo de origen, sin apropiarse de la lógica de anulación o devolución

---

### RN-07.6 — Calificaciones independientes del pedido

F5 — Calificación de experiencia se activa a partir del evento de pedido entregado publicado por F1

La calificación:

- No modifica el estado del pedido
- No ejecuta transiciones en M1
- No crea automáticamente reclamos
- Solo registra la respuesta del cliente y actualiza el agregado CSAT

---

### RN-07.7 — Reclamos y dashboard desacoplados de la base transaccional

F6 — Reclamos, dashboard y reportes debe consumir eventos de M1 y M2 para mantener sus agregados

El dashboard no debe recalcular sus indicadores recorriendo directamente toda la base transaccional del pedido en cada consulta

F6 administra sus propios reclamos, SLA, respuestas y agregados, manteniendo la separación con el ciclo de vida del pedido

---

## 4. Dependencias permitidas

| Funcionalidad             | Dependencia  | Forma permitida de interacción                     |
| ------------------------- | ------------ | -------------------------------------------------- |
| F2 — Anulaciones          | F1 — Pedidos | Solicitud de transición mediante API               |
| F3 — Devoluciones/cambios | F1 — Pedidos | Consulta de estado y referencias mediante API      |
| F4 — Reembolsos           | F2 / F3      | Recepción de un origen previamente validado        |
| F5 — Calificaciones       | F1 — Pedidos | Consumo del evento de pedido entregado             |
| F6 — Reclamos/reportes    | F1 / M2      | Consumo de eventos para actualización de agregados |

---

## 5. Escenarios y criterios de aceptación

### CA-01 — F2 no modifica directamente el pedido

**DADO** una solicitud de anulación válida  
**CUANDO** F2 determina que el pedido debe pasar a `ANULADO`  
**ENTONCES** la transición debe ser solicitada a F1 mediante su contrato  
**Y** F2 no debe escribir directamente sobre las tablas de pedido

---

### CA-02 — F3 consulta sin modificar M1

**DADO** una solicitud de devolución o cambio  
**CUANDO** F3 necesita comprobar que el pedido está `ENTREGADO`  
**ENTONCES** debe consultar dicha información mediante F1  
**Y** no debe modificar el estado del pedido directamente

---

### CA-03 — Estados de devolución separados de estados de pedido

**DADO** un expediente de devolución en estado `EN EVALUACIÓN`  
**CUANDO** el Gestor lo aprueba o rechaza  
**ENTONCES** cambia únicamente el estado del expediente de F3  
**Y** el estado del pedido en M1 permanece bajo control de F1

---

### CA-04 — F4 requiere origen válido

**DADO** una solicitud de reembolso  
**CUANDO** no proviene de F2 ni F3 con un origen válido  
**ENTONCES** F4 debe rechazarla  
**Y** no debe ejecutar ninguna operación monetaria

---

### CA-05 — F5 no altera el ciclo de vida del pedido

**DADO** un pedido `ENTREGADO` que recibe una calificación  
**CUANDO** F5 registra la respuesta y actualiza CSAT  
**ENTONCES** el pedido conserva su estado  
**Y** F5 no realiza ninguna escritura sobre M1

---

### CA-06 — F6 trabaja sobre agregados

**DADO** que F6 recibe eventos de M1 o M2  
**CUANDO** actualiza los indicadores del dashboard  
**ENTONCES** utiliza sus agregados correspondientes  
**Y** no depende de modificar ni recorrer directamente las tablas internas del pedido para cada consulta

---

## 6. Impacto en frontend

El aislamiento también debe reflejarse en la interfaz

El frontend puede mostrar información proveniente de varias funcionalidades, pero:

- No debe asumir que una acción visual equivale a una escritura directa
- Cada operación debe enviarse al endpoint correspondiente
- Las acciones disponibles deben respetar el estado y la responsabilidad de cada funcionalidad
- Una pantalla de Postventa puede mostrar datos del pedido, pero no debe permitir editar directamente campos cuya propiedad pertenece a M1
- Los errores de integración deben presentarse de forma visible y no ocultarse como si la operación hubiera sido exitosa

Ejemplo:

`W05 Devoluciones y cambios → consulta pedido en F1 → resuelve expediente en F3 → si corresponde, deriva a F4`

Cada paso mantiene su propia responsabilidad

---

## 7. Beneficios esperados

El cumplimiento de RNF-07 permite:

- Evitar inconsistencias entre pedidos y procesos de postventa
- Reducir el acoplamiento entre funcionalidades
- Mantener una única fuente de verdad para el estado del pedido
- Facilitar la trazabilidad de las operaciones
- Evitar que cambios internos de una funcionalidad afecten directamente a otra
- Mejorar la mantenibilidad y prueba independiente de los componentes

---

## 8. Casos que incumplen RNF-07

Se considera incumplimiento de aislamiento cuando:

- M2 actualiza directamente el estado de un pedido en las tablas de M1
- F3 modifica directamente un pedido al aprobar una devolución
- F4 ejecuta un reembolso sin origen válido de F2/F3
- F5 cambia el estado del pedido después de una calificación
- F6 depende de modificar datos transaccionales del pedido para generar sus reportes
- Una funcionalidad accede a tablas internas de otra evitando los contratos establecidos

---

## 9. Estrategia de verificación

Para validar RNF-07 se deben realizar pruebas de integración que comprueben:

- Que las transiciones de pedido siempre pasan por F1
- Que F2 y F3 no escriben directamente sobre las tablas de pedido
- Que F4 rechaza operaciones sin origen válido
- Que F5 no modifica el estado del pedido
- Que F6 puede actualizar sus agregados mediante eventos sin modificar la base de M1
- Que una falla en una dependencia se maneja sin alterar directamente información que pertenece a otro componente

La evidencia puede incluir registros de llamadas API, eventos procesados, historial de estados y pruebas automatizadas sobre los límites de cada funcionalidad

---

## 10. Criterio de completitud

RNF-07 se considera satisfecho cuando M1 conserva la propiedad exclusiva sobre el ciclo de vida y persistencia del pedido, M2 opera sus procesos de postventa sin realizar escrituras directas sobre las tablas de M1 y todas las interacciones entre funcionalidades se realizan mediante los contratos, eventos y responsabilidades definidos por el proyecto

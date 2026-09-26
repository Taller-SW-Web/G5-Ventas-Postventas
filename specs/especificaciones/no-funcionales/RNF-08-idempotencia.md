# RNF-08 — Idempotencia

**Módulo:** D — Ventas y Postventa  
**Tipo:** Requisito no funcional  
**Ámbito principal:** F1 — Ciclo de vida del pedido, F2 — Anulaciones y F4 — Reembolsos  
**Estado:** En especificación  
**Responsable:** Johan Solano

---

## 1. Objetivo

Definir las condiciones de idempotencia que deben cumplirse dentro del Módulo D para evitar que una misma operación lógica produzca efectos duplicados cuando una solicitud, evento o reintento es procesado más de una vez

La idempotencia es especialmente importante en operaciones que afectan el ciclo de vida del pedido, generan solicitudes de reembolso o ejecutan movimientos monetarios

El principio general es:

`Misma operación lógica + misma referencia de control → mismo resultado, sin duplicar efectos`

---

## 2. Contexto funcional

El Módulo D interactúa con canales, pasarelas, servicios externos y funcionalidades internas. En varios puntos del flujo pueden ocurrir reintentos por errores de red, demoras, respuestas tardías o reenvío de eventos

Estos reintentos no deben generar:

- Dos transiciones iguales sobre un mismo pedido
- Entradas duplicadas en el historial
- Dos solicitudes de reembolso para la misma anulación
- Dos extornos para una misma operación monetaria
- Efectos secundarios repetidos sobre stock o despacho cuando la operación ya fue procesada

RNF-08 busca que el sistema pueda recibir nuevamente una operación ya tratada y responder de manera consistente sin repetir el efecto de negocio

---

## 3. Principios de idempotencia

### RN-08.1 — Reintentos de eventos de pedido

Los eventos externos o internos relacionados con el ciclo de vida del pedido deben poder reintentarse sin duplicar la transición ni el historial

Por ejemplo, si el evento `pedido entregado` ya fue procesado, un segundo envío del mismo evento no debe generar otra transición a `ENTREGADO` ni registrar una segunda entrada equivalente en el historial

---

### RN-08.2 — Anulación sin duplicar efectos

Cuando una anulación ya fue procesada correctamente, un reintento de la misma operación no debe:

- Registrar nuevamente la transición a `ANULADO`
- Duplicar el historial
- Generar una segunda solicitud de reembolso hacia F4
- Repetir innecesariamente efectos que ya fueron completados

La operación debe reconocer que la anulación ya fue procesada y conservar un único resultado lógico

---

### RN-08.3 — Solicitud única hacia F4

F2 debe generar exactamente una solicitud de reembolso cuando una anulación válida corresponde a un pedido con pago confirmado

Si la misma anulación es reenviada o reintentada, no debe originarse una segunda solicitud monetaria

---

### RN-08.4 — Clave idempotente en reembolsos

F4 debe utilizar una clave idempotente única por operación de reembolso

Si una operación ya fue ejecutada exitosamente y se recibe nuevamente la misma clave, F4 debe devolver o reutilizar el resultado ya existente sin ejecutar un segundo movimiento de dinero

La misma clave representa la misma operación lógica

---

### RN-08.5 — Reintento seguro después de error

Cuando un reembolso queda `FALLIDO` o `PENDIENTE`, el sistema puede permitir un reintento utilizando la misma clave idempotente

El reintento debe preservar la trazabilidad de la operación y garantizar que, si la pasarela ya había procesado el extorno, no se genere un segundo movimiento monetario

---

### RN-08.6 — Persistencia y trazabilidad

Toda operación idempotente debe dejar evidencia suficiente para reconocer si ya fue procesada

Según el flujo, esta evidencia puede incluir:

- Identificador del pedido
- Identificador del evento
- Identificador de la anulación
- Clave idempotente del reembolso
- Estado final registrado
- Referencia de la transacción
- Timestamp e historial de intentos

El mecanismo exacto de persistencia debe mantenerse alineado con `specs/api-contract.md` y con el modelo de datos definido por el equipo

---

## 4. Casos principales dentro del módulo

| Funcionalidad        | Operación sensible                          | Comportamiento idempotente esperado                     |
| -------------------- | ------------------------------------------- | ------------------------------------------------------- |
| **F1 — Pedidos**     | Procesamiento repetido de eventos de estado | No duplicar transición ni historial                     |
| **F2 — Anulaciones** | Reintento de una misma anulación            | No duplicar historial ni solicitud hacia F4             |
| **F4 — Reembolsos**  | Reenvío de una misma operación monetaria    | No ejecutar un segundo extorno                          |
| **F4 — Reintento**   | Nueva ejecución con la misma clave          | Reutilizar o continuar la operación sin duplicar dinero |

---

## 5. Escenarios y criterios de aceptación

### CA-01 — Reintento de evento de entrega

**DADO** que el evento `pedido entregado` ya fue procesado para un pedido  
**CUANDO** el mismo evento se recibe nuevamente  
**ENTONCES** el sistema no debe duplicar la transición a `ENTREGADO`  
**Y** no debe registrar una segunda entrada equivalente en el historial

---

### CA-02 — Reintento de anulación

**DADO** un pedido cuya anulación ya fue procesada correctamente  
**CUANDO** se reintenta la misma anulación  
**ENTONCES** el sistema debe conservar el pedido en `ANULADO`  
**Y** no debe duplicar la transición ni el historial

---

### CA-03 — Reembolso originado una sola vez

**DADO** un pedido pagado cuya anulación requiere reembolso  
**CUANDO** F2 procesa la anulación por primera vez  
**ENTONCES** genera una única solicitud hacia F4

**Y DADO** que la misma anulación se reintenta  
**CUANDO** F2 vuelve a procesar la solicitud  
**ENTONCES** no debe generar una segunda solicitud de reembolso

---

### CA-04 — Reintento con clave idempotente ya exitosa

**DADO** un reembolso ejecutado exitosamente con una clave idempotente determinada  
**CUANDO** F4 recibe nuevamente una solicitud con la misma clave  
**ENTONCES** debe retornar el resultado existente  
**Y** no debe ejecutar un segundo movimiento de dinero

---

### CA-05 — Reintento seguro después de error

**DADO** un reembolso registrado como `FALLIDO` o `PENDIENTE`  
**CUANDO** el Gestor o el sistema realiza un reintento permitido con la misma clave idempotente  
**ENTONCES** la operación debe conservar la trazabilidad  
**Y** no debe generar un segundo extorno si el movimiento original ya había sido procesado

---

### CA-06 — Historial sin duplicados

**DADO** una operación que es recibida más de una vez por un reintento de red  
**CUANDO** el sistema reconoce que la operación lógica ya fue tratada  
**ENTONCES** mantiene una sola transición de negocio válida  
**Y** evita duplicar entradas equivalentes en el historial principal

---

## 6. Relación con F1 — Ciclo de vida del pedido

F1 debe garantizar que eventos provenientes de servicios externos, como entrega o confirmación de pago, puedan ser reenviados sin provocar transiciones repetidas

La máquina de estados continúa siendo la fuente de validación del ciclo de vida del pedido

La idempotencia no permite saltarse estados ni aceptar transiciones inválidas; únicamente evita repetir una operación ya procesada

---

## 7. Relación con F2 — Anulación de pedidos

F2 debe asegurar que una anulación repetida no produzca efectos secundarios duplicados

En especial:

- No debe generarse una segunda solicitud de reembolso
- No debe duplicarse el historial
- No debe presentarse al Gestor una segunda operación como si fuera un caso nuevo cuando corresponde al mismo origen lógico

Cuando una acción derivada haya fallado, el reintento debe realizarse sobre esa acción pendiente y no crear una nueva anulación independiente

---

## 8. Relación con F4 — Reembolsos y extornos

F4 es el punto de mayor criticidad para RNF-08 porque procesa movimientos de dinero

Toda operación de reembolso debe contar con un identificador o clave idempotente que permita reconocerla

Los estados principales de la operación deben mantenerse trazables:

- `PENDIENTE`
- `FALLIDO`
- `EXITOSO`

Una operación `EXITOSA` con una clave ya procesada no puede volver a ejecutarse

Un reintento después de error debe reutilizar la misma referencia de control y conservar el historial de intentos

---

## 9. Impacto en frontend

El frontend debe ayudar a reducir reintentos accidentales, aunque la garantía definitiva de idempotencia pertenece al backend

La interfaz debe:

- Deshabilitar temporalmente botones mientras una acción está en `loading`
- Evitar dobles clics sobre operaciones críticas
- Mostrar el resultado de una operación ya procesada cuando el backend lo indique
- No presentar como nueva una operación que corresponde a un reintento del mismo origen
- En F4, enviar la cabecera o clave idempotente definida por el contrato cuando corresponda
- Mostrar estados claros para operaciones `PENDIENTE`, `FALLIDO` o `EXITOSO`

El frontend no debe generar una nueva clave para cada reintento de la misma operación lógica si el contrato exige conservar la clave original

---

## 10. Casos que incumplen RNF-08

Se considera incumplimiento de idempotencia cuando:

- El mismo evento de entrega genera dos transiciones a `ENTREGADO`
- Un reintento de anulación registra dos veces el mismo cambio en el historial
- Una misma anulación genera dos solicitudes hacia F4
- Una misma clave idempotente produce dos extornos
- Un doble clic en frontend provoca dos operaciones monetarias efectivas
- Un reintento crea una operación nueva en lugar de reutilizar la referencia de la operación original

---

## 11. Estrategia de verificación

Para validar RNF-08 se deben realizar pruebas que incluyan:

- Reenvío del mismo evento de estado hacia F1
- Reintento de la misma anulación en F2
- Reenvío de la misma solicitud de reembolso hacia F4
- Reutilización de la misma clave idempotente después de una operación `EXITOSA`
- Reintento con la misma clave después de un estado `FALLIDO` o `PENDIENTE`
- Simulación de doble clic o repetición de la solicitud desde frontend
- Verificación de que el historial y las solicitudes derivadas no presentan duplicados

La evidencia esperada debe mostrar un único efecto de negocio para cada operación lógica aunque existan múltiples intentos técnicos

---

## 12. Criterio de completitud

RNF-08 se considera satisfecho cuando los reintentos de eventos, anulaciones y reembolsos pueden procesarse de manera segura sin duplicar transiciones, historial, solicitudes derivadas ni movimientos de dinero; y cuando las operaciones monetarias utilizan una referencia idempotente que permite reconocer y reutilizar el resultado de una operación ya procesada

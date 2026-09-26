# ESP-10 — Auditoría de la transacción de reembolso

**Funcionalidad:** F4 — Reembolsos y extornos  
**Microservicio:** M2 — Postventa  
**Responsable:** Luis Alejandro  
**Tipo:** Especificación funcional

## 1. Propósito

Definir la evidencia inmutable que F4 conserva para reconstruir una solicitud de reembolso, sus intentos ante el simulador de pasarela y el resultado asociado al origen F2 o F3.

## 2. Alcance

Esta especificación cubre el registro y consulta del estado e historial de reembolsos. La consulta queda restringida a usuarios autorizados. F4 conserva la auditoría en M2 y no escribe directamente en la base de datos de M1.

La retención de auditoría se establece **según plazo legal aplicable**. Este documento no fija una duración numérica.

## 3. Información de auditoría

Cada registro de reembolso y sus intentos debe permitir identificar, como mínimo:

| Campo | Contenido requerido |
|---|---|
| Identificador de reembolso | Identificador que relaciona la solicitud con sus intentos y resultados. |
| Identificador de transacción | Identificador asociado a la transacción del simulador cuando se genera. |
| Origen | `ANULACION` de F2 o `DEVOLUCION` de F3. |
| Referencia | Referencia de la operación de origen y del pago original. |
| Monto | Monto solicitado y resultado monetario registrado para el intento. |
| Moneda | Moneda del pago y del reembolso. |
| Actor/autorizador | Actor emisor y autorizador cuando corresponda. |
| Fecha y hora UTC | Momento de registro de la solicitud y de cada intento o resultado. |
| Estado | `PENDIENTE`, `EXITOSO` o `FALLIDO`. |
| Clave de idempotencia | Valor recibido en `X-Idempotency-Key`. |
| Número de intento | Orden del intento dentro del mismo reembolso. |
| Resultado | Resultado del simulador o detalle del fallo/timeout conocido. |

Cuando un dato de resultado aún no se conoce, el registro debe indicar el estado pendiente y conservar la evidencia disponible; al conocerse el resultado, se añade evidencia sin eliminar el intento anterior.

## 4. Inmutabilidad y retención

- Los registros y resultados ya emitidos no se editan ni eliminan.
- Cada reintento agrega su evidencia al historial del mismo reembolso; no reemplaza los intentos previos.
- Una corrección o resolución posterior se registra como un nuevo evento vinculado al reembolso, preservando la secuencia anterior.
- La evidencia de auditoría se conserva **según plazo legal aplicable**. Esta especificación no presume una duración concreta.

## 5. Consulta autorizada

- La consulta del estado actual y del historial de intentos está permitida únicamente a usuarios autorizados.
- La autorización se verifica mediante las reglas de identidad y permisos vigentes del sistema antes de mostrar cualquier dato.
- Una consulta autorizada presenta el identificador de reembolso, el origen, el estado vigente y la secuencia de intentos y resultados disponibles.
- Una consulta no autorizada no revela el estado, las referencias ni los datos de auditoría del reembolso.

## 6. Escenarios de aceptación

### ESP-10-CA-01 — Registro completo

**Dado** una solicitud o intento de reembolso  
**Cuando** F4 registra su actividad  
**Entonces** la evidencia contiene los campos de la sección 3, incluidos origen, referencia, monto, moneda, `X-Idempotency-Key`, número de intento, estado, fecha UTC y resultado disponible.

### ESP-10-CA-02 — Historial inmutable

**Dado** un reembolso con un intento ya registrado  
**Cuando** se produce un nuevo intento o se resuelve un resultado pendiente  
**Entonces** F4 agrega la nueva evidencia y mantiene intacto el intento anterior.

### ESP-10-CA-03 — Consulta autorizada

**Dado** un usuario con autorización para consultar reembolsos  
**Cuando** consulta un identificador de reembolso  
**Entonces** puede revisar su estado e historial disponibles.

### ESP-10-CA-04 — Consulta no autorizada

**Dado** un usuario sin autorización para consultar reembolsos  
**Cuando** solicita el estado o historial  
**Entonces** F4 no revela información del reembolso.

### ESP-10-CA-05 — Retención legal

**Dado** un registro de auditoría de F4  
**Cuando** se define o verifica su conservación  
**Entonces** se aplica el plazo legal aplicable sin introducir una duración no aprobada.

## 7. Límites de dominio

F4 conserva la auditoría en M2. La referencia a pedidos o pagos de M1 es lógica y se obtiene por el límite intermodular autorizado; no se crean escrituras ni relaciones físicas directas con la base de datos de M1.

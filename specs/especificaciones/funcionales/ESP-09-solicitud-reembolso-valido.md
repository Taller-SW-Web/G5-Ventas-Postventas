# ESP-09 — Solicitud de reembolso válido

**Funcionalidad:** F4 — Reembolsos y extornos  
**Microservicio:** M2 — Postventa  
**Responsable:** Luis Alejandro  
**Tipo:** Especificación funcional

## 1. Propósito

Definir cuándo F4 acepta, valida y procesa una solicitud de reembolso originada por una anulación aprobada por F2 o una devolución aprobada por F3. F4 ejecuta el extorno mediante el simulador de pasarela; no decide si el flujo de origen procede.

## 2. Alcance

Incluye la validación del origen y del pago original, reembolsos totales o parciales, idempotencia, control del saldo reembolsable, estados de procesamiento, resultados del simulador y notificación de éxito al flujo originador.

No incluye la decisión de aprobar una anulación o devolución, la ejecución de pagos en una pasarela real ni escrituras directas en la base de datos de M1.

## 3. Actores y orígenes válidos

| Emisor | Origen admitido | Condición para solicitar el extorno |
|---|---|---|
| F2 — Anulación de pedidos (M1) | `ANULACION` | La anulación fue aprobada y el pedido tiene un pago confirmado. |
| F3 — Devoluciones y cambios (M2) | `DEVOLUCION` | La devolución fue aprobada y su resolución contempla un reembolso monetario. |

`DESPACHO_FALLIDO` no es un origen directo de F4. Ante una entrega fallida, el Módulo E notifica a F2; F2 tramita la anulación y, si corresponde un reembolso de un pedido pagado, solicita a F4 el extorno con origen `ANULACION`.

F2 y F3 son responsables de decidir y aprobar sus respectivos flujos. F4 valida el origen que recibe y ejecuta la operación monetaria, sin reemplazar esas decisiones.

## 4. Precondiciones

- La solicitud proviene de F2 con origen `ANULACION` o de F3 con origen `DEVOLUCION`.
- Existe un pago original confirmado y una referencia que permite relacionar la solicitud con dicho pago.
- La moneda solicitada coincide con la moneda del pago original.
- El monto solicitado es positivo y el saldo reembolsable disponible permite cubrirlo.
- La solicitud incluye la cabecera HTTP `X-Idempotency-Key`.
- El actor y el autorizador, cuando corresponda, están identificados para fines de auditoría.

## 5. Reglas funcionales

### ESP-09-RF-01 — Validación de origen

F4 acepta únicamente `ANULACION` de F2 y `DEVOLUCION` de F3. Debe rechazar cualquier otro origen antes de solicitar un extorno al simulador. En particular, debe rechazar `DESPACHO_FALLIDO` como origen directo.

### ESP-09-RF-02 — Validación del pago, monto y moneda

F4 valida que el pago original esté confirmado y que la referencia y moneda correspondan a ese pago. Admite reembolsos totales o parciales cuando el flujo de origen aprobado define el monto. El monto solicitado y el saldo reembolsable acumulado no pueden exceder el importe pagado originalmente.

### ESP-09-RF-03 — Saldo acumulado y concurrencia

Antes de ejecutar una solicitud, F4 valida el monto solicitado junto con los montos de extornos exitosos y los montos pendientes o reservados asociados al pago original. La suma no debe superar el pago original.

F4 aplica un control o reserva atómica de los montos pendientes antes de invocar la pasarela. Si dos o más solicitudes concurrentes compiten por el mismo saldo, solo pueden avanzar los montos que permanezcan dentro del saldo reembolsable; cualquier exceso se rechaza antes de invocar el simulador.

### ESP-09-RF-04 — Idempotencia

Toda solicitud incluye `X-Idempotency-Key`. La clave identifica una operación de reembolso en F4 y se vincula con sus datos de solicitud.

- Si se repite la misma clave para la misma operación, F4 devuelve el resultado previamente registrado de la primera solicitud y no ejecuta un segundo extorno.
- Si una clave ya registrada se presenta con datos de operación diferentes, F4 rechaza la solicitud y conserva sin cambios el registro original.
- La recuperación de una operación pendiente o fallida continúa dentro del mismo expediente, conserva la clave y agrega evidencia del intento; no crea una segunda operación de reembolso.

### ESP-09-RF-05 — Estado y resultado del simulador

F4 registra cada solicitud y utiliza únicamente los siguientes estados:

| Estado | Significado |
|---|---|
| `PENDIENTE` | La operación está en curso o no se ha confirmado el resultado externo, por ejemplo, tras un timeout. |
| `EXITOSO` | El simulador confirmó el extorno. |
| `FALLIDO` | El simulador informó un fallo definitivo. |

F4 conserva el resultado de cada intento, incluso ante error o timeout. Una operación cuyo resultado externo sea incierto permanece `PENDIENTE` hasta que pueda resolverse. Los reintentos seguros mantienen la clave de idempotencia y el historial de la operación.

### ESP-09-RF-06 — Cierre del flujo de origen

Cuando el extorno alcanza `EXITOSO`, F4 notifica el resultado al flujo que lo originó: F2 para `ANULACION` o F3 para `DEVOLUCION`. La repetición de una notificación no vuelve a ejecutar el extorno.

## 6. Flujo documental de aceptación

1. F2 o F3 origina la solicitud después de aprobar su flujo correspondiente.
2. F4 valida emisor, origen, pago confirmado, referencia, moneda, monto e idempotencia.
3. F4 controla o reserva el saldo requerido, incluyendo montos pendientes de solicitudes concurrentes.
4. F4 registra la solicitud y el intento, y procesa el extorno mediante el simulador.
5. F4 registra `EXITOSO`, `FALLIDO` o `PENDIENTE` según el resultado confirmado.
6. Si el resultado es `EXITOSO`, F4 notifica al flujo originador para su cierre.

Este flujo expresa responsabilidades y resultados; no define rutas HTTP ni formatos de payload.

## 7. Escenarios de aceptación

### ESP-09-CA-01 — Solicitud válida de F2

**Dado** una anulación aprobada por F2 y un pago confirmado  
**Cuando** F2 solicita un reembolso con origen `ANULACION` y datos válidos  
**Entonces** F4 valida el pago y procesa la solicitud sin decidir nuevamente si la anulación procede.

### ESP-09-CA-02 — Solicitud válida de F3

**Dado** una devolución aprobada por F3 que contempla reembolso monetario  
**Cuando** F3 solicita el reembolso con origen `DEVOLUCION`  
**Entonces** F4 valida el pago y procesa la solicitud asociada a F3.

### ESP-09-CA-03 — Entrega fallida

**Dado** que E informa una entrega fallida  
**Cuando** el evento se gestiona para solicitar un extorno  
**Entonces** F2 tramita la anulación y F4 solo recibe el origen `ANULACION`; `DESPACHO_FALLIDO` no se acepta como origen directo.

### ESP-09-CA-04 — Validación de moneda y monto

**Dado** un pago original confirmado con referencia, moneda e importe determinados  
**Cuando** F4 recibe un reembolso total o parcial  
**Entonces** valida que la referencia y moneda coincidan, y que el monto solicitado quepa en el saldo reembolsable.

### ESP-09-CA-05 — Solicitudes concurrentes

**Dado** dos solicitudes simultáneas asociadas al mismo pago original cuyo monto combinado excede el saldo reembolsable  
**Cuando** F4 controla o reserva los montos pendientes  
**Entonces** únicamente se admite el importe que cabe en el saldo y se rechaza el exceso antes de invocar la pasarela.

### ESP-09-CA-06 — Repetición idempotente

**Dado** una solicitud ya registrada con `X-Idempotency-Key` y su resultado  
**Cuando** se repite la misma operación con la misma clave  
**Entonces** F4 devuelve el resultado previamente registrado y no ejecuta un segundo extorno.

### ESP-09-CA-07 — Reutilización conflictiva de clave

**Dado** una clave ya vinculada a una solicitud  
**Cuando** se presenta la misma clave con datos de operación diferentes  
**Entonces** F4 rechaza la nueva solicitud y conserva intacto el registro original.

### ESP-09-CA-08 — Resultado exitoso

**Dado** una solicitud válida y una respuesta exitosa del simulador  
**Cuando** F4 procesa el extorno  
**Entonces** registra `EXITOSO` y notifica a F2 o F3 según el origen.

### ESP-09-CA-09 — Error definitivo

**Dado** una solicitud válida y un error definitivo del simulador  
**Cuando** termina el intento  
**Entonces** F4 registra `FALLIDO`, conserva el resultado y permite recuperar la operación de forma segura dentro del mismo expediente.

### ESP-09-CA-10 — Timeout con resultado incierto

**Dado** que el simulador no confirma el resultado antes de un timeout  
**Cuando** F4 registra el intento  
**Entonces** mantiene la solicitud como `PENDIENTE`, conserva la evidencia y evita crear un segundo extorno durante su recuperación.

## 8. Dependencias y límites

- F2 proporciona el origen `ANULACION`; F3 proporciona el origen `DEVOLUCION`.
- El Módulo E informa la entrega fallida a F2 y no origina solicitudes directas a F4.
- F4 utiliza el simulador de pasarela y valida los datos del pago original mediante el límite intermodular aprobado.
- F4 conserva sus datos en M2 y no escribe directamente en la base de datos de M1.
- La definición del contrato compartido pertenece a su responsable y no se sustituye con esta especificación.

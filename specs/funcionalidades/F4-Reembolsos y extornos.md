# Funcionalidad 4: Reembolsos y extornos

**Responsable:** Luis Alejandro
**Estado:** En especificación
**Actor principal:** F2/F3 (origen de la solicitud) y Gestor (autoriza cuando corresponde)
**Microservicio:** M2 — Postventa
**Lineamiento del curso:** "Gestión de reembolsos (extornos de pagos)" (Módulo D — Ventas y Postventa)

## 1. Contexto

F4 es la única funcionalidad autorizada a devolver dinero real al cliente. Es de alto riesgo porque maneja plata, por eso **nunca se origina por sí sola** — solo actúa cuando F2 (anulación con pago) o F3 (devolución aprobada) le entregan un origen válido. Toda operación pasa por un simulador de pasarela de pago (simula al banco/Visa/Yape para efectos del proyecto).

## 2. Propósito

Devolver dinero al medio de pago original cuando existe un origen válido, evitando duplicados mediante idempotencia y dejando trazabilidad completa de una operación de alto riesgo.

## 3. Alcance

Incluye:
- Extorno total o parcial, según el origen.
- Verificación de idempotencia antes de ejecutar cualquier operación.
- Envío de la operación al simulador de pasarela y procesamiento de su resultado.
- Persistencia de la transacción (monto, moneda, autorizador, fecha, estado).
- Notificación a M1/M2 cuando el extorno se completa exitosamente.

**No incluye:** decidir si una anulación o devolución procede (eso lo deciden F2/F3); F4 solo ejecuta el movimiento de dinero una vez que el origen ya fue aprobado.

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- Existe un pago original asociado al pedido.
- El origen (F2 o F3) está validado y aprobado.
- El monto a reembolsar es calculable y no supera lo pagado originalmente.
- Existe un identificador de idempotencia (clave única por operación).

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| F2 — Anulación de pedidos | Origina la solicitud cuando una anulación involucra un pedido ya pagado. |
| F3 — Devoluciones y cambios | Origina la solicitud cuando una devolución es aprobada con reembolso de dinero. |
| M1 — Pedidos | Provee la referencia del pedido/pago original. |
| Simulador de pasarela de pago | Procesa la operación de extorno (simula éxito, error o latencia). |
| Seguridad (G) | Valida el rol del autorizador cuando la operación lo requiere. |

### 4.3. Resultados

- Un extorno exitoso queda persistido con `idTransacción`, monto, moneda, autorizador, fecha y estado `EXITOSO`.
- Un extorno fallido queda registrado como `FALLIDO`/`PENDIENTE`, sin perder trazabilidad, y puede reintentarse con la misma clave sin duplicar dinero.
- Un extorno exitoso notifica a M1/M2 para que el flujo de origen (F2 o F3) se marque como completado.
- Ningún reembolso se ejecuta dos veces para el mismo origen.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Validación de origen e idempotencia

El sistema DEBE rechazar cualquier solicitud de reembolso que no provenga de un origen válido (F2/F3), y DEBE evitar ejecutar dos veces la misma operación.

#### CA-01. Rechazo sin origen válido

- **DADO** una solicitud de reembolso que no proviene de F2 ni F3.
- **CUANDO** se recibe.
- **ENTONCES** el sistema la rechaza con `403 Forbidden`.

#### CA-02. Idempotencia ante reintento

- **DADO** una operación de reembolso ya ejecutada exitosamente con una clave idempotente específica.
- **CUANDO** la misma clave se reintenta (por ejemplo, por una falla de red del emisor).
- **ENTONCES** el sistema retorna el resultado ya existente sin ejecutar una segunda operación de dinero.

### RF-02. Cálculo del monto

El sistema DEBE calcular correctamente el monto a reembolsar (total o parcial) y rechazar montos que excedan lo pagado.

#### CA-03. Reembolso total

- **DADO** una anulación de un pedido pagado en su totalidad.
- **CUANDO** se origina el reembolso.
- **ENTONCES** el sistema calcula el monto total pagado como monto a extornar.

#### CA-04. Reembolso parcial

- **DADO** una devolución aprobada de solo algunos ítems del pedido.
- **CUANDO** se origina el reembolso.
- **ENTONCES** el sistema calcula el monto correspondiente solo a esos ítems.

#### CA-05. Rechazo por monto excedido

- **DADO** una solicitud cuyo monto calculado supera lo pagado originalmente.
- **CUANDO** se valida antes de llamar a la pasarela.
- **ENTONCES** el sistema rechaza la operación sin llegar a invocar al simulador.

### RF-03. Procesamiento y persistencia

El sistema DEBE procesar la operación contra el simulador de pasarela y persistir el resultado con trazabilidad completa, sin importar si es éxito o error.

#### CA-06. Extorno exitoso

- **DADO** una solicitud válida con monto correcto.
- **CUANDO** el simulador de pasarela responde con éxito.
- **ENTONCES** el sistema persiste la transacción como `EXITOSO` y notifica a M1/M2.

#### CA-07. Extorno con error del simulador

- **DADO** una solicitud válida.
- **CUANDO** el simulador de pasarela responde con error.
- **ENTONCES** el sistema persiste la transacción como `FALLIDO`/`PENDIENTE` sin corromper el estado, y permite un reintento con la misma clave.

## 6. Frontend

Superficie visible dentro del panel del Gestor:

| Elemento | Responsabilidad |
|---|---|
| Detalle de reembolso | Muestra origen (F2/F3), monto, estado, autorizador y fecha. |
| Historial de reintentos | Visualiza los intentos asociados a una misma clave idempotente, si los hubo. |
| Indicador de estado | Distingue claramente `EXITOSO`, `FALLIDO` y `PENDIENTE`. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Validador de origen | Verifica que la solicitud provenga de F2 o F3 y esté aprobada. |
| Motor de idempotencia | Registra claves procesadas y evita ejecutar dos veces la misma operación. |
| Calculador de monto | Determina el monto total o parcial según el origen. |
| Cliente del simulador de pasarela | Envía la operación y procesa su resultado (éxito/error/latencia). |
| Persistencia de transacciones | Guarda cada intento con `idTransacción`, monto, moneda, autorizador, fecha y estado. |

## 8. Requisitos no funcionales

- **Idempotencia (obligatoria):** ninguna clave procesada puede generar una segunda operación de dinero.
- **Auditabilidad:** toda operación monetaria, exitosa o fallida, queda registrada con trazabilidad completa.
- **Resiliencia del simulador:** debe poder probarse con latencia, éxito y error, sin corromper datos en ningún escenario.
- **Aislamiento:** F4 nunca se activa sin un origen validado de F2 o F3.

## 9. Fuera de alcance

- **Decisión de si procede la anulación o devolución:** corresponde a F2 y F3 respectivamente.
- **Integración con una pasarela de pago real:** se usa un simulador para efectos del proyecto.
- **Notificación al cliente del resultado:** se apoya en F5/canales, no es responsabilidad directa de F4.

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 y CA-02 | Enviar una solicitud sin origen válido, y reintentar una misma clave idempotente. | Unitaria e integración | `403` sin origen; resultado idéntico sin duplicar en el reintento. |
| CA-03 a CA-05 | Calcular reembolso total, parcial y uno que excede el monto pagado. | Unitaria | Montos correctos; rechazo antes de llamar a la pasarela cuando excede. |
| CA-06 y CA-07 | Simular respuesta exitosa y con error del simulador de pasarela. | Integración | Persistencia correcta en ambos casos, reintento posible tras error. |

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-07` están implementados y cuentan con pruebas automatizadas exitosas.
- Se demuestra con una prueba explícita que una misma clave idempotente nunca genera dos extornos.
- Ningún reembolso puede ejecutarse sin un origen validado de F2 o F3.
- Los fallos del simulador se manejan sin corrupción de datos, con reintento seguro disponible.
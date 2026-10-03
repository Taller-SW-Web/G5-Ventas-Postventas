# RNF-03 — Trazabilidad

## 1. Identificación

| Campo           | Detalle                      |
| --------------- | ---------------------------- |
| **Código**      | RNF-03                       |
| **Nombre**      | Trazabilidad                 |
| **Módulos**     | M1 — Ventas / M2 — Postventa |
| **Responsable** | Joseph                       |
| **Tipo**        | Requisito no funcional       |

---

## 2. Propósito

Garantizar que las operaciones relevantes del sistema puedan ser reconstruidas posteriormente, identificando quién realizó la acción, sobre qué recurso, cuándo ocurrió, qué motivo tuvo cuando corresponda y cuál fue su resultado.

---

## 3. Requisito

M1 y M2 deben registrar información de trazabilidad para las operaciones críticas del sistema. Los registros deben conservarse de forma persistente y permitir relacionar cada operación con el recurso afectado y el actor que la ejecutó.

La información debe estar disponible para auditoría y permitir verificar el historial de las operaciones sin depender de la sesión actual del usuario.

---

## 4. Operaciones trazables

Se debe mantener trazabilidad, como mínimo, para:

| Operación             | Información relevante                                        |
| --------------------- | ------------------------------------------------------------ |
| **Cambios de estado** | Estado anterior, estado nuevo, actor, fecha y resultado      |
| **Anulaciones**       | Actor, motivo, autorización y resultado                      |
| **Devoluciones**      | Actor, pedido, motivo, fecha, estado y resultado             |
| **Reembolsos**        | Actor, origen, monto, moneda, transacción, fecha y resultado |
| **Reclamos**          | Código, estado, responsable, fechas relevantes y resultado   |

---

## 5. Información mínima registrada

Cada registro de trazabilidad debe conservar, según corresponda:

| Campo           | Descripción                                                                   |
| --------------- | ----------------------------------------------------------------------------- |
| `actor`         | Usuario, servicio o proceso que ejecutó la operación                          |
| `fechaHora`     | Fecha y hora de la operación en UTC                                           |
| `accion`        | Operación realizada                                                           |
| `recurso`       | Tipo de recurso afectado                                                      |
| `recursoId`     | Identificador del recurso afectado                                            |
| `motivo`        | Justificación de la operación cuando corresponda                              |
| `resultado`     | Resultado de la operación                                                     |
| `correlationId` | Identificador para relacionar operaciones entre servicios, cuando corresponda |

---

## 6. Reglas

1. Toda operación crítica debe generar un registro de trazabilidad.
2. Los cambios de estado deben conservar el estado anterior y el nuevo estado.
3. Las operaciones que requieran justificación deben registrar su motivo.
4. Las operaciones monetarias deben conservar la información necesaria para identificar la transacción, monto, moneda y resultado.
5. Los registros deben persistirse y mantenerse disponibles para su posterior consulta.
6. Los registros deben permitir relacionar operaciones distribuidas mediante un identificador de correlación cuando intervengan varios servicios.

---

## 7. Criterios de aceptación

### CA-01 — Identificación de la operación

**DADO** una operación crítica ejecutada correctamente.

**CUANDO** se genera su registro de trazabilidad.

**ENTONCES** debe ser posible identificar el actor, acción, recurso, fecha y resultado.

### CA-02 — Cambio de estado

**DADO** una operación que modifica el estado de un recurso.

**CUANDO** la operación finaliza.

**ENTONCES** el registro conserva el estado anterior, estado nuevo, actor, fecha y resultado.

### CA-03 — Operación monetaria

**DADO** un reembolso procesado por F4.

**CUANDO** finaliza la operación.

**ENTONCES** su trazabilidad permite identificar el monto, moneda, transacción, actor, fecha y resultado.

### CA-04 — Persistencia

**DADO** una operación previamente registrada.

**CUANDO** se consulta posteriormente su información de auditoría.

**ENTONCES** el registro continúa disponible y permite reconstruir los datos principales de la operación.

---

## 8. Verificación

El cumplimiento del requisito se verificará mediante:

* **Pruebas funcionales:** ejecutar operaciones críticas y comprobar la generación de sus registros.
* **Revisión de BD:** verificar la persistencia de los datos de trazabilidad.
* **Revisión de logs:** comprobar la existencia de información relacionada con operaciones relevantes.
* **Pruebas de integración:** verificar la correlación de operaciones que atraviesan M1 y M2.

---

## 9. Trazabilidad del requisito

| Elemento                          | Referencia                                                      |
| --------------------------------- | --------------------------------------------------------------- |
| **Funcionalidades relacionadas**  | F1, F2, F3, F4 y F6                                             |
| **Especificaciones relacionadas** | ESP-03, ESP-05, ESP-07, ESP-08, ESP-09, ESP-10, ESP-13 y ESP-14 |
| **Arquitectura**                  | M1 — Ventas / M2 — Postventa                                    |
| **Contrato**                      | `api-contract.md`                                               |
| **Modelo de datos**               | `modelo-datos.md`                                               |
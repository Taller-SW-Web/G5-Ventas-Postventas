# ESP-03 — Transiciones de estado e historial

## 1. Identificación

| Campo              | Detalle                              |
| ------------------ | -------------------------------------- |
| **Código**          | ESP-03                                 |
| **Nombre**          | Transiciones de estado e historial      |
| **Funcionalidad**   | F1 — Ciclo de vida del pedido           |
| **Módulo**          | M1 — Pedidos                            |
| **Responsable**     | Michael                                 |
| **Tipo**            | Especificación funcional                |

---

## 2. Propósito

Definir las transiciones de estado permitidas para un pedido, quién puede dispararlas y bajo qué condición, y establecer el registro auditable de cada cambio.

M1 es el único dueño del estado del pedido: toda transición, venga del flujo interno, de un actor humano o de un evento externo, debe pasar por esta especificación.

---

## 3. Alcance

Esta especificación comprende:

* La máquina de estados completa del pedido, incluidas las transiciones disparadas automáticamente por notificaciones externas (pasarela de pago, Despacho).
* La validación de que toda transición corresponda a una arista existente.
* El registro de cada transición en el historial (actor, motivo, fecha/hora).
* El manejo idempotente de transiciones disparadas por eventos que pueden reintentarse.

La publicación de eventos de dominio derivada de estas transiciones corresponde a **ESP-04**.

---

## 4. Actores y responsabilidades

| Actor                                | Responsabilidad                                                                 |
| -------------------------------------- | ----------------------------------------------------------------------------------- |
| **Pasarela de pago (notificación)**    | Notifica la confirmación o el rechazo del pago, disparando `CREADO → PAGADO` o `CREADO → ANULADO`. |
| **Canal**                               | Dispara la anulación por `PAGO_NO_COMPLETADO` cuando la pasarela reporta el fallo, sin intervención del Gestor. |
| **Gestor**                              | Autoriza anulaciones desde `EN PREPARACIÓN` (ver F2); consulta el historial.        |
| **Despacho y Entrega (E)**              | Notifica `DESPACHADO` y `ENTREGADO` (o entrega fallida) mediante su llamada a la API de F1. |
| **M1 — Pedidos**                        | Valida cada transición contra la máquina de estados y registra el historial.        |

---

## 5. Precondiciones

1. Toda transición solicitada debe corresponder a una arista existente en la máquina de estados.
2. Las transiciones administrativas forzadas requieren token JWT con rol `GESTOR` o `ADMIN`.
3. Las transiciones disparadas por eventos externos (pasarela, Despacho) deben incluir una clave de idempotencia.

---

## 6. Disparador

```text
Evento externo (pasarela / Despacho) o acción interna (Gestor)
   │
   ▼
M1 valida la transición contra la máquina de estados
   │
   ▼
Aplica el cambio y registra el historial
```

---

## 7. Flujo funcional

### 7.1 Máquina de estados

```text
CREADO ──────► PAGADO ──────► EN PREPARACIÓN ──────► DESPACHADO ──────► ENTREGADO
  │               │
  │               └──► ANULADO  (EN PREPARACIÓN → ANULADO requiere autorización del Gestor, ver F2)
  │
  └──► ANULADO  (por CANAL, motivo PAGO_NO_COMPLETADO, sin Gestor)
```

### 7.2 Matriz de transiciones

| Origen             | Destino        | Disparador                              | Actor    | Motivo                | ¿Requiere Gestor? |
| --------------------- | ---------------- | ------------------------------------------ | ---------- | ------------------------ | :------------------: |
| `CREADO`               | `PAGADO`          | Notificación de la pasarela de pago         | Pasarela   | —                          | No                    |
| `CREADO`               | `ANULADO`         | Notificación de pago no completado          | Canal      | `PAGO_NO_COMPLETADO`      | No                    |
| `PAGADO`               | `EN PREPARACIÓN`  | Acción interna del flujo de preparación     | Sistema    | —                          | No                    |
| `EN PREPARACIÓN`       | `DESPACHADO`      | Confirmación de Despacho (E)                | Despacho   | —                          | No                    |
| `EN PREPARACIÓN`       | `ANULADO`         | Solicitud de anulación (ver F2)             | Gestor     | Tipificado (F2)           | **Sí**                |
| `DESPACHADO`           | `ENTREGADO`       | Notificación de entrega de Despacho (E)     | Despacho   | —                          | No                    |

Cualquier transición fuera de esta tabla se rechaza, incluso con permisos de `ADMIN`.

### 7.3 Flujo principal — transición por notificación de pasarela

1. La pasarela de pago notifica el resultado del cobro de un pedido `CREADO`.
2. El sistema valida la clave de idempotencia de la notificación.
3. Si el resultado es exitoso, transiciona el pedido a `PAGADO` y registra el historial (actor: `PASARELA`).
4. Si el resultado es un fallo de pago, transiciona el pedido a `ANULADO` con motivo `PAGO_NO_COMPLETADO` y registra el historial (actor: `CANAL`) — **sin requerir intervención del Gestor**.

### 7.4 Flujos alternativos

<details>
<summary><strong>A. Transición inválida (salto de estado)</strong></summary>

1. Se solicita una transición que no está en la matriz (por ejemplo, `CREADO → DESPACHADO`).
2. El sistema la rechaza con `409 Conflict`.
3. El pedido no se modifica ni se registra historial.

</details>

<details>
<summary><strong>B. Reintento de notificación (idempotencia)</strong></summary>

1. Una notificación (pasarela o Despacho) ya fue procesada para un pedido, con una clave de idempotencia específica.
2. La misma notificación se reintenta.
3. El sistema reconoce el reintento y no duplica la transición ni el historial.

</details>

<details>
<summary><strong>C. Notificación de pago no completado sobre un pedido ya pagado</strong></summary>

1. La pasarela notifica un fallo de pago para un pedido que ya está en `PAGADO`.
2. El sistema detecta que la transición `CREADO → ANULADO` no aplica desde `PAGADO`.
3. Rechaza la notificación tardía con `409 Conflict` y la deja registrada para revisión manual, sin modificar el pedido.

</details>

---

## 8. Datos

### 8.1 Datos de entrada (transición)

| Campo                  | Tipo         | Obligatorio | Descripción                                             |
| ------------------------ | ------------- | :---------: | ----------------------------------------------------------- |
| `nuevoEstado`             | Enumeración   |      Sí     | Estado destino de la transición.                             |
| `actor`                   | Texto         |      Sí     | Quién/qué dispara la transición (`PASARELA`, `CANAL`, `DESPACHO`, `GESTOR`, `SISTEMA`). |
| `motivo`                  | Texto         | Condicional | Obligatorio para transiciones a `ANULADO`.                   |
| `claveIdempotencia`       | Texto         |      Sí     | Identificador único de la operación, para evitar duplicados. |

### 8.2 Datos persistidos (historial)

| Campo               | Descripción                                  |
| --------------------- | ------------------------------------------------ |
| `estadoAnterior`       | Estado antes de la transición (`null` en creación). |
| `estadoNuevo`          | Estado resultante.                                |
| `actor`                | Quién/qué ejecutó la transición.                  |
| `motivo`               | Motivo registrado, cuando aplica.                 |
| `fechaHora`            | Fecha y hora en UTC.                               |

---

## 9. Reglas de negocio

1. M1 es el único dueño del estado del pedido; ninguna transición fuera de la matriz de la sección 7.2 está permitida, ni siquiera con permisos de `ADMIN`.
2. La transición `CREADO → PAGADO` solo puede dispararla la notificación de la pasarela de pago.
3. La transición `CREADO → ANULADO` por `PAGO_NO_COMPLETADO` la dispara el Canal a partir de la notificación de la pasarela, **sin requerir autorización del Gestor** — a diferencia de la anulación desde `EN PREPARACIÓN`, que sí la requiere (ver F2).
4. Toda transición a `ANULADO` exige un motivo tipificado.
5. Toda transición queda registrada en el historial con actor, motivo (si aplica) y fecha/hora en UTC.
6. Las notificaciones externas (pasarela, Despacho) deben procesarse de forma idempotente.

---

## 10. Validaciones y errores

| Validación                  | Condición                                     | Respuesta esperada |
| ------------------------------ | ------------------------------------------------- | ---------------------- |
| Transición no permitida          | El par (estado actual, `nuevoEstado`) no está en la matriz | `409 Conflict`        |
| Motivo obligatorio faltante      | Transición a `ANULADO` sin `motivo`                | `400 Bad Request`     |
| Clave de idempotencia repetida   | La operación ya fue procesada                       | `200 OK` (resultado existente, sin duplicar) |
| Pedido inexistente               | `pedidoId` no encontrado                            | `404 Not Found`        |

---

## 11. Estado y trazabilidad

El historial debe quedar siempre ordenado cronológicamente y debe permitir distinguir, para la transición `CREADO → ANULADO`, si fue disparada por `PAGO_NO_COMPLETADO` (sin Gestor) o por una anulación autorizada desde `EN PREPARACIÓN` (con Gestor, ver F2) — ambas terminan en `ANULADO`, pero con actor y motivo distintos.

---

## 12. Integraciones y API

```http
PATCH /api/pedidos/{pedidoId}/estado
```

Ejemplo — notificación de pago no completado:

```json
{
  "nuevoEstado": "ANULADO",
  "actor": "CANAL",
  "motivo": "PAGO_NO_COMPLETADO",
  "claveIdempotencia": "pasarela-evt-98213"
}
```

> Las rutas, cuerpos y códigos definitivos deben mantenerse alineados con `specs/api-contract.md`.

---

## 13. Criterios de aceptación

### CA-01 — Transición válida por confirmación de pago

**DADO** un pedido en estado `CREADO`.

**CUANDO** la pasarela notifica el pago como exitoso.

**ENTONCES** el sistema transiciona el pedido a `PAGADO` y registra el historial con actor `PASARELA`.

---

### CA-02 — Transición a ANULADO por pago no completado, sin Gestor

**DADO** un pedido en estado `CREADO`.

**CUANDO** la pasarela notifica que el pago no se completó.

**ENTONCES** el sistema transiciona el pedido a `ANULADO` con motivo `PAGO_NO_COMPLETADO`, registra el historial con actor `CANAL`, y **no requiere ninguna autorización del Gestor**.

---

### CA-03 — Rechazo por transición inválida (salto de estado)

**DADO** un pedido en estado `CREADO`.

**CUANDO** se solicita la transición directa a `DESPACHADO`.

**ENTONCES** el sistema responde `409 Conflict` y no modifica el pedido.

---

### CA-04 — Transición disparada por Despacho (E)

**DADO** un pedido en estado `DESPACHADO`.

**CUANDO** el módulo Despacho y Entrega notifica la entrega exitosa.

**ENTONCES** el sistema transiciona el pedido a `ENTREGADO`, registrando el actor como `DESPACHO`.

---

### CA-05 — Reintento de notificación (idempotencia)

**DADO** que una notificación (pasarela o Despacho) ya fue procesada para un pedido con una clave de idempotencia específica.

**CUANDO** la misma notificación se reintenta.

**ENTONCES** el sistema reconoce el reintento y no duplica la transición ni el historial.

---

### CA-06 — Historial completo y ordenado

**DADO** un pedido que pasó por varias transiciones.

**CUANDO** se consulta su detalle.

**ENTONCES** el historial se retorna ordenado cronológicamente, con actor, motivo y fecha/hora de cada cambio.

---

## 14. Trazabilidad

| Elemento                       | Referencia                                                    |
| --------------------------------- | ----------------------------------------------------------------- |
| **Funcionalidad**                 | F1 — Ciclo de vida del pedido                                       |
| **Especificación**                | ESP-03 — Transiciones de estado e historial                        |
| **RNF relacionados**              | RNF-03 — Trazabilidad; RNF-08 — Idempotencia                        |
| **Contrato API**                  | [`api-contract.md`](../api-contract.md)                            |
| **Especificación relacionada**    | ESP-01 — Creación de pedido; ESP-04 — Publicación de eventos; F2 — Anulación de pedidos |

### Relación con F1

```text
F1 — Ciclo de vida del pedido
│
├── ESP-01 — Creación de pedido
├── ESP-02 — Consulta y listado de pedidos
├── ESP-03 — Transiciones de estado e historial
└── ESP-04 — Publicación de eventos
```

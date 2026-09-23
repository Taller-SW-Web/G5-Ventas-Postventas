# ESP-04 — Publicación de eventos

## 1. Identificación

| Campo              | Detalle                          |
| ------------------ | --------------------------------- |
| **Código**          | ESP-04                            |
| **Nombre**          | Publicación de eventos            |
| **Funcionalidad**   | F1 — Ciclo de vida del pedido     |
| **Módulo**          | M1 — Pedidos                      |
| **Responsable**     | Michael                           |
| **Tipo**            | Especificación funcional          |

---

## 2. Propósito

Definir los eventos de dominio que M1 debe publicar ante cada transición de estado relevante, para que M2 (F2 a F6) reaccione sin acoplamiento síncrono ni acceso directo a las tablas de M1.

---

## 3. Alcance

Esta especificación comprende:

* La publicación de los eventos `pedido.pagado`, `pedido.anulado` y `pedido.entregado`.
* La estructura mínima que debe llevar cada evento.
* El comportamiento esperado cuando un consumidor reprocesa un evento.

La lógica de qué hace cada consumidor con el evento no forma parte de esta especificación (se define en la especificación de cada consumidor: ESP-11 de F5, ESP-15 de F6, etc.).

---

## 4. Actores y responsabilidades

| Actor                    | Responsabilidad                                                       |
| --------------------------- | --------------------------------------------------------------------- |
| **M1 — Pedidos**             | Publica el evento correspondiente en la misma operación que aplica la transición (ver ESP-03). |
| **M2 (F2 a F6)**              | Consume los eventos relevantes y actualiza su propio estado/agregados. |
| **Productos y Ofertas (F)**  | Consume `pedido.anulado` para reponer stock.                          |

---

## 5. Precondiciones

1. La transición de estado debe haberse aplicado exitosamente (ver ESP-03) antes de publicar cualquier evento.
2. Toda transición rechazada no debe generar publicación de evento.

---

## 6. Disparador

```text
Transición de estado aplicada (ver ESP-03)
   │
   ▼
M1 publica el evento correspondiente
   │
   ▼
Consumidores (M2, Productos) procesan el evento
```

---

## 7. Flujo funcional

### 7.1 Flujo principal

1. M1 aplica una transición de estado relevante (`→ PAGADO`, `→ ANULADO` o `→ ENTREGADO`).
2. En la misma operación, M1 arma el evento correspondiente con `pedidoId`, `estadoAnterior`, `estadoNuevo`, `actor` y `fechaHora`.
3. M1 publica el evento al canal de mensajería acordado.
4. Los consumidores procesan el evento de forma independiente y asíncrona.

### 7.2 Eventos publicados

| Evento             | Disparador                                              | Consumidores                                  |
| --------------------- | ---------------------------------------------------------- | ------------------------------------------------- |
| `pedido.pagado`         | Transición `CREADO → PAGADO`                                | M2 (agregados), F6                                 |
| `pedido.anulado`        | Transición `→ ANULADO` (por `PAGO_NO_COMPLETADO` o por F2)   | Productos y Ofertas (F, reposición de stock), F4 (si hubo pago), F6 |
| `pedido.entregado`      | Transición `→ ENTREGADO` (confirmado por Despacho)           | F5 (encuesta), F6 (agregados)                      |

### 7.3 Flujos alternativos

<details>
<summary><strong>A. Transición rechazada</strong></summary>

1. Se intenta una transición no permitida (ver ESP-03, CA-03).
2. La transición es rechazada.
3. M1 no publica ningún evento.

</details>

<details>
<summary><strong>B. Consumidor reprocesa un evento</strong></summary>

1. Un consumidor (por ejemplo, F6) recibe un evento que ya había procesado antes.
2. El consumidor debe reconocer el reprocesamiento y no duplicar su efecto (los agregados no se cuentan dos veces).

</details>

---

## 8. Datos

### 8.1 Estructura del evento

| Campo             | Tipo      | Obligatorio | Descripción                              |
| -------------------- | ---------- | :---------: | -------------------------------------------- |
| `eventoId`            | UUID       |      Sí     | Identificador único del evento.               |
| `tipo`                 | Enumeración |      Sí     | `pedido.pagado` \| `pedido.anulado` \| `pedido.entregado`. |
| `pedidoId`             | UUID       |      Sí     | Pedido asociado.                               |
| `estadoAnterior`       | Enumeración |      Sí     | Estado previo a la transición.                 |
| `estadoNuevo`          | Enumeración |      Sí     | Estado resultante.                             |
| `actor`                | Texto      |      Sí     | Quién/qué disparó la transición.               |
| `motivo`               | Texto      | Condicional | Presente cuando el evento es `pedido.anulado`. |
| `fechaHora`            | Fecha/hora |      Sí     | Momento de la transición, en UTC.              |

---

## 9. Reglas de negocio

1. Todo evento se publica en la misma operación que aplica la transición — nunca de forma separada o diferida sin garantía.
2. Ninguna transición rechazada genera evento.
3. Los consumidores deben ser idempotentes: reprocesar un evento no debe duplicar su efecto.
4. El evento `pedido.anulado` debe incluir el `motivo`, para que F4 y Productos (F) sepan si hubo pago que reembolsar.

---

## 10. Validaciones y errores

| Validación                  | Condición                                        | Respuesta esperada |
| ------------------------------ | ----------------------------------------------------- | ---------------------- |
| Publicación tras rechazo         | Se intenta publicar un evento sin transición aplicada  | Bloqueado por diseño (no expuesto como endpoint independiente) |
| Consumidor no disponible         | El canal de mensajería no puede entregar el evento     | Reintento controlado, sin bloquear la transición ya aplicada |

---

## 11. Estado y trazabilidad

Los eventos no tienen un ciclo de vida propio de estados; su trazabilidad se apoya en el historial de la transición que los originó (ver ESP-03, sección 8.2).

---

## 12. Integraciones y API

```text
M1 — Pedidos
      │
      │ publica evento
      ▼
Bus de eventos / mensajería
      │
      ├──► M2 (F2 a F6)
      └──► Productos y Ofertas (F)
```

> El mecanismo de publicación (cola, tópico, webhook) se define en `specs/api-contract.md` junto con el resto de la integración entre módulos.

---

## 13. Criterios de aceptación

### CA-01 — Publicación ante transición válida

**DADO** un pedido que transiciona de `CREADO` a `PAGADO`.

**CUANDO** la transición se aplica exitosamente.

**ENTONCES** el sistema publica el evento `pedido.pagado` con todos los campos requeridos.

---

### CA-02 — Sin publicación ante transición rechazada

**DADO** un intento de transición inválida (ver ESP-03, CA-03).

**CUANDO** la transición es rechazada.

**ENTONCES** el sistema no publica ningún evento.

---

### CA-03 — Evento de anulación incluye el motivo

**DADO** un pedido que transiciona a `ANULADO` con motivo `PAGO_NO_COMPLETADO`.

**CUANDO** se publica el evento `pedido.anulado`.

**ENTONCES** el campo `motivo` del evento contiene `PAGO_NO_COMPLETADO`.

---

### CA-04 — Consumidores idempotentes ante reintento

**DADO** que un evento se reintenta hacia un consumidor (por ejemplo, F6).

**CUANDO** el consumidor ya lo había procesado antes.

**ENTONCES** el reprocesamiento no debe duplicar el efecto en el consumidor.

---

## 14. Trazabilidad

| Elemento                       | Referencia                                                    |
| --------------------------------- | ----------------------------------------------------------------- |
| **Funcionalidad**                 | F1 — Ciclo de vida del pedido                                       |
| **Especificación**                | ESP-04 — Publicación de eventos                                     |
| **RNF relacionados**              | RNF-05 — Disponibilidad; RNF-08 — Idempotencia                      |
| **Contrato API**                  | [`api-contract.md`](../api-contract.md)                            |
| **Especificación relacionada**    | ESP-03 — Transiciones de estado e historial                        |

### Relación con F1

```text
F1 — Ciclo de vida del pedido
│
├── ESP-01 — Creación de pedido
├── ESP-02 — Consulta y listado de pedidos
├── ESP-03 — Transiciones de estado e historial
└── ESP-04 — Publicación de eventos
```

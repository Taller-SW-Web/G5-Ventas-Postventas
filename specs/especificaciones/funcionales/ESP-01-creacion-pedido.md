# ESP-01 — Creación de pedido

## 1. Identificación

| Campo              | Detalle                          |
| ------------------ | --------------------------------- |
| **Código**          | ESP-01                            |
| **Nombre**          | Creación de pedido                |
| **Funcionalidad**   | F1 — Ciclo de vida del pedido     |
| **Módulo**          | M1 — Pedidos                      |
| **Responsable**     | Michael                           |
| **Tipo**            | Especificación funcional          |

---

## 2. Propósito

Definir el comportamiento para registrar un pedido nuevo a partir de la solicitud de un canal (Marketplace, Chatbot o Retail).

La especificación establece la estructura completa que debe traer la solicitud —incluyendo canal de origen, cupón aplicado (si existe), datos de envío, contacto y pago— las validaciones que se deben ejecutar antes de persistir, y el estado inicial del pedido.

---

## 3. Alcance

Esta especificación comprende:

* Recepción de la solicitud de creación desde un canal (A/B/C).
* Validación de la estructura completa: identificación del canal, ítems, cupón (opcional), datos de envío, datos de contacto y datos de pago.
* Consulta de precio/disponibilidad de cada ítem contra Productos y Ofertas (F).
* Validación y aplicación del cupón, si fue enviado.
* Persistencia del pedido con estado inicial `CREADO`.
* Registro del primer historial de estado.

La confirmación del pago y las transiciones posteriores corresponden a **ESP-03**. La generación y publicación de eventos corresponde a **ESP-04**.

---

## 4. Actores y responsabilidades

| Actor                          | Responsabilidad                                                                         |
| ------------------------------- | ----------------------------------------------------------------------------------------- |
| **Canal (Marketplace/Chatbot/Retail)** | Envía la solicitud de creación con todos los bloques requeridos (canal, ítems, cupón, envío, contacto, pago). |
| **Cliente**                      | Es el titular del pedido; sus datos de contacto y envío se registran junto con la solicitud. |
| **M1 — Pedidos**                 | Valida la solicitud completa, consulta dependencias y persiste el pedido.                 |
| **Productos y Ofertas (F)**      | Confirma precio y disponibilidad de cada ítem.                                            |
| **Seguridad (G)**                | Valida el token/rol del canal que origina la solicitud.                                   |

> **Nota:** el canal nunca escribe directamente sobre las tablas de M1; toda creación pasa por este endpoint.

---

## 5. Precondiciones

Antes de crear un pedido se debe cumplir lo siguiente:

1. El canal debe estar autenticado (token/rol válido emitido por Seguridad — G).
2. La solicitud debe incluir el bloque `canal` con su tipo y origen identificado.
3. La solicitud debe incluir al menos un ítem válido (producto y cantidad).
4. La solicitud debe incluir el bloque `envio` con una dirección de entrega válida.
5. La solicitud debe incluir el bloque `contacto` con al menos un medio de contacto del cliente.
6. El precio y la disponibilidad de cada ítem deben validarse contra Productos (F).
7. Si se envía el bloque `cupon`, el código debe existir y estar vigente.

---

## 6. Disparador

El proceso se inicia cuando un canal envía la solicitud de creación tras el checkout del cliente.

```text
Canal (A/B/C)
   │
   ▼
Arma la solicitud: canal, items, cupon, envio, contacto, pago
   │
   ▼
M1 valida estructura y dependencias
   │
   ▼
Se registra el pedido en estado CREADO
```

---

## 7. Flujo funcional

### 7.1 Flujo principal

1. El canal arma la solicitud de creación con los bloques `canal`, `items`, `cupon` (opcional), `envio`, `contacto` y `pago`.
2. El sistema valida que el canal esté autenticado y su token sea válido.
3. El sistema valida que el bloque `canal` identifique correctamente el origen (Marketplace, Chatbot o Retail).
4. El sistema valida que existan uno o más ítems, cada uno con producto y cantidad válidos.
5. El sistema consulta a Productos (F) el precio y disponibilidad de cada ítem.
6. Si se incluyó el bloque `cupon`, el sistema valida su vigencia y calcula el descuento aplicable.
7. El sistema valida que el bloque `envio` incluya una dirección de entrega existente.
8. El sistema valida que el bloque `contacto` incluya al menos un medio de contacto.
9. El sistema registra el bloque `pago` como referencia del medio de pago declarado (sin procesar el cobro — ver ESP-03).
10. El sistema calcula subtotal, descuento (si hubo cupón) y total.
11. El sistema persiste el pedido con estado inicial `CREADO`.
12. El sistema registra el primer historial de estado (`null → CREADO`, actor: canal).
13. El sistema devuelve al canal la confirmación con el identificador del pedido.

### 7.2 Flujos alternativos

<details>
<summary><strong>A. Falta un bloque obligatorio (canal, items, envio o contacto)</strong></summary>

1. El sistema valida la estructura completa de la solicitud.
2. Detecta que falta el bloque `canal`, `items`, `envio` o `contacto`.
3. Rechaza la solicitud indicando qué bloque falta.
4. El pedido no se persiste.

</details>

<details>
<summary><strong>B. Ítem sin disponibilidad</strong></summary>

1. El sistema consulta disponibilidad a Productos (F) para cada ítem.
2. Detecta que al menos uno no tiene stock disponible.
3. Rechaza la solicitud completa — no se persiste el pedido ni siquiera con los ítems que sí tenían stock.
4. Informa al canal cuál ítem no está disponible.

</details>

<details>
<summary><strong>C. Cupón inválido o vencido</strong></summary>

1. El sistema recibe el bloque `cupon` con un código.
2. Valida su existencia y vigencia.
3. Si el cupón no existe o está vencido, rechaza la solicitud e informa el motivo.
4. El pedido no se persiste con un descuento inválido.

</details>

<details>
<summary><strong>D. Error durante el registro</strong></summary>

1. El sistema valida todos los bloques recibidos.
2. Si ocurre un error durante la persistencia o comunicación con una dependencia, no debe generarse un pedido incompleto.
3. El sistema informa que no fue posible registrar el pedido.
4. El canal puede reintentar la solicitud.

</details>

---

## 8. Datos

### 8.1 Datos de entrada

| Bloque       | Campo             | Tipo                  | Obligatorio | Descripción                                                    |
| ------------ | ------------------ | ---------------------- | :---------: | ---------------------------------------------------------------- |
| `canal`      | `tipo`              | Enumeración             |      Sí     | `MARKETPLACE` \| `CHATBOT` \| `RETAIL`.                           |
| `canal`      | `origenId`          | Texto                   |      Sí     | Identificador del canal/sesión que origina la solicitud.         |
| `items[]`    | `productoId`        | UUID / identificador    |      Sí     | Producto solicitado.                                              |
| `items[]`    | `cantidad`          | Entero                  |      Sí     | Cantidad solicitada (> 0).                                        |
| `cupon`      | `codigo`            | Texto                   |      No     | Código de cupón aplicado, si existe.                              |
| `envio`      | `direccionId`       | UUID / identificador    |      Sí     | Dirección de entrega registrada del cliente.                     |
| `envio`      | `tipoEntrega`       | Enumeración             |      No     | `DOMICILIO` \| `RECOJO_TIENDA` (por defecto `DOMICILIO`).         |
| `contacto`   | `telefono`          | Texto                   | Condicional | Al menos uno entre `telefono` y `email` es obligatorio.          |
| `contacto`   | `email`             | Texto                   | Condicional | Al menos uno entre `telefono` y `email` es obligatorio.          |
| `pago`       | `metodo`            | Enumeración             |      Sí     | Medio de pago declarado por el cliente (referencia, no procesamiento). |
| `pago`       | `referencia`        | Texto                   |      No     | Referencia externa del medio de pago, si aplica.                 |

### 8.2 Datos de salida

Cuando el pedido se registra correctamente, el sistema devuelve información que permite identificarlo y consultarlo.

| Campo             | Descripción                                            |
| ------------------ | --------------------------------------------------------- |
| `pedidoId`          | Identificador único del pedido.                            |
| `codigo`            | Código legible del pedido.                                 |
| `estado`            | Estado actual. Inicialmente `CREADO`.                       |
| `subtotal`          | Suma de los ítems antes de descuento.                       |
| `descuento`         | Monto de descuento aplicado por el cupón, si corresponde.  |
| `total`             | Monto final del pedido.                                     |
| `fechaCreacion`     | Fecha y hora de creación.                                    |

Ejemplo de respuesta:

```json
{
  "pedidoId": "PED-000789",
  "codigo": "PED-000789",
  "estado": "CREADO",
  "subtotal": 150.00,
  "descuento": 15.00,
  "total": 135.00,
  "fechaCreacion": "2026-09-22T15:30:00Z"
}
```

### 8.3 Datos persistidos

El pedido debe conservar como mínimo:

* Identificador del pedido y código.
* Bloque `canal` (tipo y origen).
* Ítems con precio unitario al momento de la venta (snapshot).
* Bloque `cupon` aplicado, si existe, con el descuento calculado.
* Bloque `envio` (dirección y tipo de entrega).
* Bloque `contacto` (teléfono y/o email).
* Bloque `pago` (método y referencia declarados).
* Estado actual y fecha de creación.

---

## 9. Reglas de negocio

1. Todo pedido debe originarse desde un canal identificado (`MARKETPLACE`, `CHATBOT` o `RETAIL`).
2. Un pedido no puede crearse sin al menos un ítem válido.
3. El precio de cada ítem se fija (snapshot) al momento de la creación y no cambia si el catálogo se actualiza después.
4. Un pedido no puede crearse si algún ítem no tiene disponibilidad confirmada — no se permite creación parcial.
5. El bloque `envio` es obligatorio; toda solicitud sin dirección de entrega válida se rechaza.
6. El bloque `contacto` es obligatorio, con al menos un medio de contacto (teléfono o email).
7. El bloque `pago` se registra como referencia declarada por el cliente; el procesamiento del cobro no ocurre en esta especificación (ver ESP-03).
8. Si se envía un cupón, debe validarse su vigencia antes de aplicar el descuento; un cupón inválido rechaza toda la solicitud.
9. Todo pedido creado debe iniciar en estado `CREADO`, sin excepción.
10. El primer registro de historial se genera en la misma operación que la creación, nunca por separado.

---

## 10. Validaciones y errores

| Validación             | Condición                                         | Respuesta esperada |
| ------------------------ | ---------------------------------------------------- | --------------------- |
| Autenticación             | Canal no autenticado                                  | `401 Unauthorized`    |
| Bloque `canal` inválido   | Tipo de canal no reconocido o `origenId` ausente     | `400 Bad Request`     |
| Ítems vacíos              | `items` vacío o ausente                                | `400 Bad Request`     |
| Ítem sin disponibilidad   | Algún ítem sin stock según Productos (F)              | `409 Conflict`        |
| Bloque `envio` inválido   | `direccionId` ausente o inexistente                    | `400 Bad Request`     |
| Bloque `contacto` inválido| `telefono` y `email` ambos ausentes                    | `400 Bad Request`     |
| Cupón inválido            | Código de cupón inexistente o vencido                 | `409 Conflict`        |
| Error de dependencia      | Fallo al consultar Productos (F) o Seguridad (G)      | Error controlado según contrato API |

Los mensajes de error deben ser claros para el canal y no deben exponer información interna del sistema.

Ejemplo:

```json
{
  "error": "ITEM_SIN_DISPONIBILIDAD",
  "message": "No es posible crear el pedido porque uno o más productos no tienen stock disponible."
}
```

---

## 11. Estado y trazabilidad

### 11.1 Estado inicial

Todo pedido creado correctamente inicia en:

```text
CREADO
```

El flujo posterior de transiciones se desarrolla en **ESP-03**.

### 11.2 Trazabilidad

El registro debe permitir identificar:

* Qué canal originó la solicitud.
* Qué ítems, cupón, envío, contacto y pago se declararon.
* Cuándo se creó el pedido.
* Qué precio tenía cada ítem al momento de la venta.

---

## 12. Integraciones y API

### Consulta de precio/disponibilidad

```text
M1 — Pedidos
      │
      │ consulta precio/disponibilidad por item
      ▼
Productos y Ofertas (F)
      │
      │ precio + disponibilidad
      ▼
M1
```

### Creación del pedido

```http
POST /api/pedidos
```

Con un cuerpo similar a:

```json
{
  "canal": { "tipo": "MARKETPLACE", "origenId": "web-mkt-01" },
  "items": [
    { "productoId": "PROD-001", "cantidad": 2 }
  ],
  "cupon": { "codigo": "BIENVENIDA10" },
  "envio": { "direccionId": "DIR-100", "tipoEntrega": "DOMICILIO" },
  "contacto": { "telefono": "+51999999999", "email": "cliente@correo.com" },
  "pago": { "metodo": "TARJETA", "referencia": "tok_abc123" }
}
```

> Las rutas, nombres de campos y estructuras definitivas deben mantenerse alineadas con `specs/api-contract.md`.

---

## 13. Criterios de aceptación

### CA-01 — Creación exitosa con todos los bloques

**DADO** que el Canal Marketplace envía un pedido con `canal`, `items`, `envio` y `contacto` válidos, sin cupón.

**CUANDO** se confirma la solicitud.

**ENTONCES** el sistema consulta precio/disponibilidad a Productos (F), persiste el pedido con estado `CREADO` y registra el primer historial.

---

### CA-02 — Rechazo por bloque obligatorio faltante

**DADO** un pedido sin el bloque `envio` o sin el bloque `contacto`.

**CUANDO** se envía la solicitud de creación.

**ENTONCES** el sistema responde `400 Bad Request` y no persiste el pedido.

---

### CA-03 — Rechazo por producto sin disponibilidad

**DADO** un pedido que incluye un ítem sin stock disponible según Productos (F).

**CUANDO** se confirma la solicitud.

**ENTONCES** el sistema responde `409 Conflict` y no persiste el pedido.

---

### CA-04 — Creación exitosa con cupón válido

**DADO** un pedido que incluye el bloque `cupon` con un código vigente.

**CUANDO** se confirma la solicitud.

**ENTONCES** el sistema aplica el descuento correspondiente y persiste el pedido con el `total` ya descontado.

---

### CA-05 — Rechazo por cupón inválido

**DADO** un pedido que incluye el bloque `cupon` con un código inexistente o vencido.

**CUANDO** se confirma la solicitud.

**ENTONCES** el sistema rechaza toda la solicitud con `409 Conflict`, sin crear el pedido.

---

## 14. Trazabilidad

| Elemento                       | Referencia                                                    |
| --------------------------------- | ----------------------------------------------------------------- |
| **Funcionalidad**                 | F1 — Ciclo de vida del pedido                                       |
| **Especificación**                | ESP-01 — Creación de pedido                                        |
| **RNF relacionados**              | RNF-01 — Performance; RNF-02 — Seguridad                            |
| **Wireframe**                     | [`F1-ciclo-pedido.md`](../../diseno/wireframes/F1-ciclo-pedido.md) |
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

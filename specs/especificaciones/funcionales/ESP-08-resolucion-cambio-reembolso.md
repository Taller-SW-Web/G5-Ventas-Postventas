# ESP-08 — Resolución (cambio, reembolso o rechazo)

## 1. Identificación

| Campo             | Detalle                                  |
| ----------------- | ---------------------------------------- |
| **Código**        | ESP-08                                   |
| **Nombre**        | Resolución (cambio, reembolso o rechazo) |
| **Funcionalidad** | F3 — Devoluciones y cambios              |
| **Módulo**        | M2 — Postventa                           |
| **Responsable**   | Joseph                                   |
| **Tipo**          | Especificación funcional                 |

---

## 2. Propósito

Definir el comportamiento para evaluar y resolver una solicitud de devolución previamente registrada.

La especificación establece las condiciones para aprobar o rechazar la solicitud y, en caso de aprobación, determinar si corresponde realizar un cambio de producto o iniciar un reembolso.

---

## 3. Alcance

Esta especificación comprende:

* Consulta y evaluación de una solicitud de devolución.
* Validación de las condiciones necesarias para resolverla.
* Cambio del estado de la solicitud a `EN_EVALUACION`.
* Resolución mediante cambio de producto.
* Resolución mediante reembolso.
* Rechazo de la solicitud con un motivo obligatorio.
* Registro del resultado de la evaluación.
* Coordinación con Productos, Despacho y F4 cuando corresponda.
* Actualización del estado de la devolución.

El registro inicial de la devolución y su evidencia corresponden a **ESP-07**.

La ejecución del reembolso corresponde a **F4 — Reembolsos y extornos**, mediante la interfaz definida entre módulos.

---

## 4. Actores y responsabilidades

| Actor               | Responsabilidad                                                                   |
| ------------------- | --------------------------------------------------------------------------------- |
| **Gestor**          | Evalúa la solicitud y determina si corresponde aprobarla o rechazarla.            |
| **M2 — Postventa**  | Gestiona el expediente, valida las reglas de resolución y mantiene su estado.     |
| **Productos — F**   | Valida la disponibilidad de stock cuando se solicita un cambio (`GET /api/v1/inventario/disponibilidad`, no vinculante), reserva el stock de la unidad de reemplazo (misma reserva que 1.1, la pide M1, ver `M1 — Ciclo de vida del pedido` abajo) y reintegra al inventario la(s) unidad(es) devuelta(s) — solo las físicamente recibidas y aptas, solo después de que M2 confirme la recepción física (acuerdo 2026-10-13, ver `integraciones/ACUERDO_G6_PRODUCTOS.md`). |
| **M1 — Ciclo de vida del pedido** | **Ejecuta el cambio** — desde 2026-10-16 (acuerdo con Productos, issue G6 #100): M2 le pide una orden de reemplazo (`POST /api/v1/pedidos/reemplazos`, `api-ventas.md` 1.11) y M1 crea un pedido nuevo sin cobro, reserva el stock y lo despacha por su flujo normal de F1. M2 **ya no coordina directo con Despacho** — solo recibe los eventos `pedido.anulado`/`pedido.entregado` de esa orden. |
| **Despacho — E**    | Despacha el producto de reemplazo como cualquier pedido (no distingue un reemplazo de una venta) — ya no recibe una coordinación aparte desde M2.                       |
| **Gestor / almacén** | Confirma la recepción física de la unidad devuelta y su aptitud para reventa — paso obligatorio antes de solicitar el reintegro, distinto del dictamen comercial de la resolución (ver sección 9, reglas 14-16). |
| **F4 — Reembolsos** | Procesa el reembolso cuando la resolución corresponde a una devolución de dinero. |

> **Nota:** M2 coordina las operaciones mediante las interfaces definidas entre módulos y no modifica directamente los datos internos de otros módulos.

---

## 5. Precondiciones

Antes de resolver una devolución se debe cumplir lo siguiente:

1. La solicitud debe existir.
2. La solicitud debe encontrarse en estado `SOLICITADA` o `EN_EVALUACION`.
3. El Gestor debe estar autenticado y autorizado para evaluar la solicitud.
4. La solicitud debe contener la información necesaria para su evaluación.
5. El pedido asociado debe corresponder a una solicitud válida de devolución.
6. Cuando corresponda a un defecto o incidencia, la evidencia requerida debe encontrarse registrada.

---

## 6. Disparador

El proceso se inicia cuando el Gestor selecciona una solicitud de devolución pendiente de evaluación.

```text
Gestor
   │
   ▼
Consulta solicitud
   │
   ▼
Inicia evaluación
   │
   ▼
EN_EVALUACION
   │
   ├───────────────┐
   ▼               ▼
APROBADA        RECHAZADA
   │
   ├───────────────┐
   ▼               ▼
CAMBIO          REEMBOLSO
   │               │
   ▼               ▼
COMPLETADA      F4 — Reembolso
```

---

## 7. Flujo funcional

### 7.1 Flujo principal

1. El Gestor consulta una solicitud de devolución registrada.
2. El sistema verifica que la solicitud pueda ser evaluada.
3. La solicitud pasa al estado `EN_EVALUACION`.
4. El sistema muestra la información del pedido, motivo, descripción y evidencia disponible.
5. El Gestor analiza la solicitud.
6. El Gestor selecciona una resolución:

   * `CAMBIO`
   * `REEMBOLSO`
   * `RECHAZO`
7. Si selecciona `CAMBIO`, el sistema solicita la validación de disponibilidad de stock.
8. Si selecciona `REEMBOLSO`, el sistema genera una solicitud hacia F4.
9. Si selecciona `RECHAZO`, el Gestor debe proporcionar un motivo.
10. El sistema registra la decisión, actor, fecha y resultado.
11. La solicitud se actualiza al estado correspondiente.
12. El sistema muestra la confirmación de la resolución.

### 7.2 Flujos alternativos

<details>
<summary><strong>A. La solicitud no puede ser evaluada</strong></summary>

1. El sistema consulta el estado actual de la solicitud.
2. Si la solicitud no se encuentra en un estado válido para evaluación, no permite iniciar la resolución.
3. El sistema informa que la solicitud no puede ser evaluada en su estado actual.
4. El proceso finaliza sin modificar la solicitud.

</details>

<details>
<summary><strong>B. Se aprueba un cambio de producto</strong></summary>

1. El Gestor selecciona `CAMBIO`.
2. M2 consulta a Productos una disponibilidad preliminar, informativa y no vinculante, de una nueva unidad del **mismo producto devuelto** (acuerdo 2026-10-13, ver `integraciones/ACUERDO_G6_PRODUCTOS.md`). Si no hay: `409 SIN_STOCK`, el Gestor puede derivar a `REEMBOLSO` o `RECHAZO` (regla 10). Un `CAMBIO` nunca es por un producto distinto — ver regla 17.
3. Si existe stock, se registra la resolución como `APROBADA`. Esto es **únicamente el dictamen comercial** del Gestor sobre la evidencia de `ESP-07` — por sí solo **no** autoriza el reintegro de inventario (ver regla 14) ni mueve el pedido de reemplazo.
4. M2 pide a M1 la **orden de reemplazo** (`POST /api/v1/pedidos/reemplazos`, `api-ventas.md` 1.11 — acuerdo con Productos, issue G6 #100, 2026-10-16): M1 crea un pedido nuevo sin cobro, hace la reserva real y autoritativa del stock (mismo mecanismo que 1.1, no la consulta preliminar del paso 2) y lo despacha por su flujo normal de F1 — M2 **ya no coordina directo con Despacho**.
5. Si Productos rechaza o vence esa reserva, M1 anula el reemplazo y avisa con `pedido.anulado` (`datos.devolucionId`): la devolución vuelve a `EN_EVALUACION` (no se cierra como fallida) — al resolverla otra vez (reintento idempotente, regla 18), se pide un reemplazo nuevo.
6. Cuando la unidad devuelta llega físicamente al almacén, el Gestor (o quien reciba en almacén, mismo rol `ADMIN_VENTAS`) **confirma la recepción física**: registra la cantidad recibida y la cantidad apta para reventa por línea. Solo en ese momento M2 solicita a Productos el reintegro (`POST /api/v1/inventario/reintegros`), únicamente por las unidades aptas, admitiendo reintegros parciales por línea/cantidad (ver regla 15).
7. Cuando M1 entrega el reemplazo avisa con `pedido.entregado` (`datos.devolucionId`); con eso y el reintegro ya confirmado, la solicitud pasa a `COMPLETADA`.

</details>

<details>
<summary><strong>C. No existe stock para el cambio</strong></summary>

1. El Gestor selecciona `CAMBIO`.
2. M2 consulta la disponibilidad de stock.
3. Productos informa que no existe disponibilidad.
4. El sistema informa la falta de stock al Gestor.
5. La solicitud no debe quedar bloqueada indefinidamente.
6. El Gestor puede derivar la resolución a `REEMBOLSO` o `RECHAZO`, según corresponda.

</details>

<details>
<summary><strong>D. Se aprueba un reembolso</strong></summary>

1. El Gestor selecciona `REEMBOLSO`.
2. M2 valida que la solicitud pueda generar un reembolso, y registra si la resolución **requiere devolución física** del producto o no (`requiereDevolucionFisica` — por defecto `true`; un reembolso puede no requerirla, ej. el cliente conserva un producto defectuoso que no vale la pena devolver, ver regla 16).
3. M2 envía la solicitud correspondiente a F4 — el reembolso de dinero **no depende** de que exista o se confirme la recepción física; son procesos independientes.
4. F4 procesa el reembolso según su propia especificación. Si F4 confirma el resultado exitoso, la solicitud puede pasar a `COMPLETADA` aunque el reintegro de inventario siga pendiente.
5. Si `requiereDevolucionFisica` es `true`: cuando la unidad llega físicamente, el Gestor/almacén confirma la recepción (cantidad recibida y apta por línea). Solo entonces M2 solicita a Productos el reintegro (`POST /api/v1/inventario/reintegros`), únicamente por las unidades aptas, admitiendo reintegros parciales (ver regla 15).
6. Si `requiereDevolucionFisica` es `false`, no se solicita confirmación de recepción ni reintegro — la solicitud puede quedar `COMPLETADA` sin movimiento de inventario.
7. M2 conserva la referencia de la operación de reembolso y, si aplica, la del reintegro.

</details>

<details>
<summary><strong>E. Se rechaza la solicitud</strong></summary>

1. El Gestor selecciona `RECHAZO`.
2. El sistema solicita el motivo del rechazo.
3. El Gestor registra el fundamento correspondiente.
4. El sistema valida que el motivo no esté vacío.
5. La solicitud pasa al estado `RECHAZADA`.
6. Se registra el actor, fecha, motivo y resultado.

</details>

<details>
<summary><strong>F. Error durante la resolución</strong></summary>

1. El sistema detecta un error durante la comunicación con una dependencia.
2. La resolución no debe registrarse como completada si la operación requerida no fue confirmada.
3. El sistema conserva la información necesaria para identificar el error.
4. El Gestor recibe una indicación de que la operación requiere revisión o reintento.

</details>

---

## 8. Datos

### 8.1 Datos de entrada

| Campo              | Tipo                 | Obligatorio | Descripción                                      |
| ------------------ | -------------------- | :---------: | ------------------------------------------------ |
| `devolucionId`     | UUID / identificador |      Sí     | Identificador de la devolución a resolver.       |
| `resolucion`       | Enumeración          |      Sí     | Tipo de resolución seleccionada.                 |
| `motivoResolucion` | Texto                | Condicional | Justificación de la decisión cuando corresponda. |
| `requiereDevolucionFisica` | Booleano | Condicional, solo `REEMBOLSO` | Si es `false`, no se espera ni se confirma recepción física de la unidad — por defecto `true` (ver regla 16). En `CAMBIO` siempre es `true`. |

~~`productoCambio` (producto solicitado para el cambio)~~ — **retirado 2026-10-16, decisión de PO:** un `CAMBIO` siempre reemplaza por una nueva unidad del mismo producto que el cliente devolvió (defecto, daño o producto incorrecto, ver catálogo cerrado de `MotivoDevolucion` en `ESP-07` 8.2) — nunca por un producto distinto (otra talla, color o modelo). El contrato real (`api-postventas.md` 2.5) nunca tuvo este campo, y así está implementado: `DevolucionService.resolver` verifica disponibilidad de `d.getItems()` (el producto devuelto), no de un producto elegido aparte. Ver regla 17.

### 8.2 Tipos de resolución

```text
CAMBIO
REEMBOLSO
RECHAZO
```

### 8.2b Confirmación de recepción física

Paso posterior a la resolución `APROBADA` (`CAMBIO` o `REEMBOLSO` con `requiereDevolucionFisica: true`), antes de solicitar el reintegro a Productos:

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `devolucionId` | UUID / identificador | Sí | Identificador de la devolución. |
| `lineas[].sku` | Texto | Sí | SKU de la línea recibida (el mismo que `items[].sku` del pedido original, ver `api-ventas.md` 1.3). |
| `lineas[].cantidadRecibida` | Entero | Sí | Unidades físicamente recibidas en almacén. |
| `lineas[].cantidadApta` | Entero | Sí | De las recibidas, cuántas son aptas para reventa (`cantidadApta` ≤ `cantidadRecibida`). |
| `evidencia` | Archivo / referencia | No | Evidencia adicional de la recepción (ej. foto del producto ya en almacén). |

Datos de salida: `devolucionId`, `recepcionConfirmada: true`, `fechaRecepcion`, `actor`, y por línea `sku`/`cantidadApta` — esto es lo que se traduce 1:1 en `lines[]` del `POST /api/v1/inventario/reintegros` (ver `integraciones/ACUERDO_G6_PRODUCTOS.md`). Solo se reintegra `cantidadApta`, nunca `cantidadRecibida` si hay unidades no aptas.

### 8.3 Datos de salida

Cuando la resolución se registra correctamente, el sistema debe devolver información que permita identificar la decisión tomada.

| Campo                 | Descripción                                          |
| --------------------- | ---------------------------------------------------- |
| `devolucionId`        | Identificador de la devolución.                      |
| `estado`              | Estado actual de la solicitud.                       |
| `resolucion`          | Decisión tomada.                                     |
| `motivoResolucion`    | Fundamento de la decisión cuando corresponda.        |
| `fechaResolucion`     | Fecha y hora de la decisión.                         |
| `actor`               | Gestor que realizó la resolución.                    |
| `referenciaOperacion` | Referencia al cambio o reembolso cuando corresponda. |

Ejemplo:

```json
{
  "devolucionId": "DEV-000123",
  "estado": "APROBADA",
  "resolucion": "REEMBOLSO",
  "fechaResolucion": "2026-09-22T15:30:00Z",
  "actor": "USR-0042",
  "referenciaOperacion": "REF-000789"
}
```

### 8.4 Datos persistidos

La resolución debe conservar como mínimo:

* Identificador de la devolución.
* Tipo de resolución.
* Estado resultante.
* Actor que realizó la resolución.
* Fecha y hora.
* Motivo o fundamento cuando corresponda.
* Referencia de la operación derivada, cuando corresponda.
* Resultado de la coordinación con otros módulos.

La información de trazabilidad debe mantenerse de acuerdo con **RNF-03 — Trazabilidad**.

---

## 9. Reglas de negocio

1. Solo pueden resolverse solicitudes existentes y válidas.
2. Una solicitud debe encontrarse en `SOLICITADA` o `EN_EVALUACION` para iniciar su evaluación.
3. Toda solicitud evaluada debe terminar en una resolución definida.
4. Las resoluciones permitidas son `CAMBIO`, `REEMBOLSO` o `RECHAZO`.
5. Un rechazo debe registrar obligatoriamente su motivo.
6. Un cambio requiere validación de disponibilidad de stock.
7. Un cambio aprobado se ejecuta como una orden de reemplazo pedida a M1 (`api-ventas.md` 1.11) — M1 coordina la reserva de stock y la logística de Despacho con su flujo normal de pedido; M2 no coordina directo con Despacho.
8. Un reembolso debe ser solicitado a F4 y no ejecutarse directamente desde M2.
9. Una solicitud no debe generar simultáneamente un cambio y un reembolso.
10. Si no existe stock para un cambio, la solicitud debe poder derivarse a reembolso o rechazo según la decisión del Gestor.
11. Una solicitud aprobada pasa a `COMPLETADA` cuando la operación correspondiente ha sido confirmada.
12. M2 no debe modificar directamente las tablas pertenecientes a otros módulos.
13. Toda resolución debe conservar la información necesaria para su trazabilidad.
14. **La aprobación comercial del Gestor (resolución `APROBADA`) nunca autoriza por sí sola el reintegro de inventario.** El reintegro solo se solicita después de confirmarse la recepción física de la unidad devuelta y su aptitud para reventa (sección 8.2b) — son dos pasos distintos, con su propio actor y registro.
15. El reintegro a Productos solo incluye las unidades `cantidadApta`, nunca las no recibidas o no aptas. Una recepción parcial (ej. 1 de 3 unidades) reintegra solo esa unidad; una recepción posterior de las 2 restantes es una confirmación y un reintegro aparte, no una repetición de la primera (ver `integraciones/ACUERDO_G6_PRODUCTOS.md`, idempotencia).
16. En `REEMBOLSO`, el reembolso de dinero (F4) no depende de la recepción física — son procesos independientes. Si `requiereDevolucionFisica` es `false`, la solicitud se completa sin esperar ninguna recepción ni solicitar reintegro.
17. **Un `CAMBIO` siempre es por una nueva unidad del mismo producto devuelto** — nunca por un producto distinto (otra talla, color o modelo). La disponibilidad se valida sobre ese mismo producto; no existe un campo para elegir uno diferente.
18. **Si M1 anula la orden de reemplazo de un `CAMBIO`** (Productos rechazó o venció la reserva), la devolución vuelve a `EN_EVALUACION` — no se cierra como `RECHAZADA` ni pierde la aprobación comercial ya dada. Al resolverla otra vez, M2 pide un reemplazo nuevo con una reserva nueva; repetir la misma aprobación mientras el reemplazo vigente no está confirmado reintenta la coordinación sin duplicar nada (idempotencia por `devolucionId`, `api-ventas.md` 1.11).

---

## 10. Validaciones y errores

| Validación            | Condición                            | Respuesta esperada                  |
| --------------------- | ------------------------------------ | ----------------------------------- |
| Autenticación         | Usuario no autenticado               | `401 Unauthorized`                  |
| Autorización          | Usuario sin permisos para resolver   | `403 Forbidden`                     |
| Solicitud inexistente | `devolucionId` no encontrado         | `404 Not Found`                     |
| Estado incorrecto     | Solicitud no resoluble               | `409 Conflict`                      |
| Resolución inválida   | Valor diferente de los permitidos    | `400 Bad Request`                   |
| Motivo de rechazo     | Rechazo sin fundamento               | `400 Bad Request`                   |
| Sin stock             | No existe disponibilidad para cambio | `409 Conflict`                      |
| Falla de F4           | No se confirma el reembolso          | Error controlado según contrato API |
| Falla de M1           | No se confirma la orden de reemplazo (`api-ventas.md` 1.11) | Error controlado según contrato API; reintentar la misma aprobación no duplica nada |

Los mensajes de error deben ser claros para el Gestor y no deben exponer información interna del sistema.

Ejemplo:

```json
{
  "error": "SIN_STOCK",
  "message": "No existe disponibilidad para realizar el cambio solicitado."
}
```

---

## 11. Estado y trazabilidad

### 11.1 Estados

El proceso de resolución utiliza los siguientes estados:

```text
SOLICITADA
     │
     ▼
EN_EVALUACION
     │
     ├───────────────┐
     ▼               ▼
 APROBADA         RECHAZADA
     │
     ├───────────────┐
     ▼               ▼
  CAMBIO         REEMBOLSO
     │               │
     ▼               ▼
COMPLETADA       COMPLETADA
```

El estado `RECHAZADA` finaliza el proceso de la solicitud.

### 11.2 Trazabilidad

La resolución debe permitir identificar:

* Quién realizó la evaluación.
* Qué decisión fue tomada.
* Cuándo se realizó.
* Qué motivo o fundamento se registró.
* Qué operación derivada se generó.
* Cuál fue el resultado de la resolución.

Los registros deben conservarse de acuerdo con **RNF-03 — Trazabilidad**.

---

## 12. Integraciones y API

La resolución puede requerir comunicación con otros módulos dependiendo de la decisión tomada.

### Validación de stock

```text
M2 — Postventa
      │
      │ GET /api/v1/inventario/disponibilidad (scope inventario:disponibilidad:leer)
      ▼
Productos — F
      │
      │ respuesta informativa, no vinculante
      ▼
M2
```

### Confirmación de recepción física y reintegro

```text
Gestor / almacén
      │
      │ confirma recepción (cantidadRecibida, cantidadApta por línea)
      ▼
M2 — Postventa
      │
      │ POST /api/v1/inventario/reintegros (solo cantidadApta)
      ▼
Productos — F
```

### Coordinación de cambio (orden de reemplazo, acuerdo con Productos issue G6 #100)

```text
M2 — Postventa
      │
      │ POST /api/v1/pedidos/reemplazos (api-ventas.md 1.11)
      ▼
M1 — Ciclo de vida del pedido
      │
      │ reserva stock (igual que 1.1) y despacha por su flujo normal
      ▼
Productos — F / Despacho — E
      │
      │ pedido.anulado o pedido.entregado (datos.devolucionId)
      ▼
M2
```

### Solicitud de reembolso

```text
M2 — Postventa
      │
      │ solicitud de reembolso
      ▼
F4 — Reembolsos
```

Una referencia para la resolución puede ser:

```http
PATCH /devoluciones/{id}/resolucion
```

Con un cuerpo similar a:

```json
{
  "resolucion": "REEMBOLSO"
}
```

Para un rechazo:

```json
{
  "resolucion": "RECHAZO",
  "motivoResolucion": "La evidencia presentada no permite validar el defecto."
}
```

> Las rutas, nombres de campos y estructuras definitivas deben mantenerse alineadas con `specs/api-contract.md`.

---

## 13. Criterios de aceptación

### CA-01 — Evaluación de solicitud

**DADO** una devolución en estado `SOLICITADA`.

**CUANDO** el Gestor inicia su evaluación.

**ENTONCES** la solicitud pasa a `EN_EVALUACION` y se muestra la información necesaria para tomar una decisión.

---

### CA-02 — Resolución mediante cambio

**DADO** una solicitud elegible para cambio y disponibilidad confirmada.

**CUANDO** el Gestor selecciona `CAMBIO`.

**ENTONCES** el sistema registra la aprobación y coordina el cambio con los módulos correspondientes.

---

### CA-03 — Resolución mediante reembolso

**DADO** una solicitud elegible para devolución de dinero.

**CUANDO** el Gestor selecciona `REEMBOLSO`.

**ENTONCES** M2 genera una solicitud hacia F4 y conserva la referencia de la operación.

---

### CA-04 — Rechazo

**DADO** una solicitud que no cumple las condiciones para ser aprobada.

**CUANDO** el Gestor selecciona `RECHAZO` e indica el fundamento.

**ENTONCES** el sistema registra la solicitud como `RECHAZADA` junto con el motivo correspondiente.

---

### CA-05 — Falta de stock

**DADO** una solicitud cuya resolución seleccionada es `CAMBIO`.

**CUANDO** Productos informa que no existe stock disponible.

**ENTONCES** el sistema informa la situación y permite derivar la solicitud a `REEMBOLSO` o `RECHAZO`.

---

### CA-06 — Trazabilidad de la resolución

**DADO** una solicitud que ha sido resuelta.

**CUANDO** se consulta su información.

**ENTONCES** deben estar disponibles el actor, fecha, resolución, motivo cuando corresponda y resultado de la operación.

---

### CA-07 — Sin reintegro antes de la recepción física

**DADO** una solicitud `APROBADA` (`CAMBIO` o `REEMBOLSO` con `requiereDevolucionFisica: true`).

**CUANDO** todavía no se registró la confirmación de recepción física (sección 8.2b).

**ENTONCES** el sistema no solicita el reintegro a Productos ni modifica inventario, aunque la resolución ya esté `APROBADA`.

---

### CA-08 — Reintegro parcial por unidades aptas

**DADO** una confirmación de recepción física con 3 unidades recibidas y solo 1 apta para reventa.

**CUANDO** M2 solicita el reintegro a Productos.

**ENTONCES** el reintegro incluye únicamente 1 unidad; las 2 no aptas no incrementan inventario.

---

### CA-09 — Reemplazo anulado reabre la devolución

**DADO** un `CAMBIO` `APROBADA` con una orden de reemplazo pedida a M1 (1.11).

**CUANDO** M1 avisa `pedido.anulado` con `datos.devolucionId` porque Productos rechazó o venció la reserva.

**ENTONCES** la devolución vuelve a `EN_EVALUACION` (no queda `RECHAZADA` ni `COMPLETADA`), y al resolverla otra vez se pide un reemplazo nuevo.

---

## 14. Trazabilidad

| Elemento                          | Referencia                                                                   |
| --------------------------------- | ---------------------------------------------------------------------------- |
| **Funcionalidad**                 | F3 — Devoluciones y cambios                                                  |
| **Especificación**                | ESP-08 — Resolución (cambio, reembolso o rechazo)                            |
| **Especificación previa**         | ESP-07 — Registro de devolución con evidencia                                |
| **RNF relacionados**              | RNF-03 — Trazabilidad; RNF-07 — Aislamiento; RNF-08 — Idempotencia           |
| **Wireframe**                     | `F3-devoluciones.md`                                                         |
| **Contrato API**                  | `api-contract.md`                                                            |
| **Especificaciones relacionadas** | ESP-09 — Solicitud de reembolso válido; ESP-10 — Auditoría de la transacción |

### Relación con F3

```text
F3 — Devoluciones y cambios
│
├── ESP-07 — Registro de devolución con evidencia
│
└── ESP-08 — Resolución
    ├── Cambio
    ├── Reembolso
    └── Rechazo
```
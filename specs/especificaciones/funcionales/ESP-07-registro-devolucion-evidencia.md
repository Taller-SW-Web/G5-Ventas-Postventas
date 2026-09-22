# ESP-07 — Registro de devolución con evidencia

## 1. Identificación

| Campo             | Detalle                              |
| ----------------- | ------------------------------------ |
| **Código**        | ESP-07                               |
| **Nombre**        | Registro de devolución con evidencia |
| **Funcionalidad** | F3 — Devoluciones y cambios          |
| **Módulo**        | M2 — Postventa                       |
| **Responsable**   | Joseph                               |
| **Tipo**          | Especificación funcional             |

---

## 2. Propósito

Definir el comportamiento para registrar y consultar una solicitud de devolución asociada a un pedido entregado.

La especificación establece las condiciones que debe cumplir la solicitud, los datos que se deben registrar, los estados iniciales y las validaciones necesarias para garantizar la trazabilidad del proceso.

---

## 3. Alcance

Esta especificación comprende:

* Registro de una nueva solicitud de devolución.
* Asociación de la devolución con un pedido existente.
* Validación del estado del pedido.
* Registro del motivo de devolución.
* Registro de evidencia cuando el motivo lo requiera.
* Consulta del estado de una solicitud de devolución.
* Registro de la información necesaria para su posterior evaluación.

La resolución de la devolución mediante cambio, reembolso o rechazo corresponde a **ESP-08**.

---

## 4. Actores y responsabilidades

| Actor                             | Responsabilidad                                                                       |
| --------------------------------- | ------------------------------------------------------------------------------------- |
| **Cliente**                       | Solicita la devolución, proporciona el motivo y adjunta evidencia cuando corresponda. |
| **Gestor**                        | Puede consultar y evaluar posteriormente la solicitud registrada.                     |
| **M2 — Postventa**                | Valida las condiciones de la solicitud, registra la devolución y mantiene su estado.  |
| **M1 — Ciclo de vida del pedido** | Proporciona la información necesaria para validar el pedido y su estado.              |

> **Nota:** M2 no modifica directamente los datos internos de M1. La consulta del pedido debe realizarse mediante la interfaz definida entre ambos módulos.

---

## 5. Precondiciones

Antes de registrar una devolución se debe cumplir lo siguiente:

1. El usuario debe estar autenticado.
2. El pedido indicado debe existir.
3. El pedido debe encontrarse en estado `ENTREGADO`.
4. El usuario debe tener autorización para solicitar la devolución del pedido.
5. El motivo de devolución debe haber sido proporcionado.
6. Si el motivo corresponde a un defecto o incidencia que requiera comprobación, se debe adjuntar evidencia.
7. La solicitud debe encontrarse dentro del plazo permitido para devoluciones.

---

## 6. Disparador

El proceso se inicia cuando el cliente selecciona la opción **Solicitar devolución** desde la información de un pedido entregado.

```text
Cliente
   │
   ▼
Selecciona "Solicitar devolución"
   │
   ▼
Ingresa motivo y evidencia
   │
   ▼
M2 valida la solicitud
   │
   ▼
Se registra la devolución
```

---

## 7. Flujo funcional

### 7.1 Flujo principal

1. El cliente consulta uno de sus pedidos.
2. El sistema verifica que el pedido se encuentre en estado `ENTREGADO`.
3. El cliente selecciona la opción **Solicitar devolución**.
4. El sistema muestra el formulario de devolución.
5. El cliente selecciona el motivo de la devolución.
6. El cliente proporciona una descripción adicional cuando sea necesaria.
7. Si el motivo requiere evidencia, el cliente adjunta uno o más archivos.
8. El sistema valida que los datos obligatorios estén completos.
9. El sistema valida que el pedido pueda iniciar un proceso de devolución.
10. M2 registra la solicitud.
11. La solicitud recibe el estado inicial `SOLICITADA`.
12. El sistema genera un identificador para la devolución.
13. Se registra la fecha y hora de creación.
14. El sistema muestra al cliente la confirmación de la solicitud.

### 7.2 Flujos alternativos

<details>
<summary><strong>A. El pedido no está ENTREGADO</strong></summary>

1. El sistema consulta el estado actual del pedido.
2. Si el pedido no se encuentra en `ENTREGADO`, no permite registrar la devolución.
3. El sistema informa que la devolución solo puede solicitarse para pedidos entregados.
4. El proceso finaliza sin registrar una solicitud.

</details>

<details>
<summary><strong>B. Falta el motivo de devolución</strong></summary>

1. El sistema valida los campos obligatorios.
2. Detecta que el motivo no fue seleccionado.
3. Muestra un mensaje indicando que el motivo es obligatorio.
4. La solicitud no es registrada hasta completar el campo.

</details>

<details>
<summary><strong>C. El motivo requiere evidencia y no se adjunta</strong></summary>

1. El sistema identifica que el motivo seleccionado requiere evidencia.
2. Verifica que exista al menos un archivo adjunto.
3. Si no existe evidencia, muestra un mensaje indicando que debe adjuntarse.
4. La solicitud no es registrada.

</details>

<details>
<summary><strong>D. La devolución se encuentra fuera del plazo permitido</strong></summary>

1. El sistema consulta la fecha de entrega del pedido.
2. Calcula si la solicitud se encuentra dentro del plazo permitido.
3. Si el plazo ha vencido, rechaza el registro de la solicitud.
4. El sistema informa al cliente que la devolución se encuentra fuera del plazo permitido.

</details>

<details>
<summary><strong>E. Error durante el registro</strong></summary>

1. El sistema valida los datos recibidos.
2. Si ocurre un error durante la persistencia o comunicación con una dependencia, no debe generarse una devolución incompleta.
3. El sistema informa que no fue posible registrar la solicitud.
4. El cliente puede intentar nuevamente.

</details>

---

## 8. Datos

### 8.1 Datos de entrada

| Campo         | Tipo                 | Obligatorio | Descripción                                                      |
| ------------- | -------------------- | :---------: | ---------------------------------------------------------------- |
| `pedidoId`    | UUID / identificador |      Sí     | Identificador del pedido asociado.                               |
| `motivo`      | Enumeración          |      Sí     | Motivo seleccionado para solicitar la devolución.                |
| `descripcion` | Texto                |      No     | Explicación adicional proporcionada por el cliente.              |
| `evidencia`   | Archivo / referencia | Condicional | Evidencia asociada a la devolución cuando el motivo lo requiera. |

### 8.2 Motivos de devolución

Los motivos deben manejarse mediante valores definidos por el sistema. Como mínimo, deben permitir distinguir los casos que requieren evidencia de aquellos que no.

Ejemplo:

```text
PRODUCTO_DEFECTUOSO
PRODUCTO_DANADO
PRODUCTO_INCORRECTO
OTRO
```

> Los valores definitivos deben mantenerse consistentes con el modelo de datos y el contrato de API del módulo.

### 8.3 Datos de salida

Cuando la solicitud se registra correctamente, el sistema debe devolver información que permita identificar y consultar la devolución.

| Campo           | Descripción                                                |
| --------------- | ---------------------------------------------------------- |
| `devolucionId`  | Identificador único de la solicitud.                       |
| `pedidoId`      | Pedido asociado.                                           |
| `estado`        | Estado actual de la devolución. Inicialmente `SOLICITADA`. |
| `motivo`        | Motivo registrado.                                         |
| `fechaCreacion` | Fecha y hora de creación.                                  |
| `evidencia`     | Referencia a la evidencia registrada, si corresponde.      |

Ejemplo de respuesta:

```json
{
  "devolucionId": "DEV-000123",
  "pedidoId": "PED-000456",
  "estado": "SOLICITADA",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "fechaCreacion": "2026-09-20T15:30:00Z"
}
```

### 8.4 Datos persistidos

La solicitud debe conservar como mínimo:

* Identificador de la devolución.
* Identificador del pedido.
* Identificador del cliente.
* Motivo de devolución.
* Descripción proporcionada.
* Evidencia asociada, cuando corresponda.
* Estado actual.
* Fecha y hora de creación.
* Información necesaria para identificar al usuario que realizó la solicitud.

La información de trazabilidad debe mantenerse de acuerdo con **RNF-03 — Trazabilidad**.

---

## 9. Reglas de negocio

1. Solo pueden registrarse devoluciones asociadas a pedidos existentes.
2. El pedido debe encontrarse en estado `ENTREGADO`.
3. El motivo de devolución es obligatorio.
4. Los motivos que correspondan a defectos o incidencias que requieran comprobación deben contar con evidencia.
5. La solicitud debe encontrarse dentro del plazo permitido.
6. Toda nueva devolución debe iniciar en estado `SOLICITADA`.
7. Una devolución registrada debe poder ser consultada posteriormente mediante su identificador.
8. El registro de una devolución no implica automáticamente la aprobación del cambio o reembolso.
9. La resolución de la devolución se realiza mediante el proceso definido en **ESP-08**.
10. M2 no debe modificar directamente las tablas pertenecientes a M1.
11. Las operaciones deben conservar la información necesaria para mantener la trazabilidad de la solicitud.

---

## 10. Validaciones y errores

| Validación           | Condición                                  | Respuesta esperada                  |
| -------------------- | ------------------------------------------ | ----------------------------------- |
| Autenticación        | Usuario no autenticado                     | `401 Unauthorized`                  |
| Autorización         | El usuario no puede operar sobre el pedido | `403 Forbidden`                     |
| Pedido inexistente   | `pedidoId` no encontrado                   | `404 Not Found`                     |
| Estado incorrecto    | Pedido diferente de `ENTREGADO`            | `409 Conflict`                      |
| Motivo obligatorio   | `motivo` vacío o ausente                   | `400 Bad Request`                   |
| Evidencia requerida  | Motivo que requiere evidencia sin archivo  | `400 Bad Request`                   |
| Plazo vencido        | Solicitud fuera del periodo permitido      | `409 Conflict`                      |
| Error de dependencia | Fallo al consultar M1 u otra dependencia   | Error controlado según contrato API |

Los mensajes de error deben ser claros para el usuario y no deben exponer información interna del sistema.

Ejemplo:

```json
{
  "error": "PEDIDO_NO_ENTREGADO",
  "message": "No es posible solicitar una devolución porque el pedido aún no ha sido entregado."
}
```

---

## 11. Estado y trazabilidad

### 11.1 Estado inicial

Toda solicitud creada correctamente debe iniciar en:

```text
SOLICITADA
```

El flujo posterior de la devolución se desarrolla en **ESP-08**.

### 11.2 Trazabilidad

El registro debe permitir identificar:

* Quién realizó la solicitud.
* Qué pedido está asociado.
* Cuándo se registró.
* Qué motivo fue seleccionado.
* Qué evidencia fue adjuntada.
* Qué estado tiene actualmente la solicitud.

Los cambios posteriores del proceso deben conservar su correspondiente registro de acuerdo con **RNF-03 — Trazabilidad**.

---

## 12. Integraciones y API

La implementación debe utilizar las interfaces definidas para la comunicación entre módulos.

### Consulta del pedido

Antes de registrar una devolución, M2 necesita verificar la existencia y estado del pedido mediante la interfaz correspondiente de M1.

```text
M2 — Postventa
      │
      │ consulta pedido
      ▼
M1 — Ciclo de vida del pedido
      │
      │ pedido + estado
      ▼
M2
```

### Registro de devolución

El registro pertenece a M2 y debe realizarse mediante el endpoint definido para devoluciones.

Una referencia de contrato puede ser:

```http
POST /devoluciones
```

Con un cuerpo similar a:

```json
{
  "pedidoId": "PED-000456",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El producto presenta daños visibles.",
  "evidencia": [
    "evidencia-001.jpg"
  ]
}
```

> Las rutas, nombres de campos y estructuras definitivas deben mantenerse alineadas con `specs/api-contract.md`.

---

## 13. Criterios de aceptación

### CA-01 — Registro exitoso

**DADO** un cliente autenticado con un pedido en estado `ENTREGADO`.

**CUANDO** registra un motivo válido y proporciona la evidencia requerida.

**ENTONCES** el sistema crea la solicitud de devolución con estado `SOLICITADA`.

---

### CA-02 — Pedido no entregado

**DADO** un pedido que no se encuentra en estado `ENTREGADO`.

**CUANDO** el cliente intenta registrar una devolución.

**ENTONCES** el sistema rechaza la solicitud y muestra el motivo del rechazo.

---

### CA-03 — Motivo obligatorio

**DADO** un pedido elegible para devolución.

**CUANDO** el cliente intenta enviar el formulario sin seleccionar un motivo.

**ENTONCES** el sistema rechaza el registro e indica que el motivo es obligatorio.

---

### CA-04 — Evidencia obligatoria

**DADO** un pedido elegible y un motivo que requiere evidencia.

**CUANDO** el cliente intenta registrar la devolución sin adjuntar evidencia.

**ENTONCES** el sistema rechaza la solicitud e indica que debe adjuntarse la evidencia correspondiente.

---

### CA-05 — Identificación de la devolución

**DADO** una solicitud registrada correctamente.

**CUANDO** finaliza el proceso de creación.

**ENTONCES** el sistema devuelve un identificador único que permite consultar la devolución posteriormente.

---

### CA-06 — Trazabilidad

**DADO** una devolución registrada.

**CUANDO** se consulta su información.

**ENTONCES** deben estar disponibles los datos necesarios para identificar el pedido, usuario, fecha, motivo y estado de la solicitud.

---

## 14. Trazabilidad

| Elemento                       | Referencia                                                         |
| ------------------------------ | ------------------------------------------------------------------ |
| **Funcionalidad**              | F3 — Devoluciones y cambios                                        |
| **Especificación**             | ESP-07 — Registro de devolución con evidencia                      |
| **RNF relacionados**           | RNF-03 — Trazabilidad; RNF-07 — Aislamiento                        |
| **Wireframe**                  | [`F3-devoluciones.md`](../../diseno/wireframes/F3-devoluciones.md) |
| **Contrato API**               | [`api-contract.md`](../api-contract.md)                            |
| **Especificación relacionada** | ESP-08 — Resolución de devolución                                  |

### Relación con F3

```text
F3 — Devoluciones y cambios
│
├── ESP-07 — Registro de devolución con evidencia
│
└── ESP-08 — Resolución: cambio, reembolso o rechazo
```
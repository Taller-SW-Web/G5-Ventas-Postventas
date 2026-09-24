# ESP-14 — Formato y evidencia de atención

**Funcionalidad:** F6 — Reclamos, dashboard y reportes  
**Referencia:** SPEC-20 / RF-14  
**Microservicio:** M2 — Postventa  
**Responsable:** Fabrizio  
**Estado:** En especificación

## 1. Propósito

Registrar la respuesta formal emitida por el Gestor para un reclamo, hacerla visible al consumidor, actualizar el expediente al estado `ATENDIDO` y conservar el timestamp de la atención como evidencia para auditar el cumplimiento del SLA.

## 2. Contrato de API

- **Método y endpoint:** `PATCH /api/v2/reclamos/{reclamoId}/respuesta`
- **Autenticación:** `Authorization: Bearer <token_gestor>`
- **Parámetro de ruta:** `reclamoId`, identificador del reclamo que será atendido.
- **Content-Type:** `application/json`
- **Resultado exitoso:** `200 OK`

## 3. Datos de entrada

| Campo | Tipo | Obligatorio | Regla |
|---|---|---:|---|
| `nuevoEstado` | string | Sí | Para registrar correctamente la respuesta y cerrar la atención debe ser `ATENDIDO`. |
| `respuestaVisibleCliente` | string | Sí | Respuesta formal redactada por el Gestor. No puede ser nula ni vacía y será visible para el consumidor cuando consulte su reclamo. |
| `atendidoPor` | string | Sí | Identificador del Gestor que emite y registra la respuesta, por ejemplo `GESTOR-02`; se conserva para la trazabilidad de la atención. |

El nombre del campo de respuesta debe mantenerse exactamente como `respuestaVisibleCliente` en el request, la persistencia y las respuestas expuestas por la API.

## 4. Resultado de la operación

Cuando la operación se registra correctamente:

1. El expediente pasa al estado `ATENDIDO`.
2. Se almacena `respuestaVisibleCliente` como respuesta formal del Gestor que el consumidor podrá consultar posteriormente.
3. Se conserva `atendidoPor` para identificar al Gestor responsable de la atención.
4. Se registra la fecha y hora de la respuesta en UTC para auditar si la atención se realizó antes o después de `fechaLimiteSLA`.
5. La respuesta del endpoint expone este timestamp mediante el campo `fechaRespuesta`, conforme a `specs/api-contract.md`.

## 5. Validaciones

1. La solicitud debe incluir un token válido correspondiente a un Gestor.
2. `reclamoId` debe identificar el expediente que se pretende responder.
3. `nuevoEstado` es obligatorio y debe ser `ATENDIDO` para completar esta operación.
4. `respuestaVisibleCliente` es obligatorio y no puede ser nulo, vacío ni contener únicamente una ausencia de contenido efectivo.
5. `atendidoPor` es obligatorio y debe identificar al Gestor que realiza la atención.
6. La actualización debe respetar el ciclo de vida definido para el reclamo antes de establecer `ATENDIDO`.
7. Si `respuestaVisibleCliente` está vacío o es nulo, la operación se rechaza con `400 Bad Request` y el reclamo no se marca como `ATENDIDO`.
8. Solo después de superar las validaciones se persisten la respuesta formal, el Gestor responsable y el timestamp de atención.

## 6. Evidencia y auditoría de la atención

La evidencia de atención está compuesta por:

- El identificador del reclamo (`reclamoId`).
- El estado final `ATENDIDO`.
- El contenido de `respuestaVisibleCliente`.
- El identificador del Gestor registrado en `atendidoPor`.
- El timestamp UTC de la respuesta, expuesto como `fechaRespuesta` por este endpoint.
- La relación temporal entre el timestamp de respuesta y `fechaLimiteSLA`, utilizada para determinar el cumplimiento o la excedencia del SLA de 15 días hábiles.

`respuestaVisibleCliente` no es una nota interna: es el dictamen o comunicación formal que el consumidor podrá ver al consultar el estado de su reclamo.

## 7. Ejemplo de request

```json
{
  "nuevoEstado": "ATENDIDO",
  "respuestaVisibleCliente": "Texto formal de respuesta que el consumidor podrá ver en la consulta de su reclamo",
  "atendidoPor": "GESTOR-02"
}
```

## 8. Ejemplo de response

### `200 OK`

```json
{
  "reclamoId": "REC-2026-0015",
  "estado": "ATENDIDO",
  "fechaRespuesta": "2026-09-23T00:18:00Z",
  "respuestaVisibleCliente": "Estimado Juan, lamentamos la demora. Se ha coordinado la entrega prioritaria y se ha aplicado una bonificación a su cuenta."
}
```

### `400 Bad Request`

Se devuelve cuando `respuestaVisibleCliente` está vacío o es nulo.

## 9. Criterios de aceptación

### CA-01. Atención correcta

- **DADO** un reclamo que puede ser atendido y un Gestor autenticado.
- **CUANDO** se invoca `PATCH /api/v2/reclamos/{reclamoId}/respuesta` con `nuevoEstado: ATENDIDO`, `respuestaVisibleCliente` no vacío y `atendidoPor` informado.
- **ENTONCES** el sistema registra la respuesta formal, actualiza el estado a `ATENDIDO` y responde `200 OK`.

### CA-02. Respuesta visible para el consumidor

- **DADO** un reclamo atendido correctamente.
- **CUANDO** el consumidor consulta su expediente.
- **ENTONCES** puede ver exactamente la respuesta formal almacenada en `respuestaVisibleCliente`.

### CA-03. Rechazo de respuesta vacía

- **DADO** un request con `respuestaVisibleCliente` nulo o vacío.
- **CUANDO** el Gestor intenta completar la atención.
- **ENTONCES** el sistema responde `400 Bad Request` y no actualiza el reclamo a `ATENDIDO`.

### CA-04. Auditoría del SLA

- **DADO** un reclamo con `fechaLimiteSLA` calculada.
- **CUANDO** se registra correctamente la respuesta.
- **ENTONCES** el sistema conserva el timestamp UTC de atención y permite compararlo con `fechaLimiteSLA` para determinar si el SLA de 15 días hábiles fue cumplido o excedido.

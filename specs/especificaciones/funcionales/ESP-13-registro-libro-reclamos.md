# ESP-13 — Registro del Libro de Reclamaciones

**Funcionalidad:** F6 — Reclamos, dashboard y reportes  
**Referencia:** SPEC-19 / RF-13  
**Microservicio:** M2 — Postventa  
**Responsable:** Fabrizio  
**Estado:** En especificación

## 1. Propósito

Registrar un reclamo o una queja en el Libro de Reclamaciones, asignarle un identificador y código de seguimiento correlativos, establecer `REGISTRADO` como estado inicial y calcular el plazo máximo de atención de 15 días hábiles mediante el campo `fechaLimiteSLA`.

## 2. Contrato de API

- **Método y endpoint:** `POST /api/v2/reclamos`
- **Autenticación:** `Authorization: Bearer <token_canal_o_cliente>`
- **Content-Type:** `application/json`
- **Resultado exitoso:** `201 Created`

## 3. Datos de entrada

| Campo | Tipo | Obligatorio | Regla |
|---|---|---:|---|
| `pedidoId` | string | No | Identificador del pedido relacionado. Es opcional cuando se registra una queja general no asociada a un pedido. |
| `tipo` | string | Sí | Solo admite `RECLAMO` o `QUEJA`. |
| `canal` | string | Sí | Solo admite `CHATBOT`, `WEB` o `RETAIL`. |
| `motivo` | string | Sí | Debe pertenecer al catálogo de motivos permitido. |
| `detalle` | string | Sí | Descripción detallada de la disconformidad comunicada por el consumidor; no puede estar vacío. |
| `consumidor` | object | Sí | Datos necesarios para identificar y contactar al consumidor. |
| `consumidor.nombreCompleto` | string | Sí | Nombre completo del consumidor; no puede ser nulo ni vacío. |
| `consumidor.documento` | string | Sí | Documento de identidad del consumidor; no puede ser nulo ni vacío. |
| `consumidor.email` | string | Sí | Correo electrónico de contacto; no puede ser nulo ni vacío. |
| `consumidor.telefono` | string | Sí | Número telefónico de contacto; no puede ser nulo ni vacío. |

El contrato vigente no define longitudes ni expresiones regulares adicionales para los campos de `consumidor`; por lo tanto, esta especificación no incorpora restricciones de formato que no estén respaldadas por `specs/api-contract.md`.

### 3.1. Valores permitidos para `tipo`

- `RECLAMO`
- `QUEJA`

### 3.2. Valores permitidos para `canal`

- `CHATBOT`
- `WEB`
- `RETAIL`

### 3.3. Motivos permitidos

- `INCUMPLIMIENTO_PLAZO_ENTREGA`
- `PRODUCTO_DEFECTUOSO_O_INCORRECTO`
- `COBRO_INDEBIDO_O_NO_RECONOCIDO`
- `ATENCION_INADECUADA`
- `INCUMPLIMIENTO_GARANTIA`

## 4. Estados del reclamo

Los estados admitidos para el ciclo de vida del reclamo son:

- `REGISTRADO`
- `EN_PROCESO`
- `ATENDIDO`
- `DERIVADO`

Todo reclamo o queja creado correctamente inicia obligatoriamente en estado `REGISTRADO`. El flujo principal definido por F6 es `REGISTRADO → EN_PROCESO → ATENDIDO`; `DERIVADO` representa la rama de escalamiento prevista por la funcionalidad.

## 5. Identificación y seguimiento

Al registrar el expediente, el sistema genera un identificador `reclamoId` y un `codigoSeguimiento`. El formato correlativo ya definido en el repositorio es `REC-YYYY-XXXX`, por ejemplo `REC-2026-0015`.

El código debe ser único y permitir la consulta posterior del expediente. La respuesta de creación devuelve tanto `reclamoId` como `codigoSeguimiento`, de acuerdo con el contrato de API vigente.

## 6. SLA de atención

- El plazo de respuesta es de **15 días hábiles**.
- El plazo se calcula al registrar correctamente el reclamo o la queja.
- El resultado del cálculo se almacena en `fechaLimiteSLA`.
- `fechaLimiteSLA` se representa como timestamp ISO-8601 en UTC, conforme a las convenciones generales del contrato de API.
- La respuesta de creación informa `plazoDiasHabiles: 15` y el valor calculado de `fechaLimiteSLA`.
- `fechaLimiteSLA` se conserva para auditar posteriormente si la atención se realizó dentro o fuera del plazo.

## 7. Validaciones

1. La solicitud debe incluir un token válido de canal o cliente.
2. `tipo` debe corresponder a uno de los valores permitidos.
3. `canal` debe corresponder a uno de los valores permitidos.
4. `motivo` es obligatorio y debe pertenecer al catálogo definido.
5. `detalle` es obligatorio y no puede estar vacío.
6. `consumidor` es obligatorio y debe incluir `nombreCompleto`, `documento`, `email` y `telefono` con valores no nulos ni vacíos.
7. `pedidoId` puede omitirse cuando el expediente corresponda a una queja general.
8. El sistema no debe generar el identificador ni registrar el expediente cuando los datos obligatorios del consumidor estén incompletos o el motivo no sea válido.
9. Después de superar las validaciones, el sistema debe asignar el código correlativo, fijar el estado inicial `REGISTRADO`, calcular `fechaLimiteSLA` y persistir el expediente.

Cuando los datos del consumidor estén incompletos o el motivo no esté tipificado, el contrato establece una respuesta `400 Bad Request`.

## 8. Ejemplo de request

```json
{
  "pedidoId": "PED-2026-00981",
  "tipo": "RECLAMO",
  "canal": "CHATBOT",
  "motivo": "INCUMPLIMIENTO_PLAZO_ENTREGA",
  "detalle": "Descripción detallada del consumidor",
  "consumidor": {
    "nombreCompleto": "Juan Pérez",
    "documento": "72458912",
    "email": "juan.perez@example.com",
    "telefono": "+51999888777"
  }
}
```

## 9. Ejemplo de response

### `201 Created`

```json
{
  "reclamoId": "REC-2026-0015",
  "codigoSeguimiento": "REC-2026-0015",
  "estado": "REGISTRADO",
  "motivo": "INCUMPLIMIENTO_PLAZO_ENTREGA",
  "plazoDiasHabiles": 15,
  "fechaLimiteSLA": "2026-10-14T23:59:59Z",
  "respuestaVisibleCliente": null
}
```

### `400 Bad Request`

Se devuelve cuando los datos del consumidor están incompletos o `motivo` no pertenece al catálogo permitido.

## 10. Criterios de aceptación

### CA-01. Registro exitoso

- **DADO** un request con los campos obligatorios y valores permitidos.
- **CUANDO** se invoca `POST /api/v2/reclamos`.
- **ENTONCES** el sistema registra el expediente, genera `reclamoId` y `codigoSeguimiento`, fija `REGISTRADO` como estado inicial y responde `201 Created`.

### CA-02. Queja general sin pedido

- **DADO** un request con `tipo` igual a `QUEJA` y sin `pedidoId`.
- **CUANDO** los demás datos obligatorios son válidos.
- **ENTONCES** el sistema registra la queja sin exigir un pedido asociado.

### CA-03. Cálculo del SLA

- **DADO** un reclamo o una queja válidos.
- **CUANDO** se registra el expediente.
- **ENTONCES** el sistema establece un plazo de 15 días hábiles y almacena el resultado en `fechaLimiteSLA` como timestamp UTC.

### CA-04. Rechazo de datos inválidos

- **DADO** un request con datos obligatorios del consumidor incompletos o un motivo no tipificado.
- **CUANDO** se intenta registrar el expediente.
- **ENTONCES** el sistema responde `400 Bad Request` y no crea el reclamo ni su código de seguimiento.

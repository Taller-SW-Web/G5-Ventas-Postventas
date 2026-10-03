# Contrato de API (OpenAPI / REST) --- Microservicio M2: Postventa

**Versión:** 1.4.0

**Fecha:** Septiembre 2026

**Servicio:** M2 (Postventa)

**Audiencia:** `api-postventa`

**Convenciones generales:**

-   Formato de datos: `application/json; charset=utf-8`
-   Timestamps: ISO-8601 en UTC (`YYYY-MM-DDTHH:mm:ssZ`)
-   Autenticación: Cabecera HTTP `Authorization: Bearer <JWT>`
-   Estándar de errores:

``` json
{
  "codigo": "RECURSO_NO_ENCONTRADO",
  "mensaje": "Descripción legible del error",
  "timestamp": "2026-09-23T00:05:00Z",
  "detalles": []
}
```

## Catálogo de Scopes OAuth2 / JWT Expuestos por M2

-   **`postventa:devoluciones:escribir`**: Registro de solicitudes de
    devolución y subida de archivos adjuntos. Utilizado por Canales A, B
    y C.
-   **`postventa:devoluciones:leer`**: Consulta de expedientes de
    devolución y estado de trámite. Utilizado por Canales A, B y C.
-   **`postventa:reembolsos:procesar`**: Procesamiento de desembolsos
    monetarios originados exclusivamente por M1 (`ANULACION`) o M2
    (`DEVOLUCION`). Utilizado por M1 y M2 internamente.
-   **`postventa:reclamos:escribir`**: Registro formal de reclamos y
    quejas en el Libro de Reclamaciones. Utilizado por Canales A, B y C.
-   **`postventa:reclamos:leer`**: Consulta pública del estado y la
    respuesta formal visible del reclamo. Utilizado por Canales A, B y
    C.
-   **`postventa:csat:escribir`**: Envío de calificaciones de
    satisfacción de compra. Utilizado por Canales A, B y C.
-   **`ventas:admin`**: Gestión administrativa completa (dictamen de
    devoluciones, emisión de respuesta formal a reclamos y métricas de
    dashboard). Utilizado por Backoffice / Gestor.

## Endpoints de M2

### F3: Devoluciones y Cambios (Responsable: Joseph)

#### 2.1 Subir Evidencia Multimedia de Devolución

-   **Endpoint:** `POST /api/v2/devoluciones/evidencias/upload`
-   **Descripción:** Permite subir un archivo fotográfico o documento de
    soporte antes de registrar la solicitud. Retorna la URL que debe
    incluirse en el arreglo `evidencias` del expediente.
-   **Headers:**
    -   `Authorization: Bearer <token_canal_o_cliente>`
    -   `Content-Type: multipart/form-data`
-   **Request Body (multipart/form-data):**
    -   `file`: Archivo binario adjunto (Formatos: `image/jpeg`,
        `image/png`, `image/webp`, `application/pdf`. Máximo 5 MB).
-   **Respuestas:**
    -   **`201 Created`**

``` json
{
  "tipo": "IMAGEN",
  "url": "https://api.empresa.com/v2/uploads/evidencias/ev-981-foto1.jpg",
  "nombreArchivoOriginal": "evidencia_pantalla.jpg",
  "tamanioBytes": 1048576,
  "fechaSubida": "2026-09-23T15:50:00Z"
}
```

-   **`400 Bad Request`**: Formato no admitido o tamaño mayor a 5 MB.

#### 2.2 Registrar Expediente de Devolución / Cambio

-   **Endpoint:** `POST /api/v2/devoluciones`
-   **Descripción:** Crea un expediente de devolución o cambio tras la
    entrega. Valida vía API con M1 que el pedido exista y se encuentre
    en estado `ENTREGADO`.
-   **Headers:**
    -   `Authorization: Bearer <token_canal_o_cliente>`
    -   `Content-Type: application/json`
-   **Request Body:**

``` json
{
  "pedidoId": "PED-2026-00981",
  "tipo": "DEVOLUCION_DINERO",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El auricular izquierdo no emite sonido y no carga en el estuche",
  "items": [
    {
      "productoId": "PROD-101",
      "cantidad": 1
    }
  ],
  "evidencias": [
    {
      "tipo": "IMAGEN",
      "url": "https://api.empresa.com/v2/uploads/evidencias/ev-981-foto1.jpg"
    }
  ]
}
```

-   **Respuestas:**
    -   **`201 Created`**

``` json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "tipo": "DEVOLUCION_DINERO",
  "estado": "SOLICITADA",
  "fechaRegistro": "2026-09-23T15:51:00Z"
}
```

-   **`400 Bad Request`**: Evidencias visuales faltantes o plazo
    excedido (\> 7 días naturales).
-   **`409 Conflict`**: El pedido no se encuentra en estado `ENTREGADO`.

#### 2.3 Consultar Expediente de Devolución por ID

-   **Endpoint:** `GET /api/v2/devoluciones/{devolucionId}`
-   **Descripción:** Consulta el detalle, estado del expediente y, en
    caso de resolución monetaria, la trazabilidad del reembolso generado
    en F4.
-   **Headers:** `Authorization: Bearer <token>`
-   **Parámetros Path:** `devolucionId` (string, ej. `DEV-2026-0042`)
-   **Respuestas:**
    -   **`200 OK` (Aprobada con reembolso):**

``` json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "clienteId": "CLI-8841",
  "tipo": "DEVOLUCION_DINERO",
  "estado": "APROBADA",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El auricular izquierdo no emite sonido",
  "resolucion": {
    "decision": "APROBADA",
    "fundamento": "Falla de fábrica confirmada en control de calidad",
    "autorizadorId": "GESTOR-03",
    "fechaResolucion": "2026-09-23T16:00:00Z",
    "reembolso": {
      "reembolsoId": "REEM-90812",
      "estado": "EXITOSO",
      "monto": 129.90,
      "moneda": "PEN",
      "transaccionPasarelaId": "TX-SIM-871239",
      "fechaEjecucion": "2026-09-23T16:01:10Z"
    }
  },
  "evidencias": [
    {
      "tipo": "IMAGEN",
      "url": "https://api.empresa.com/v2/uploads/evidencias/ev-981-foto1.jpg"
    }
  ],
  "fechaRegistro": "2026-09-23T15:51:00Z"
}
```

-   **`200 OK` (En evaluación):**

``` json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "clienteId": "CLI-8841",
  "tipo": "DEVOLUCION_DINERO",
  "estado": "EN_EVALUACION",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El auricular izquierdo no emite sonido",
  "resolucion": null,
  "fechaRegistro": "2026-09-23T15:51:00Z"
}
```

-   **`404 Not Found`**: El expediente solicitado no existe.

#### 2.4 Listar Devoluciones por Cliente

-   **Endpoint:** `GET /api/v2/devoluciones`
-   **Headers:** `Authorization: Bearer <token>`
-   **Query Params:**
    -   `clienteId` (requerido para clientes): Identificador del
        cliente.
    -   `estado` (opcional):
        `SOLICITADA | EN_EVALUACION | APROBADA | RECHAZADA | COMPLETADA`
    -   `tipo` (opcional): `CAMBIO | DEVOLUCION_DINERO`
    -   `pagina` (opcional, default: `0`)
    -   `tamano` (opcional, default: `10`)
-   **Respuestas:**
    -   **`200 OK`**

``` json
{
  "clienteId": "CLI-8841",
  "contenido": [
    {
      "devolucionId": "DEV-2026-0042",
      "pedidoId": "PED-2026-00981",
      "tipo": "DEVOLUCION_DINERO",
      "estado": "APROBADA",
      "motivo": "PRODUCTO_DEFECTUOSO",
      "estadoReembolso": "EXITOSO",
      "fechaRegistro": "2026-09-23T15:51:00Z"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

#### 2.5 Resolver Expediente de Devolución

-   **Endpoint:** `PATCH /api/v2/devoluciones/{devolucionId}/resolucion`
-   **Descripción:** El Gestor aprueba o rechaza el expediente. Si es
    rechazo, exige fundamento no vacío. Si se aprueba con
    `tipo: DEVOLUCION_DINERO`, deriva la instrucción de reembolso a F4.
-   **Headers:** `Authorization: Bearer <token_gestor>`
-   **Request Body:**

``` json
{
  "decision": "RECHAZADA",
  "fundamento": "El equipo presenta signos evidentes de manipulación interna y sulfatación por agua",
  "autorizadorId": "GESTOR-03"
}
```

-   **Respuestas:**
    -   **`200 OK`**: Actualizado exitosamente.
    -   **`400 Bad Request`**: Rechazo sin fundamento explicativo.
    -   **`404 Not Found`**: Expediente no encontrado.

### F4: Reembolsos y Extornos (Responsable: Luis Alejandro)

#### 2.6 Procesar Solicitud de Reembolso

-   **Endpoint:** `POST /api/v2/reembolsos`
-   **Descripción:** Procesamiento monetario idempotente derivado formal
    y exclusivamente de **`ANULACION` (F2 de M1)** o **`DEVOLUCION` (F3
    de M2)**. Cumple con la garantía RNF-08 mediante clave de
    idempotencia obligatoria.
-   **Headers:**
    -   `Authorization: Bearer <token_servicio_o_gestor>`
    -   `X-Idempotency-Key: a4c89f55-1211-4fce-bc2a-605e55e396dc`
-   **Request Body:**

``` json
{
  "origen": "ANULACION",
  "referenciaId": "PED-2026-00981",
  "monto": 129.90,
  "moneda": "PEN",
  "motivo": "Entrega fallida definitiva en ruta; anulación tramitada por M1",
  "solicitadoPor": "SISTEMA_M1"
}
```

-   **Respuestas:**
    -   **`201 Created`**

``` json
{
  "reembolsoId": "REEM-90812",
  "transaccionPasarelaId": "TX-SIM-871239",
  "estado": "EXITOSO",
  "monto": 129.90,
  "moneda": "PEN",
  "fechaEjecucion": "2026-09-23T00:15:30Z"
}
```

-   **`400 Bad Request`**: Monto fuera de rango o estructura inválida.
-   **`403 Forbidden`**: Solicitud con origen no permitido (distinto de
    `ANULACION` o `DEVOLUCION`).
-   **`409 Conflict`**: Conflicto de idempotencia o fallo de pasarela.

### F5: Calificación de Experiencia / CSAT (Responsable: Johan)

#### 2.7 Registrar Encuesta CSAT

-   **Endpoint:** `POST /api/v2/csat`
-   **Request Body:**

``` json
{
  "pedidoId": "PED-2026-00981",
  "clienteId": "CLI-8841",
  "canal": "CHATBOT",
  "puntuacion": 5,
  "comentario": "Excelente tiempo de entrega y respuesta rápida"
}
```

-   **Respuestas:**
    -   **`201 Created`**: Encuesta guardada.
    -   **`400 Bad Request`**: Puntuación fuera de rango (1 al 5).
    -   **`409 Conflict`**: Encuesta ya registrada para ese pedido.

### F6: Reclamos y Dashboard (Responsable: Fabrizio)

#### 2.8 Registrar Reclamo (Libro de Reclamaciones)

-   **Endpoint:** `POST /api/v2/reclamos`
-   **Descripción:** Registra un reclamo formal según normativa Indecopi
    con plazo de respuesta de 15 días hábiles (A10).
-   **Headers:**
    -   `Authorization: Bearer <token_canal_o_cliente>`
    -   `Content-Type: application/json`
-   **Request Body:**

``` json
{
  "pedidoId": "PED-2026-00981",
  "tipo": "RECLAMO",
  "canal": "CHATBOT",
  "motivo": "INCUMPLIMIENTO_PLAZO_ENTREGA",
  "detalle": "El pedido no llegó en la fecha programada",
  "consumidor": {
    "nombreCompleto": "Juan Pérez",
    "documento": "72458912",
    "email": "juan.perez@example.com",
    "telefono": "+51999888777"
  }
}
```

-   **Respuestas:**
    -   **`201 Created`**

``` json
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

-   **`400 Bad Request`**: Datos incompletos del consumidor o motivo no
    tipificado.

#### 2.9 Consultar Reclamo por Código de Seguimiento

-   **Endpoint:** `GET /api/v2/reclamos/{codigoSeguimiento}`
-   **Descripción:** Permite consultar el estado actual y la respuesta
    formal visible emitida al reclamante (A10).
-   **Headers:** `Authorization: Bearer <token>`
-   **Parámetros Path:** `codigoSeguimiento` (string, ej.
    `REC-2026-0015`)
-   **Respuestas:**
    -   **`200 OK`**

``` json
{
  "reclamoId": "REC-2026-0015",
  "codigoSeguimiento": "REC-2026-0015",
  "pedidoId": "PED-2026-00981",
  "tipo": "RECLAMO",
  "canal": "CHATBOT",
  "motivo": "INCUMPLIMIENTO_PLAZO_ENTREGA",
  "detalle": "El pedido no llegó en la fecha programada",
  "estado": "ATENDIDO",
  "plazoDiasHabiles": 15,
  "fechaLimiteSLA": "2026-10-14T23:59:59Z",
  "fechaRegistro": "2026-09-23T00:10:00Z",
  "fechaAtencion": "2026-09-23T08:30:00Z",
  "respuestaVisibleCliente": "Estimado Juan, su reclamo fue atendido. Se coordinó la entrega prioritaria y se emitió una bonificación a su cuenta."
}
```

-   **`401 Unauthorized`**: Token ausente o inválido.
-   **`404 Not Found`**: Reclamo no encontrado con ese código de
    seguimiento.

#### 2.10 Listar Reclamos por Cliente / Consumidor

-   **Endpoint:** `GET /api/v2/reclamos`
-   **Headers:** `Authorization: Bearer <token>`
-   **Query Params:**
    -   `documento` (opcional): Número de documento de identidad del
        reclamante.
    -   `clienteId` (opcional): Identificador del cliente.
    -   `estado` (opcional):
        `REGISTRADO | EN_PROCESO | ATENDIDO | DERIVADO`
    -   `pagina` (opcional, default: `0`)
    -   `tamano` (opcional, default: `10`)
-   **Respuestas:**
    -   **`200 OK`**

``` json
{
  "contenido": [
    {
      "reclamoId": "REC-2026-0015",
      "codigoSeguimiento": "REC-2026-0015",
      "tipo": "RECLAMO",
      "motivo": "INCUMPLIMIENTO_PLAZO_ENTREGA",
      "estado": "ATENDIDO",
      "fechaRegistro": "2026-09-23T00:10:00Z",
      "fechaLimiteSLA": "2026-10-14T23:59:59Z"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

#### 2.11 Responder y Resolver Reclamo

-   **Endpoint:** `PATCH /api/v2/reclamos/{reclamoId}/respuesta`
-   **Descripción:** El Gestor emite la respuesta formal que será
    visible para el cliente (Requisito A10).
-   **Headers:** `Authorization: Bearer <token_gestor>`
-   **Request Body:**

``` json
{
  "nuevoEstado": "ATENDIDO",
  "respuestaVisibleCliente": "Estimado Juan, lamentamos la demora. Se ha coordinado la entrega prioritaria y se ha aplicado una bonificación a su cuenta.",
  "atendidoPor": "GESTOR-02"
}
```

-   **Respuestas:**
    -   **`200 OK`**

``` json
{
  "reclamoId": "REC-2026-0015",
  "estado": "ATENDIDO",
  "fechaRespuesta": "2026-09-23T00:18:00Z",
  "respuestaVisibleCliente": "Estimado Juan, lamentamos la demora. Se ha coordinado la entrega prioritaria y se ha aplicado una bonificación a su cuenta."
}
```

-   **`400 Bad Request`**: Campo `respuestaVisibleCliente` vacío o nulo.

#### 2.12 Consultar Métricas del Dashboard

-   **Endpoint:** `GET /api/v2/dashboard/metricas`
-   **Query Params:**
    -   `desde`: 2026-09-01
    -   `hasta`: 2026-09-30
    -   `canal` (opcional): `MARKETPLACE | CHATBOT | RETAIL`
-   **Headers:** `Authorization: Bearer <token_admin>`
-   **Respuestas:**
    -   **`200 OK`**

``` json
{
  "periodo": {
    "desde": "2026-09-01",
    "hasta": "2026-09-30"
  },
  "pedidos": {
    "total": 5420,
    "anulados": 115,
    "entregados": 4980
  },
  "postventa": {
    "devolucionesAprobadas": 45,
    "montoReembolsadoPEN": 5890.50,
    "csatPromedio": 4.62,
    "reclamosPendientesSLA": 3
  }
}
```

# Contrato de API (OpenAPI / REST) — Módulo D: Ventas y Postventa

**Versión:** 1.3.0  
**Fecha:** Septiembre 2026  
**Servicios:** M1 (Ventas / Pedidos) y M2 (Postventa)  
**Convenciones generales:**
- Formato de datos: `application/json; charset=utf-8`
- Timestamps: ISO-8601 en UTC (`YYYY-MM-DDTHH:mm:ssZ`)
- Autenticación: Cabecera HTTP `Authorization: Bearer <JWT>`
- Estándar de errores:
```json
{
  "codigo": "RECURSO_NO_ENCONTRADO",
  "mensaje": "Descripción legible del error",
  "timestamp": "2026-09-23T00:05:00Z",
  "detalles": []
}
```

---

## 1. M1 — Módulo de Ventas

### F1: Ciclo de Vida del Pedido (Responsable: Michael)

#### 1.1 Crear Pedido
- **Endpoint:** `POST /api/v1/pedidos`
- **Descripción:** Registra un nuevo pedido proveniente de Canales A (Marketplace), B (Chatbot) o C (Retail). Incluye obligatoriamente los bloques de `canal`, `contacto`, `items`, `envio`, `pago` y el bloque opcional `cupon`. Inicializa en estado `CREADO`.
- **Headers:**
  - `Authorization: Bearer <token_canal>`
  - `Content-Type: application/json`

##### Especificación de Validación del Objeto `contacto`
Los campos `tipoDocumento` y `numeroDocumento` son **estrictamente obligatorios**. Las reglas para la validación son:

| `tipoDocumento` | Obligatorio | Formato / Regex | Longitud | Descripción |
|---|---|---|---|---|
| `DNI` | SÍ | `^[0-9]{8}$` | 8 dígitos | Documento Nacional de Identidad peruano. Solo dígitos numéricos. |
| `RUC` | SÍ | `^(10\|15\|17\|20)[0-9]{9}$` | 11 dígitos | Registro Único de Contribuyentes. Inicia en 10, 15, 17 o 20. |
| `CE` | SÍ | `^[a-zA-Z0-9]{8,12}$` | 8 a 12 car. | Carné de Extranjería. Caracteres alfanuméricos sin guiones ni espacios. |
| `PASAPORTE` | SÍ | `^[a-zA-Z0-9]{6,12}$` | 6 a 12 car. | Pasaporte internacional. Alfanumérico sin caracteres especiales. |

- **Request Body:**
```json
{
  "canal": "CHATBOT",
  "contacto": {
    "clienteId": "CLI-8841",
    "nombreCompleto": "Juan Pérez Rodríguez",
    "tipoDocumento": "DNI",
    "numeroDocumento": "72458912",
    "telefono": "+51999888777",
    "email": "juan.perez@example.com"
  },
  "items": [
    {
      "productoId": "PROD-101",
      "sku": "SKU-AUR-01",
      "descripcion": "Audífonos Inalámbricos Bluetooth",
      "cantidad": 1,
      "precioUnitario": 129.90
    }
  ],
  "cupon": {
    "codigo": "CYBER2026",
    "descuento": 10.00,
    "aplicado": true
  },
  "envio": {
    "modalidad": "DELIVERY",
    "costo": 10.00,
    "destinatario": "Juan Pérez",
    "departamento": "Lima",
    "provincia": "Lima",
    "distrito": "San Miguel",
    "direccion": "Av. La Marina 1234, Dpto 401",
    "referencia": "Frente al centro comercial"
  },
  "pago": {
    "metodoPago": "TARJETA_CREDITO",
    "moneda": "PEN",
    "subtotal": 129.90,
    "descuentoCupon": 10.00,
    "costoEnvio": 10.00,
    "total": 129.90
  }
}
```
- **Respuestas:**
  - **`201 Created`**
```json
{
  "pedidoId": "PED-2026-00981",
  "estado": "CREADO",
  "total": 129.90,
  "moneda": "PEN",
  "canal": "CHATBOT",
  "fechaCreacion": "2026-09-23T00:05:00Z"
}
```
  - **`400 Bad Request` (Documento inválido o faltante):**
```json
{
  "codigo": "DOCUMENTO_INVALIDO",
  "mensaje": "El número de documento no cumple con el formato requerido para el tipo indicado",
  "timestamp": "2026-09-23T00:05:00Z",
  "detalles": [
    {
      "campo": "contacto.numeroDocumento",
      "error": "Para tipoDocumento 'DNI' se requieren exactamente 8 dígitos numéricos"
    }
  ]
}
```
  - **`409 Conflict`**: Fallo de validación de catálogo o stock con el módulo de Productos (F).

---

#### 1.2 Notificación de Pago (Webhook / Callback de Pasarela)
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion`
- **Descripción:** Recibe la confirmación o el rechazo de la transacción desde la pasarela externa de pagos. Si es exitoso, avanza el pedido de `CREADO` a `PAGADO`. Si falla, permite al canal anularlo o reintentar el cobro.
- **Headers:**
  - `Authorization: Bearer <token_pasarela_o_servicio>`
  - `Content-Type: application/json`
- **Request Body:**
```json
{
  "transaccionId": "TX-PASARELA-778120",
  "resultado": "APROBADO",
  "monto": 129.90,
  "moneda": "PEN",
  "metodo": "TARJETA_CREDITO",
  "marcaTarjeta": "VISA",
  "ultimosCuatroDigitos": "4321",
  "fechaPago": "2026-09-23T00:06:00Z",
  "codigoAutorizacion": "AUTH-99021"
}
```
- **Respuestas:**
  - **`200 OK`**
```json
{
  "pedidoId": "PED-2026-00981",
  "nuevoEstado": "PAGADO",
  "transaccionId": "TX-PASARELA-778120",
  "fechaTransicion": "2026-09-23T00:06:00Z"
}
```
  - **`400 Bad Request`**: Inconsistencia de montos o datos de transacción.
  - **`404 Not Found`**: El pedido indicado no existe.
  - **`409 Conflict`**: El pedido no se encuentra en estado `CREADO`.

---

#### 1.3 Consultar Pedido por ID (Endpoint clave para Chatbot)
- **Endpoint:** `GET /api/v1/pedidos/{pedidoId}`
- **Descripción:** Permite a clientes, canales (Chatbot/Marketplace) y administradores consultar el estado y detalle del pedido.
- **Headers:** `Authorization: Bearer <token>`
- **Parámetros Path:** `pedidoId` (string, ej. `PED-2026-00981`)
- **Respuestas:**
  - **`200 OK`**
```json
{
  "pedidoId": "PED-2026-00981",
  "canal": "CHATBOT",
  "estado": "EN_PREPARACION",
  "contacto": {
    "clienteId": "CLI-8841",
    "nombreCompleto": "Juan Pérez Rodríguez",
    "tipoDocumento": "DNI",
    "numeroDocumento": "72458912",
    "email": "juan.perez@example.com",
    "telefono": "+51999888777"
  },
  "pago": {
    "total": 129.90,
    "moneda": "PEN",
    "metodoPago": "TARJETA_CREDITO"
  },
  "envio": {
    "modalidad": "DELIVERY",
    "direccion": "Av. La Marina 1234, Dpto 401",
    "distrito": "San Miguel"
  },
  "items": [
    {
      "productoId": "PROD-101",
      "sku": "SKU-AUR-01",
      "descripcion": "Audífonos Inalámbricos Bluetooth",
      "cantidad": 1,
      "precioUnitario": 129.90
    }
  ],
  "fechaCreacion": "2026-09-23T00:05:00Z",
  "ultimaActualizacion": "2026-09-23T00:08:15Z",
  "historialEstados": [
    {
      "estado": "CREADO",
      "fecha": "2026-09-23T00:05:00Z",
      "actor": "CANAL_CHATBOT",
      "motivo": "Registro inicial de compra"
    },
    {
      "estado": "PAGADO",
      "fecha": "2026-09-23T00:06:00Z",
      "actor": "PASARELA_PAGOS",
      "motivo": "Confirmación de cobro exitoso"
    },
    {
      "estado": "EN_PREPARACION",
      "fecha": "2026-09-23T00:08:15Z",
      "actor": "SISTEMA_LOGISTICA",
      "motivo": "Recepción en almacén central"
    }
  ]
}
```
  - **`401 Unauthorized`**: Token ausente o caducado.
  - **`403 Forbidden`**: El cliente autenticado no es el dueño de la orden ni cuenta con rol gestor.
  - **`404 Not Found`**: El pedido solicitado no existe.

---

#### 1.4 Listar Pedidos por Cliente
- **Endpoint:** `GET /api/v1/pedidos`
- **Descripción:** Permite obtener el listado histórico de pedidos asociados a un cliente específico.
- **Headers:** `Authorization: Bearer <token>`
- **Query Params:**
  - `clienteId` (requerido para clientes): Identificador del cliente.
  - `estado` (opcional): `CREADO | PAGADO | EN_PREPARACION | DESPACHADO | ENTREGADO | ANULADO`
  - `desde` (opcional): Fecha inicial ISO.
  - `hasta` (opcional): Fecha final ISO.
  - `pagina` (opcional, default: `0`)
  - `tamano` (opcional, default: `10`)
- **Respuestas:**
  - **`200 OK`**
```json
{
  "clienteId": "CLI-8841",
  "contenido": [
    {
      "pedidoId": "PED-2026-00981",
      "canal": "CHATBOT",
      "estado": "EN_PREPARACION",
      "total": 129.90,
      "moneda": "PEN",
      "fechaCreacion": "2026-09-23T00:05:00Z"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

---

#### 1.5 Transición de Estado del Pedido
- **Endpoint:** `PATCH /api/v1/pedidos/{pedidoId}/estado`
- **Descripción:** Valida la máquina de estados e inserta el evento en el historial. Invocado por Logística (E) o por F2 (Anulación).
- **Headers:** `Authorization: Bearer <token_admin_o_servicio>`
- **Request Body:**
```json
{
  "nuevoEstado": "DESPACHADO",
  "actor": "SISTEMA_LOGISTICA",
  "motivo": "Guía de remisión GR-00892 asignada a transporte"
}
```
- **Respuestas:**
  - **`200 OK`**: Transición exitosa.
  - **`409 Conflict`**: Transición no permitida por la máquina de estados.

---

#### 1.6 Notificación de Incidencias desde Despacho / Logística (Módulo E)
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/eventos-logistica`
- **Descripción:** Despacho (E) notifica entrega fallida definitiva o rechazo en puerta. M1 anula el pedido y deriva a F4 para el reembolso.
- **Headers:** `Authorization: Bearer <token_servicio_despacho>`
- **Request Body:**
```json
{
  "evento": "ENTREGA_FALLIDA_DEFINITIVA",
  "guiaRemision": "GR-00892",
  "motivo": "Dirección inexistente tras 3 visitas; devuelto a almacén central",
  "requiereReembolso": true
}
```
- **Respuestas:**
  - **`200 OK`**
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "ANULADO",
  "reembolso": {
    "solicitudId": "REEM-90815",
    "estado": "EN_PROCESO",
    "monto": 129.90,
    "moneda": "PEN"
  },
  "mensaje": "Pedido anulado e instrucción de reembolso remitida a F4"
}
```

---

### F2: Anulación de Pedidos (Responsable: Luis Arroyo)

#### 1.7 Solicitar Anulación
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/anulaciones`
- **Descripción:** Cancela el pedido. Soporta cancelación automática e inmediata por el canal en estado `CREADO` por motivo `PAGO_NO_COMPLETADO` sin intervención del Gestor.
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "motivo": "PAGO_NO_COMPLETADO",
  "comentario": "Tiempo límite de espera de pasarela agotado; cancelado por el canal"
}
```
- **Respuestas:**
  - **`200 OK`** (Anulación directa sin gestor — `CREADO` o `PAGADO`):
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "ANULADO",
  "autorizacionRequerida": false,
  "solicitudReembolsoGenerada": false,
  "timestamp": "2026-09-23T00:10:00Z"
}
```
  - **`202 Accepted`** (Requiere autorización del Gestor si está en `EN_PREPARACION`):
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "EN_PREPARACION",
  "solicitudAnulacionId": "ANUL-0012",
  "autorizacionRequerida": true,
  "mensaje": "Pedido en preparación; requiere aprobación administrativa"
}
```
  - **`400 Bad Request`**: Motivo ausente o no tipificado.
  - **`409 Conflict`**: Pedido ya en `DESPACHADO` o `ENTREGADO` (derivar a F3).

---

## 2. M2 — Módulo de Postventa

### F3: Devoluciones y Cambios (Responsable: Joseph)

#### 2.1 Registrar Expediente de Devolución / Cambio
- **Endpoint:** `POST /api/v2/devoluciones`
- **Descripción:** Crea expediente tras la entrega. Valida contra F1 que el pedido esté en estado `ENTREGADO`.
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "pedidoId": "PED-2026-00981",
  "tipo": "CAMBIO",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El botón de encendido no responde",
  "items": [
    {
      "productoId": "PROD-101",
      "cantidad": 1
    }
  ],
  "evidencias": [
    {
      "tipo": "IMAGEN",
      "url": "[https://storage.empresa.com/evidencias/ev-981-foto1.jpg](https://storage.empresa.com/evidencias/ev-981-foto1.jpg)"
    }
  ]
}
```
- **Respuestas:**
  - **`201 Created`**
```json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "estado": "SOLICITADA",
  "fechaRegistro": "2026-09-23T00:12:00Z"
}
```
  - **`400 Bad Request`**: Falta de evidencias visuales obligatorias en defectos o plazo excedido.
  - **`409 Conflict`**: El pedido no se encuentra en estado `ENTREGADO`.

---

#### 2.2 Consultar Expediente de Devolución por ID
- **Endpoint:** `GET /api/v2/devoluciones/{devolucionId}`
- **Respuestas:**
  - **`200 OK`**
```json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "tipo": "CAMBIO",
  "estado": "EN_EVALUACION",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "resolucion": null,
  "fechaRegistro": "2026-09-23T00:12:00Z"
}
```
  - **`404 Not Found`**: Expediente no encontrado.

---

#### 2.3 Resolver Expediente de Devolución
- **Endpoint:** `PATCH /api/v2/devoluciones/{devolucionId}/resolucion`
- **Descripción:** El Gestor aprueba o rechaza. Si es rechazo, exige fundamento no vacío.
- **Headers:** `Authorization: Bearer <token_gestor>`
- **Request Body:**
```json
{
  "decision": "RECHAZADA",
  "fundamento": "El equipo presenta signos de manipulación y daño por agua",
  "autorizadorId": "GESTOR-03"
}
```
- **Respuestas:**
  - **`200 OK`**: Actualizado a `APROBADA` o `RECHAZADA`.
  - **`400 Bad Request`**: Rechazo sin fundamento explicativo.

---

### F4: Reembolsos y Extornos (Responsable: Luis Alejandro)

#### 2.4 Procesar Solicitud de Reembolso
- **Endpoint:** `POST /api/v2/reembolsos`
- **Descripción:** Procesamiento monetario idempotente derivado formalmente de `ANULACION` (F2), `DEVOLUCION` (F3) o `DESPACHO_FALLIDO` (Módulo E).
- **Headers:**
  - `Authorization: Bearer <token_servicio_o_gestor>`
  - `X-Idempotency-Key: a4c89f55-1211-4fce-bc2a-605e55e396dc`
- **Request Body:**
```json
{
  "origen": "DESPACHO_FALLIDO",
  "referenciaId": "PED-2026-00981",
  "monto": 129.90,
  "moneda": "PEN",
  "motivo": "Paquete devuelto a almacén por entrega fallida en ruta",
  "solicitadoPor": "MODULO_DESPACHO_E"
}
```
- **Respuestas:**
  - **`201 Created`**
```json
{
  "reembolsoId": "REEM-90812",
  "transaccionPasarelaId": "TX-SIM-871239",
  "estado": "EXITOSO",
  "monto": 129.90,
  "moneda": "PEN",
  "fechaEjecucion": "2026-09-23T00:15:30Z"
}
```
  - **`400 Bad Request`**: El monto excede el total pagado originalmente.
  - **`403 Forbidden`**: Solicitud sin origen legítimo reconocido.
  - **`409 Conflict`**: Fallo de pasarela o conflicto de idempotencia.

---

### F5: Calificación de Experiencia / CSAT (Responsable: Johan)

#### 2.5 Registrar Encuesta CSAT
- **Endpoint:** `POST /api/v2/csat`
- **Request Body:**
```json
{
  "pedidoId": "PED-2026-00981",
  "clienteId": "CLI-8841",
  "canal": "CHATBOT",
  "puntuacion": 5,
  "comentario": "Excelente tiempo de entrega y respuesta rápida"
}
```
- **Respuestas:**
  - **`201 Created`**: Encuesta guardada.
  - **`400 Bad Request`**: Puntuación fuera de rango (1 al 5).
  - **`409 Conflict`**: Encuesta ya registrada para ese pedido.

---

### F6: Reclamos y Dashboard (Responsable: Fabrizio)

#### 2.6 Registrar Reclamo (Libro de Reclamaciones)
- **Endpoint:** `POST /api/v2/reclamos`
- **Descripción:** Registra un reclamo formal según normativa Indecopi con plazo de respuesta de 15 días hábiles.
- **Headers:**
  - `Authorization: Bearer <token_canal_o_cliente>`
  - `Content-Type: application/json`
- **Request Body:**
```json
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
- **Respuestas:**
  - **`201 Created`**
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
  - **`400 Bad Request`**: Datos incompletos del consumidor o motivo no tipificado.

---

#### 2.7 Consultar Reclamo por Código de Seguimiento (Consulta para Chatbot / Web)
- **Endpoint:** `GET /api/v2/reclamos/{codigoSeguimiento}`
- **Descripción:** Permite al cliente (desde Chatbot o Web) o al Gestor consultar el estado actual y la respuesta formal de un reclamo específico mediante su código.
- **Headers:** `Authorization: Bearer <token>`
- **Parámetros Path:** `codigoSeguimiento` (string, ej. `REC-2026-0015`)
- **Respuestas:**
  - **`200 OK`**
```json
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
  - **`401 Unauthorized`**: Token ausente o inválido.
  - **`404 Not Found`**: Reclamo no encontrado con ese código de seguimiento.

---

#### 2.8 Listar Reclamos por Cliente / Consumidor
- **Endpoint:** `GET /api/v2/reclamos`
- **Descripción:** Permite obtener el listado histórico de reclamos asociados a un cliente o número de documento de identidad.
- **Headers:** `Authorization: Bearer <token>`
- **Query Params:**
  - `documento` (opcional): Número de documento de identidad del reclamante.
  - `clienteId` (opcional): Identificador del cliente.
  - `estado` (opcional): `REGISTRADO | EN_PROCESO | ATENDIDO | DERIVADO`
  - `pagina` (opcional, default: `0`)
  - `tamano` (opcional, default: `10`)
- **Respuestas:**
  - **`200 OK`**
```json
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

---

#### 2.9 Responder y Resolver Reclamo
- **Endpoint:** `PATCH /api/v2/reclamos/{reclamoId}/respuesta`
- **Descripción:** El Gestor emite la respuesta formal que será visible para el cliente (Requisito A10).
- **Headers:** `Authorization: Bearer <token_gestor>`
- **Request Body:**
```json
{
  "nuevoEstado": "ATENDIDO",
  "respuestaVisibleCliente": "Estimado Juan, lamentamos la demora. Se ha coordinado la entrega prioritaria y se ha aplicado una bonificación a su cuenta.",
  "atendidoPor": "GESTOR-02"
}
```
- **Respuestas:**
  - **`200 OK`**
```json
{
  "reclamoId": "REC-2026-0015",
  "estado": "ATENDIDO",
  "fechaRespuesta": "2026-09-23T00:18:00Z",
  "respuestaVisibleCliente": "Estimado Juan, lamentamos la demora. Se ha coordinado la entrega prioritaria y se ha aplicado una bonificación a su cuenta."
}
```
  - **`400 Bad Request`**: Campo `respuestaVisibleCliente` vacío o nulo.

---

#### 2.10 Consultar Métricas del Dashboard
- **Endpoint:** `GET /api/v2/dashboard/metricas`
- **Query Params:**
  - `desde`: 2026-09-01
  - `hasta`: 2026-09-30
  - `canal` (opcional): `MARKETPLACE | CHATBOT | RETAIL`
- **Headers:** `Authorization: Bearer <token_admin>`
- **Respuestas:**
  - **`200 OK`**
```json
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


```

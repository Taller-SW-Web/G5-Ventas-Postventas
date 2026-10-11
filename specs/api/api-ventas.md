# Contrato de API (OpenAPI / REST) — Microservicio M1: Ventas y Pedidos

**Versión:** 1.4.0

**Fecha:** Septiembre 2026

**Servicio:** M1 (Ventas / Pedidos)

**Audiencia:** `api-ventas`

---

## Convenciones generales

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
## Catálogo de Scopes OAuth2 / JWT Expuestos por M1
- **`ventas:pedidos:escribir`**: Registro de nuevos pedidos (`POST /api/v1/pedidos`). Utilizado por Canales A, B y C.
- **`ventas:pedidos:leer`**: Consulta de estado, detalle y tracking (`GET /api/v1/pedidos/{id}`, `GET /api/v1/pedidos/me`). Utilizado por Canales A, B y C.
- **`ventas:pedidos:anular`**: Cancelación directa en estado inicial por falta de pago (`POST /api/v1/pedidos/{id}/anulaciones`). Utilizado por Canales A, B y C.
- **`ventas:pedidos:estado`**: Actualización del ciclo de vida y recepción de eventos logísticos (`PATCH /api/v1/pedidos/{id}/estado`, `POST /api/v1/pedidos/{id}/eventos-logistica`). Utilizado por Módulo E (Despacho / Logística).
- **`ventas:pagos:webhook`**: Confirmación o rechazo de transacciones monetarias (`POST /api/v1/pedidos/{id}/pagos/notificacion`). Utilizado por Pasarela de Pagos.
- **`ventas:admin`**: Administración, autorización de anulaciones y consulta global. Requiere el rol `ADMIN_VENTAS` (claim `roles` del JWT, catálogo cerrado de Seguridad — "Gestor" es solo el nombre que usamos en specs/interfaz, no un rol real del sistema).
# Endpoints de M1
## F1: Ciclo de Vida del Pedido (Responsable: Michael)
### 1.1 Crear Pedido
- **Endpoint:** `POST /api/v1/pedidos`
Descripción: Registra un nuevo pedido proveniente de Canales A (Marketplace), B (Chatbot) o C (Retail). Incluye obligatoriamente los bloques de canal, contacto, items, envio, pago y el bloque opcional cupon. Inicializa en estado `CREADO`.

**Orquestación del cobro:** quién dispara el cobro simulado depende de si el canal construye su propia experiencia de pago o no (ver `AGENTS.md`, sección 2, punto 8):
- **Marketplace** (acuerdo 2026-10-10): no toca pago en absoluto. Inmediatamente después de responder `201 Created` con el pedido en `CREADO` y la reserva de stock/cupón confirmada, M1 invoca por su cuenta al simulador de pasarela compartido. El canal solo crea el pedido aquí y consulta su estado (1.3/1.4b) hasta ver `PAGADO`.
- **Chatbot** (acuerdo 2026-10-10, su propio `PaymentSimulator` ya construido): su backend procesa el pago simulado con sus propios datos de prueba y notifica `1.2` directamente, con su propia credencial de servicio.

Ver [F1-Ciclo de vida del pedido.md](../funcionalidades/F1-Ciclo%20de%20vida%20del%20pedido.md), CA-01b.
### Headers
  - `Authorization: Bearer <token_canal>`
  - `Content-Type: application/json`
  - `Idempotency-Key: <UUID v4>` — **obligatorio**, máximo 128 caracteres.

### Idempotencia (acuerdo H-02 con Marketplace)

- **Mismo titular + misma clave + mismo payload:** responde `200 OK` o `201 Created` con el pedido ya creado (mismo `pedidoId`), sin volver a reservar stock.
- **Misma clave + payload distinto:** `409 Conflict`, código `IDEMPOTENCY_KEY_REUSED`.
- **Peticiones concurrentes con la misma clave:** el primer hilo en procesar adquiere el bloqueo transaccional; las solicitudes paralelas reciben la respuesta de la primera, sin duplicar el pedido.
- **Error de validación (`400 Bad Request`):** la clave no se persiste; el canal puede reintentar tras corregir los datos.
- M1 valida y retiene la reserva de stock asociada a la clave ya procesada exitosamente — un reintento con la misma clave no vuelve a reservar ni libera lo ya reservado.
- La clave se guarda en `pedido.idempotency_key` (única por fila).
### Especificación de Validación del Objeto contacto (Auditoría A8 / Legal)

Los campos tipoDocumento y numeroDocumento son estrictamente obligatorios.

| **tipoDocumento** | **Obligatorio** | **Formato / Regex** | **Longitud** | **Descripción** |
|---|---|---|---|---|
| `DNI` | SÍ | `^[0-9]{8}$` | 8 dígitos | Documento Nacional de Identidad peruano. Solo dígitos numéricos. |
| `RUC` | SÍ | `^(10\|15\|17\|20)[0-9]{9}$` | 11 dígitos | Registro Único de Contribuyentes. Inicia en 10, 15, 17 o 20. |
| `CE` | SÍ | `^[a-zA-Z0-9]{8,12}$` | 8 a 12 car. | Carné de Extranjería. Caracteres alfanuméricos sin guiones ni espacios. |
| `PASAPORTE` | SÍ | `^[a-zA-Z0-9]{6,12}$` | 6 a 12 car. | Pasaporte internacional. Alfanumérico sin caracteres especiales. |
### Request Body
{
  "canal": "CHATBOT",
  "contacto": {
    "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
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
### Respuestas
#### `201 Created`
```json
{
  "pedidoId": "PED-2026-00981",
  "estado": "`CREADO`",
  "total": 129.90,
  "moneda": "PEN",
  "canal": "CHATBOT",
  "fechaCreacion": "2026-09-23T00:05:00Z"
}
```
#### `400 Bad Request`
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
#### `400 Bad Request`

Cabecera `Idempotency-Key` ausente o con formato inválido — código `CABECERA_FALTANTE`.

#### `409 Conflict`

- Fallo de validación de catálogo o stock con el módulo de Productos (F).
- `Idempotency-Key` ya usada con un payload distinto — código `IDEMPOTENCY_KEY_REUSED`.

### 1.2 Notificación de Pago (Webhook de Pasarela)
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion`
Descripción: Recibe la confirmación o el rechazo de la transacción desde la pasarela externa de pagos. Si es exitoso, avanza el pedido de `CREADO` a `PAGADO`.
### Headers
  - `Authorization: Bearer <token_pasarela_o_servicio>`
  - `Content-Type: application/json`
### Request Body
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

Valores de `resultado`:

| `resultado` | Estado guardado en `ventas.pago` | Estado del pedido | Actor en el historial |
|---|---|---|---|
| `APROBADO` | `CONFIRMADO` | `CREADO` → `PAGADO` | `PASARELA_PAGOS` |
| `RECHAZADO` | `RECHAZADO` | `CREADO` → `ANULADO`, motivo `PAGO_NO_COMPLETADO` | `PASARELA_PAGOS` |

La transición a `ANULADO` por rechazo repone el stock en Productos (F) automáticamente, sin intervención del Gestor y sin generar solicitud de reembolso hacia F4 — ver [F1-Ciclo de vida del pedido.md](../funcionalidades/F1-Ciclo%20de%20vida%20del%20pedido.md), CA-07b. (La liberación del cupón ante Productos y Ofertas no tiene integración documentada todavía.)

Cualquier otro valor responde `400 Bad Request`. Si la misma `transaccionId` llega dos veces, se responde `200 OK` con el resultado ya registrado, sin repetir el cambio.
### Respuestas
#### `200 OK`
```json
{
  "pedidoId": "PED-2026-00981",
  "nuevoEstado": "`PAGADO`",
  "transaccionId": "TX-PASARELA-778120",
  "fechaTransicion": "2026-09-23T00:06:00Z"
}
```
- **`400 Bad Request`**: Inconsistencia de montos, datos de transacción o `resultado` distinto de `APROBADO` o `RECHAZADO`.
- **`404 Not Found`**: El pedido indicado no existe.
- **`409 Conflict`**: El pedido no se encuentra en estado `CREADO`.
### 1.3 Consultar Pedido por ID
- **Endpoint:** `GET /api/v1/pedidos/{pedidoId}`
Descripción: Permite a clientes, canales y administradores consultar el estado completo del pedido y su snapshot inmutable.
- **Headers:** `Authorization: Bearer <token>`
- **Parámetros Path:** `pedidoId (string, ej. PED-2026-00981)`
### Respuestas
#### `200 OK`
```json
{
  "pedidoId": "PED-2026-00981",
  "canal": "CHATBOT",
  "estado": "`EN_PREPARACION`",
  "contacto": {
    "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
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
      "estado": "`CREADO`",
      "fecha": "2026-09-23T00:05:00Z",
      "actor": "CANAL_CHATBOT",
      "motivo": "Registro inicial de compra"
    },
    {
      "estado": "`PAGADO`",
      "fecha": "2026-09-23T00:06:00Z",
      "actor": "PASARELA_PAGOS",
      "motivo": "Confirmación de cobro exitoso"
    },
    {
      "estado": "`EN_PREPARACION`",
      "fecha": "2026-09-23T00:08:15Z",
      "actor": "SISTEMA_LOGISTICA",
      "motivo": "Recepción en almacén central"
    }
  ]
}
```
- **`401 Unauthorized`**: Token ausente o inválido.
- **`403 Forbidden`**: El cliente autenticado no es el titular de la orden.
- **`404 Not Found`**: El pedido solicitado no existe.
### 1.4 Listar Pedidos por Cliente (uso administrativo)

- **Endpoint:** `GET /api/v1/pedidos`
Descripción: Listado paginado de pedidos para el Gestor/Backoffice — requiere indicar explícitamente el `clienteId` a consultar. Para que un canal muestre "mis pedidos" al propio cliente autenticado, usar **1.4b** (`/pedidos/me`), no este endpoint.
- **Headers:** `Authorization: Bearer <token_gestor>` (scope `ventas:admin`, requiere rol `ADMIN_VENTAS`)
### Query Params
clienteId (requerido): Identificador del cliente.
estado (opcional): `CREADO` | `PAGADO` | `EN_PREPARACION` | `DESPACHADO` | `ENTREGADO` | `ANULADO`
desde (opcional): Fecha inicial ISO.
hasta (opcional): Fecha final ISO.
pagina (opcional, default: 0)
tamano (opcional, default: 10)
### Respuestas
#### `200 OK`
```json
{
  "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
  "contenido": [
    {
      "pedidoId": "PED-2026-00981",
      "canal": "CHATBOT",
      "estado": "`EN_PREPARACION`",
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

### 1.4b Listar Mis Pedidos (acuerdo H-03 con Marketplace)

- **Endpoint:** `GET /api/v1/pedidos/me`
Descripción: Historial de pedidos del cliente autenticado, para que un canal (Marketplace, Chatbot) muestre "mis pedidos" sin exponer `clienteId` en la URL. La identidad se toma exclusivamente del JWT (`sub`/`customerId`); nunca se acepta `clienteId` por query string.
- **Headers:** `Authorization: Bearer <token_cliente>` (scope `ventas:pedidos:leer`)
### Query Params
estado (opcional, valores públicos): `CREADO` | `PAGADO` | `EN_PREPARACION` | `DESPACHADO` | `ENTREGADO` | `ANULADO`
page (opcional, default: 1)
pageSize (opcional, default: 10, máximo: 50)
### Respuestas
#### `200 OK`

Si el cliente no tiene compras previas:
```json
{ "items": [], "total": 0, "page": 1, "pageSize": 10 }
```

Con resultados:
```json
{
  "items": [
    {
      "pedidoId": "PED-2026-00981",
      "canal": "CHATBOT",
      "estado": "EN_PREPARACION",
      "total": 129.90,
      "moneda": "PEN",
      "fechaCreacion": "2026-09-23T00:05:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 10
}
```

> Este endpoint usa `items`/`total`/`page`/`pageSize` en vez de `contenido`/`totalElementos`/`pagina`/`tamano` (el patrón del resto de la API) porque así quedó formalmente acordado con Marketplace (H-03) — no es un error de copiado, es una excepción deliberada para este endpoint específico.

- **`401 Unauthorized`**: Token ausente o inválido.
- **`403 Forbidden`**: El token no tiene el scope `ventas:pedidos:leer`.

### 1.5 Transición de Estado del Pedido
- **Endpoint:** `PATCH /api/v1/pedidos/{pedidoId}/estado`
Descripción: Valida la máquina de estados e inserta el evento en el historial. Invocado por Despacho / Logística (E).
- **Headers:** `Authorization: Bearer <token_admin_o_servicio>`
### Request Body
{
  "nuevoEstado": "`DESPACHADO`",
  "actor": "SISTEMA_LOGISTICA",
  "motivo": "Guía de remisión GR-00892 asignada a transporte"
}
### Respuestas
200 OK: Transición exitosa.
- **`409 Conflict`**: Transición no permitida por la máquina de estados.
### 1.6 Notificación de Incidencias desde Despacho / Logística (Módulo E)
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/eventos-logistica`
Descripción: Despacho (E) notifica entrega fallida definitiva o rechazo en puerta. M1 ejecuta la anulación mediante F2 (motivo: `ENTREGA_FALLIDA_DEFINITIVA`) y deriva la instrucción de reembolso a M2 bajo el origen autorizado `ANULACION`.
- **Headers:** `Authorization: Bearer <token_servicio_despacho>`
### Request Body
{
  "evento": "`ENTREGA_FALLIDA_DEFINITIVA`",
  "guiaRemision": "GR-00892",
  "motivo": "Dirección inexistente tras 3 visitas; devuelto a almacén central",
  "requiereReembolso": true
}
### Respuestas
#### `200 OK`
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "`ANULADO`",
  "reembolso": {
    "solicitudId": "REEM-90815",
    "estado": "EN_PROCESO",
    "monto": 129.90,
    "moneda": "PEN"
  },
  "mensaje": "Pedido anulado e instrucción de reembolso generada hacia M2 con origen `ANULACION`"
}
```
# F2: Anulación de Pedidos (Responsable: Luis Arroyo)
### 1.7 Solicitar Anulación
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/anulaciones`
Descripción: Cancela el pedido. Soporta cancelación automática e inmediata por el canal en estado `CREADO` por motivo `PAGO_NO_COMPLETADO` (A9) sin intervención del Gestor.
- **Headers:** `Authorization: Bearer <token>`
### Request Body
{
  "motivo": "`PAGO_NO_COMPLETADO`",
  "comentario": "Tiempo límite de espera de pasarela agotado; cancelado por el canal"
}
### Respuestas
#### `200 OK`

Anulación directa sin gestor — `CREADO` o `PAGADO`:

```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "`ANULADO`",
  "autorizacionRequerida": false,
  "solicitudReembolsoGenerada": false,
  "timestamp": "2026-09-23T00:10:00Z"
}
```
#### `202 Accepted`

Requiere autorización del Gestor si está en `EN_PREPARACION`:

```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "`EN_PREPARACION`",
  "solicitudAnulacionId": "ANUL-0012",
  "autorizacionRequerida": true,
  "mensaje": "Pedido en preparación; requiere aprobación administrativa"
}
```
### Errores
- **`400 Bad Request`**: Motivo ausente o no tipificado.
- **`409 Conflict`**: Pedido ya en `DESPACHADO` o `ENTREGADO` (derivar al microservicio M2).

### 1.8 Listar Anulaciones Pendientes de Autorización

- **Endpoint:** `GET /api/v1/pedidos/anulaciones/pendientes`
Descripción: Lista las anulaciones en `PENDIENTE_AUTORIZACION` que esperan decisión del Gestor (bandeja de F2).
- **Headers:** `Authorization: Bearer <token_gestor>` (scope `ventas:admin`, requiere rol `ADMIN_VENTAS`)
### Query Params
pagina (opcional, default: 0)
tamano (opcional, default: 10)
### Respuestas
#### `200 OK`
```json
{
  "contenido": [
    {
      "solicitudAnulacionId": "ANUL-0012",
      "pedidoId": "PED-2026-00981",
      "motivo": "SOLICITUD_CLIENTE",
      "fechaSolicitud": "2026-09-23"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

### 1.9 Aprobar o Rechazar una Anulación Pendiente

- **Endpoint:** `PATCH /api/v1/pedidos/{pedidoId}/anulaciones/{anulacionId}`
Descripción: El Gestor resuelve una anulación en `PENDIENTE_AUTORIZACION`. Si aprueba, F1 ejecuta `EN_PREPARACION → ANULADO` y dispara los efectos de F2 (ESP-06). Si rechaza, el pedido conserva su estado.
- **Headers:** `Authorization: Bearer <token_gestor>` (scope `ventas:admin`, requiere rol `ADMIN_VENTAS`)
### Request Body
```json
{
  "decision": "APROBADA",
  "autorizadorId": "GESTOR-03",
  "comentario": "Motivo validado con el cliente"
}
```
### Respuestas
#### `200 OK`
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "ANULADO",
  "estadoAnulacion": "EJECUTADA"
}
```
Si `decision` es `RECHAZADA`, `estadoPedido` vuelve a `EN_PREPARACION` y `estadoAnulacion` queda en `RECHAZADA`.
### Errores
- **`409 Conflict`**: La anulación no está en `PENDIENTE_AUTORIZACION`, o el pedido ya no está en `EN_PREPARACION` (por ejemplo, ya despachó) — en ese caso la anulación pasa a `RECHAZADA`.

---

## Eventos salientes de M1 hacia Marketplace

### 1.10 Webhook de Estado de Envío (acuerdo H-05 con Marketplace)

- **Evento:** `pedidos.envio.estado_actualizado` (versión `1.0.0`)
- **Descripción:** M1 actúa como intermediario entre Despacho (Módulo E) y Marketplace, para que Marketplace no se acople directamente a los eventos internos de Despacho. Cuando M1 recibe de Despacho una actualización pública de estado (`DESPACHADO`, `ENTREGADO`, u otra que el equipo defina como pública), M1 notifica a Marketplace con este webhook.
- **Mecanismo de entrega:** pendiente de diseño técnico (reintentos, backoff, cola de salida). Es responsabilidad de quien implemente F1 definirlo; este documento solo fija el contrato que Marketplace ya aceptó.

**Cuerpo del evento:**

```json
{
  "eventId": "evt_uuid_123456",
  "eventType": "ShipmentStatusUpdated",
  "version": "1.0.0",
  "timestamp": "2026-10-09T21:40:00Z",
  "emitter": "modulo-ventas",
  "data": {
    "orderId": "PED-2026-00981",
    "publicStatus": "DESPACHADO",
    "trackingNumber": "TRK-987654",
    "estimatedDeliveryDate": "2026-10-12"
  }
}
```

**Garantías de entrega:**
- **Deduplicación:** Marketplace almacena y valida el `eventId` recibido, para no duplicar notificaciones al usuario final si M1 reintenta.
- **Privacidad:** el payload no expone datos sensibles ni direcciones detalladas — solo identificadores de tracking y estados públicos.

> Este webhook es independiente de los eventos internos de dominio que M1 publica hacia M2 (`pedido.pagado`, `pedido.anulado`, `pedido.entregado`, ver [catalogo-eventos.md](catalogo-eventos.md)). Tiene su propio nombre, formato y destino — no reutiliza el mecanismo de `outbox_evento`/M2 tal cual; el mecanismo de entrega hacia Marketplace todavía está por diseñarse.

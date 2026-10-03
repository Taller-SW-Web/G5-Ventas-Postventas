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
- **`ventas:pedidos:leer`**: Consulta de estado, detalle y tracking (`GET /api/v1/pedidos/{id}`). Utilizado por Canales A, B y C.
- **`ventas:pedidos:anular`**: Cancelación directa en estado inicial por falta de pago (`POST /api/v1/pedidos/{id}/anulaciones`). Utilizado por Canales A, B y C.
- **`ventas:pedidos:estado`**: Actualización del ciclo de vida y recepción de eventos logísticos (`PATCH /api/v1/pedidos/{id}/estado`, `POST /api/v1/pedidos/{id}/eventos-logistica`). Utilizado por Módulo E (Despacho / Logística).
- **`ventas:pagos:webhook`**: Confirmación o rechazo de transacciones monetarias (`POST /api/v1/pedidos/{id}/pagos/notificacion`). Utilizado por Pasarela de Pagos.
- **`ventas:admin`**: Administración, autorización de anulaciones y consulta global. Utilizado por Backoffice / Gestor.
# Endpoints de M1
## F1: Ciclo de Vida del Pedido (Responsable: Michael)
### 1.1 Crear Pedido
- **Endpoint:** `POST /api/v1/pedidos`
Descripción: Registra un nuevo pedido proveniente de Canales A (Marketplace), B (Chatbot) o C (Retail). Incluye obligatoriamente los bloques de canal, contacto, items, envio, pago y el bloque opcional cupon. Inicializa en estado `CREADO`.
### Headers
  - `Authorization: Bearer <token_canal>`
  - `Content-Type: application/json`
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
409 Conflict

Fallo de validación de catálogo o stock con el módulo de Productos (F).

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
- **`400 Bad Request`**: Inconsistencia de montos o datos de transacción.
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
### 1.4 Listar Pedidos por Cliente
- **Endpoint:** `GET /api/v1/pedidos`
Descripción: Permite obtener el listado histórico paginado de pedidos asociados a un cliente.
- **Headers:** `Authorization: Bearer <token>`
### Query Params
clienteId (requerido para clientes): Identificador del cliente.
estado (opcional): `CREADO` | `PAGADO` | `EN_PREPARACION` | `DESPACHADO` | `ENTREGADO` | `ANULADO`
desde (opcional): Fecha inicial ISO.
hasta (opcional): Fecha final ISO.
pagina (opcional, default: 0)
tamano (opcional, default: 10)
### Respuestas
#### `200 OK`
```json
{
  "clienteId": "CLI-8841",
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

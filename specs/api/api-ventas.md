# Contrato de API (OpenAPI / REST) — Microservicio M1: Ventas y Pedidos

**Versión:** 1.5.0

**Fecha:** Octubre 2026

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

Según el acuerdo A10 con Seguridad (G7) hay dos tipos de token:

- **Token de servicio** (`tipo: "servicio"`, `aud` incluye `api-ventas`): lo usan los otros módulos. Se autoriza por `scope`.
- **Token de usuario** (`tipo: "acceso"`, sin `aud`): lo usa una persona. Se autoriza por rol: `CLIENTE` o `ADMIN_VENTAS` (el Gestor). Su `sub` es el UUID del usuario.

| Scope (token de servicio) | Endpoints | Lo usa |
|---|---|---|
| `ventas:pedidos:crear` | `POST /api/v1/pedidos` (1.1) | Marketplace, Chatbot y Retail |
| `ventas:pedidos:anular` | `POST /api/v1/pedidos/{id}/anulaciones` (1.7) | Marketplace, Chatbot y Retail |
| `ventas:pedidos:estado` | `POST /api/v1/integraciones/despachos/eventos` (1.5 — reemplaza el `PATCH .../estado` y `POST .../eventos-logistica` anteriores) | Despacho (E) — reusamos este scope ya concedido a `modulo-despacho`, decisión nuestra (2026-10-13); no se pide el `despachos:eventos:recibir` que propuso G2, ver `integraciones/ACUERDO_G2_DESPACHO.md` |
| `ventas:pagos:webhook` | `POST /api/v1/pedidos/{id}/pagos/notificacion` (1.2) | Simulador de pasarela y Chatbot |
| `ventas:pedidos:consultar` | `GET /api/v1/pedidos/{id}` (1.3), uso exclusivo módulo-a-módulo | `modulo-postventa` (F3 valida `ENTREGADO`; F5 valida `ENTREGADO` para CSAT) — **registrado** (Seguridad, PR #60, verificado 2026-10-21), ver `integraciones/ACUERDO_G7_SEGURIDAD.md` |
| `ventas:pedidos:reemplazar` | `POST /api/v1/pedidos/reemplazos` (1.11) | `modulo-postventa` (F3, orden de reemplazo de un `CAMBIO`) — **propuesto 2026-10-16, pendiente de que Seguridad lo registre**, ver `integraciones/ACUERDO_G7_SEGURIDAD.md` |

| Rol (token de usuario) | Endpoints |
|---|---|
| `CLIENTE` | `GET /api/v1/pedidos/me` (1.4b) y `GET /api/v1/pedidos/{id}` de sus propios pedidos (1.3) |
| `ADMIN_VENTAS` | Consulta y listado global (1.3, 1.4), anulaciones pendientes y su autorización (1.8, 1.9), y también 1.7 |

`ventas:pedidos:leer` y `ventas:admin` ya no son scopes: esos permisos los da el rol del token de usuario.
# Endpoints de M1
## F1: Ciclo de Vida del Pedido (Responsable: Michael)
### 1.1 Crear Pedido
- **Endpoint:** `POST /api/v1/pedidos`
Descripción: Registra un nuevo pedido proveniente de Canales A (Marketplace), B (Chatbot) o C (Retail). Incluye obligatoriamente los bloques de canal, contacto, items, pago y el bloque opcional cupon. `envio` es obligatorio salvo en Retail.

Estado inicial según el canal:

| Canal | Estado inicial | Qué hace M1 |
|---|---|---|
| `MARKETPLACE` | `CREADO` | Reserva stock en Productos (F) y pide el cobro al simulador de pasarela. El resultado llega por 1.2 |
| `CHATBOT` | `CREADO` | Reserva stock en Productos (F). El chatbot cobra y avisa el resultado por 1.2 |
| `RETAIL` | `PAGADO` y, en la misma operación, `ENTREGADO` (actor `CLIENTE`, motivo `ENTREGA_INMEDIATA_EN_TIENDA`) | No reserva stock ni usa 1.2: la venta ya se cobró en el POS (acuerdo G4) |

### Headers
  - `Authorization: Bearer <token_de_servicio_del_canal>` (scope `ventas:pedidos:crear`)
  - `Content-Type: application/json`
  - `Idempotency-Key: <uuid-v4>` (obligatoria, máximo 128 caracteres; acuerdo H-02)

### Idempotencia (acuerdo H-02)

| Caso | Respuesta |
|---|---|
| Clave nueva | `201 Created` y se registra el pedido |
| Misma clave y mismo cuerpo (reintento) | `200 OK` con el mismo pedido; no se crea otro |
| Misma clave con otro cuerpo | `409 Conflict`, código `IDEMPOTENCY_KEY_REUSED` |
| Sin cabecera o con un valor que no es UUID v4 | `400 Bad Request`, código `CABECERA_FALTANTE` |

Un pedido rechazado por validación (`400`) no consume la clave: el canal puede corregir y reintentar con la misma.
### Especificación de Validación del Objeto contacto (Auditoría A8 / Legal)

Los campos tipoDocumento y numeroDocumento son estrictamente obligatorios.

| **tipoDocumento** | **Obligatorio** | **Formato / Regex** | **Longitud** | **Descripción** |
|---|---|---|---|---|
| `DNI` | SÍ | `^[0-9]{8}$` | 8 dígitos | Documento Nacional de Identidad peruano. Solo dígitos numéricos. |
| `RUC` | SÍ | `^(10\|15\|17\|20)[0-9]{9}$` | 11 dígitos | Registro Único de Contribuyentes. Inicia en 10, 15, 17 o 20. |
| `CE` | SÍ | `^[a-zA-Z0-9]{8,12}$` | 8 a 12 car. | Carné de Extranjería. Caracteres alfanuméricos sin guiones ni espacios. |
| `PASAPORTE` | SÍ | `^[a-zA-Z0-9]{6,12}$` | 6 a 12 car. | Pasaporte internacional. Alfanumérico sin caracteres especiales. |
### Request Body

`contacto.clienteId` es el UUID del cliente en Seguridad (claim `sub`). Se exige `telefono` o `email` (al menos uno).

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
### Campos adicionales de Retail (acuerdo G4)

| Campo | Obligatorio | Regla |
|---|---|---|
| `envio.tiendaId` | Sí | Código de la tienda donde se hizo la venta. El resto de `envio` se omite |
| `pago.metodoPago` | Sí | `EFECTIVO`, `TARJETA_POS` o `MIXTO` |
| `pago.referenciaOperacion` | Con `TARJETA_POS` o `MIXTO` | Número de voucher del POS |
| `pago.montoEfectivo` y `pago.montoTarjeta` | Con `MIXTO` | Deben sumar `pago.total` |
| `pago.fechaVenta` | No | Solo para ventas registradas sin conexión. UTC, no futura y como máximo 72 horas antes. Si no se envía, se usa la hora de registro |

```json
{
  "canal": "RETAIL",
  "contacto": { "clienteId": "11111111-1111-1111-1111-111111111111", "nombreCompleto": "Ana Díaz", "tipoDocumento": "DNI", "numeroDocumento": "40123456", "email": "ana@example.com" },
  "items": [ { "productoId": "PROD-7", "sku": "SKU-7", "cantidad": 2, "precioUnitario": 50.00 } ],
  "envio": { "tiendaId": "TIENDA-MIRAFLORES" },
  "pago": {
    "metodoPago": "MIXTO", "moneda": "PEN",
    "subtotal": 100.00, "descuentoCupon": 0, "costoEnvio": 0, "total": 100.00,
    "referenciaOperacion": "VOU-778", "montoEfectivo": 40.00, "montoTarjeta": 60.00,
    "fechaVenta": "2026-10-12T15:30:00Z"
  }
}
```

### Reglas de montos

- `pago.subtotal` = suma de `cantidad × precioUnitario` de los ítems.
- `pago.total` = `subtotal − descuentoCupon + costoEnvio`.

Si no se cumplen, se responde `400` con código `MONTOS_INCONSISTENTES`.

### Respuestas
#### `201 Created`
También `200 OK` con el mismo cuerpo cuando es un reintento con la misma `Idempotency-Key`. En Retail, `estado` es `ENTREGADO`.
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
Otros códigos `400` de 1.1:

| Código | Cuándo |
|---|---|
| `CABECERA_FALTANTE` | Falta `Idempotency-Key` o no es UUID v4 |
| `DATOS_INVALIDOS` | Campo obligatorio ausente o con formato inválido (incluye `envio` incompleto, sin `telefono` ni `email`, y las reglas de Retail). `detalles` indica el campo |
| `FORMATO_INVALIDO` | JSON mal formado o valor fuera de catálogo (por ejemplo, un `canal` desconocido) |
| `MONTOS_INCONSISTENTES` | `subtotal` o `total` no cuadran, o en `MIXTO` los montos no suman `total` |
| `FECHA_VENTA_FUERA_DE_RANGO` | Retail: `fechaVenta` futura o con más de 72 horas |

#### `409 Conflict`

| Código | Cuándo |
|---|---|
| `ITEM_SIN_DISPONIBILIDAD` | Productos (F) no confirma el stock de uno o más ítems. El pedido no se registra |
| `IDEMPOTENCY_KEY_REUSED` | La `Idempotency-Key` ya se usó con un pedido distinto |

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

La transición a `ANULADO` por rechazo libera la reserva de stock en Productos y, si había cupón aplicado, publica su restauración, automáticamente y sin intervención del Gestor, sin generar solicitud de reembolso hacia F4 — ver [F1-Ciclo de vida del pedido.md](../funcionalidades/F1-Ciclo%20de%20vida%20del%20pedido.md), CA-07b.

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
Si la notificación es un reintento, `nuevoEstado` y `fechaTransicion` son los ya registrados.

| HTTP | Código | Cuándo |
|---|---|---|
| `400` | `DATOS_INVALIDOS` / `FORMATO_INVALIDO` | Falta `transaccionId`, `monto` o `moneda`, o `resultado` no es `APROBADO` ni `RECHAZADO` |
| `400` | `MONTOS_INCONSISTENTES` | `monto` o `moneda` no coinciden con el total del pedido |
| `404` | `PEDIDO_NO_ENCONTRADO` | El pedido indicado no existe |
| `409` | `ESTADO_NO_PERMITE_PAGO` | El pedido no está en `CREADO` (por ejemplo, un rechazo tardío sobre un pedido ya `PAGADO`). No se modifica y queda en el log para revisión |
| `409` | `TRANSACCION_DE_OTRO_PEDIDO` | La `transaccionId` ya se registró en otro pedido |
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
### 1.4 Listar Pedidos (bandeja del Gestor, mockup 02)

- **Endpoint:** `GET /api/v1/pedidos`
Descripción: Listado paginado de pedidos para el Gestor. Sin `clienteId` lista todos — ya **no** es obligatorio (corregido 2026-10-16, antes el contrato lo exigía). Para que un canal muestre "mis pedidos" al propio cliente autenticado, usar **1.4b** (`/pedidos/me`), no este endpoint.
- **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`, claim `roles` del JWT — no es un scope, ver catálogo de scopes)
### Query Params
clienteId (opcional): UUID del cliente en Seguridad (claim `sub`).
estado (opcional): `CREADO` | `PAGADO` | `EN_PREPARACION` | `DESPACHADO` | `ENTREGADO` | `ANULADO`
canal (opcional, **agregado 2026-10-16, no estaba en el contrato**): `MARKETPLACE` | `CHATBOT` | `RETAIL`.
buscar (opcional, **agregado 2026-10-16**): un código `PED-AAAA-NNNNN` filtra por ese pedido exacto; cualquier otro texto busca por número de documento exacto o parte del nombre de contacto.
orden (opcional, **agregado 2026-10-16**): `RECIENTES` (default) | `ANTIGUOS`, por fecha de creación.
desde (opcional): Fecha inicial ISO (día de creación, UTC, inclusive).
hasta (opcional): Fecha final ISO (inclusive).
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
      "fechaCreacion": "2026-09-23T00:05:00Z",
      "nombreCliente": "Juan Pérez Rodríguez"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

- `nombreCliente` (**agregado 2026-10-16, no está en el contrato**): nombre de contacto del pedido, para la columna "Cliente" de la bandeja (mockup 02).
- `clienteId` en la raíz de la respuesta queda `null` cuando no se filtró por un cliente puntual.
### 1.4b Listar Mis Pedidos (acuerdo H-03)
- **Endpoint:** `GET /api/v1/pedidos/me`
Descripción: Devuelve los pedidos del cliente autenticado. La identidad sale del claim `sub` del token; no se acepta `clienteId` en la URL.
- **Headers:** `Authorization: Bearer <token_de_usuario>` (rol `CLIENTE`)
### Query Params
estado (opcional): `CREADO` | `PAGADO` | `EN_PREPARACION` | `DESPACHADO` | `ENTREGADO` | `ANULADO`
page (opcional, default: 1, desde 1)
pageSize (opcional, default: 10, de 1 a 50)

Este endpoint usa `page` y `pageSize` desde 1 (excepción acordada con Marketplace), no `pagina` y `tamano`.
### Respuestas
#### `200 OK`
```json
{
  "items": [
    {
      "pedidoId": "PED-2026-00981",
      "canal": "MARKETPLACE",
      "estado": "PAGADO",
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
- **`401 Unauthorized`**: Token ausente o inválido.
- **`403 Forbidden`**: El token no tiene el rol `CLIENTE` (por ejemplo, un token de servicio).
### 1.5 Webhook de Eventos de Despacho (acuerdo con G2, 2026-10-12)

- **Endpoint:** `POST /api/v1/integraciones/despachos/eventos`
- **Descripción:** **Reemplaza por completo** el antiguo `PATCH /pedidos/{id}/estado` y `POST /pedidos/{id}/eventos-logistica` — Despacho adopta su propio modelo de webhook genérico en vez de que nosotros les dictemos nuestros valores de estado. Un solo endpoint recibe todos los eventos del ciclo logístico.
- **Headers:** `Authorization: Bearer <token_servicio_despacho>` (scope `ventas:pedidos:estado`, reusado — ver nota de abajo), cabecera `Idempotency-Key` (UUID v4, misma convención H-02, confirmada por G2).
- **Request Body (genérico, formato de Despacho):**

```json
{
  "idEvento": "evt-desp-001",
  "idPedido": "PED-2026-00981",
  "idDespacho": "DESP-00412",
  "tipo": "DESPACHO_EN_CAMINO",
  "estadoAnterior": "ASIGNADO",
  "estadoNuevo": "EN_CAMINO",
  "ocurridoEn": "2026-10-12T18:30:00Z",
  "datos": {}
}
```

**Mapeo hacia la máquina de estados de Ventas (ESP-03):**

| `tipo` | Efecto en `pedido.estado` | Actor / motivo |
|---|---|---|
| `DESPACHO_ASIGNADO` | Ninguno — sigue `EN_PREPARACION` (capacidad y repartidor reservados, el pedido todavía no salió) | — |
| `DESPACHO_EN_CAMINO` | `EN_PREPARACION → DESPACHADO` | `SISTEMA_LOGISTICA` |
| `DESPACHO_ENTREGADO` | `DESPACHADO → ENTREGADO` | `SISTEMA_LOGISTICA` |
| `DESPACHO_FALLIDO` | Ninguno — intento no definitivo (máx. 2, política de Despacho); queda solo registrado para auditoría | — |
| `DESPACHO_DEVUELTO_A_ORIGEN` | `DESPACHADO → ANULADO` | `SISTEMA_LOGISTICA`, motivo `ENTREGA_FALLIDA_DEFINITIVA` — informa que el ciclo logístico terminó sin entrega; origina la solicitud de reembolso a M2 (ver ESP-06) |
| `DESPACHO_REPROGRAMADO` | Ninguno en el estado del pedido — actualiza `pedido.fecha_estimada_entrega` con `datos.nuevaFechaProgramada` (columna nueva, confirmada necesaria por G2 el 2026-10-12; pendiente de agregar al modelo de datos) | — |
| `DESPACHO_CANCELADO` | Ninguno — es el acuse de que una cancelación que nosotros solicitamos ya se aplicó en Despacho; idempotente, no reabre nada si ya estaba `ANULADO` | — |

Ya **no se envía `guiaRemision`** (Despacho no emite ni gestiona guías de remisión) — el campo `datos.motivoCierre` de `DESPACHO_DEVUELTO_A_ORIGEN` (por ejemplo `MAXIMO_INTENTOS_ALCANZADO`, `ANULACION_SOLICITADA_POR_VENTAS`, `PAQUETE_DANADO`) es suficiente para la auditoría de la anulación y el reembolso — confirmado por G2.

- **Respuestas:**
    - **`200 OK`**: Evento procesado (o ya procesado antes, mismo `idEvento` — idempotente).
    - **`409 Conflict`**: Transición no permitida por la máquina de estados.

**Scope del token (decisión nuestra, 2026-10-13):** reusamos `ventas:pedidos:estado`, ya concedido a `modulo-despacho`, en vez del `despachos:eventos:recibir` nuevo que propuso G2 — es semánticamente correcto, ya está concedido y evita pedirle otro registro a Seguridad. Ver `integraciones/ACUERDO_G2_DESPACHO.md`.

**Pendientes de implementación (nuestros, ya no hay nada por preguntarle a Despacho — ver `integraciones/ACUERDO_G2_DESPACHO.md`):**
1. ~~Señal interna que marca "paquete físicamente preparado y sellado"~~ — **resuelto 2026-10-16:** dos botones del Gestor, ver 1.12 (`POST /pedidos/{id}/preparacion`) y 1.13 (`POST /pedidos/{id}/despacho`).
2. **Columna `pedido.fecha_estimada_entrega`** para `DESPACHO_REPROGRAMADO` — agregar al modelo de datos (`diagrama-fisico.md`, `diagrama-logico.md`, `ventas_postventa_schema.sql`) y aplicar en Supabase.
3. **Manejo de `409 Conflict` al cancelar despacho por condición de carrera** (`EN_CAMINO` ya en curso cuando Ventas pide cancelar): G2 confirmó que no debemos reintentar y que la anulación debe marcarse como improcedente comercialmente, no como una falla técnica — ver ESP-06 CA-06 (nuevo, distinto del CA-05 existente que cubre timeout/5xx).

### 1.6 — retirado (fusionado en 1.5)

La notificación de incidencias logísticas ahora es un caso más del webhook genérico de 1.5 (`DESPACHO_DEVUELTO_A_ORIGEN`), no un endpoint aparte.
# F2: Anulación de Pedidos (Responsable: Luis Arroyo)
### 1.7 Solicitar Anulación
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/anulaciones`
Descripción: Cancela el pedido. Soporta cancelación automática e inmediata por el canal en estado `CREADO` por motivo `PAGO_NO_COMPLETADO` (A9) sin intervención del Gestor.
- **Headers:** `Authorization: Bearer <token_canal>` — token de servicio del canal (`tipo: "servicio"`, scope `ventas:pedidos:anular`), no el token del cliente.
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

### 1.8 Listar Anulaciones (Bandeja de Anulaciones de F2)


- **Endpoint:** `GET /api/v1/pedidos/anulaciones` (soporta también por retrocompatibilidad `GET /api/v1/pedidos/anulaciones/pendientes`)
Descripción: Lista las anulaciones registradas en el sistema para gestión del Backoffice (bandeja de F2). Soporta paginación, ordenamiento y filtrado delegado en el servidor (Server-Side Filtering, Sorting & Pagination) para control de decisiones pendientes e histórico global de resoluciones.
- **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`, claim `roles` del JWT — no es un scope, ver catálogo de scopes)

### Query Params
- `estado` (opcional): Filtro por estado de la solicitud (`PENDIENTE_AUTORIZACION`, `EJECUTADA`, `RECHAZADA`). Si se omite, lista todas las solicitudes.
- `canal` (opcional): Filtro por canal de origen del pedido (`MARKETPLACE`, `CHATBOT`, `RETAIL`).
- `busqueda` (opcional): Término de búsqueda por código de pedido o nombre del cliente.
- `sort` (opcional, default: `fecha,desc`): Criterio y dirección de ordenamiento (`fecha,desc` o `fecha,asc`).
- `pagina` / `page` (opcional, default: 0): Índice de página basado en 0.
- `tamano` / `size` (opcional, default: 10): Cantidad de registros por página.
### Respuestas
#### `200 OK`
```json
{
  "contenido": [
    {
      "solicitudAnulacionId": "ANUL-0012",
      "pedidoId": "PED-2026-00981",
      "motivo": "SOLICITUD_CLIENTE",
      "fechaSolicitud": "2026-09-23",
      "estado": "PENDIENTE_AUTORIZACION",
      "canal": "MARKETPLACE",
      "nombreCliente": "Carlos Ramírez",
      "estadoPedido": "EN_PREPARACION"
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
- **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`, claim `roles` del JWT — no es un scope, ver catálogo de scopes)
### Request Body
```json
{
  "decision": "APROBADA",
  "autorizadorId": "GESTOR-03",
  "comentario": "Motivo validado con el cliente"
}
```
- `comentario` es **obligatorio en ambas decisiones** (corregido 2026-10-21 — el backend real lo valida con `@NotBlank` sin condicionarlo a `RECHAZADA`): también hay que justificar una aprobación, no solo un rechazo.
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
- **`400 Bad Request`**: `decision` o `comentario` vacíos/ausentes.
- **`409 Conflict`**: La anulación no está en `PENDIENTE_AUTORIZACION`, o el pedido ya no está en `EN_PREPARACION` (por ejemplo, ya despachó) — en ese caso la anulación pasa a `RECHAZADA`.

---

# F1 (continuación): Botones del Gestor para preparación y despacho (resuelve AGENTS.md sección 4, acuerdo G2 D1 — construido 2026-10-16)

No estaban en el contrato original. Resuelven la señal pendiente de "qué dispara `POST /despachos`" — son dos acciones separadas del Gestor, no una sola.

### 1.12 Iniciar Preparación

- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/preparacion`
- **Descripción:** Botón "Iniciar preparación" del Gestor — `PAGADO → EN_PREPARACION`. Actor `SISTEMA_LOGISTICA` (es el flujo interno de preparación; el Gestor solo lo dispara, no cambia el actor de la matriz de `ESP-03`). No aplica a `RETAIL` (ya nace y se entrega sin pasar por aquí).
- **Headers:** `Authorization: Bearer <token_gestor>` (rol `ADMIN_VENTAS`)
- **Idempotente:** si el pedido ya está `EN_PREPARACION`, responde `200` sin error ("El pedido ya estaba en preparación").
- **Respuestas:**
    - **`200 OK`**: `{ "pedidoId": "PED-2026-00981", "estado": "EN_PREPARACION", "idDespacho": null, "mensaje": "Pedido en preparación" }`
    - **`409 Conflict`** (`TRANSICION_NO_PERMITIDA`): el pedido no está `PAGADO`.
    - **`409 Conflict`** (`DESPACHO_NO_APLICA`): el pedido es `RETAIL`.

### 1.13 Paquete Sellado

- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/despacho`
- **Descripción:** Botón "Paquete sellado" del Gestor — crea el despacho en Despacho (G2), `POST /api/v1/despachos` de su contrato 7.1. No cambia el estado del pedido: pasa a `DESPACHADO` cuando Despacho avisa que salió (webhook de 1.5). **Orden de reemplazo (F3, acuerdo G6 #100):** como nunca pasó por `PAGADO`, antes de crear el despacho M1 confirma/consume aquí la reserva de Productos con el mismo `operation_id` en cada intento (reintentar es seguro); si la reserva venció, el reemplazo se anula y M2 reabre la devolución a `EN_EVALUACION` (ver `ESP-08` regla 18).
- **Headers:** `Authorization: Bearer <token_gestor>` (rol `ADMIN_VENTAS`)
- **Idempotente:** mismo pedido → misma `Idempotency-Key` hacia Despacho (UUID v4 derivado del `pedidoId`, no uno nuevo por intento) — reintentar es seguro.
- **Respuestas:**
    - **`200 OK`**: `{ "pedidoId": "PED-2026-00981", "estado": "EN_PREPARACION", "idDespacho": "DESP-00412", "mensaje": "Despacho solicitado a G2" }` — `idDespacho` sale del campo `idDespacho` de la respuesta de Despacho (confirmado 2026-10-16).
    - **`409 Conflict`** (`ESTADO_NO_PERMITE_DESPACHO`): el pedido no está `EN_PREPARACION`.
    - **`409 Conflict`** (`DATOS_ENVIO_INCOMPLETOS`): falta `direccion` o `distrito` — son los dos únicos campos de destino que Despacho exige; `referencia`, `departamento` y `provincia` son opcionales (confirmado con G2, 2026-10-16).
    - **`409 Conflict`** (`DESPACHO_NO_APLICA`): el pedido es `RETAIL`.
    - **`409 Conflict`** (`RESERVA_EXPIRADA`): solo en una orden de reemplazo — la reserva de Productos venció antes de sellar.
    - **`422 Unprocessable Entity`** (`DESP_ERROR_SIN_COBERTURA`): Despacho no cubre el destino. Despacho responde `application/problem+json` con un campo `code` — M1 clasifica el error por `status` + `code`, nunca por el texto.
    - **`409 Conflict`** (`DESPACHO_RECHAZADO`): Despacho rechazó la solicitud por otro motivo de negocio (no reintentar).
    - **`503 Service Unavailable`** (`DESPACHO_NO_DISPONIBLE` / `PRODUCTOS_NO_DISPONIBLE`): Despacho o Productos no respondieron — el pedido sigue `EN_PREPARACION`, se puede reintentar.

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

### 1.11 Solicitar Orden de Reemplazo (F3, acuerdo con Productos — issue G6 #100, 2026-10-16)

- **Endpoint:** `POST /api/v1/pedidos/reemplazos`
- **Descripción:** M2 lo invoca al aprobar un `CAMBIO` (ESP-08, flujo B). M1 crea un pedido nuevo **sin cobro** (`pedido.tipo: REEMPLAZO`), vinculado al pedido original y a la devolución, reserva el stock con el mismo mecanismo de 1.1 (`ProductosClient.reservar` — ningún scope ni acuerdo nuevo con Productos) y lo despacha por el flujo normal de F1 (el Gestor marca "paquete sellado" como cualquier pedido; Despacho no distingue un reemplazo de una venta). No aplica al canal `RETAIL` — esos cambios se hacen en tienda.
- **Headers:** `Authorization: Bearer <token_servicio_postventa>` (scope `ventas:pedidos:reemplazar`, propuesto 2026-10-16, pendiente de que Seguridad lo registre)
- **Idempotente por `devolucionId`:** mientras el reemplazo de esa devolución no esté `ANULADO`, una nueva llamada devuelve el mismo pedido (`200`) en vez de crear otro.
- **Request Body:**

```json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoOrigenId": "PED-2026-00981",
  "items": [
    { "sku": "SKU-AUR-01", "cantidad": 1 }
  ]
}
```

- **Respuestas:**
    - **`201 Created`**: reemplazo creado.
    - **`200 OK`**: esa devolución ya tenía un reemplazo vigente (idempotencia); se devuelve el mismo.

```json
{
  "pedidoId": "PED-2026-01203",
  "estado": "`CREADO`",
  "devolucionId": "DEV-2026-0042",
  "pedidoOrigenId": "PED-2026-00981",
  "fechaCreacion": "2026-10-16T10:00:00Z"
}
```

- **Errores:**
    - **`400 Bad Request`** (`ITEM_NO_PERTENECE_AL_PEDIDO`): un `sku` no está en el pedido original.
    - **`400 Bad Request`** (`CANTIDAD_EXCEDE_COMPRADA`): se pide reponer más unidades de las que se compraron de ese `sku`.
    - **`404 Not Found`** (`PEDIDO_NO_ENCONTRADO`): `pedidoOrigenId` no existe.
    - **`409 Conflict`** (`PEDIDO_NO_ENTREGADO`): el pedido original no está `ENTREGADO`.
    - **`409 Conflict`** (`REEMPLAZO_NO_APLICA`): el pedido original es del canal `RETAIL`.
    - **`409 Conflict`** (`REEMPLAZO_YA_EXISTE`): la `devolucionId` ya tiene un reemplazo vigente de **otro** pedido origen (inconsistencia real, no el caso idempotente de arriba).

**Ciclo de vida del reemplazo** (ver `ESP-03` 7.2, nuevas transiciones exclusivas de `pedido.tipo: REEMPLAZO`):
- Sin pago que esperar: si Productos confirma la reserva, `CREADO → EN_PREPARACION` (actor `SISTEMA_PRODUCTOS`), directo a preparación.
- Si Productos rechaza o vence la reserva (en `CREADO` o, en un caso raro, ya en `EN_PREPARACION`): `→ ANULADO` (actor `SISTEMA_PRODUCTOS`, motivo `STOCK_NO_DISPONIBLE`). M1 publica `pedido.anulado` con `datos.devolucionId` — M2 reabre la devolución a `EN_EVALUACION` (no la cierra como fallida); al resolverla otra vez, se crea un reemplazo nuevo con una reserva nueva.
- Al entregarse (mismo flujo de Despacho que cualquier pedido): M1 publica `pedido.entregado` con `datos.devolucionId` — M2 cierra el lado logístico del cambio (ver `ESP-08` 8.2b y regla 11).

# Contrato de API (OpenAPI / REST) — Módulo D: Ventas y Postventa

**Versión:** 1.1.0  
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
  "timestamp": "2026-09-22T21:45:00Z",
  "detalles": []
}
```

---

## 1. M1 — Módulo de Ventas

### F1: Ciclo de Vida del Pedido (Responsable: Michael)

#### 1.1 Crear Pedido
- **Endpoint:** `POST /api/v1/pedidos`
- **Descripción:** Registra un nuevo pedido proveniente de Canales A (Marketplace), B (Chatbot) o C (Retail). Inicializa en estado `CREADO`.
- **Headers:**
  - `Authorization: Bearer <token_canal>`
  - `Content-Type: application/json`
- **Request Body:**
```json
{
  "canal": "CHATBOT",
  "cliente": {
    "id": "CLI-8841",
    "nombre": "Juan Pérez",
    "email": "juan.perez@example.com",
    "documentoTipo": "DNI",
    "documentoNumero": "72458912"
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
  "moneda": "PEN",
  "subtotal": 129.90,
  "costoEnvio": 10.00,
  "total": 139.90,
  "direccionEntrega": {
    "departamento": "Lima",
    "distrito": "San Miguel",
    "direccion": "Av. La Marina 1234, Dpto 401"
  }
}
```
- **Respuestas:**
  - **`201 Created`**
```json
{
  "pedidoId": "PED-2026-00981",
  "estado": "CREADO",
  "total": 139.90,
  "moneda": "PEN",
  "fechaCreacion": "2026-09-22T21:40:00Z"
}
```
  - **`400 Bad Request`**: Datos incompletos o tipos inválidos.
  - **`409 Conflict`**: Fallo de validación de stock o catálogo con el módulo de Productos (F).

---

#### 1.2 Consultar Pedido por ID (Endpoint de consulta para Chatbot)
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
  "clienteId": "CLI-8841",
  "estado": "EN_PREPARACION",
  "moneda": "PEN",
  "total": 139.90,
  "items": [
    {
      "productoId": "PROD-101",
      "sku": "SKU-AUR-01",
      "descripcion": "Audífonos Inalámbricos Bluetooth",
      "cantidad": 1,
      "precioUnitario": 129.90
    }
  ],
  "fechaCreacion": "2026-09-22T21:40:00Z",
  "ultimaActualizacion": "2026-09-22T21:42:15Z",
  "historialEstados": [
    {
      "estado": "CREADO",
      "fecha": "2026-09-22T21:40:00Z",
      "actor": "CANAL_CHATBOT",
      "motivo": "Registro inicial de compra"
    },
    {
      "estado": "PAGADO",
      "fecha": "2026-09-22T21:41:00Z",
      "actor": "PASARELA_PAGOS",
      "motivo": "Confirmación de cobro exitoso"
    },
    {
      "estado": "EN_PREPARACION",
      "fecha": "2026-09-22T21:42:15Z",
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

#### 1.3 Listar Pedidos por Cliente / Filtros
- **Endpoint:** `GET /api/v1/pedidos`
- **Query Params:**
  - `clienteId` (opcional): Filtro por identificador de cliente.
  - `estado` (opcional): `CREADO | PAGADO | EN_PREPARACION | DESPACHADO | ENTREGADO | ANULADO`
  - `desde` (opcional): Fecha inicial ISO.
  - `hasta` (opcional): Fecha final ISO.
  - `pagina` (opcional, default: `0`)
  - `tamano` (opcional, default: `10`)
- **Respuestas:**
  - **`200 OK`**
```json
{
  "contenido": [
    {
      "pedidoId": "PED-2026-00981",
      "estado": "EN_PREPARACION",
      "total": 139.90,
      "moneda": "PEN",
      "fechaCreacion": "2026-09-22T21:40:00Z"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

---

#### 1.4 Transición de Estado del Pedido
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

#### 1.5 Notificación de Incidencias desde Despacho / Logística (Módulo E)
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/eventos-logistica`
- **Descripción:** Permite al Módulo E (Despacho) notificar eventos críticos de entrega (como entrega fallida definitiva o rechazo en puerta). M1 transiciona el pedido y dispara de inmediato la solicitud de reembolso hacia F4, devolviendo al Módulo E el estado del reembolso para su liquidación.
- **Headers:** `Authorization: Bearer <token_servicio_despacho>`
- **Request Body:**
```json
{
  "evento": "ENTREGA_FALLIDA_DEFINITIVA",
  "guiaRemision": "GR-00892",
  "motivo": "Dirección inexistente tras 3 visitas; paquete devuelto a almacén central",
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
    "monto": 139.90,
    "moneda": "PEN"
  },
  "mensaje": "Incidencia procesada, pedido cancelado y solicitud de reembolso remitida a F4"
}
```
  - **`404 Not Found`**: El pedido no existe.
  - **`409 Conflict`**: El pedido ya se encontraba en un estado terminal incompatible.

---

### F2: Anulación de Pedidos (Responsable: Luis Arroyo)

#### 1.6 Solicitar Anulación
- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/anulaciones`
- **Descripción:** Procesa la cancelación. Si está en `CREADO` o `PAGADO`, anula directamente; si está en `EN_PREPARACION`, genera solicitud pendiente de aprobación para el Gestor.
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "motivo": "ERROR_SELECCION_PRODUCTO",
  "comentario": "El cliente se equivocó de modelo antes de que salga de almacén"
}
```
- **Respuestas:**
  - **`200 OK`** (Anulación directa):
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "ANULADO",
  "autorizacionRequerida": false,
  "solicitudReembolsoGenerada": true,
  "timestamp": "2026-09-22T21:46:00Z"
}
```
  - **`202 Accepted`** (Requiere autorización gestor):
```json
{
  "pedidoId": "PED-2026-00981",
  "estadoPedido": "EN_PREPARACION",
  "solicitudAnulacionId": "ANUL-0012",
  "autorizacionRequerida": true,
  "mensaje": "La orden está en preparación; requiere aprobación administrativa"
}
```
  - **`400 Bad Request`**: Motivo ausente o no tipificado.
  - **`409 Conflict`**: Pedido ya en estado `DESPACHADO` o `ENTREGADO` (debe derivarse a Devolución F3).

---

## 2. M2 — Módulo de Postventa

### F3: Devoluciones y Cambios (Responsable: Joseph)

#### 2.1 Registrar Expediente de Devolución / Cambio
- **Endpoint:** `POST /api/v2/devoluciones`
- **Descripción:** Crea un expediente post-entrega. Valida contra F1 que el pedido esté en estado `ENTREGADO`.
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
  "fechaRegistro": "2026-09-22T21:47:00Z"
}
```
  - **`400 Bad Request`**: Faltan evidencias en caso de defecto o está fuera del plazo reglamentario.
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
  "fechaRegistro": "2026-09-22T21:47:00Z"
}
```
  - **`404 Not Found`**: Expediente no encontrado.

---

#### 2.3 Resolver Expediente de Devolución
- **Endpoint:** `PATCH /api/v2/devoluciones/{devolucionId}/resolucion`
- **Descripción:** Realizado por el Gestor. Deriva a cambio logístico, reembolso (F4) o rechazo fundamentado.
- **Headers:** `Authorization: Bearer <token_gestor>`
- **Request Body:**
```json
{
  "decision": "RECHAZADA",
  "fundamento": "El equipo presenta signos evidentes de daño por agua y mal uso físico",
  "autorizadorId": "GESTOR-03"
}
```
- **Respuestas:**
  - **`200 OK`**: Expediente actualizado a `APROBADA` o `RECHAZADA`.
  - **`400 Bad Request`**: En caso de `RECHAZADA` sin enviar el campo obligatorio `fundamento`.

---

### F4: Reembolsos y Extornos (Responsable: Luis Alejandro)

#### 2.4 Procesar Solicitud de Reembolso
- **Endpoint:** `POST /api/v2/reembolsos`
- **Descripción:** Procesamiento monetario idempotente. Solo acepta solicitudes originadas formalmente en `ANULACION` (F2), `DEVOLUCION` (F3) o `DESPACHO_FALLIDO` (Módulo E).
- **Headers:**
  - `Authorization: Bearer <token_servicio_o_gestor>`
  - `X-Idempotency-Key: a4c89f55-1211-4fce-bc2a-605e55e396dc`
- **Request Body:**
```json
{
  "origen": "DESPACHO_FALLIDO",
  "referenciaId": "PED-2026-00981",
  "monto": 139.90,
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
  "monto": 139.90,
  "moneda": "PEN",
  "fechaEjecucion": "2026-09-22T21:48:30Z"
}
```
  - **`400 Bad Request`**: Monto excede el total pagado originalmente.
  - **`403 Forbidden`**: Invocado sin origen formal reconocido (`ANULACION`, `DEVOLUCION` o `DESPACHO_FALLIDO`).
  - **`409 Conflict`**: Fallo en pasarela simulada o conflicto de idempotencia.

---

### F5: Calificación de Experiencia / CSAT (Responsable: Johan)

#### 2.5 Registrar Encuesta CSAT
- **Endpoint:** `POST /api/v2/csat`
- **Descripción:** Captura la satisfacción del cliente tras la entrega de la orden.
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
  - **`201 Created`**: Encuesta registrada.
  - **`400 Bad Request`**: Puntuación fuera de rango (debe ser entero del 1 al 5).
  - **`409 Conflict`**: Encuesta ya completada previamente para ese pedido.

---

### F6: Reclamos y Dashboard (Responsable: Fabrizio)

#### 2.6 Registrar Reclamo (Libro de Reclamaciones)
- **Endpoint:** `POST /api/v2/reclamos`
- **Request Body:**
```json
{
  "pedidoId": "PED-2026-00981",
  "tipo": "QUEJA",
  "canal": "WEB",
  "detalle": "Retraso en la comunicación durante el despacho",
  "consumidor": {
    "nombre": "Juan Pérez",
    "documento": "72458912",
    "email": "juan.perez@example.com"
  }
}
```
- **Respuestas:**
  - **`201 Created`**
```json
{
  "reclamoId": "REC-2026-0015",
  "codigoSeguimiento": "REC-2026-0015",
  "plazoDiasHabiles": 15,
  "fechaLimiteSLA": "2026-10-13T23:59:59Z",
  "estado": "REGISTRADO"
}
```

---

#### 2.7 Consultar Métricas y Agregados del Dashboard
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
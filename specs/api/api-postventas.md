# Contrato de API (OpenAPI / REST) --- Microservicio M2: Postventa

**Versión:** 1.5.0

**Fecha:** Octubre 2026 (F3 cerrado contra implementación real, 2026-10-12)

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
-   **`postventa:reembolsos:procesar`**: Procesamiento de desembolsos
    monetarios originados exclusivamente por M1 (`ANULACION`) o M2
    (`DEVOLUCION`). Utilizado por M1 y M2 internamente.
-   **`postventa:reclamos:escribir`**: Registro formal de reclamos y
    quejas en el Libro de Reclamaciones. Utilizado por Canales A, B y C.

**`postventa:devoluciones:leer` y `postventa:reclamos:leer` no existen como scopes para canales** (acuerdo con Seguridad, 2026-10-10): el listado por `clienteId` con token de servicio permitía que cualquier canal leyera los datos de cualquier cliente. Se reemplazó por el patrón de `/pedidos/me` — ver `2.4b` y `2.10b`, que usan el token del cliente (rol `CLIENTE`, filtrado por `sub`), sin scope. El listado administrativo (`2.4`, `2.10`) sigue existiendo, pero requiere rol `ADMIN_VENTAS`, no scope.

**`postventa:csat:escribir` tampoco es un scope real** (corrección, 2026-10-12 — estaba mal registrado en el acuerdo A10 con Seguridad, ver `integraciones/ACUERDO_G7_SEGURIDAD.md`): `POST /api/v2/csat` (sección 2.7) exige verificar que `pedidoId` pertenezca al `sub` del usuario autenticado (acuerdo H-04 con Marketplace), lo que solo es posible si el token es el del propio cliente — un token de servicio del canal nunca tiene un `sub` de cliente real. Por eso este endpoint usa el mismo patrón que `/pedidos/me`: token del cliente, rol `CLIENTE`, sin scope.

**`ventas:admin` no es un scope real** — Seguridad no lo registra porque depende de identidad de persona, no de módulo. Gestión administrativa completa (dictamen de devoluciones, emisión de respuesta formal a reclamos y métricas de dashboard) se resuelve con el claim `roles` del token del usuario incluyendo `ADMIN_VENTAS` (catálogo cerrado de Seguridad; "Gestor" es solo el nombre que usamos en specs/interfaz).

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

-   **Respuestas de error:**
    -   **`400 Bad Request`** (`ARCHIVO_REQUERIDO`): No se envió el archivo.
    -   **`400 Bad Request`** (`ARCHIVO_INVALIDO`): Formato no admitido, tamaño mayor a 5 MB, o el contenido no corresponde al formato declarado.
    -   **`503 Service Unavailable`** (`ALMACEN_NO_DISPONIBLE`): Supabase Storage no responde.

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

-   **Respuestas de error:**
    -   **`400 Bad Request`** (`EVIDENCIA_REQUERIDA`): Motivo exige evidencia y no se adjuntó ninguna.
    -   **`400 Bad Request`** (`PLAZO_VENCIDO`): Más de 7 días naturales desde la entrega.
    -   **`400 Bad Request`** (`EVIDENCIA_INVALIDA`): Alguna `url` de `evidencias` no salió de 2.1.
    -   **`400 Bad Request`** (`ITEM_INVALIDO`): Algún `productoId` no está en el pedido, o pide más unidades de las compradas.
    -   **`403 Forbidden`** (`ACCESO_DENEGADO`): El pedido pertenece a otro cliente.
    -   **`404 Not Found`** (`PEDIDO_NO_ENCONTRADO`): El pedido indicado no existe.
    -   **`409 Conflict`** (`PEDIDO_NO_ENTREGADO`): El pedido no se encuentra en estado `ENTREGADO`.
    -   **`409 Conflict`** (`DEVOLUCION_EN_CURSO`): Ya existe una devolución no rechazada sobre esas mismas unidades.
    -   **`503 Service Unavailable`** (`VENTAS_NO_DISPONIBLE`): M1 no responde la consulta del pedido (1.3).

#### 2.3 Consultar Expediente de Devolución por ID

-   **Endpoint:** `GET /api/v2/devoluciones/{devolucionId}`
-   **Descripción:** Consulta el detalle, estado del expediente y, en
    caso de resolución monetaria, la trazabilidad del reembolso generado
    en F4. **Efecto secundario (ESP-08 §7.1):** si el expediente está
    `SOLICITADA` y lo consulta el Gestor, pasa a `EN_EVALUACION` en la
    misma llamada — no existe un endpoint aparte para "abrir a revisión".
-   **Headers:** `Authorization: Bearer <token>`
-   **Parámetros Path:** `devolucionId` (string, ej. `DEV-2026-0042`)
-   **Respuestas:**
    -   **`200 OK` (Aprobada con reembolso):**

``` json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
  "tipo": "DEVOLUCION_DINERO",
  "estado": "APROBADA",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El auricular izquierdo no emite sonido",
  "items": [
    { "productoId": "PROD-101", "cantidad": 1 }
  ],
  "resolucion": {
    "decision": "APROBADA",
    "tipoResolucion": "REEMBOLSO",
    "fundamento": "Falla de fábrica confirmada en control de calidad",
    "autorizadorId": "GESTOR-03",
    "fechaResolucion": "2026-09-23T16:00:00Z",
    "referenciaOperacion": "REEM-90812",
    "requiereDevolucionFisica": true,
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
  "fechaRegistro": "2026-09-23T15:51:00Z",
  "historial": [
    {
      "estadoAnterior": null,
      "estado": "SOLICITADA",
      "actor": "CLIENTE",
      "idActor": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
      "detalle": null,
      "fecha": "2026-09-23T15:51:00Z"
    },
    {
      "estadoAnterior": "SOLICITADA",
      "estado": "APROBADA",
      "actor": "GESTOR",
      "idActor": "GESTOR-03",
      "detalle": "Falla de fábrica confirmada en control de calidad",
      "fecha": "2026-09-23T16:00:00Z"
    }
  ],
  "recepciones": [
    {
      "sku": "SKU-AUR-01",
      "productoId": "PROD-101",
      "cantidadRecibida": 1,
      "cantidadApta": 1,
      "reintegroEstado": "COMPLETADO",
      "idActor": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
      "fecha": "2026-09-24T10:00:00Z"
    }
  ]
}
```

`resolucion.tipoResolucion` es `CAMBIO`, `REEMBOLSO` o `RECHAZO` — puede no coincidir con `tipo` del expediente cuando un `CAMBIO` se derivó a reembolso por falta de stock (ver 2.5, `SIN_STOCK`). `resolucion.requiereDevolucionFisica` (agregado al contrato) refleja lo pedido en 2.5 (o su default `true`) para que el frontend no tenga que recordarlo aparte. `historial` (agregado al contrato, actor `CLIENTE`/`CANAL`/`GESTOR`/`SISTEMA`, RNF-03) y `recepciones` (agregado al contrato, una fila por línea confirmada en 2.5b) vienen vacíos/`null` mientras no aplica; `recepciones` solo existe si hubo al menos una confirmación de 2.5b.

-   **`200 OK` (En evaluación):**

``` json
{
  "devolucionId": "DEV-2026-0042",
  "pedidoId": "PED-2026-00981",
  "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
  "tipo": "DEVOLUCION_DINERO",
  "estado": "EN_EVALUACION",
  "motivo": "PRODUCTO_DEFECTUOSO",
  "descripcion": "El auricular izquierdo no emite sonido",
  "items": [
    { "productoId": "PROD-101", "cantidad": 1 }
  ],
  "resolucion": null,
  "fechaRegistro": "2026-09-23T15:51:00Z"
}
```

-   **`404 Not Found`** (`DEVOLUCION_NO_ENCONTRADA`): El expediente solicitado no existe.

#### 2.4 Listar Devoluciones (uso administrativo)

-   **Endpoint:** `GET /api/v2/devoluciones`
-   **Descripción:** Bandeja del Gestor (mockup 06). Sin `clienteId` lista todos los expedientes — mismo criterio que `api-ventas.md` 1.4 (`clienteId` opcional desde 2026-10-16). **Pendiente de implementación (encontrado 2026-10-17):** `DevolucionController.listar` en el backend real todavía tiene `clienteId` como parámetro obligatorio (sin `required = false`) — eso rompe con `400` la bandeja principal de Mockup 06, que llama a este endpoint sin `clienteId`. El contrato ya queda fijado como opcional abajo; falta el ajuste de una línea en el backend (`DevolucionController`/`DevolucionService`).
-   **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`, claim `roles` del JWT — no es un scope). Para que un cliente consulte sus propias devoluciones, usar **2.4b** (`/devoluciones/me`), no este endpoint.
-   **Query Params:**
    -   `clienteId` (opcional, **corregido 2026-10-17** — antes el contrato lo exigía): Identificador del cliente. Sin él, lista todos los expedientes.
    -   `estado` (opcional):
        `SOLICITADA | EN_EVALUACION | APROBADA | RECHAZADA | COMPLETADA`
    -   `tipo` (opcional): `CAMBIO | DEVOLUCION_DINERO`
    -   `pagina` (opcional, default: `0`)
    -   `tamano` (opcional, default: `10`)
-   **Respuestas:**
    -   **`200 OK`**

``` json
{
  "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
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

-   `clienteId` en la raíz de la respuesta queda `null` cuando no se filtró por un cliente puntual (mismo criterio que 1.4).
-   **Respuestas de error:**
    -   **`400 Bad Request`** (`PAGINACION_INVALIDA`): `pagina`/`tamano` fuera de rango o no numéricos.

#### 2.4b Listar Mis Devoluciones

-   **Endpoint:** `GET /api/v2/devoluciones/me`
-   **Descripción:** Historial de devoluciones del cliente autenticado, para que un canal muestre "mis devoluciones" sin exponer `clienteId` en la URL. La identidad se toma exclusivamente del JWT (`sub`); nunca se acepta `clienteId` por query string.
-   **Headers:** `Authorization: Bearer <token_cliente>` (requiere rol `CLIENTE`, claim `roles` del JWT — no es un scope)
-   **Query Params:**
    -   `estado` (opcional):
        `SOLICITADA | EN_EVALUACION | APROBADA | RECHAZADA | COMPLETADA`
    -   `tipo` (opcional): `CAMBIO | DEVOLUCION_DINERO`
    -   `pagina` (opcional, default: `0`)
    -   `tamano` (opcional, default: `10`)
-   **Respuestas:**
    -   **`200 OK`** — mismo formato que 2.4, sin el campo `clienteId` en la raíz (ya está implícito en el token).
    -   **`400 Bad Request`** (`PAGINACION_INVALIDA`): `pagina`/`tamano` fuera de rango o no numéricos.

#### 2.5 Resolver Expediente de Devolución

-   **Endpoint:** `PATCH /api/v2/devoluciones/{devolucionId}/resolucion`
-   **Descripción:** El Gestor aprueba o rechaza el expediente. Si es
    rechazo, exige fundamento no vacío. Si se aprueba con
    `tipo: DEVOLUCION_DINERO`, deriva la instrucción de reembolso a F4.
    Reintentar la misma aprobación sobre un expediente que quedó
    `APROBADA` (porque F4 o Despacho todavía no confirmaron) reintenta la
    coordinación sin duplicar nada — el expediente solo pasa a
    `COMPLETADA` cuando F4 o Despacho confirman, nunca antes.
-   **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`)
-   **Request Body:**

``` json
{
  "decision": "RECHAZADA",
  "fundamento": "El equipo presenta signos evidentes de manipulación interna y sulfatación por agua"
}
```

-   `tipoResolucion` (opcional): `CAMBIO` o `REEMBOLSO`. Si no se envía,
    sale de `tipo` del expediente (`CAMBIO` → cambio, `DEVOLUCION_DINERO`
    → reembolso). Sirve para resolver como `REEMBOLSO` un `CAMBIO` que
    quedó sin stock (ESP-08 CA-05, CA-09) — solo tiene efecto con
    `decision: APROBADA`.
-   `requiereDevolucionFisica` (opcional, booleano, por defecto `true`, solo con
    `tipoResolucion: REEMBOLSO`): si es `false`, el expediente se completa sin
    esperar la confirmación de recepción física ni solicitar reintegro de
    inventario (ej. el cliente conserva un producto defectuoso que no vale la
    pena devolver). En `CAMBIO` siempre es `true` — ver ESP-08 regla 16.
-   `autorizadorId` **no** va en el cuerpo: se toma del `sub` del token
    del Gestor, nunca de un campo enviado por el cliente — se retiró del
    ejemplo de request a partir de esta versión.
-   **Importante (2026-10-13):** esta aprobación comercial **ya no autoriza por sí
    sola** el reintegro de inventario cuando `tipoResolucion` es `CAMBIO` o
    `REEMBOLSO` con `requiereDevolucionFisica: true` — ver 2.5b, `ESP-08` reglas
    14-16 y `integraciones/ACUERDO_G6_PRODUCTOS.md`.
-   **Respuestas:**
    -   **`200 OK`**:

``` json
{
  "devolucionId": "DEV-2026-0042",
  "estado": "APROBADA",
  "decision": "APROBADA",
  "tipoResolucion": "REEMBOLSO",
  "fundamento": null,
  "autorizadorId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
  "fechaResolucion": "2026-09-23T16:00:00Z",
  "referenciaOperacion": "REEM-90812"
}
```

-   **Respuestas de error:**
    -   **`400 Bad Request`** (`FUNDAMENTO_REQUERIDO`): Rechazo sin fundamento explicativo.
    -   **`400 Bad Request`** (`RESOLUCION_INVALIDA`): `tipoResolucion` incompatible con el expediente (por ejemplo, `CAMBIO` en una devolución de dinero sin `CAMBIO` como opción válida).
    -   **`404 Not Found`** (`DEVOLUCION_NO_ENCONTRADA`): Expediente no encontrado.
    -   **`409 Conflict`** (`DEVOLUCION_NO_RESOLUBLE`): El expediente ya está resuelto, o otro Gestor lo resolvió al mismo tiempo.
    -   **`409 Conflict`** (`PEDIDO_INCONSISTENTE`): El pedido asociado ya no está en un estado compatible con la resolución.
    -   **`409 Conflict`** (`SIN_STOCK`): Aprobación con `tipo: CAMBIO` (o `tipoResolucion: CAMBIO`) sin stock disponible en Productos (F). El Gestor puede reintentar con `tipoResolucion: REEMBOLSO`, o rechazar.
    -   **`503 Service Unavailable`** (`PRODUCTOS_NO_DISPONIBLE`): Productos (F) no responde la validación de disponibilidad.

#### 2.5b Confirmar Recepción Física (nuevo, 2026-10-13)

-   **Endpoint:** `PATCH /api/v2/devoluciones/{devolucionId}/recepcion`
-   **Descripción:** Registra que la unidad devuelta llegó físicamente al almacén y
    si es apta para reventa — paso obligatorio antes de solicitar el reintegro de
    inventario a Productos (G6), sin importar que el expediente ya esté `APROBADA`.
    Separa el dictamen comercial del Gestor (2.5) de la confirmación física, que
    puede hacer el mismo Gestor o quien reciba en almacén (mismo rol `ADMIN_VENTAS`).
    No aplica si la resolución fue `REEMBOLSO` con `requiereDevolucionFisica: false`.
-   **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`)
-   **Request Body:**

``` json
{
  "lineas": [
    { "sku": "SKU-AUR-01", "cantidadRecibida": 1, "cantidadApta": 1 }
  ],
  "evidencia": "https://api.empresa.com/v2/uploads/recepciones/rec-0042-foto1.jpg"
}
```

-   `lineas[].sku` debe corresponder a una línea del pedido original (`items[].sku`
    de `GET /api/v1/pedidos/{pedidoId}`, ver `api-ventas.md` 1.3) — nunca se infiere
    de `productoId`.
-   `cantidadApta` ≤ `cantidadRecibida`; solo `cantidadApta` se reintegra.
-   `evidencia` es opcional.
-   **Respuestas:**
    -   **`200 OK`**:

``` json
{
  "devolucionId": "DEV-2026-0042",
  "recepcionConfirmada": true,
  "fechaRecepcion": "2026-09-24T10:00:00Z",
  "actor": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
  "lineas": [
    { "sku": "SKU-AUR-01", "cantidadApta": 1 }
  ],
  "reintegroSolicitado": true,
  "estado": "COMPLETADA"
}
```

-   `estado` (agregado al contrato): el estado del expediente **después** de esta recepción — pasa a `COMPLETADA` si con esta confirmación ya no falta nada (reembolso ya `EXITOSO` en F4, o reemplazo ya entregado en `CAMBIO`); si todavía falta algo, se mantiene en `APROBADA`.

-   **Respuestas de error:**
    -   **`400 Bad Request`** (`CANTIDAD_INVALIDA`): `cantidadApta` mayor que `cantidadRecibida`, o SKU no pertenece al pedido original.
    -   **`404 Not Found`** (`DEVOLUCION_NO_ENCONTRADA`): Expediente no encontrado.
    -   **`409 Conflict`** (`RESOLUCION_NO_APROBADA`): El expediente no está `APROBADA` (`CAMBIO` o `REEMBOLSO`), o no requiere devolución física.
    -   **`409 Conflict`** (`RECEPCION_YA_CONFIRMADA`): Ya existe una confirmación de recepción para ese `devolucionId` y esas líneas — evita duplicar el reintegro (idempotencia, ver `integraciones/ACUERDO_G6_PRODUCTOS.md`).
    -   **`503 Service Unavailable`** (`PRODUCTOS_NO_DISPONIBLE`): Productos (F) no responde la solicitud de reintegro.

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
  "origenId": "ANUL-0012",
  "referenciaId": "PED-2026-00981",
  "monto": 129.90,
  "moneda": "PEN",
  "motivo": "Entrega fallida definitiva en ruta; anulación tramitada por M1",
  "solicitadoPor": "SISTEMA_M1"
}
```

`origenId` es el código de la anulación (`ANUL-NNNN`) o de la devolución (`DEV-AAAA-NNNN`) que origina el reembolso. Su número final se guarda en `reembolso.id_origen` junto con `tipo_origen`, para la restricción de unicidad `(tipo_origen, id_origen)` — distinto de `referenciaId`, cuyo número final va a `reembolso.id_pedido`.

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
-   **`403 Forbidden`** (`ORIGEN_NO_PERMITIDO`): Solicitud con origen no permitido (distinto de
    `ANULACION` o `DEVOLUCION`).
-   **`409 Conflict`** (`CLAVE_IDEMPOTENCIA_EN_CONFLICTO`): La `X-Idempotency-Key` ya existe para una solicitud con datos distintos (origen, monto, moneda), o la pasarela respondió con error.
-   **`409 Conflict`** (`SALDO_INSUFICIENTE`): El monto, sumado a los reembolsos `EXITOSO`/`PENDIENTE` ya registrados para el mismo pedido, supera el total pagado.

#### 2.6b Listar Reembolsos (bandeja del Gestor, mockup 08 — nuevo, 2026-10-16, no está en el contrato)

-   **Endpoint:** `GET /api/v2/reembolsos`
-   **Descripción:** Bandeja del Gestor. `ConsultaReembolsosService`, separado del `POST` de 2.6 (que solo ejecuta extornos).
-   **Headers:** `Authorization: Bearer <token_gestor>` (rol `ADMIN_VENTAS`)
-   **Query Params:** `estado` (opcional, `EstadoReembolso`), `origen` (opcional, `ANULACION`\|`DEVOLUCION`), `pedidoId` (opcional, código `PED-AAAA-NNNNN`), `buscar` (opcional, **decisión PO 2026-10-16**: código `REEM-`/`ANUL-`/`DEV-`/`PED-` exacto — mismo patrón que `buscar` en 2.10 y en `api-ventas.md` 1.4, no hay nombre de cliente que buscar porque no se persiste, ver Q5 abajo), `desde`/`hasta` (opcional, **decisión PO**: fecha ISO sobre `fecha`, ambos inclusivos), `orden` (opcional, **decisión PO**: `RECIENTES` default \| `ANTIGUOS`), `pagina` (default `0`), `tamano` (default `10`, máximo `100`).
-   **Respuestas:**
    -   **`200 OK`**:

``` json
{
  "contenido": [
    {
      "reembolsoId": "REEM-90812",
      "pedidoId": "PED-2026-00981",
      "origen": "ANULACION",
      "origenId": "ANUL-0012",
      "monto": 129.90,
      "moneda": "PEN",
      "estado": "EXITOSO",
      "transaccionPasarelaId": "TX-SIM-871239",
      "fecha": "2026-09-23",
      "intentos": 1,
      "ultimoResultado": "EXITOSO",
      "fechaUltimoIntento": "2026-09-23T00:15:30Z"
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

-   **`400 Bad Request`** (`PAGINACION_INVALIDA`): `pagina` negativo o `tamano` fuera de 1-100.

#### 2.6c Consultar Reembolso por ID (panel "Ver", mockup 08 — nuevo, 2026-10-16, no está en el contrato)

-   **Endpoint:** `GET /api/v2/reembolsos/{reembolsoId}`
-   **Descripción:** Detalle completo, incluido el historial de intentos (ESP-10) y los datos crudos de la solicitud original — estos últimos son los que el frontend reenvía tal cual a 2.6 para un "Reintentar" (ver nota de reintento abajo).
-   **Headers:** `Authorization: Bearer <token_gestor>` (rol `ADMIN_VENTAS`)
-   **Respuestas:**
    -   **`200 OK`**:

``` json
{
  "reembolsoId": "REEM-90812",
  "pedidoId": "PED-2026-00981",
  "origen": "ANULACION",
  "origenId": "ANUL-0012",
  "monto": 129.90,
  "moneda": "PEN",
  "estado": "EXITOSO",
  "transaccionPasarelaId": "TX-SIM-871239",
  "fecha": "2026-09-23",
  "autorizadorId": null,
  "clienteId": "9c3b2e1a-4f3d-4a8e-9b2a-1e6f7a8b9c0d",
  "clienteNombre": "Juan Pérez Rodríguez",
  "canal": "CHATBOT",
  "metodoPago": "TARJETA_CREDITO",
  "total": true,
  "claveIdempotencia": "a4c89f55-1211-4fce-bc2a-605e55e396dc",
  "intentos": [
    { "numero": 1, "estado": "EXITOSO", "transaccionPasarelaId": "TX-SIM-871239", "resultado": null, "fecha": "2026-09-23T00:15:30Z" }
  ]
}
```

-   **`404 Not Found`**: `reembolsoId` no existe.

**Nota (2026-10-17): esta sección se corrigió para que coincida con `DetalleReembolsoResponse`/`ConsultaReembolsosService` ya construidos — manda el código, los nombres de campo y el punto 1 de abajo cambiaron frente a la primera versión de estas decisiones (2026-10-16).**

**Decisiones de PO (2026-10-16, punto 1 corregido 2026-10-17), resuelven las 4 preguntas que quedaron abiertas:**

1. **`autorizadorId`:** no se deriva con un join a `devolucion.id_autorizador` — sale directo de `reembolso.id_autorizador`, columna propia que `ReembolsoService.preparar` llena al crear el reembolso (2.6) parseando `solicitadoPor` del request como UUID (`null` si no se manda o no es un UUID válido). Es el mismo valor para `ANULACION` y `DEVOLUCION`: quien haga el `POST` (M1 para `ANULACION`, el Gestor para `DEVOLUCION`) debe mandar su identidad en `solicitadoPor` si quiere que quede autorizador; si no la manda, queda `null` igual que antes.
2. **"Autorizar" es solo una confirmación visual del frontend, sin estado ni endpoint nuevo.** Un reembolso no es algo que el Gestor cree a mano desde la bandeja — es el efecto automático de una anulación (F2) o una devolución aprobada (F3). El respaldo de auditoría (RNF-03) ya existe: actor, motivo y fecha quedan registrados en la acción de origen (anulación/devolución), y en un reintento el actor sale del JWT del Gestor que lo ejecuta.
3. **El reintento es el mismo mecanismo que ya especifica ESP-09 (guía 8.3): reenviar el `POST /api/v2/reembolsos` original con la misma `X-Idempotency-Key`** — no se construye un `POST /reembolsos/{id}/reintentar` aparte. Para ese reenvío el frontend usa `claveIdempotencia`, `origen`, `origenId`, `pedidoId`, `monto` y `moneda` de este detalle; `motivo` y `solicitadoPor` no están en la respuesta porque son opcionales en el `POST` (`ProcesarReembolsoRequest`) y no hacen falta para reconstruirlo.
4. **`canal`, `clienteId`/`clienteNombre` y `metodoPago` se resuelven consultando a M1** (`VentasClient.consultarPedido`, el mismo cliente que ya usa el resto de F3/F4) — no se agregan columnas nuevas a `reembolso`. Solo en el **detalle** (2.6c): una consulta por reembolso es aceptable, pero repetirla por cada fila de una página de 2.6b no — por eso **la bandeja (2.6b) no trae estos campos**, y el detalle sí.
5. **`total` (booleano, nuevo):** indica si el reembolso cubre el monto completo del pedido (`reembolso.monto == pedido.total`) — lo distingue un reembolso parcial de uno total sin que el frontend tenga que volver a comparar montos. `transaccionPasarelaId` (la "referencia de pago") se muestra en el frontend como `—` cuando es `null` (reembolsos con origen `ANULACION` que nunca llegaron a cobrarse, o cualquier caso sin transacción de pasarela asociada); el backend sigue devolviendo `null` tal cual, el guion es puramente de presentación.

**Para pruebas locales (Q6):** igual que el resto del módulo — `servicio-postventa` directo en `http://localhost:8082` (más simple mientras se desarrolla; el Gateway en `8080` enruta aquí en producción, ver `AGENTS.md` sección 2 punto 6), `CORS_ORIGINS` ya incluye `http://localhost:5173` por defecto. Con `SEGURIDAD_HABILITADA=false` (default local) no hace falta ningún JWT — si se quiere probar la validación de rol, se necesita un JWT real de Seguridad con `roles: ["ADMIN_VENTAS"]`, o `seguridad.habilitada=true` con un token de prueba del kit de integración.

### F5: Calificación de Experiencia / CSAT (Responsable: Johan)

#### 2.7 Registrar Encuesta CSAT

-   **Endpoint:** `POST /api/v2/csat`
-   **Headers:** `Authorization: Bearer <token_cliente>` (requiere rol `CLIENTE`, claim `roles` del JWT — no es un scope; el `sub` del token es el que se valida contra `pedidoId` en el `403`)
-   **Acuerdo H-04 con Marketplace:** Marketplace usa una escala de 3 botones (Mal/Regular/Bien), con mapeo interno `1 (Mal) → sentiment: "NEGATIVE"`, `3 (Regular) → sentiment: "NEUTRAL"`, `5 (Bien) → sentiment: "POSITIVE"` — el campo `sentiment` es una etiqueta propia de Marketplace, no se guarda de nuestro lado; nosotros solo recibimos `puntuacion` (siempre `1`, `3` o `5`, nunca `2` ni `4`). No requiere cambio de esquema de nuestro lado. Mientras consolidan su propia tabla de motivos estructurados, Marketplace puede incluir motivos concatenados dentro de `comentario` con el prefijo `"Motivos: [RAZON_1, RAZON_2] - "` seguido del comentario libre — se guarda tal cual en `calificacion.comentario` (texto libre, sin parseo de nuestro lado).
-   **Request Body:**

``` json
{
  "pedidoId": "PED-2026-00981",
  "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
  "canal": "CHATBOT",
  "puntuacion": 5,
  "comentario": "Excelente tiempo de entrega y respuesta rápida"
}
```

-   **Respuestas:**
    -   **`201 Created`**: Encuesta guardada.
    -   **`400 Bad Request`**: Puntuación fuera de rango (1 al 5).
    -   **`403 Forbidden`**: El `pedidoId` no pertenece al `sub` del usuario autenticado en el JWT (acuerdo H-04).
    -   **`422 Unprocessable Entity`** (`ORDER_NOT_DELIVERED`): El pedido no está en estado terminal `ENTREGADO`. *(Excepción al código `PEDIDO_NO_ENTREGADO`/`409` que usa el resto de este contrato — para este endpoint específico se usó literalmente el código y HTTP status acordados con Marketplace en H-04; ver nota en [catalogo-errores.md](catalogo-errores.md).)*
    -   **`409 Conflict`** (`CSAT_ALREADY_SUBMITTED`): Ya existe una encuesta registrada para ese pedido. *(Mismo caso que `CALIFICACION_DUPLICADA` en el resto del repo; aquí se usa el nombre acordado con Marketplace.)*

#### 2.7b Listar Calificaciones (bandeja del Gestor, mockup 09 — nuevo, 2026-10-16, no está en el contrato)

-   **Endpoint:** `GET /api/v2/csat`
-   **Descripción:** Detalle CSAT, distribución y comentarios por canal para el Gestor. `resumen` se calcula sobre todo el filtro aplicado, no solo sobre la página actual; `distribucion` siempre trae las claves `1` a `5` (con `0` si no hay datos para ese puntaje).
-   **Headers:** `Authorization: Bearer <token_gestor>` (rol `ADMIN_VENTAS`)
-   **Query Params:** `canal` (opcional), `puntaje` (opcional, 1-5), `desde`/`hasta` (opcional, fecha ISO), `pagina` (default `0`), `tamano` (default `10`).
-   **Respuestas:**
    -   **`200 OK`**:

``` json
{
  "contenido": [
    { "pedidoId": "PED-2026-00981", "puntaje": 5, "comentario": "Excelente", "canal": "CHATBOT", "fecha": "2026-09-23" }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1,
  "resumen": {
    "total": 1,
    "promedio": 5.0,
    "distribucion": { "1": 0, "2": 0, "3": 0, "4": 0, "5": 1 }
  }
}
```

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

-   `canal`: `MARKETPLACE | CHATBOT | RETAIL`.

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
  "respuestaVisibleCliente": "Estimado Juan, su reclamo fue atendido. Se coordinó la entrega prioritaria y se emitió una bonificación a su cuenta.",
  "consumidor": {
    "nombreCompleto": "Juan Pérez Rodríguez",
    "documento": "45678912",
    "email": "juan.perez@example.com",
    "telefono": "987654321"
  },
  "atendidoPor": "GESTOR-02",
  "estadoSla": "ATENDIDO",
  "diasHabilesRestantes": null,
  "slaCumplido": true
}
```

-   `consumidor`, `atendidoPor`, `estadoSla`, `diasHabilesRestantes` y `slaCumplido` (agregados al contrato, 2026-10-17): los usa la pantalla de Reclamos (mockup 07). `estadoSla` es el semáforo del plazo (`EN_PLAZO`\|`POR_VENCER`\|`CRITICO`\|`VENCIDO`\|`ATENDIDO`, ver 2.10), distinto de `estado`. `diasHabilesRestantes` es `null` cuando ya está `ATENDIDO` (0 = vence hoy, negativo = vencido). `slaCumplido` es `null` mientras no haya respuesta formal, y después indica si la respuesta llegó dentro del plazo (ESP-14 CA-04).
-   **`401 Unauthorized`**: Token ausente o inválido.
-   **`404 Not Found`**: Reclamo no encontrado con ese código de
    seguimiento.

#### 2.10 Listar Reclamos por Cliente / Consumidor (uso administrativo)

-   **Endpoint:** `GET /api/v2/reclamos`
-   **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`, claim `roles` del JWT — no es un scope). Para que un cliente consulte sus propios reclamos, usar **2.10b** (`/reclamos/me`), no este endpoint. Búsqueda por `documento` (consumidor sin cuenta, Libro de Reclamaciones) solo disponible aquí.
-   **Query Params:**
    -   `documento` (opcional): Número de documento de identidad del
        reclamante.
    -   `clienteId` (opcional): Identificador del cliente.
    -   `estado` (opcional):
        `REGISTRADO | EN_PROCESO | ATENDIDO | DERIVADO`
    -   `buscar` (opcional, **agregado 2026-10-16, no está en el contrato** — mockup 07): un código `PED-AAAA-NNNNN` filtra por ese pedido; cualquier otro texto busca por código de reclamo exacto, documento exacto o parte del nombre del consumidor.
    -   `sla` (opcional, **agregado 2026-10-16**): `EN_PLAZO` (6+ días hábiles) \| `POR_VENCER` (3-5) \| `CRITICO` (0-2) \| `VENCIDO` (pasó la fecha límite sin respuesta) \| `ATENDIDO` (ya tiene respuesta formal) — semáforo del plazo legal, distinto de `estado`: un reclamo puede estar `EN_PROCESO` y `VENCIDO` a la vez.
    -   `desde` / `hasta` (opcional, **agregado 2026-10-16**): fecha ISO, día de registro (UTC), ambos inclusivos.
    -   `orden` (opcional, **agregado 2026-10-16**): `RECIENTES` (default) \| `ANTIGUOS`, por fecha de registro.
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
      "fechaLimiteSLA": "2026-10-14T23:59:59Z",
      "pedidoId": "PED-2026-00981",
      "canal": "CHATBOT",
      "nombreConsumidor": "Juan Pérez Rodríguez",
      "estadoSla": "ATENDIDO",
      "diasHabilesRestantes": null
    }
  ],
  "pagina": 0,
  "totalPaginas": 1,
  "totalElementos": 1
}
```

-   `pedidoId`, `canal`, `nombreConsumidor`, `estadoSla` y `diasHabilesRestantes` (agregados al contrato, 2026-10-17): la bandeja del mockup 07 los muestra sin abrir cada reclamo — mismo significado que en 2.9.

#### 2.10b Listar Mis Reclamos

-   **Endpoint:** `GET /api/v2/reclamos/me`
-   **Descripción:** Historial de reclamos del cliente autenticado, para que un canal muestre "mis reclamos" sin exponer `clienteId` en la URL. La identidad se toma exclusivamente del JWT (`sub`); nunca se acepta `clienteId` ni `documento` por query string (esa búsqueda es solo administrativa, ver 2.10).
-   **Headers:** `Authorization: Bearer <token_cliente>` (requiere rol `CLIENTE`, claim `roles` del JWT — no es un scope)
-   **Query Params:**
    -   `estado` (opcional):
        `REGISTRADO | EN_PROCESO | ATENDIDO | DERIVADO`
    -   `pagina` (opcional, default: `0`)
    -   `tamano` (opcional, default: `10`)
-   **Respuestas:**
    -   **`200 OK`** — mismo formato que 2.10.

#### 2.11 Responder y Resolver Reclamo

-   **Endpoint:** `PATCH /api/v2/reclamos/{reclamoId}/respuesta`
-   **Descripción:** El Gestor emite la respuesta formal que será
    visible para el cliente (Requisito A10).
-   **Headers:** `Authorization: Bearer <token_gestor>` (requiere rol `ADMIN_VENTAS`)
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

-   **`400 Bad Request`** (`RESPUESTA_VACIA`): Campo `respuestaVisibleCliente` vacío o nulo.
-   **`409 Conflict`**: El reclamo ya está `ATENDIDO`.

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
  },
  "ultimaActualizacion": "2026-09-30T22:00:00Z"
}
```

-   `ultimaActualizacion` (agregado al contrato, 2026-10-17): hasta cuándo están consolidados los agregados (ESP-15 §7); `null` si el periodo no tiene actividad.

---

## Endpoint interno de M2

### Eventos de M1

#### 2.13 Recibir Evento de Pedido

-   **Endpoint:** `POST /api/v2/eventos`
-   **Descripción:** Recibe los eventos que publica M1 cuando cambia el
    estado de un pedido (ESP-04). Alimenta CSAT (F5, con
    `pedido.entregado`) y los agregados del dashboard (F6). Es interno:
    el API Gateway no lo publica y solo acepta la credencial de servicio
    de M1.
-   **Headers:**
    -   `Authorization: Bearer <token_servicio_m1>`
    -   `Content-Type: application/json`
-   **Request Body:**

``` json
{
  "idEvento": "3f2c9a10-6b7d-4e21-9c55-1a2b3c4d5e6f",
  "tipo": "pedido.pagado",
  "pedidoId": "PED-2026-00981",
  "fecha": "2026-09-27T15:40:00Z",
  "datos": {
    "canal": "MARKETPLACE",
    "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
    "total": 129.90,
    "moneda": "PEN",
    "motivo": null,
    "items": [
      { "productoId": "PROD-101", "cantidad": 1, "importe": 129.90 }
    ],
    "devolucionId": null
  }
}
```

-   `datos.vendedorId` y `datos.items` solo vienen en `pedido.pagado` (se usan para `agregado_ventas`); en `pedido.anulado` y `pedido.entregado` pueden omitirse. `datos.motivo` es obligatorio solo en `pedido.anulado`.
-   `datos.devolucionId` solo viene cuando el pedido es una orden de reemplazo de un `CAMBIO` (`pedido.tipo: REEMPLAZO`, `api-ventas.md` 1.11, acuerdo con Productos issue G6 #100) — identifica la devolución de M2 que originó el reemplazo. `EventoPedidoService` usa `pedido.anulado` con este campo para reabrir la devolución a `EN_EVALUACION` (`DevolucionService.reemplazoAnulado`) y `pedido.entregado` para cerrar su lado logístico (`reemplazoEntregado`). Nunca viene en una venta normal.
-   `tipo`: `pedido.pagado | pedido.anulado | pedido.entregado`.
-   `idEvento`: UUID generado por M1. Si M1 reintenta, envía el mismo
    valor.
-   **Respuestas:**
    -   **`200 OK`**: `{ "idEvento": "...", "repetido": false }` si es la primera vez que se procesa; `repetido: true` si ya se había procesado antes (se guarda en `postventa.evento_recibido` y no se procesa dos veces) — en ambos casos M1 deja de reintentar.
    -   **`400 Bad Request`**: `tipo` desconocido o estructura inválida.
    -   **`401 Unauthorized`**: Credencial distinta a la de M1.

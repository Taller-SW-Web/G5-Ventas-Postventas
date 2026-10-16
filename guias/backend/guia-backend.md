# Guía para programar el backend - Módulo D Ventas y Postventa

Esta guía dice qué programar, en qué orden, con qué reglas y cómo saber que está terminado. Se usa junto con:

Si esta guía y un contrato de API no coinciden, manda el contrato; avisa en el grupo para corregir la guía.

---

## Índice

1. Reparto y orden de trabajo
2. Preparar el entorno
3. Reglas comunes para todos
4. Decisiones sobre la base y el contrato
5. M1 — F1 Ciclo de vida del pedido (Michael)
6. M1 — F2 Anulación de pedidos (Luis Arroyo)
7. M2 — F3 Devoluciones y cambios (Joseph)
8. M2 — F4 Reembolsos (Luis Alejandro)
9. M2 — F5 CSAT, receptor de eventos y simulador de pasarela (Johan)
10. M2 — F6 Reclamos y dashboard (Fabrizio)
11. Eventos entre M1 y M2
12. Seguridad y scopes
13. Pruebas
14. Antes de abrir un PR

---

## 1. Reparto y orden de trabajo

### 1.1. Quién hace qué

| Persona | Funcionalidad | Carpetas | Endpoints |
|---|---|---|---|
| Michael | F1 + base común | `ventas/compartido/`, `ventas/pedido/`, `ventas/integracion/eventos/` | 1.1 a 1.6 de `api-ventas.md` |
| Luis Arroyo | F2 | `ventas/anulacion/`, `ventas/integracion/` (Productos, Despacho, Postventa) | 1.7 a 1.9 |
| Joseph | F3 | `postventa/devolucion/` | 2.1 a 2.5 de `api-postventas.md` |
| Luis Alejandro | F4 | `postventa/reembolso/`, `postventa/integracion/PasarelaClient` | 2.6 |
| Johan | F5 + eventos + simulador de pasarela | `postventa/calificacion/`, `postventa/integracion/eventos/`, `simulador-pasarela/` | 2.7, `POST /api/v2/eventos` (2.13), cobros y extornos del simulador (9.3) |
| Fabrizio | F6 | `postventa/reclamo/`, `postventa/dashboard/` | 2.8 a 2.12 |

`compartido/` de M2 ya está hecho (Michael, en el esqueleto). Es igual al de M1.

Aplicaciones: `api-gateway` (8080), `servicio-ventas` M1 (8081), `servicio-postventa` M2 (8082) y `simulador-pasarela` (8083).

### 1.2. Fases

```text
Fase 0  ✅ Esqueleto de las 4 aplicaciones en main y compilando (Michael)
        Cambios de la base ya aplicados (sección 4); cada uno ajusta sus entidades

Fase 1  Cada uno, en paralelo, con clientes simulados:
        DTOs + validaciones + service + controller + pruebas

Fase 2  Integración dentro de cada microservicio:
        F2 usa MaquinaEstados de F1
        F3 llama a F4 (mismo servicio, por su Service)

Fase 3  Integración entre microservicios:
        M1 → M2: eventos (Michael envía, Johan recibe)
        M1 → M2: reembolso por anulación (Luis Arroyo llama, Luis Alejandro recibe)
        M2 → M1: consulta de pedido (Joseph y Johan)
        Pasarela → M1: notificación de pago (Johan avisa, Michael recibe)
        M2 → Pasarela: extorno (Luis Alejandro llama, Johan responde)

Fase 4  Integración con otros módulos (E, F y G) cuando entreguen sus URLs
```

### 1.3. Qué se puede avanzar ya, sin esperar a nadie

| Persona | Puede avanzar ya | Espera a |
|---|---|---|
| Michael | Todo F1. Es el camino crítico. **Ya hecho:** esqueleto de las 4 aplicaciones, `compartido/` de M1 y M2, entidades de M1 ajustadas a Supabase, outbox, `EventoRecibido` y `MaquinaEstados` | — |
| Luis Arroyo | Catálogo de motivos, validaciones, decidir directa o pendiente, bandeja del Gestor | Nada: `MaquinaEstados.cambiar(...)` de Michael ya está hecha y probada (ver 5.2) |
| Joseph | Subir evidencia, registrar, consultar, listar y resolver | Nada: `VentasClient` simulado devuelve un pedido `ENTREGADO` |
| Luis Alejandro | Todo F4 | Nada: `PasarelaClient` simulado devuelve éxito. Cuando Johan tenga el simulador, se prueba con `PASARELA_SIMULADA=false` |
| Johan | `POST /csat`, receptor de eventos y simulador de pasarela | Nada: los eventos se prueban a mano y el simulador es independiente |
| Fabrizio | Reclamos completo | Dashboard: espera los eventos y la tabla de métricas (sección 4) |

**Regla de oro para no bloquearse:** si necesitas algo de otra persona, programa contra la interfaz (el método del cliente o del service) con una respuesta simulada. Cuando la otra parte esté lista, solo cambias esa implementación.

---

## 2. Preparar el entorno

### 2.1. Herramientas

| Herramienta | Versión |
|---|---|
| JDK | 21 (Temurin recomendado) |
| Maven | 3.9 o superior (o el de IntelliJ) |
| IDE | IntelliJ IDEA (plugin de Lombok y "Enable annotation processing" activo) o VS Code (Extension Pack for Java) |
| Cliente HTTP | Postman, Insomnia, `curl.exe` o los `.http` (IntelliJ o la extensión REST Client de VS Code) |
| Git | Rama propia, PR hacia `main` |

### 2.2. Primera ejecución

```bash
cd G5-Ventas-Postventas-Backend
copy .env.example .env        # Windows (en Linux o Mac: cp). Completar DB_URL, DB_USER y DB_PASSWORD
mvn clean package             # compila las cuatro aplicaciones y corre las pruebas
```

Datos de conexión: Supabase → **Connect** → **Direct** → **Session pooler** (la conexión directa solo funciona con IPv6):

```properties
DB_URL=jdbc:postgresql://aws-0-ca-central-1.pooler.supabase.com:5432/postgres?sslmode=require
DB_USER=postgres.nsfrwxrjidyckgfriyhv
DB_PASSWORD=<contraseña de la base; pedirla al líder>
```

El `.env` nunca se sube a Git (ya está en `.gitignore`).

Para probar en local sin tokens, en `.env`:

```properties
SEGURIDAD_HABILITADA=false
```

Arrancar cada servicio en una terminal (o desde IntelliJ):

```bash
mvn -pl servicio-ventas spring-boot:run
mvn -pl servicio-postventa spring-boot:run
mvn -pl api-gateway spring-boot:run
mvn -pl simulador-pasarela spring-boot:run
```

Prueba rápida, pasando por el Gateway (en PowerShell se escribe `curl.exe`, no `curl`):

```bash
curl.exe -i http://localhost:8080/api/v1/pedidos/PED-2026-00001
# Mientras no esté programado: 501 con el formato de error del contrato
```

También están listas las peticiones de `servicio-ventas/peticiones/pedidos.http`.

Si el servicio no arranca con un error de Hibernate del tipo `Schema-validation: missing column` o `wrong column type`, la entidad no coincide con la tabla. Revisa la tabla en Supabase (manda sobre los diagramas); nunca cambies `ddl-auto` a `update`. Ojo: las columnas `char(3)` (`moneda`) necesitan `@JdbcTypeCode(SqlTypes.CHAR)` en la entidad.

### 2.3. Base de datos

- Todos usan la misma base de Supabase. **Nadie crea ni modifica tablas desde el código.**
- Si necesitas otra columna o tabla, pídeselo al líder del proyecto. Él aplica el cambio en Supabase y actualiza `diagrama-fisico.md` y `ventas_postventa_schema.sql`; tú solo actualizas tu entidad.
- Para datos de prueba, cada uno usa códigos con su prefijo en los textos (`"detalle": "prueba joseph"`) y borra lo suyo al terminar.

---

## 3. Reglas comunes para todos

### 3.1. Capas

```text
Controller  →  Service  →  Repository
                  └──────→  Client (integracion/)
```

| Capa | Hace | No hace |
|---|---|---|
| Controller | Recibe el DTO, `@Valid`, llama al service, arma el `ResponseEntity` con el código HTTP | Reglas de negocio, acceso a repositorios |
| Service | Reglas de negocio, `@Transactional`, lanza excepciones del negocio | Saber de HTTP (no devuelve `ResponseEntity`) |
| Repository | Consultas a su tabla | Lógica |
| Client | Llamada HTTP a otro sistema | Decidir reglas |

Paquetes: cada microservicio usa un paquete raíz corto, sin `pe/unmsm/...`:

| Aplicación | Paquete raíz | Carpeta |
|---|---|---|
| `api-gateway` | `gateway` | `api-gateway/src/main/java/gateway/` |
| `servicio-ventas` | `ventas` | `servicio-ventas/src/main/java/ventas/` |
| `servicio-postventa` | `postventa` | `servicio-postventa/src/main/java/postventa/` |

Cada funcionalidad es un subpaquete: `ventas.pedido`, `ventas.anulacion`, `postventa.reembolso`, etc.

**Regla desde F3 (2026-10-12):** `compartido/` (de M1 y de M2) no se modifica sin autorización del líder. Si alguien necesita un cambio ahí, se lo pide antes.

### 3.2. DTOs

- Un `record` por request y por response, en el subpaquete `dto/` de cada funcionalidad.
- Los nombres de los campos son **exactamente** los del contrato (`pedidoId`, `fechaCreacion`, `respuestaVisibleCliente`).
- Nunca se devuelve una entidad JPA en un response.

Ejemplo, `CrearReclamoRequest`: `pedidoId` (opcional en una queja general), `tipo`, `canal` y `motivo` como enums obligatorios (`@NotNull`), `detalle` obligatorio (`@NotBlank`) y `consumidor` obligatorio y validado por dentro (`@NotNull @Valid`).

Cuando el JSON trae un valor que no existe en el enum, Jackson falla; el `GlobalExceptionHandler` debe convertir ese error en `400` (ver 3.3).

### 3.3. Errores

El formato es el del contrato, ya está en `compartido/ErrorResponse.java`:

```json
{ "codigo": "PEDIDO_NO_ENCONTRADO", "mensaje": "...", "timestamp": "2026-09-23T00:05:00Z", "detalles": [] }
```

En `compartido/` de M1 y de M2 (ya hechos) están estas excepciones y su manejo:

| Excepción | HTTP | Uso |
|---|---|---|
| `SolicitudInvalidaException(codigo, mensaje)` | 400 | Dato inválido o regla de formato |
| `RecursoNoEncontradoException(codigo, mensaje)` | 404 | No existe |
| `ConflictoException(codigo, mensaje)` | 409 | Estado no permite la operación, duplicado, sin stock |
| `DependenciaNoDisponibleException(codigo, mensaje)` | 503 | **Obligatoria** cuando otro sistema no responde (M1, Productos, Despacho, almacenamiento, pasarela). La operación no se da por hecha y se puede reintentar — nunca `500` ni una excepción propia para este caso. Ya está en `postventa/compartido/` (agregada en F3, 2026-10-12) |

Cada excepción extiende `RuntimeException` y guarda su `codigo`, que el `GlobalExceptionHandler` copia en la respuesta. Además está `NoImplementadoException` (501, `NO_IMPLEMENTADO`) para los endpoints que todavía no se programan. **Ya están en `ventas/compartido/` y `postventa/compartido/`**: no hay que copiarlas.

En `GlobalExceptionHandler`, además:

| Error de Spring | HTTP | `codigo` |
|---|---|---|
| `MethodArgumentNotValidException` (falla `@Valid`) | 400 | `DATOS_INVALIDOS`, con un elemento en `detalles` por campo |
| `HttpMessageNotReadableException` (JSON mal formado o enum desconocido) | 400 | `FORMATO_INVALIDO` |
| `MissingRequestHeaderException` | 400 | `CABECERA_FALTANTE` |
| `AccessDeniedException` | 403 | `ACCESO_DENEGADO` |
| `MethodArgumentTypeMismatchException` (parámetro con tipo equivocado) | 400 | `FORMATO_INVALIDO` |
| `NoResourceFoundException` (ruta que no existe) | 404 | `RUTA_NO_ENCONTRADA` |
| `HttpRequestMethodNotSupportedException` | 405 | `METODO_NO_PERMITIDO` |
| `MissingServletRequestParameterException` / `MissingServletRequestPartException` | 400 | `PARAMETRO_FALTANTE` |
| `MaxUploadSizeExceededException` | 400 | `ARCHIVO_INVALIDO` |
| Cualquier otra | 500 | `ERROR_INTERNO`, sin el mensaje interno |

Códigos de error usados en esta guía (se pueden agregar otros, siempre en MAYÚSCULAS_CON_GUION):

`PEDIDO_NO_ENCONTRADO`, `CODIGO_INVALIDO`, `MOTIVO_REQUERIDO`, `TRANSICION_NO_PERMITIDA`, `DOCUMENTO_INVALIDO`, `ITEM_SIN_DISPONIBILIDAD`, `MOTIVO_INVALIDO`, `PEDIDO_NO_ANULABLE`, `PEDIDO_NO_ENTREGADO`, `PLAZO_VENCIDO`, `EVIDENCIA_REQUERIDA`, `SIN_STOCK`, `ORIGEN_NO_PERMITIDO`, `CLAVE_IDEMPOTENCIA_EN_CONFLICTO`, `SALDO_INSUFICIENTE`, `CALIFICACION_DUPLICADA`, `RECLAMO_NO_ENCONTRADO`, `RESPUESTA_VACIA`, `ARCHIVO_REQUERIDO`, `ARCHIVO_INVALIDO`, `EVIDENCIA_INVALIDA`, `ITEM_INVALIDO`, `DEVOLUCION_EN_CURSO`, `DEVOLUCION_NO_ENCONTRADA`, `FUNDAMENTO_REQUERIDO`, `RESOLUCION_INVALIDA`, `DEVOLUCION_NO_RESOLUBLE`, `PEDIDO_INCONSISTENTE`, `PAGINACION_INVALIDA`, `PARAMETRO_FALTANTE`, `VENTAS_NO_DISPONIBLE`, `PRODUCTOS_NO_DISPONIBLE`, `ALMACEN_NO_DISPONIBLE` (estos últimos 15, de F3, ya en `catalogo-errores.md`).

### 3.4. Fechas

- En Java: `OffsetDateTime` en UTC (`OffsetDateTime.now(ZoneOffset.UTC)`) y `LocalDate` para columnas `date`.
- En JSON: ISO-8601 con `Z`. En cada `application.yml` van estas dos propiedades:

- `spring.jackson.time-zone: UTC`
- `spring.jackson.serialization.write-dates-as-timestamps: false`

En M1 ya está configurado.

### 3.5. Códigos públicos

El contrato usa códigos legibles (`PED-2026-00981`) y la base usa `id` numérico. Regla única para los dos servicios:

| Recurso | Formato | Se guarda en | El número final es |
|---|---|---|---|
| Pedido | `PED-AAAA-NNNNN` | `pedido.codigo` | `pedido.id` |
| Anulación | `ANUL-NNNN` | No se guarda; se arma con el id | `anulacion.id` |
| Devolución | `DEV-AAAA-NNNN` | No se guarda | `devolucion.id` |
| Reembolso | `REEM-NNNNN` | No se guarda | `reembolso.id` |
| Reclamo | `REC-AAAA-NNNN` | `reclamo.codigo` | `reclamo.id` |

`AAAA` es el año de creación. Así M2 puede guardar `id_pedido` (bigint) tomando el número final de `PED-2026-00981`.

`CodigoPublico` (**ya hecho** en `ventas/compartido/` y `postventa/compartido/`) tiene un método por recurso para armar el código: `pedido(id, anio)`, `anulacion(id)`, `devolucion(id, anio)`, `reembolso(id)` y `reclamo(id, anio)`. Además, `id(codigo)` devuelve el número que va después del último guion; si el código está mal formado, lanza 400 `CODIGO_INVALIDO`.

`pedido.codigo` y `reclamo.codigo` son `NOT NULL` y el `id` lo genera la base. Se guarda con un código temporal y se actualiza en la misma transacción:

1. Guardar con `codigo = CodigoPublico.temporal()` y hacer `saveAndFlush` para que la base asigne el `id`. `temporal()` devuelve `TMP-` + 24 caracteres (28 en total), porque `codigo` es `varchar(30)` y un `"TMP-" + UUID` completo (40) no entra.
2. Reemplazar el código por el definitivo con `CodigoPublico`, en la misma transacción.

Los identificadores de otros módulos (`CLI-8841`, `PROD-101`) se tratan igual: el número final va a `id_cliente` o `id_producto`. **Hay que confirmarlo con G y F** (sección 4).

### 3.6. Transacciones

- `@Transactional` en el método público del service que cambia datos.
- Las llamadas HTTP a otros sistemas **no** van dentro de una transacción larga si se puede evitar: primero se guarda, luego se llama. Si la llamada falla, se reintenta con la misma clave de idempotencia.
- Los eventos de M1 se guardan con `PublicadorEventos.publicar(...)`, que exige estar dentro de una transacción (`Propagation.MANDATORY`).

### 3.7. Clientes simulados

Mientras otro sistema no exista, cada cliente responde datos de prueba. En el `application.yml` de cada servicio va esta propiedad:

- `integracion.simulado: ${INTEGRACION_SIMULADA:true}`

Cómo funciona cada cliente:

- Cada cliente es un `@Component` que recibe la URL base del otro sistema y el valor de `integracion.simulado`.
- Si está en modo simulado, devuelve datos de prueba fijos.
- Si no, llama al otro sistema por HTTP con `RestClient`.

Cada cliente devuelve un `record` propio (por ejemplo `PedidoResumen`), no un `JsonNode`. El record vive en `integracion/` del servicio que lo usa.

**En M2 (`postventa/integracion/`) ya existen estos tres — usar esos, no crear otros:**

- `VentasClient.consultarPedido(pedidoId)`: devuelve `PedidoResumen` (estado, `clienteId`, ítems con precio y `fechaEntrega`). Lo usan F3 y F5. En modo simulado: `PED-AAAA-00404` no existe, `PED-AAAA-00409` está `DESPACHADO`, `PED-AAAA-00030` se entregó hace 30 días; cualquier otro código está `ENTREGADO` hace 2 días.
- `ProductosClient`: disponibilidad para un cambio y reintegro de stock. En modo simulado, `PROD-999` no tiene stock.
- `DespachoClient`: logística de un cambio de producto.

**Pendiente, cuando Seguridad registre `ventas:pedidos:consultar`** (ver `integraciones/ACUERDO_G7_SEGURIDAD.md`): `VentasClient` hoy reenvía el token de quien lo llama al pedir 1.3 a M1 — cuando el scope exista, debe usar el token de servicio propio de M2 en vez de reenviar el de quien llama.

### 3.8. Git (flujo simple)

Solo hay dos tipos de rama:

| Rama | Para qué | Quién sube |
|---|---|---|
| `main` | Código que compila y funciona | Nadie directo: solo por PR, que revisa el líder del proyecto |
| Una por persona: `michael`, `luis-arroyo`, `joseph`, `luis-alejandro`, `johan`, `fabrizio` | Tu trabajo del día a día | Cada uno en la suya |

**La primera vez:**

```bash
git clone https://github.com/Taller-SW-Web/G5-Ventas-Postventas-Backend.git
cd G5-Ventas-Postventas-Backend
git checkout -b joseph        # tu nombre
```

**Cada día:**

```bash
git pull origin main          # traer lo último de main a tu rama
# ... programar ...
git add .
git commit -m "feat(f3): registrar devolución"
git push origin joseph
```

**Cuando terminas un bloque** (por ejemplo, un endpoint con su prueba): abre un PR de tu rama hacia `main`. Cuando el líder lo aprueba y se une, sigues trabajando en la misma rama.

**Mensajes de commit (Conventional Commits):**

```text
tipo(alcance): qué hiciste, en minúsculas y sin punto final
```

| Tipo | Cuándo |
|---|---|
| `feat` | Algo nuevo (endpoint, regla, entidad) |
| `fix` | Corregir un error |
| `test` | Agregar o cambiar pruebas |
| `refactor` | Ordenar código sin cambiar lo que hace |
| `docs` | Documentación |
| `chore` | Configuración, `.gitignore`, `pom.xml` |

Alcance: `f1` a `f6`, `compartido` o `eventos`.

Ejemplos: `feat(f3): registrar devolución`, `fix(f1): validar documento RUC`, `test(f4): idempotencia del reembolso`, `chore: agregar .env.example`.

---

## 4. Decisiones sobre la base y el contrato

Al cruzar contratos, especificaciones y base salieron estos huecos. Las decisiones ya están tomadas y **los cambios en la base ya están aplicados en Supabase**. Nadie vuelve a correr SQL: solo actualicen sus entidades (4.1). Los cambios al contrato están en 4.2.

| # | Hueco | Afecta a | Decisión |
|---|---|---|---|
| H1 | No hay endpoint para que el Gestor apruebe o rechace una anulación pendiente, ni para listar la bandeja (ESP-05 RF-02) | F2 | Agregar dos endpoints (ver 6.4) |
| H2 | `devolucion` no tiene `descripcion`, ítems ni cliente, pero el contrato los pide y lista por `clienteId` | F3 | Agregar columnas y tabla `devolucion_item` |
| H3 | `reembolso` guarda un solo intento, pero ESP-10 exige el historial de intentos; tampoco guarda el pedido, que hace falta para controlar el saldo | F4 | Nueva tabla `reembolso_intento` y columna `reembolso.id_pedido` |
| H4 | El request de reembolso trae `referenciaId` (código del pedido) pero la tabla necesita `id_origen` (id de la anulación o devolución) | F2, F3, F4 | Agregar el campo `origenId` al request |
| H5 | `reclamo` no guarda fecha de registro, fecha de atención, quién atendió ni cliente | F6 | Agregar columnas |
| H6 | El dashboard pide anulados, entregados, devoluciones, reembolsos, CSAT y reclamos pendientes, y no hay tabla para esas métricas | F6 | Nueva tabla `agregado_metricas` por día y canal |
| H7 | El formato de los ids de G (`CLI-8841`) y F (`PROD-101`) no está confirmado | F1, F3 | ~~Usar el número final (3.5) y confirmarlo con G y F~~ — **superado:** `id_cliente`/`id_vendedor`/`id_solicitante`/`id_autorizador` son `uuid` (= claim `sub` del JWT de Seguridad), no texto con número final. Ver `AGENTS.md` sección 2, punto 10 |
| H8 | Las rutas reales de Productos (F), Despacho (E) y Seguridad (G) no están acordadas | Todos | **Superado:** con Productos (G6), Despacho (G2) y Seguridad (G7) ya hay acuerdo formal (`integraciones/ACUERDO_G6_PRODUCTOS.md`, `ACUERDO_G2_DESPACHO.md`, `ACUERDO_G7_SEGURIDAD.md`). La pasarela la hacemos nosotros (9.3) |
| H9 | Falta un actor para cuando Productos rechaza la reserva de stock o el consumo de cupón (no es `CLIENTE`, `GESTOR`, pasarela ni Despacho) | F1 | Aprobado en equipo (2026-10-12): nuevo actor `SISTEMA_PRODUCTOS` y motivos `STOCK_NO_DISPONIBLE`/`CUPON_RECHAZADO`. Ver 5.2 y 6.1 |
| H10 | El pedido `RETAIL` necesita campos que la tabla original no tenía (`tiendaId`, desglose de pago mixto, fecha de venta retroactiva) | F1 | Acuerdo con Retail (G4, 2026-10-12): columnas `pedido.tienda_id` y `pago.monto_efectivo`/`monto_tarjeta`/`fecha_venta`. Ver 4.1 y 5.3 |
| H11 | `postventa.devolucion` no tenía hora de registro, fecha de resolución ni la referencia a la operación derivada (reembolso o despacho de un cambio) — pero `ESP-07` 8.3 y `ESP-08` 8.3 ya prometen devolver esos campos | F3 | Columnas `fecha_registro`, `fecha_resolucion`, `referencia_operacion`. Ver 4.1 |
| H12 | `id_producto` está declarado `bigint` en `ventas.detalle_pedido`, `postventa.devolucion_item` y `postventa.agregado_ventas`, pero Productos (G6) identifica sus SKUs con texto (ej. `"PROD-101"`), nunca un número — detectado 2026-10-16 revisando `DetallePedido.java`/`DevolucionItem.java`, que ya usan `String`/`varchar(64)` | F1, F3, F6 | Cambiar el tipo a `varchar(64)` en las 3 tablas. Ver 4.1 |

### 4.1. Cambios en la base (ya aplicados en Supabase)

Cada responsable actualiza sus entidades para que coincidan con estas columnas y tablas:

| Hueco | Tabla | Qué se agregó | Quién actualiza la entidad |
|---|---|---|---|
| H9 | `ventas.historial_estado.actor` (CHECK) | Se agrega `SISTEMA_PRODUCTOS` a los valores permitidos | Michael (**ya aplicado** — ya está en `ActorHistorial.java` y `MaquinaEstados.java`) |
| H9 | `ventas.evento_recibido.origen` (CHECK) | Se agrega `SISTEMA_PRODUCTOS` | Michael (**ya aplicado**) |
| H9 | `ventas.pedido.reserva_id` | Columna `varchar(100)`, null mientras la reserva está pendiente o en `RETAIL` | Michael (**ya aplicado** — `Pedido.java` ya la usa) |
| H10 | `ventas.pedido.tienda_id` | Columna `varchar(40)`, null salvo `RETAIL` | Michael (**corregido 2026-10-12** — `Pedido.java` y `CrearPedidoService` ya la usan, dejó de guardarse dentro de `direccion`) |
| H10 | `ventas.pago.monto_efectivo`, `monto_tarjeta`, `fecha_venta` | Columnas nuevas para `RETAIL` con `metodoPago: MIXTO` o venta sin conexión | Michael (**corregido 2026-10-12** — `Pago.java` y `CrearPedidoService` ya las guardan) — **falta confirmar con Michael si ya aplicó el `ALTER TABLE` sobre la Supabase real**, no solo en la entidad |
| H11 | `postventa.devolucion.fecha_registro`, `fecha_resolucion`, `referencia_operacion` | Columnas nuevas (ver script en 7.6) | Joseph — **aplicado en Supabase el 2026-10-12**, `Devolucion.java` ya las usa |
| H12 | `ventas.detalle_pedido.id_producto`, `postventa.devolucion_item.id_producto`, `postventa.agregado_ventas.id_producto` | `varchar(64)` en vez de `bigint` | **Ya corregido en las entidades** (`DetallePedido.java`, `DevolucionItem.java`) — **falta confirmar si ya se aplicó el `ALTER TABLE` sobre la Supabase real** |
| F3 (recepción física) | `postventa.devolucion.requiere_devolucion_fisica`, tablas nuevas `postventa.devolucion_recepcion` y `postventa.historial_devolucion` | Ver script actualizado en `infra/bd/ventas_postventa_schema.sql` | **Ya implementado en el código** (`RecepcionDevolucion.java`, `HistorialDevolucion.java`, `RecepcionService.java`) — **falta confirmar si ya se aplicó en Supabase** |
| H2 | `postventa.devolucion` | Columnas `descripcion` e `id_cliente` | Joseph |
| H2 | `postventa.devolucion_item` | Tabla nueva: `id_devolucion`, `id_producto`, `cantidad` (> 0) | Joseph |
| H3 | `postventa.reembolso` | Columna `id_pedido` | Luis Alejandro |
| H3 | `postventa.reembolso_intento` | Tabla nueva: `id_reembolso`, `numero_intento`, `estado` (`PENDIENTE`, `EXITOSO`, `FALLIDO`), `id_transaccion`, `resultado`, `fecha_hora`. Un número de intento por reembolso | Luis Alejandro |
| H5 | `postventa.reclamo` | Columnas `id_cliente`, `fecha_registro`, `fecha_atencion` y `atendido_por` | Fabrizio |
| H6 | `postventa.agregado_metricas` | Tabla nueva por `(fecha, canal)` con los contadores del dashboard (`pedidos_pagados`, `pedidos_anulados`, `pedidos_entregados`, `devoluciones_aprobadas`, `monto_reembolsado_pen`, `csat_suma`, `csat_cantidad`, `reclamos_registrados`, `reclamos_atendidos`) y `actualizado_en` | Fabrizio |

H2, H3, H5 y H6 aplicados en Supabase con la migración `huecos_h2_h3_h5_h6_postventa` (10/10/2026). H9 (`SISTEMA_PRODUCTOS`, `reserva_id`) ya está aplicado — Michael lo confirma corriendo contra Supabase real. **H10 (`tienda_id`, `monto_efectivo`, `monto_tarjeta`, `fecha_venta`) está en `diagrama-fisico.md`/`ventas_postventa_schema.sql` pero falta confirmar con el líder del proyecto si ya se aplicó sobre la Supabase real** — mientras tanto, el servicio puede arrancar sin esas columnas en la entidad (no da error porque Hibernate no las conoce), pero no las va a poder usar hasta que la entidad las declare y existan de verdad en la base.

Los nombres exactos y los tipos están en `diagrama-fisico.md` y en `ventas_postventa_schema.sql`, actualizados el 12/10/2026 para que coincidan con Supabase. Si alguna vez no coinciden, manda Supabase. Lo que más hay que tener en cuenta:

- `ventas.outbox_evento` y `ventas.evento_recibido` no tienen `id`: su clave primaria es `id_evento`.
- `ventas.pago.estado` solo acepta `PENDIENTE`, `CONFIRMADO` y `RECHAZADO`.
- `postventa.evento_recibido` tiene `id_evento` (uuid, clave primaria), `tipo` y `recibido_en`.
- `postventa.reclamo` tiene además la columna `canal`.

### 4.2. Cambios al contrato (H1, H4)

| Contrato | Agregar |
|---|---|
| `api-ventas.md` | `GET /api/v1/pedidos/anulaciones/pendientes` y `PATCH /api/v1/pedidos/{pedidoId}/anulaciones/{anulacionId}` (detalle en 6.4) |
| `api-postventas.md` | Campo `origenId` en `POST /api/v2/reembolsos`: código de la anulación (`ANUL-0012`) o de la devolución (`DEV-2026-0042`) |

---

## 5. M1 — F1 Ciclo de vida del pedido (Michael)

Especificaciones: ESP-01, ESP-02, ESP-03, ESP-04. Contrato: `api-ventas.md` 1.1 a 1.6.

### 5.1. Endpoints

| # | Método y ruta | Autorización | Respuesta OK | Service |
|---|---|---|---|---|
| 1.1 | `POST /api/v1/pedidos` | scope `ventas:pedidos:crear` (token de servicio del canal) | 201 | `PedidoService.crear` |
| 1.2 | `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` | scope `ventas:pagos:webhook` | 200 | `PagoService.procesarNotificacion` |
| 1.3 | `GET /api/v1/pedidos/{pedidoId}` | rol `CLIENTE` (dueño del pedido) o `ADMIN_VENTAS` — **no es scope** | 200 | `PedidoService.consultar` |
| 1.4 | `GET /api/v1/pedidos` (uso administrativo, filtra por `clienteId`) | rol `ADMIN_VENTAS` — **no es scope** | 200 | `PedidoService.listar` |
| 1.4b | `GET /api/v1/pedidos/me` (acuerdo H-03) | rol `CLIENTE`, identidad por `sub` del JWT, sin `clienteId` en la URL — **no es scope** | 200 | `PedidoService.listarMios` |
| 1.5 | `POST /api/v1/integraciones/despachos/eventos` (reemplaza el viejo 1.5/1.6, ver 5.6/5.7) | scope `ventas:pedidos:estado` (token de servicio de Despacho, reusado — decisión nuestra, 2026-10-13) | 200 | `LogisticaService.procesarEvento` |
| 1.11 | `POST /api/v1/pedidos/reemplazos` (nuevo, 2026-10-16 — F3, acuerdo con Productos issue G6 #100, ver 5.10) | scope `ventas:pedidos:reemplazar` (token de servicio de `modulo-postventa`, pendiente de que Seguridad lo registre) | 201/200 | `ReemplazoService.crear` |

`ventas:pedidos:leer` y `ventas:admin` **no son scopes reales** — Seguridad no los registra porque dependen de identidad de persona, no de módulo. Se resuelven con el claim `roles` del token de usuario (ver sección 12 y `api-ventas.md`, catálogo de scopes).

### 5.2. Primero: `MaquinaEstados` (lo necesitan F1 y F2)

Es la única clase que cambia `pedido.estado`. Valida la matriz de ESP-03, guarda el historial y publica el evento, todo en la misma transacción.

**Ya está hecha** en `ventas/pedido/MaquinaEstados.java`, con su prueba. Se usa así: `maquinaEstados.cambiar(pedido, destino, actor, motivo)`.

Matriz de ESP-03 (sección 7.2), actualizada al 2026-10-12 con Retail (G4) y el rechazo de Productos:

| Desde | Hacia | Actores permitidos | Motivo |
|---|---|---|---|
| `CREADO` | `PAGADO` | `PASARELA_PAGOS` | — |
| `CREADO` | `ANULADO` | `PASARELA_PAGOS`, `CANAL_CHATBOT`, `CLIENTE`, `GESTOR`, `SISTEMA_PRODUCTOS` | `PAGO_NO_COMPLETADO` / catálogo ESP-05 / `STOCK_NO_DISPONIBLE` / `CUPON_RECHAZADO` |
| `PAGADO` | `EN_PREPARACION` | `SISTEMA_LOGISTICA` | — |
| `PAGADO` | `ENTREGADO` | `CLIENTE` — **solo `RETAIL`** (acuerdo G4) | `ENTREGA_INMEDIATA_EN_TIENDA` |
| `PAGADO` | `ANULADO` | `CLIENTE`, `GESTOR`, `SISTEMA_PRODUCTOS` (caso Chatbot: cobró antes de que Productos confirmara stock) | catálogo ESP-05 / `STOCK_NO_DISPONIBLE` |
| `EN_PREPARACION` | `DESPACHADO` | `SISTEMA_LOGISTICA` | — |
| `EN_PREPARACION` | `ANULADO` | `GESTOR` | catálogo ESP-05 |
| `DESPACHADO` | `ENTREGADO` | `SISTEMA_LOGISTICA` | — |
| `DESPACHADO` | `ANULADO` | `SISTEMA_LOGISTICA` | `ENTREGA_FALLIDA_DEFINITIVA` |

**Corregido (2026-10-12):** la fila `PAGADO → ANULADO` ya incluye `SISTEMA_PRODUCTOS` en `MaquinaEstados.PERMITIDAS`. `ResultadoReservaService.rechazada()` registra la anulación (nueva clase `AnulacionSistemaService`, bien aislada de F2 — no pisa el trabajo de Luis Arroyo) y dispara el reembolso automático a M2.

Qué hace `cambiar(...)`:

1. Si la transición o el actor no están en la matriz: 409 `TRANSICION_NO_PERMITIDA`.
2. Para `PAGADO → ENTREGADO`, además valida que el canal sea `RETAIL`; si no, 409 (aunque el actor esté permitido en general).
3. Si el destino es `ANULADO` y no hay motivo: 400 `MOTIVO_REQUERIDO`.
4. Cambia el estado y guarda una fila en `historial_estado` (estado anterior, nuevo, actor, motivo y fecha UTC — o `fechaVenta` para `PAGADO → ENTREGADO` de una venta `RETAIL` sin conexión).
5. Si el destino es `PAGADO`, `ANULADO` o `ENTREGADO`, publica el evento correspondiente en el outbox.
6. Exige una transacción ya abierta (`Propagation.MANDATORY`): quien la llama debe tener `@Transactional`.

El formato del evento está en la sección 11.

Luis Arroyo ya puede usarla para F2.

### 5.3. 1.1 Crear pedido (ESP-01)

**Ya construido** en `CrearPedidoService` (Michael). Esta sección describe el estado real del código al 2026-10-12, no una propuesta — si lo que sigue no coincide con lo que ves en el repo, manda el repo y avisa en el grupo.

Pasos del service, en este orden:

1. `validarClave(Idempotency-Key)`: obligatoria, UUID v4, máximo 128 caracteres — si falta o está mal formada, 400 `CABECERA_FALTANTE`.
2. Validar el request (`ValidadorPedido`):
   - `contacto.tipoDocumento`/`numeroDocumento` contra la tabla de regex (igual que antes).
   - Al menos `telefono` o `email`.
   - **Si `canal` no es `RETAIL`:** `envio` obligatorio con `direccion`, `distrito` y `destinatario`.
   - **Si `canal` es `RETAIL`:** `envio.tiendaId` obligatorio (el resto de `envio` se ignora); `pago.metodoPago` debe ser `EFECTIVO`, `TARJETA_POS` o `MIXTO`; `referenciaOperacion` obligatorio salvo `EFECTIVO`; con `MIXTO`, `montoEfectivo` + `montoTarjeta` deben sumar `total`; si viene `fechaVenta`, no puede ser futura ni tener más de 72 h (400 `FECHA_VENTA_FUERA_DE_RANGO`).
   - `pago.subtotal` = suma de ítems; `pago.total = subtotal − descuentoCupon + costoEnvio`. Si no cuadra: 400 `MONTOS_INCONSISTENTES`.
3. Buscar por `Idempotency-Key`: si ya existe un pedido con esa clave y el **mismo** cuerpo, se devuelve ese pedido (`creado = false`, 200). Con cuerpo distinto: 409 `IDEMPOTENCY_KEY_REUSED`.
4. **Reserva de stock — distinto según el canal:**
   - **Marketplace y Chatbot:** `ProductosClient.reservar(clave, clienteId, items)` antes de guardar el pedido. La respuesta es asíncrona (`202 Accepted` solo admite el comando); el resultado real (confirmada o rechazada) llega después por `po.sales.q` y lo procesa `ResultadoReservaService` — ver más abajo. **No** hay una validación síncrona de `ITEM_SIN_DISPONIBILIDAD` en la creación: el pedido se guarda igual y se anula después si Productos rechaza.
   - **Retail:** no se reserva nada — el POS ya vendió en tienda. La `Idempotency-Key` sirve de referencia para cuando llegue el resultado de la conciliación offline (acuerdo G4, R9).
5. En una sola transacción (`registrar(...)`):
   - **Estado inicial:** `CREADO` para Marketplace/Chatbot; `PAGADO` para `RETAIL` (el cobro ya pasó por el POS).
   - Guardar `pedido`: `fecha` = la fecha real, salvo `RETAIL` con `fechaVenta`, que usa esa fecha; `codigo` temporal (3.5) y se reemplaza tras el `saveAndFlush`; `id_cliente` = `contacto.clienteId` (UUID, **no** un número final — ver H7).
   - Guardar cada `detalle_pedido` con `sku`, `descripcion`, `id_producto` e `importe`.
   - Guardar `pago`: `metodo`, `monto = total`, `referencia = referenciaOperacion`. `estado = CONFIRMADO` si el pedido nace `PAGADO` (Retail), si no `PENDIENTE`.
   - Guardar el primer `historial_estado` (`estado_anterior = null`): actor `CANAL_CHATBOT` si es Chatbot, `CLIENTE` en los demás casos (incluido Retail), motivo `"Registro inicial de compra"`, `fechaHora` = la hora real de la llamada (nunca `fechaVenta`, eso solo va en el siguiente punto).
   - **Solo Retail:** en la misma operación, `maquina.cambiar(pedido, ENTREGADO, CLIENTE, "ENTREGA_INMEDIATA_EN_TIENDA", fechaHora)` — con `fechaHora = fechaVenta` si vino, si no la hora real.
6. Fuera de la transacción: si hubo reserva de stock (Marketplace/Chatbot), se procesa el resultado — en modo simulado llega al instante (`ResultadoReservaService.procesar`); en modo real llega por el listener de `po.sales.q` (**todavía no existe**, ver tema 1 de la guía de Productos).
7. Responder 201 con `pedidoId`, `estado`, `total`, `moneda`, `canal`, `fechaCreacion`.

**Resultado de la reserva de stock** (`ResultadoReservaService`, Marketplace/Chatbot únicamente):

- **Confirmada:** guarda `reservaId` en el pedido. Si es Marketplace y sigue `CREADO`, recién ahí se pide el cobro al simulador (`PasarelaClient.iniciarCobro`). Si es Chatbot y ya está `PAGADO` (cobró por su cuenta), se confirma el consumo con Productos.
- **Rechazada, pedido `CREADO`:** `maquina.cambiar(pedido, ANULADO, SISTEMA_PRODUCTOS, "STOCK_NO_DISPONIBLE")` — automático, sin Gestor. **Ya construido.**
- **Rechazada, pedido `PAGADO`** (Chatbot cobró antes de que llegara el resultado): **pendiente** — el equipo ya decidió (2026-10-12) anular automático con reembolso (opción A), falta implementarlo (ver 5.2).

Mapeo del request a la tabla `pedido` (no `RETAIL`):

| Request | Columna |
|---|---|
| `canal` | `canal` |
| `contacto.clienteId` | `id_cliente` (uuid) |
| `contacto.nombreCompleto` | `nombre_contacto` |
| `contacto.tipoDocumento`, `numeroDocumento`, `telefono`, `email` | Mismas columnas |
| `envio.modalidad`, `costo`, `destinatario`, `distrito`, `direccion` | `modalidad_envio`, `costo_envio`, `destinatario`, `distrito`, `direccion` |
| `cupon.codigo`, `cupon.descuento` | `codigo_cupon`, `descuento` |
| `pago.moneda`, `subtotal`, `total` | `moneda`, `subtotal`, `total` |
| Cabecera `Idempotency-Key` | `idempotency_key` |

Mapeo adicional para `RETAIL` — **corregido 2026-10-12** (ver H10, 4.1): `envio.tiendaId` ya se guarda en `pedido.tienda_id`, y `pago.montoEfectivo`/`montoTarjeta`/`fechaVenta` en sus columnas reales de `pago`.

`envio.departamento`, `provincia` y `referencia` no tienen columna: no se guardan.

### 5.4. 1.2 Notificación de pago (ESP-03)

1. Si `transaccionId` ya está en `ventas.evento_recibido` con origen `PASARELA_PAGOS`: responder 200 con el estado actual del pedido, sin cambiar nada.
2. Buscar el pedido por código. No existe: 404.
3. Validar `resultado` (`ResultadoPasarela`), `monto = pedido.total` y `moneda = pedido.moneda`. Si no: 400.
4. Si el pedido no está en `CREADO`: 409 (ESP-03 flujo C: notificación tardía).
5. En una transacción:
   - Actualizar `pago`: `estado = resultado.aEstadoPago()`, `referencia = transaccionId`, `fecha_proceso = fechaPago`.
   - `APROBADO`: `maquinaEstados.cambiar(pedido, PAGADO, PASARELA_PAGOS, "Confirmación de cobro exitoso")`.
   - `RECHAZADO`: `maquinaEstados.cambiar(pedido, ANULADO, PASARELA_PAGOS, "PAGO_NO_COMPLETADO")` y llamar a F2 para que registre la anulación y reponga stock (`AnulacionService.registrarPorPagoRechazado`).
   - Guardar `evento_recibido(id_evento = transaccionId, origen = PASARELA_PAGOS)`.
6. Responder 200 con `pedidoId`, `nuevoEstado`, `transaccionId`, `fechaTransicion`.

### 5.5. 1.3 y 1.4 Consultar y listar (ESP-02)

- **Consultar**: devuelve el pedido completo con `items` y `historialEstados` ordenados por `fecha_hora` ascendente.
- **Propiedad**: si el token es de canal o cliente y su `clienteId` no es el del pedido: 403. El Gestor (`ventas:admin`) ve todo. Mientras la seguridad esté apagada, no se valida.
- **Listar**: filtros `clienteId`, `estado`, `desde`, `hasta`, `pagina` (default 0), `tamano` (default 10). Usar `Pageable` y una consulta con `Specification` o `@Query`. Respuesta con `contenido`, `pagina`, `totalPaginas`, `totalElementos`.
- `ultimaActualizacion` es la `fecha_hora` del último historial.

### 5.6 y 5.7. **Cambiaron de diseño (2026-10-12) — no construir lo de abajo tal cual**

Despacho (G2) confirmó que no van a llamar a `PATCH /pedidos/{id}/estado` ni a `POST /eventos-logistica` — adoptan su propio webhook genérico. El diseño real ahora es **un solo endpoint** `POST /api/v1/integraciones/despachos/eventos` (ver `api-ventas.md` 1.5, ya actualizado) que recibe los 7 tipos de evento de Despacho y aplica el mapeo de la tabla de ahí. La idempotencia es por `idEvento` (no por `guiaRemision + evento`, ese campo ya no existe). `DESPACHO_DEVUELTO_A_ORIGEN` hace lo mismo que hacía el viejo 1.6 (`DESPACHADO → ANULADO`, reembolso a M2 con origen `ANULACION`), solo que ahora es un caso dentro del mismo endpoint, no uno aparte.

**Scope: cerrado.** Se reusa `ventas:pedidos:estado` (ya concedido a `modulo-despacho`); no se pide el `despachos:eventos:recibir` que propuso G2 — decisión nuestra, 2026-10-13, ver `integraciones/ACUERDO_G2_DESPACHO.md`.

**Pendiente antes de programarlo** (ya no depende de G2, ver `api-ventas.md` 1.5 y `integraciones/ACUERDO_G2_DESPACHO.md`):
- Agregar `pedido.fecha_estimada_entrega` al modelo de datos (confirmado necesario, falta la migración) para que `DESPACHO_REPROGRAMADO` la actualice con `datos.nuevaFechaProgramada`.
- Definir la señal interna que marca "paquete sellado y listo" para disparar `POST /api/v1/despachos` (no apenas `EN_PREPARACION`) — diseño de F1/frontend, pendiente.
- F2: manejar el `409 Conflict` de Despacho al cancelar un despacho ya `EN_CAMINO` como rechazo de negocio (no reintentar, marcar la anulación como improcedente), no como la falla técnica de ESP-06 CA-05 — ver ESP-06 CA-06 (nuevo).

<details>
<summary>Diseño anterior (ya no vigente, se deja solo como referencia de lo que cambió)</summary>

- 1.5 validaba `nuevoEstado`/`actor` y llamaba a `maquinaEstados.cambiar(...)` directo.
- 1.6 solo aceptaba `evento = ENTREGA_FALLIDA_DEFINITIVA`, idempotencia por `guiaRemision + ":" + evento`, y llamaba a `AnulacionService.anularPorEntregaFallida(pedido, motivo)`.

</details>

### 5.8. Envío de eventos (`EnvioEventosScheduler`)

1. Cada 5 s (`integracion.eventos.intervalo-ms`), toma hasta 50 eventos de `outbox_evento` sin enviar, del más antiguo al más nuevo.
2. Por cada uno llama a `PostventaClient.enviarEvento` (`POST /api/v2/eventos` de M2).
3. Si M2 responde bien, marca `enviado_en`. Si falla, suma 1 a `intentos` y lo deja para la siguiente vuelta.

Agregar `enviarEvento(String payloadJson)` a `PostventaClient`. En modo simulado solo registra en el log.

### 5.9. Lista para terminar F1

Al 2026-10-12, revisando el repo directamente:

- [x] `compartido/`: excepciones, `GlobalExceptionHandler` completo, `CodigoPublico`, Jackson en UTC
- [x] `MaquinaEstados` con su prueba (todas las filas de la matriz y al menos 5 transiciones prohibidas), incluyendo `SISTEMA_PRODUCTOS` en `PAGADO → ANULADO` (corregido 2026-10-12, ver 5.2)
- [x] Entidades de M1 validadas contra Supabase (`servicio-ventas` arranca) y `EventoRecibido` listo para la idempotencia de 1.2 y 1.6
- [x] 1.1 crear, con validación de documento, total, idempotencia y la variante Retail — `tienda_id`/`monto_efectivo`/`monto_tarjeta`/`fecha_venta` ya se guardan en sus columnas reales (corregido 2026-10-12, ver H10)
- [x] `ResultadoReservaService` listo para aplicar la respuesta de la reserva (confirmada/rechazada) — **falta** el `@RabbitListener` real de `po.sales.q` (hoy solo se llama en modo simulado desde `CrearPedidoService`)
- [x] 1.2 notificación de pago, idempotente
- [x] 1.4b (`/pedidos/me`, acuerdo H-03) — `PedidoService.listarMios`
- [ ] 1.3 y 1.4 consultar y listar — hoy son stubs (`NoImplementadoException`, 501)
- [ ] 1.5 (nuevo diseño, webhook único) — todavía sin construir, mejor así porque el diseño cambió (ver 5.6/5.7); **las rutas viejas `PATCH .../estado` y `POST .../eventos-logistica` que hoy están mapeadas como stubs en el controller hay que borrarlas, no implementarlas**
- [ ] Consumo y restauración de cupón por RabbitMQ (`promotions.coupon.consumption.requested`) — no hay nada programado todavía, incluyendo el motivo `CUPON_RECHAZADO` (ver 6.1)
- [ ] `EnvioEventosScheduler` y `PostventaClient.enviarEvento`
- [ ] Criterios de aceptación de ESP-01 a ESP-04 probados
- [x] 1.11 orden de reemplazo (`ReemplazoService`) — construido 2026-10-16, ver 5.10

### 5.10. 1.11 Orden de reemplazo (`ReemplazoService`, construido 2026-10-16)

F3 lo invoca al aprobar un `CAMBIO` (ESP-08, flujo B). Resuelve lo que antes iba a ser una coordinación directa de M2 con Despacho — ahora M1 crea un pedido normal, sin cobro:

1. Valida que `pedidoOrigenId` exista y esté `ENTREGADO` (si no: 404/409), y que su canal no sea `RETAIL` (409 `REEMPLAZO_NO_APLICA` — esos cambios se hacen en tienda).
2. Cada `sku` del body debe pertenecer a una línea del pedido original, y la cantidad pedida no debe exceder la comprada (400 `ITEM_NO_PERTENECE_AL_PEDIDO` / `CANTIDAD_EXCEDE_COMPRADA`).
3. Crea el `Pedido` con `tipo: REEMPLAZO`, `idPedidoOrigen`, `devolucionId`, copiando contacto/dirección del original; `total = 0` (sin fila de `Pago` — el cliente ya pagó el original).
4. Llama a `ProductosClient.reservar(...)` — el mismo método de 1.1, mismo scope, nada nuevo que pedirle a Productos.
5. **Idempotente por `devolucionId`:** un índice único (`ux_pedido_reemplazo_vigente`, solo `estado <> ANULADO`) impide dos reemplazos vigentes de la misma devolución. Si ya existe uno, responde `200` con ese mismo pedido en vez de crear otro; si la carrera la gana otra petición, captura el `DataIntegrityViolationException` y hace lo mismo.
6. Si Productos confirma la reserva (modo simulado: al instante): `CREADO → EN_PREPARACION` (actor `SISTEMA_PRODUCTOS`, sin pasar por `PAGADO` — ver `MaquinaEstados`, transiciones exclusivas de `REEMPLAZO`). Sigue el flujo normal de F1 (Gestor marca "paquete sellado" → Despacho).
7. Si Productos rechaza o vence la reserva: `→ ANULADO` (actor `SISTEMA_PRODUCTOS`, motivo `STOCK_NO_DISPONIBLE`) y M1 publica `pedido.anulado` con `datos.devolucionId` — `DevolucionService.reemplazoAnulado` en M2 reabre la devolución a `EN_EVALUACION`.
8. Al entregarse, `pedido.entregado` con `datos.devolucionId` — `DevolucionService.reemplazoEntregado` en M2 cierra el lado logístico del cambio.

Ver `api-ventas.md` 1.11, `ESP-03` 7.2 (nuevas transiciones) y `ESP-08` 8.1/flujo B/reglas 7, 17, 18.

---

## 6. M1 — F2 Anulación de pedidos (Luis Arroyo)

Especificaciones: ESP-05, ESP-06. Contrato: `api-ventas.md` 1.7 + H1.

### 6.1. Catálogo de motivos (`MotivoAnulacion`)

| Motivo | Se puede usar con el pedido en |
|---|---|
| `PAGO_NO_COMPLETADO` | `CREADO` |
| `ERROR_SELECCION_PRODUCTO` | `CREADO`, `PAGADO` |
| `ARREPENTIMIENTO_COMPRA` | `CREADO`, `PAGADO` |
| `SOLICITUD_CLIENTE` | `CREADO`, `PAGADO`, `EN_PREPARACION` |
| `ERROR_DATOS_ENVIO` | `CREADO`, `PAGADO`, `EN_PREPARACION` |
| `DUPLICADO` | `CREADO`, `PAGADO` |
| `ENTREGA_FALLIDA_DEFINITIVA` | `DESPACHADO` (solo por 1.6, nunca por 1.7) |
| `STOCK_NO_DISPONIBLE` | `CREADO`, `PAGADO` (caso Chatbot) — **no es por 1.7**, ver nota |
| `CUPON_RECHAZADO` | `CREADO` únicamente — **no es por 1.7**, ver nota |

El enum debe poder responder si un motivo aplica a un estado dado.

**`STOCK_NO_DISPONIBLE` y `CUPON_RECHAZADO` no pasan por el endpoint 1.7 ni por `AnulacionService`:** las dispara Productos de forma asíncrona (actor `SISTEMA_PRODUCTOS`), y hoy el propio F1 las aplica directo con `maquinaEstados.cambiar(...)` desde `ResultadoReservaService` (ver 5.3). Se incluyen aquí solo para que el catálogo quede completo y Luis Arroyo sepa que puede aparecer ese motivo en el historial sin que él lo haya disparado. Si el cupón se rechaza con el pedido ya `PAGADO`, no se anula — queda como inconsistencia para que el Gestor la revise (ESP-01 regla 12), eso tampoco es parte de F2.

### 6.2. 1.7 Solicitar anulación

1. `motivo` ausente o fuera del catálogo: 400 `MOTIVO_INVALIDO`. `ENTREGA_FALLIDA_DEFINITIVA` por este endpoint: 400.
2. Pedido en `DESPACHADO` o `ENTREGADO`: 409 `PEDIDO_NO_ANULABLE`, mensaje "corresponde iniciar una devolución (F3)".
3. Pedido ya `ANULADO`: 409.
4. Motivo que no aplica al estado (por ejemplo `DUPLICADO` en `EN_PREPARACION`): 400.
5. Actor: `CANAL_CHATBOT` si el motivo es `PAGO_NO_COMPLETADO`; `GESTOR` si el token tiene el rol `ADMIN_VENTAS` (claim `roles`, **no es scope** — ver sección 12); `CLIENTE` en los demás casos.
6. Según el estado:

| Estado | Qué se hace | Respuesta |
|---|---|---|
| `CREADO` o `PAGADO` | Guardar `anulacion` con `EJECUTADA`, `maquinaEstados.cambiar(..., ANULADO, actor, motivo)`, ejecutar efectos | 200 con `autorizacionRequerida: false` |
| `EN_PREPARACION` | Guardar `anulacion` con `PENDIENTE_AUTORIZACION`. El pedido no cambia | 202 con `solicitudAnulacionId` (`ANUL-NNNN`) |

`anulacion.id_pedido` es único: si ya existe una anulación `PENDIENTE_AUTORIZACION` para ese pedido, 409. Si existe una `RECHAZADA`, se reutiliza la fila (se actualiza a la nueva solicitud) para no romper la restricción única.

### 6.3. Efectos (`EfectosAnulacionService`, ESP-06)

| Anulado desde | Reponer stock | Cancelar despacho | Pedir reembolso a M2 |
|---|---|---|---|
| `CREADO` (por F2: Cliente/Gestor/`PAGO_NO_COMPLETADO`) | Sí, libera la reserva (`productosClient.liberar`) | No | No (nunca se cobró) |
| `PAGADO` (por F2) | Sí | No | Sí |
| `EN_PREPARACION` (aprobada) | Sí | Sí | Sí |
| `DESPACHADO` (entrega fallida) | Sí (el producto vuelve al almacén) | No | Sí |

**Caso aparte, no es F2:** cuando Productos rechaza la reserva (`STOCK_NO_DISPONIBLE`), nunca hubo una reserva confirmada que liberar — Productos mismo está avisando que no hay stock. `ResultadoReservaService` no llama a `liberar`, y Luis Arroyo no necesita hacer nada para ese caso (ver 6.1).

#### 6.3.1. Liberar stock al anular (pendiente, F2)

El método ya existe en `ProductosClient` (Michael). Falta usarlo en `AnulacionService`, después de guardar la anulación y el cambio de estado (1.7 y 1.9):

```java
if (pedido.getCanal() != CanalVenta.RETAIL && pedido.getReservaId() != null) {
    productosClient.liberar(pedido.getReservaId());
}
```

- `RETAIL` nunca reserva stock (acuerdo G4, R9), por eso queda excluido.
- Si `reservaId` todavía no llegó (la respuesta de Productos es async, ver 5.3), no hace nada ahora: cuando `ResultadoReservaService` procese la confirmación tardía sobre un pedido ya `ANULADO`, libera solo (ver el `switch` de `aplicar(...)` en `ResultadoReservaService`, caso `ANULADO → Accion.LIBERAR`).

**También pendiente:** antes de ejecutar la anulación, consultar a Seguridad (`GET /usuarios/{clienteId}`, scope `usuarios:leer`) que la cuenta del cliente siga activa — acuerdo A10, ver `AGENTS.md` sección 2 punto 11.

Reembolso a M2 (`PostventaClient.solicitarReembolso`):

```text
POST /api/v2/reembolsos
X-Idempotency-Key: ANULACION-{anulacion.id}           ← siempre la misma para la misma anulación
{
  "origen": "ANULACION",
  "referenciaId": "PED-2026-00981",
  "origenId": "ANUL-0012",
  "monto": <pedido.total>,
  "moneda": "PEN",
  "motivo": "<motivo>",
  "solicitadoPor": "SISTEMA_M1"
}
```

- Los efectos se ejecutan **después** de guardar la anulación y el cambio de estado.
- Si una llamada falla, la anulación queda hecha y se registra el error en el log. Se reintenta con la misma clave; M2 no crea un segundo reembolso.
- `solicitudReembolsoGenerada` en la respuesta es `true` si M2 respondió 201.

### 6.4. Bandeja del Gestor (H1, agregar al contrato)

```text
GET /api/v1/pedidos/anulaciones/pendientes?pagina=0&tamano=10      rol ADMIN_VENTAS (no es scope)
→ 200 { "contenido": [ { "solicitudAnulacionId": "ANUL-0012", "pedidoId": "PED-2026-00981",
                         "motivo": "SOLICITUD_CLIENTE", "fechaSolicitud": "2026-09-23" } ],
        "pagina": 0, "totalPaginas": 1, "totalElementos": 1 }

PATCH /api/v1/pedidos/{pedidoId}/anulaciones/{anulacionId}           rol ADMIN_VENTAS (no es scope)
{ "decision": "APROBADA" | "RECHAZADA", "autorizadorId": "GESTOR-03", "comentario": "..." }
→ 200 { "pedidoId": "...", "estadoPedido": "ANULADO" | "EN_PREPARACION", "estadoAnulacion": "EJECUTADA" | "RECHAZADA" }
```

- `APROBADA`: `id_autorizador`, `estado = EJECUTADA`, `maquinaEstados.cambiar(pedido, ANULADO, GESTOR, motivo)`, efectos.
- `RECHAZADA`: `estado = RECHAZADA`, el pedido no cambia (ESP-05 CA-06). `comentario` obligatorio.
- Si la anulación no está `PENDIENTE_AUTORIZACION`: 409.
- Si el pedido ya no está en `EN_PREPARACION` (por ejemplo, ya salió a despacho): 409, y la anulación pasa a `RECHAZADA`.

En el controller, la ruta `/anulaciones/pendientes` debe declararse antes que `/{pedidoId}` para que Spring no la confunda (o usar `@GetMapping("/anulaciones/pendientes")` en `AnulacionController`; Spring prioriza la ruta literal).

### 6.5. Métodos que usa F1

**Corregido (2026-10-12), opción A elegida:** `NotificacionPagoService` (1.2) resuelve el pago rechazado solo, sin pasar por F2 — después de `maquinaEstados.cambiar(..., ANULADO, PASARELA_PAGOS, ...)` llama directo a `ProductosClient.liberar(reservaId)` (o `confirmar` si el resultado fue aprobado), y si había cupón aplicado, también a `productos.restaurarCupon(...)`. Maneja bien la carrera con la reserva: si `reservaId` todavía no llegó cuando se procesa el pago, `ResultadoReservaService` la libera apenas llegue, viendo el pedido ya `ANULADO`. No quedó ningún método nuevo para F2 — `registrarPorPagoRechazado` que proponía esta guía originalmente no se construyó, ni hace falta.

| Método | Lo llama | Qué hace |
|---|---|---|
| `anularPorEntregaFallida(Pedido, String detalle)` | El service de 1.6 (hoy es un stub en `PedidoController`, no existe todavía — ver 5.9) | `DESPACHADO → ANULADO` con `SISTEMA_LOGISTICA`, repone stock y pide reembolso |

**Ojo:** el webhook de Despacho (1.5, nuevo diseño) todavía no está implementado (ver 5.9), así que `anularPorEntregaFallida` tampoco se puede probar de punta a punta todavía.

### 6.6. Lista para terminar F2

- [ ] `MotivoAnulacion` y validaciones de 6.2 (`STOCK_NO_DISPONIBLE`/`CUPON_RECHAZADO` NO van aquí, ver 6.1)
- [ ] Anulación directa (`CREADO`, `PAGADO`) y pendiente (`EN_PREPARACION`) — ojo con la tabla `ventas.anulacion`: Michael ya la usa (`AnulacionSistemaService`) para el caso de stock rechazado tras pago, revisarla antes de diseñar la tuya para no chocar con sus filas `EJECUTADA`
- [ ] Efectos según la tabla de 6.3, incluyendo liberar stock (6.3.1) con clave de idempotencia fija
- [ ] Verificar con Seguridad que la cuenta del cliente siga activa antes de anular (6.3.1)
- [ ] Bandeja: listar pendientes, aprobar y rechazar
- [ ] Criterios de aceptación CA-01 a CA-06 de ESP-05 y los de ESP-06

---

## 7. M2 — F3 Devoluciones y cambios (Joseph)

Especificaciones: ESP-07, ESP-08. Contrato: `api-postventas.md` 2.1 a 2.5 (v1.5.0). Usa los cambios de H2 y H11 (4.1).

**Ya construido** (F3 completo, en `main` del backend, con pruebas en verde desde el 2026-10-12). Esta sección describe el estado real del código, no una propuesta.

### 7.1. Valores

| Campo | Valores |
|---|---|
| `tipo` (`TipoDevolucion`) | `CAMBIO`, `DEVOLUCION_DINERO` |
| `motivo` (`MotivoDevolucion`) | `PRODUCTO_DEFECTUOSO`, `PRODUCTO_DANADO`, `PRODUCTO_INCORRECTO`, `OTRO` |
| Motivos que exigen evidencia | `PRODUCTO_DEFECTUOSO`, `PRODUCTO_DANADO`, `PRODUCTO_INCORRECTO` |
| `estado` | `SOLICITADA`, `EN_EVALUACION`, `APROBADA`, `RECHAZADA`, `COMPLETADA` |
| `resolucion` (columna) | `CAMBIO`, `REEMBOLSO`, `RECHAZO` |
| Plazo | 7 días naturales desde la entrega |

### 7.2. 2.1 Subir evidencia

1. `file` obligatorio. Tipo `image/jpeg`, `image/png`, `image/webp` o `application/pdf`; máximo 5 MB. Si no: 400.
2. Guardar el archivo en Supabase Storage (bucket `evidencias`) con un nombre único (`UUID` + extensión). `AlmacenEvidencias` encapsula esto; en local puede guardar en una carpeta y devolver una URL falsa.
3. Responder 201 con `tipo` (`IMAGEN` o `DOCUMENTO`), `url`, `nombreArchivoOriginal`, `tamanioBytes`, `fechaSubida`.

No se guarda en la base todavía: la evidencia se asocia cuando se registra la devolución.

### 7.3. 2.2 Registrar devolución

1. Validar: `pedidoId`, `tipo`, `motivo` y `items` obligatorios.
2. `VentasClient.consultarPedido(pedidoId)`: no existe, 404. Estado distinto de `ENTREGADO`, 409 `PEDIDO_NO_ENTREGADO`.
3. Fecha de entrega = fecha del historial `ENTREGADO`. Si pasaron más de 7 días: 400 `PLAZO_VENCIDO` (el contrato dice 400; ESP-07 dice 409; manda el contrato).
4. Motivo que exige evidencia y `evidencias` vacío: 400 `EVIDENCIA_REQUERIDA`.
5. Guardar `devolucion` (`estado = SOLICITADA`, `id_pedido` = número del código, `id_cliente`, `descripcion`), sus `evidencia_devolucion` y sus `devolucion_item`.
6. Responder 201 con `devolucionId` (`DEV-AAAA-NNNN`).

### 7.4. 2.3 y 2.4 Consultar y listar

- Consultar: si tiene resolución de reembolso, incluir el bloque `reembolso` leyendo `postventa.reembolso` por `tipo_origen = DEVOLUCION` e `id_origen = devolucion.id` (mismo servicio, a través de `ReembolsoService`, no del repositorio de F4).
- Listar: filtros `clienteId`, `estado`, `tipo`, paginado.
- **Efecto secundario (ESP-08 §7.1):** cuando el Gestor consulta un expediente `SOLICITADA`, pasa a `EN_EVALUACION` en la misma llamada — no hay un endpoint aparte para "abrir a revisión".

### 7.5. 2.5 Resolver

| `decision` | Qué se hace |
|---|---|
| `RECHAZADA` | `fundamento` obligatorio (400 si falta). `estado = RECHAZADA`, `resolucion = RECHAZO`, `fundamento_rechazo`, `id_autorizador` |
| `APROBADA` con `tipo = DEVOLUCION_DINERO` | `estado = APROBADA`, `resolucion = REEMBOLSO`. Llamar a `ReembolsoService.procesar(...)` con origen `DEVOLUCION`, clave `DEVOLUCION-{id}`. Si queda `EXITOSO`: `estado = COMPLETADA` — **esto no depende de la recepción física, ver 7.5b** |
| `APROBADA` con `tipo = CAMBIO` | `ProductosClient.hayDisponibilidad` (chequeo preliminar, informativo). Sin stock: 409 `SIN_STOCK` (el Gestor puede volver a resolver como reembolso o rechazo). Con stock: `resolucion = CAMBIO`, `VentasClient.solicitarReemplazo(...)` (`POST /api/v1/pedidos/reemplazos`, M1 1.11 — **ya no se llama a Despacho directo**, ver 5.10 y 7.5c). El reintegro de inventario **tampoco se dispara aquí** — ver 7.5b. `COMPLETADA` cuando M1 avisa `pedido.entregado` (y la recepción física, si aplica, ya está confirmada) |

- Solo se resuelve si está `SOLICITADA` o `EN_EVALUACION`; si no, 409.
- Una devolución no puede terminar con cambio y reembolso a la vez.
- Sumar `devoluciones_aprobadas` en `agregado_metricas` (sección 10.4) al aprobar.
- **`decision` acepta además `tipoResolucion` opcional** (`CAMBIO` o `REEMBOLSO`, contrato v1.5.0) — permite derivar un `CAMBIO` sin stock a `REEMBOLSO` sin tener que inventarlo del lado del cliente.
- **`requiereDevolucionFisica` opcional** (booleano, por defecto `true`, solo con `REEMBOLSO`) — si es `false`, no se espera confirmación de recepción ni reintegro (ver 7.5b).
- **El autorizador sale del `sub` del token del Gestor**, nunca de un campo del cuerpo — se retiró `autorizadorId` del request a partir de v1.5.0.
- **Repetir la misma aprobación** sobre un expediente que quedó `APROBADA` (porque F4 o Despacho no confirmaron todavía) reintenta la coordinación sin duplicar nada — el expediente solo pasa a `COMPLETADA` cuando F4 o Despacho confirman.

### 7.5b. 2.5b Confirmar recepción física (nuevo, construido 2026-10-16)

**Cambio de diseño importante, hecho al responder el issue G6 #51 (P-02):** la aprobación del Gestor en 2.5 (`APROBADA`) **ya no dispara el reintegro de inventario**. G6 prohíbe incrementar stock solo por una aprobación comercial — hay que confirmar antes que la unidad llegó físicamente y es apta para reventa. Ya está construido: `PATCH /api/v2/devoluciones/{devolucionId}/recepcion` (`api-postventas.md` 2.5b), `RecepcionService`/`RecepcionDevolucion` (`postventa.devolucion`).

1. Precondición: `devolucion.estado = APROBADA`, `resolucion` en `CAMBIO` o `REEMBOLSO`, y `requiereDevolucionFisica = true`. Si no: 409 `RESOLUCION_NO_APROBADA`.
2. Body: `lineas[].sku` (debe corresponder a una línea del pedido devuelto), `lineas[].cantidadRecibida`, `lineas[].cantidadApta` (≤ recibida, si no 400 `CANTIDAD_INVALIDA`), `evidencia` opcional.
3. **Idempotencia real (G6 P-05):** si la confirmación repite exactamente las mismas cantidades que una operación que quedó `PENDIENTE` (Productos no respondió la vez anterior), se reintenta con el **mismo** `operation_id` — no se crea una fila nueva. Si ya se recibieron todas las unidades devueltas de ese SKU: 409 `RECEPCION_YA_CONFIRMADA`. Una recepción parcial distinta (llegan más unidades después) es una operación nueva, con su propio `operation_id`.
4. Se guardan las filas en `devolucion_recepcion` como `PENDIENTE` *antes* de llamar a Productos (para poder reintentar si falla), y `HistorialDevolucion` registra el detalle.
5. `ProductosClient.reintegrar(...)` (`POST /api/v1/inventario/reintegros`, `reason: DEVOLUCION_ACEPTADA`) — **solo** con `cantidadApta`. Si `cantidadApta` es 0 para todas las líneas, no se llama a Productos en absoluto. Si Productos no responde: 503 `PRODUCTOS_NO_DISPONIBLE`, las filas quedan `PENDIENTE` para el siguiente intento (punto 3). Si responde: filas a `COMPLETADO`.
6. `location_id` sale de `integracion.productos-ubicacion-devoluciones` (env `PRODUCTOS_UBICACION_DEVOLUCIONES`) — **todavía vacío**, G6 no lo ha definido (P-04); en modo real sin ese valor, 503 en vez de inventar uno.
7. No cambia `devolucion.estado` directamente — sigue `APROBADA` hasta que `DevolucionService.completarSiCorresponde(...)` confirme que ya no falta nada (reembolso exitoso en F4, o el reemplazo de M1 entregado en `CAMBIO`, ver 7.5c); ahí pasa a `COMPLETADA`.

**Importante para `REEMBOLSO`:** el llamado a `ReembolsoService` en 2.5 (paso de arriba) no espera a este endpoint — el dinero se devuelve igual, haya llegado o no el producto. Este paso 2.5b solo afecta inventario, nunca el reembolso.

Ver `ESP-08` 8.2b y reglas 14-16, y `integraciones/ACUERDO_G6_PRODUCTOS.md` para el payload exacto de `/inventario/reintegros`. Modelo de datos: `postventa.devolucion_recepcion`, `postventa.historial_devolucion` y `postventa.devolucion.requiere_devolucion_fisica` — ver `infra/bd/ventas_postventa_schema.sql` (**falta confirmar si ya se aplicó en Supabase**).

### 7.5c. Avisos de M1 sobre el reemplazo (`DevolucionService.reemplazoAnulado`/`reemplazoEntregado`, construido 2026-10-16)

M1 avisa por `POST /api/v2/eventos` (el mismo canal de siempre, `EnvioEventosScheduler` de M1 → `PostventaClient`) cuando la orden de reemplazo de un `CAMBIO` cambia de estado — ya no hay coordinación directa con Despacho de este lado:

- **`pedido.anulado` con `datos.devolucionId`:** Productos rechazó o venció la reserva del reemplazo. `reemplazoAnulado` busca la devolución por ese código y la devuelve a `EN_EVALUACION` (`HistorialDevolucion` registra el motivo), **no** la deja `RECHAZADA` — el Gestor puede volver a resolverla y pedir otro reemplazo.
- **`pedido.entregado` con `datos.devolucionId`:** el reemplazo llegó al cliente. `reemplazoEntregado` marca esa parte como confirmada; `completarSiCorresponde` cierra la devolución a `COMPLETADA` si la recepción física (7.5b) también está lista.
- Un aviso de una devolución que no existe, o de un reemplazo que ya no es el vigente de esa devolución (viejo o repetido), se ignora — M1 no tiene que reintentarlo.

### 7.6. Lista para terminar F3

Al 2026-10-16, F3 está completo en `main`, incluida la recepción física:

- [x] Entidades actualizadas con H2 (`Devolucion`, `DevolucionItem`)
- [x] Subir evidencia con validación de tipo y tamaño
- [x] Registrar con todas las validaciones de 7.3
- [x] Consultar y listar
- [x] Resolver: rechazo, reembolso y cambio
- [x] Usar las columnas de H11 (`fecha_registro`, `fecha_resolucion`, `referencia_operacion`)
- [x] 2.5b Confirmar recepción física — `RecepcionService`, `devolucion_recepcion`, `historial_devolucion` (ver 7.5b)
- [x] `ProductosClient.reintegrar` con el payload real de G6 (`operation_id`, `order_id`, `source_ref`, `reason`, `lines[]`) — sin inventar `location_id`
- [x] Verificado contra Supabase real: el servicio arranca y los endpoints 2.1 a 2.5 funcionan (2026-10-12)
- [x] `CAMBIO` ya no coordina directo con Despacho — pide la orden de reemplazo a M1 (1.11) y reacciona a `pedido.anulado`/`pedido.entregado` (ver 7.5c)

Pendientes:

- [ ] Reemplazar el reembolso simulado (`SolicitadorReembolsoSimulado`) por `ReembolsoService` de F4 cuando exista
- [ ] Sumar `devoluciones_aprobadas` al dashboard cuando exista `ProyeccionesService`
- [ ] Cuando Seguridad registre `ventas:pedidos:consultar`, `VentasClient` debe usar el token de servicio de M2 en vez de reenviar el token de quien llama (ver 3.7)
- [ ] `ProductosClient.consultarDisponibilidad` para `CAMBIO` (`hayDisponibilidad` hoy lanza 503 en modo real) — construir contra `GET /api/v1/inventario/disponibilidad` cuando G6 autorice explícitamente a M2 y Seguridad registre `inventario:disponibilidad:leer`
- [ ] Activar `ProductosClient.reintegrar` en modo real — el código ya está (7.5b), solo falta que Seguridad registre `inventario:reintegrar` para `modulo-postventa` y que G6 confirme el `location_id` (`PRODUCTOS_UBICACION_DEVOLUCIONES`) — ver `integraciones/ACUERDO_G6_PRODUCTOS.md`
- [ ] Criterios de aceptación de ESP-07 y ESP-08 (incluye CA-07/CA-08/CA-09 y reglas 17-18, nuevos)
- [ ] Confirmar en Supabase: H12 (`id_producto` a `varchar(64)`), las tablas/columna nuevas de recepción física (`devolucion_recepcion`, `historial_devolucion`, `devolucion.requiere_devolucion_fisica`) y las de la orden de reemplazo en M1 (`pedido.tipo`, `id_pedido_origen`, `devolucion_id`, `ux_pedido_reemplazo_vigente`)
- [ ] Que Seguridad registre `ventas:pedidos:reemplazar` para `modulo-postventa` (1.11) — ver `integraciones/ACUERDO_G7_SEGURIDAD.md`

---

## 8. M2 — F4 Reembolsos (Luis Alejandro)

Especificaciones: ESP-09, ESP-10. Contrato: `api-postventas.md` 2.6. Usa los cambios de H3 y H4 (4.1 y 4.2).

### 8.1. 2.6 Procesar reembolso

1. `X-Idempotency-Key` obligatoria: si falta, 400.
2. Buscar `reembolso` por `idempotency_key`:
   - Existe con los **mismos datos** (`origen`, `origenId`, `monto`, `moneda`): devolver el mismo resultado registrado (201 con el mismo cuerpo). No se llama a la pasarela.
   - Existe con **datos distintos**: 409 `CLAVE_IDEMPOTENCIA_EN_CONFLICTO`.
3. `origen` fuera de `ANULACION` o `DEVOLUCION` (por ejemplo `DESPACHO_FALLIDO`): 403 `ORIGEN_NO_PERMITIDO`.
4. `monto <= 0`: 400.
5. Validar el pago original con `VentasClient.consultarPedido(referenciaId)`: moneda igual a la del pedido y pedido con pago confirmado (en el historial hay `PAGADO`). Si no: 400.
6. **Saldo reembolsable**: suma de reembolsos `EXITOSO` y `PENDIENTE` del mismo pedido + monto nuevo ≤ total del pedido. Si se pasa: 409 `SALDO_INSUFICIENTE`.
7. Guardar `reembolso` con `estado = PENDIENTE`, `tipo_origen`, `id_origen` (número de `origenId`), `id_pedido` (número de `referenciaId`), `idempotency_key`, `monto`, `moneda`.
8. Llamar a `PasarelaClient.solicitarExtorno(clave, ...)` (extorno del simulador, 9.5) y guardar un `reembolso_intento`:

| Resultado de la pasarela | `reembolso.estado` | Intento |
|---|---|---|
| Éxito | `EXITOSO`, `id_transaccion` | `EXITOSO` |
| Error definitivo | `FALLIDO` | `FALLIDO` con el detalle |
| Timeout o error de red | Sigue `PENDIENTE` | `PENDIENTE` con "timeout" |

9. Responder 201 con `reembolsoId` (`REEM-NNNNN`), `transaccionPasarelaId`, `estado`, `monto`, `moneda`, `fechaEjecucion`.
10. Si queda `EXITOSO`, sumar a `monto_reembolsado_pen` en `agregado_metricas` (si la moneda es PEN).

### 8.2. Concurrencia del saldo

Dos solicitudes al mismo tiempo para el mismo pedido no deben pasar del saldo. Para eso:

La consulta que trae los reembolsos `EXITOSO` y `PENDIENTE` del pedido debe usar un bloqueo pesimista (`PESSIMISTIC_WRITE`), para que la segunda solicitud espere a que termine la primera.

Se llama dentro de la misma transacción que guarda el nuevo reembolso. La columna `id_pedido` viene de H3.

### 8.3. Reintento de un reembolso `PENDIENTE` o `FALLIDO`

ESP-09 pide poder recuperarlo sin crear otro. Basta con que una nueva llamada con la **misma clave y mismos datos** vuelva a intentar la pasarela si el estado no es `EXITOSO`, agregando un nuevo `reembolso_intento` con `numero_intento + 1`. Nunca se crea un segundo `reembolso`.

### 8.4. Lista para terminar F4

- [ ] Entidades actualizadas con H3 (`Reembolso`, `ReembolsoIntento`) y campo `origenId` de H4
- [ ] Idempotencia: misma clave y mismos datos, misma clave y otros datos
- [ ] Validación de origen, monto, moneda y saldo
- [ ] Intentos guardados (ESP-10), nunca se editan ni se borran
- [ ] Prueba de concurrencia: dos hilos con el mismo saldo, solo uno pasa
- [ ] Criterios ESP-09-CA-01 a CA-10 y ESP-10-CA-01 a CA-05

---

## 9. M2 — F5 CSAT, receptor de eventos y simulador de pasarela (Johan)

Especificaciones: ESP-11, ESP-12. Contrato: 2.7 y 2.13.

### 9.1. 2.7 Registrar encuesta

1. `puntuacion` de 1 a 5 (en la tabla se llama `puntaje`). Fuera de rango: 400.
2. `canal` en `CanalVenta`. `comentario` opcional.
3. El pedido debe estar `ENTREGADO`: `VentasClient.consultarPedido` — usar el que ya existe en `postventa/integracion/` (lo construyó F3, ver 3.7), no crear uno nuevo. Si no: 409 `PEDIDO_NO_ENTREGADO`.
4. Ya existe una calificación para ese pedido (`calificacion.id_pedido` es único): 409 `CALIFICACION_DUPLICADA`.
5. Guardar y sumar al agregado: `csat_suma += puntaje`, `csat_cantidad += 1` en la fila `(hoy, canal)`.
6. 201.

Una calificación baja no cambia el pedido ni crea un reclamo.

### 9.2. `POST /api/v2/eventos` (receptor)

1. Validar el formato (sección 11). `tipo` desconocido: 400.
2. Si `idEvento` ya está en `postventa.evento_recibido`: 200 sin hacer nada.
3. En una transacción:
   - Guardar `evento_recibido`.
   - Llamar a `ProyeccionesService.aplicar(evento)` (Fabrizio, sección 10.4).
   - Si es `pedido.entregado`: habilitar la encuesta. Como la validación de 9.1 ya consulta a M1, aquí basta con registrar el evento. Si el equipo quiere avisar al cliente, usar `SeguridadClient.consultarContacto`.
4. 200.

Este endpoint no pasa por el Gateway. En `SecurityConfig` de M2, `POST /api/v2/eventos` exige el scope de servicio de M1 (sección 12).

### 9.3. Simulador de pasarela (`simulador-pasarela`, puerto 8083)

La pasarela de pagos la hacemos nosotros. Es una aplicación aparte, con paquete `pasarela`, y se comporta como un **sistema externo**:

- No usa base de datos: guarda las transacciones en memoria. Si se reinicia, se pierden, y para la demo alcanza.
- No pasa por el Gateway y no valida tokens.
- No importa código de M1 ni de M2 (lo revisa su `ArquitecturaTest`); solo se comunica por HTTP.
- Si el frontend la llama directo, hay que habilitar CORS para el origen del frontend.

| Quién | Llama a | Para qué |
|---|---|---|
| Frontend o Postman | `POST /pasarela/v1/cobros` | "Pagar" un pedido creado |
| Simulador | `POST /api/v1/pedidos/{pedidoId}/pagos/notificacion` de M1 (1.2) | Avisar si el cobro se aprobó o se rechazó |
| M2 (`PasarelaClient`, Luis Alejandro) | `POST /pasarela/v1/extornos` | Devolver el dinero de un reembolso (F4) |

M1 nunca llama a la pasarela: solo recibe la notificación.

### 9.4. Cobro

1. `POST /pasarela/v1/cobros` con `pedidoId`, `monto`, `moneda`, `metodoPago` y `escenario` (opcional: `APROBADO` por defecto, o `RECHAZADO` para probar el rechazo).
2. Validar `monto > 0` y `moneda` (`PEN` o `USD`). Si no: 400.
3. Generar un `transaccionId` único (por ejemplo `TX-` + UUID), guardar la transacción como `PROCESANDO` y responder **201** de inmediato.
4. Después de `pasarela.demora-ms` (2 s), avisar a M1 por el endpoint 1.2 con `transaccionId`, `resultado`, `monto`, `moneda` y `fechaPago`. **Los nombres de los campos son los del contrato 1.2 de `api-ventas.md`**: acordarlos con Michael.
5. Si M1 no responde 200, reintentar hasta `pasarela.reintentos` veces (3), siempre con el **mismo** `transaccionId`. M1 es idempotente, así que no se cobra dos veces.
6. `GET /pasarela/v1/transacciones/{transaccionId}` devuelve el estado (`PROCESANDO`, `APROBADO`, `RECHAZADO`) y si M1 ya fue avisado.

### 9.5. Extorno

1. `POST /pasarela/v1/extornos` con cabecera `X-Idempotency-Key` (obligatoria: 400 si falta) y cuerpo con `referencia` (código del reembolso o del pedido), `monto`, `moneda` y `escenario` (opcional: `EXITOSO` por defecto, `FALLIDO` o `TIMEOUT`).
2. Misma clave y mismos datos: devolver la misma respuesta guardada. Misma clave con otros datos: 409.
3. Según el escenario:

| Escenario | Respuesta | Sirve para probar en F4 |
|---|---|---|
| `EXITOSO` | 201 con `idTransaccion` y `estado: EXITOSO` | Reembolso `EXITOSO` |
| `FALLIDO` | 201 con `estado: FALLIDO` y un `detalle` | Reembolso `FALLIDO` |
| `TIMEOUT` | Tarda más que el timeout del cliente (por ejemplo, 10 s) | Reembolso que queda `PENDIENTE` |

4. **Acordar con Luis Alejandro** el request y el response exactos: él los usa como `record` en `PasarelaClient`.
5. En M2, `PasarelaClient` llama al simulador cuando `PASARELA_SIMULADA=false` (URL en `PASARELA_URL`). Con `true`, responde éxito sin llamar a nadie.

### 9.6. Lista para terminar F5 y el simulador

- [ ] Registrar encuesta con todas las validaciones
- [ ] Receptor de eventos idempotente
- [ ] Criterios de ESP-11 y ESP-12
- [ ] Simulador: cobro con aviso a M1 y reintentos
- [ ] Simulador: extorno idempotente con los tres escenarios
- [ ] Probado el recorrido completo: crear pedido → cobrar → pedido `PAGADO`

---

## 10. M2 — F6 Reclamos y dashboard (Fabrizio)

Especificaciones: ESP-13 a ESP-16. Contrato: 2.8 a 2.12. Usa los cambios de H5 y H6 (4.1).

### 10.1. Valores

| Campo | Valores |
|---|---|
| `tipo` (`TipoReclamo`) | `RECLAMO`, `QUEJA` |
| `canal` | `MARKETPLACE`, `CHATBOT`, `RETAIL` |
| `motivo` (`MotivoReclamo`) | `INCUMPLIMIENTO_PLAZO_ENTREGA`, `PRODUCTO_DEFECTUOSO_O_INCORRECTO`, `COBRO_INDEBIDO_O_NO_RECONOCIDO`, `ATENCION_INADECUADA`, `INCUMPLIMIENTO_GARANTIA` |
| `estado` | `REGISTRADO`, `EN_PROCESO`, `ATENDIDO`, `DERIVADO` |

### 10.2. 2.8 Registrar reclamo

1. `tipo`, `canal`, `motivo` y `detalle` obligatorios. `consumidor` con `nombreCompleto`, `documento`, `email` y `telefono`, todos no vacíos. `pedidoId` opcional (queja general).
2. Si algo falla: 400 y no se genera código.
3. Guardar con `estado = REGISTRADO`, `plazo_dias_habiles = 15`, `fecha_registro = ahora`, `fecha_limite_respuesta = CalculadoraSla.sumarDiasHabiles(hoy, 15)`.
4. Generar `codigo` (`REC-AAAA-NNNN`, 3.5).
5. Sumar `reclamos_registrados` en el agregado.
6. 201 con `reclamoId`, `codigoSeguimiento`, `estado`, `motivo`, `plazoDiasHabiles`, `fechaLimiteSLA` (fecha límite a las `23:59:59Z`), `respuestaVisibleCliente: null`.

`CalculadoraSla.sumarDiasHabiles(desde, dias)` avanza día por día desde la fecha de registro, cuenta solo de lunes a viernes y se detiene al llegar a los días pedidos.

No considera feriados; se puede agregar una lista fija de feriados de Perú más adelante.

### 10.3. 2.9 a 2.11

- **Consultar por código**: 404 `RECLAMO_NO_ENCONTRADO` si no existe.
- **Listar**: filtros `documento`, `clienteId`, `estado`, paginado.
- **Responder**:
  - `nuevoEstado` debe ser `ATENDIDO` o `DERIVADO`. Otro valor: 400.
  - `respuestaVisibleCliente` obligatorio y no vacío tras `trim()` (400 `RESPUESTA_VACIA`, el reclamo no cambia).
  - `atendidoPor` obligatorio.
  - Si el reclamo ya está `ATENDIDO`: 409.
  - Guardar `respuesta_visible_cliente`, `atendido_por`, `fecha_atencion = ahora`, `estado`. Sumar `reclamos_atendidos` en el agregado si pasa a `ATENDIDO`.
  - `EN_PROCESO`: se marca cuando el Gestor abre el reclamo. Opción simple: el `PATCH` acepta también `EN_PROCESO` sin respuesta (agregar al contrato) o se pasa de `REGISTRADO` a `ATENDIDO` directamente.

### 10.4. Proyecciones (`ProyeccionesService`, ESP-15)

Actualiza `agregado_metricas` (H6) y `agregado_ventas`. La fila es `(fecha UTC del evento, canal)`; si no existe, se crea con ceros.

| Origen | Cambio |
|---|---|
| Evento `pedido.pagado` | `pedidos_pagados + 1`; por cada ítem, `agregado_ventas(periodo AAAA-MM, canal, vendedor, producto)`: `unidades + cantidad`, `monto + importe` |
| Evento `pedido.anulado` | `pedidos_anulados + 1` |
| Evento `pedido.entregado` | `pedidos_entregados + 1` |
| F3 aprueba devolución | `devoluciones_aprobadas + 1` |
| F4 reembolso `EXITOSO` en PEN | `monto_reembolsado_pen + monto` |
| F5 calificación válida | `csat_suma + puntaje`, `csat_cantidad + 1` |
| F6 reclamo registrado / atendido | `reclamos_registrados + 1` / `reclamos_atendidos + 1` |

- Los eventos llegan una sola vez gracias a `evento_recibido`; las operaciones de F3 a F6 suman dentro de su misma transacción.
- Para evitar choques entre hilos, usar un `upsert` en SQL nativo.
  Es decir, `insert ... on conflict (fecha, canal) do update`, sumando sobre el valor actual y actualizando `actualizado_en`.

### 10.5. 2.12 Métricas

1. Solo `ventas:admin`.
2. `desde` y `hasta` obligatorios; `desde > hasta`: 400. `canal` opcional, del catálogo.
3. Sumar las filas de `agregado_metricas` entre `desde` y `hasta` (y del canal si viene):

| Campo del response | Cálculo |
|---|---|
| `pedidos.total` | Suma de `pedidos_pagados` |
| `pedidos.anulados` | Suma de `pedidos_anulados` |
| `pedidos.entregados` | Suma de `pedidos_entregados` |
| `postventa.devolucionesAprobadas` | Suma de `devoluciones_aprobadas` |
| `postventa.montoReembolsadoPEN` | Suma de `monto_reembolsado_pen` |
| `postventa.csatPromedio` | `suma(csat_suma) / suma(csat_cantidad)`, 2 decimales; `null` si no hay encuestas |
| `postventa.reclamosPendientesSLA` | Contar en `reclamo` los que no están `ATENDIDO` y tienen `fecha_limite_respuesta` dentro del periodo |

No se recorre `pedido` ni ninguna tabla de M1. La exportación no se programa hasta que esté en el contrato (ESP-16).

### 10.6. Lista para terminar F6

- [ ] Entidades actualizadas con H5 (`Reclamo`) y H6 (`AgregadoMetricas`)
- [ ] Registrar reclamo con código y SLA
- [ ] Consultar, listar y responder
- [ ] `ProyeccionesService` con upsert
- [ ] Métricas con filtros
- [ ] Criterios de ESP-13 a ESP-16

---

## 11. Eventos entre M1 y M2

### 11.1. Formato

Es el `payload` que M1 guarda en `outbox_evento` y envía a `POST /api/v2/eventos`. Un `record` igual en los dos servicios (`EventoPedidoPayload`):

```json
{
  "idEvento": "3f2c9a10-6b7d-4e21-9c55-1a2b3c4d5e6f",
  "tipo": "pedido.pagado",
  "pedidoId": "PED-2026-00981",
  "fecha": "2026-09-23T00:06:00Z",
  "datos": {
    "canal": "MARKETPLACE",
    "clienteId": "3f9a2b7e-6c1d-4e2a-9b3f-7a1d2c4e5f6a",
    "vendedorId": null,
    "total": 129.90,
    "moneda": "PEN",
    "motivo": null,
    "items": [ { "productoId": 101, "cantidad": 1, "importe": 129.90 } ]
  }
}
```

| Tipo | Cuándo | `motivo` | `items` |
|---|---|---|---|
| `pedido.pagado` | `CREADO → PAGADO` | `null` | Sí (para `agregado_ventas`) |
| `pedido.anulado` | Cualquier `→ ANULADO` | Obligatorio (ESP-04) | No hace falta |
| `pedido.entregado` | `DESPACHADO → ENTREGADO`, o `PAGADO → ENTREGADO` en `RETAIL` (acuerdo G4) | `null` | No hace falta |

`idEvento` es el mismo `id_evento` de `outbox_evento`. Agregar `items` y `vendedorId` al ejemplo de `api-postventas.md` 2.13.

### 11.2. Recorrido

```text
M1  MaquinaEstados.cambiar()  ──misma transacción──►  ventas.outbox_evento (enviado_en = null)
M1  EnvioEventosScheduler (cada 5 s)  ──POST /api/v2/eventos──►  M2
M2  ¿idEvento en postventa.evento_recibido?  sí → 200 sin hacer nada
                                              no → guarda + ProyeccionesService → 200
M1  marca enviado_en; si falló, intentos + 1 y vuelve a intentar
```

### 11.3. Cómo probar sin M1

```bash
curl -X POST http://localhost:8082/api/v2/eventos \
  -H "Content-Type: application/json" \
  -d '{"idEvento":"11111111-1111-1111-1111-111111111111","tipo":"pedido.entregado",
       "pedidoId":"PED-2026-00001","fecha":"2026-10-09T12:00:00Z",
       "datos":{"canal":"MARKETPLACE","clienteId":"11111111-1111-1111-1111-111111111111","total":100,"moneda":"PEN"}}'
# Enviarlo dos veces: la segunda no debe sumar nada.
```

---

## 12. Seguridad y scopes

Con `SEGURIDAD_HABILITADA=true`, cada servicio valida el JWT del Módulo G y los scopes. Spring guarda cada scope como autoridad `SCOPE_<scope>`.

Catálogo real (acuerdo A10, `integraciones/ACUERDO_G7_SEGURIDAD.md`, `api-ventas.md` y `api-postventas.md`): hay **dos tipos de token**, y se autorizan distinto.

- **Token de servicio** (`tipo: "servicio"`): lo usa un módulo (canal, Despacho, el simulador). Se autoriza por `scope` → Spring lo guarda como `SCOPE_<scope>`.
- **Token de usuario** (`tipo: "acceso"`): lo usa una persona (cliente o Gestor). Se autoriza por el claim `roles` → Spring lo guarda como `ROLE_<rol>` (`CLIENTE`, `ADMIN_VENTAS`).

`ventas:pedidos:leer`, `ventas:admin`, `postventa:devoluciones:leer`, `postventa:reclamos:leer` y `postventa:csat:escribir` **no son scopes reales** — Seguridad no los registra porque dependen de identidad de persona, no de módulo. Si una ruta necesitaba uno de esos "scopes" en versiones anteriores de esta guía, ahora va por rol.

### 12.1. M1

| Ruta | Autorización |
|---|---|
| `POST /api/v1/pedidos` | scope `ventas:pedidos:crear` |
| `POST /api/v1/pedidos/*/pagos/notificacion` | scope `ventas:pagos:webhook` |
| `POST /api/v1/pedidos/*/anulaciones` | scope `ventas:pedidos:anular` o rol `ADMIN_VENTAS` |
| `POST /api/v1/integraciones/despachos/eventos` | scope `ventas:pedidos:estado` (reusado, decisión nuestra — ver 5.6/5.7) |
| `GET /api/v1/pedidos/me` | rol `CLIENTE` |
| `GET /api/v1/pedidos/anulaciones/**` | rol `ADMIN_VENTAS` |
| `PATCH /api/v1/pedidos/*/anulaciones/*` | rol `ADMIN_VENTAS` |
| `GET /api/v1/pedidos` | rol `ADMIN_VENTAS` |
| `GET /api/v1/pedidos/*` | rol `CLIENTE` o `ADMIN_VENTAS` (1.3 debe además verificar que el `CLIENTE` sea dueño del pedido — eso no lo hace Spring Security, lo valida el service) |
| `/actuator/health` | Libre |
| Cualquier otra | Denegada |

**Ya está hecho y correcto** en `ventas/compartido/SecurityConfig.java` — coincide exactamente con esta tabla. Si agregas un endpoint nuevo en M1, agrega su regla ahí con el mismo criterio (scope para token de servicio, `hasRole(...)` para token de usuario).

### 12.2. M2

| Ruta | Autorización |
|---|---|
| `POST /api/v2/devoluciones/**` | scope `postventa:devoluciones:escribir` |
| `GET /api/v2/devoluciones/me` | rol `CLIENTE` (2.4b, identidad por `sub`, sin `clienteId` en la URL) |
| `GET /api/v2/devoluciones/**` (listado administrativo, 2.4) | rol `ADMIN_VENTAS` |
| `PATCH /api/v2/devoluciones/*/resolucion` | rol `ADMIN_VENTAS` |
| `POST /api/v2/reembolsos` | scope `postventa:reembolsos:procesar` |
| `POST /api/v2/csat` | rol `CLIENTE` (titularidad del `pedidoId` contra el `sub`, acuerdo H-04 — nunca scope de servicio) |
| `POST /api/v2/reclamos` | scope `postventa:reclamos:escribir` |
| `GET /api/v2/reclamos/me` | rol `CLIENTE` (2.10b) |
| `GET /api/v2/reclamos/**` (listado administrativo, 2.10, también por `documento`) | rol `ADMIN_VENTAS` |
| `PATCH /api/v2/reclamos/*/respuesta` | rol `ADMIN_VENTAS` |
| `GET /api/v2/dashboard/**` | rol `ADMIN_VENTAS` |
| `POST /api/v2/eventos` | scope `postventa:reembolsos:procesar` (credencial de servicio de M1 — no pasa por el Gateway) |

**Corregido (2026-10-12):** `postventa/compartido/SecurityConfig.java` ya coincide exactamente con esta tabla — `/devoluciones/me`, `/reclamos/me` y `/csat` piden rol `CLIENTE`, nada de los scopes viejos que Seguridad nunca iba a emitir.

Los tokens de servicio (M1 llamando a M2, M2 llamando a M1, y el simulador llamando a la 1.2 con `ventas:pagos:webhook`) se piden al Módulo G. Mientras tanto, se prueba con la seguridad apagada.

El simulador de pasarela no valida tokens: es un sistema externo de prueba.

---

## 13. Pruebas

### 13.1. Qué probar

| Tipo | Herramienta | Qué |
|---|---|---|
| Unitarias de service | JUnit 5 + Mockito | Reglas de negocio con repositorios y clientes simulados |
| Controller | `@WebMvcTest` + MockMvc | Códigos HTTP, formato de error, validación de DTO |
| Arquitectura | `ArquitecturaTest` (ya existe) | M1 no importa M2 y al revés |
| Manual | Postman o `.http` | Recorrido completo contra Supabase |

No se usan pruebas que escriban en la base compartida dentro de `mvn package`.

**Desde F3 (2026-10-12):** cada controller nuevo de M2 debe declarar sus services con `@MockitoBean` en `SeguridadPostventaTest`. Esa prueba ya no espera `404` — comprueba que la respuesta no sea `401` ni `403` (verifica autorización, no que el endpoint esté implementado).

### 13.2. Modelo a seguir

Tomen como modelo `MaquinaEstadosTest` (**ya hecho**, en `servicio-ventas/src/test/java/ventas/pedido/`):

- Los repositorios y `PublicadorEventos` se simulan con Mockito (`@Mock`) y la clase a probar se crea con `@InjectMocks`.
- Un caso feliz: `PAGADO → ANULADO` por `CLIENTE` cambia el estado y publica `pedido.anulado`.
- Un caso de error: `CREADO → DESPACHADO` lanza `ConflictoException` y no toca el historial ni los eventos.

Esquema de cada prueba: preparar el estado, ejecutar el método y verificar el resultado y las llamadas.

### 13.3. Criterio mínimo por funcionalidad

Cada criterio de aceptación (`CA-xx`) de sus ESP tiene al menos una prueba con el código del criterio en el nombre, por ejemplo `ca03_rechazaAnulacionDePedidoDespachado()`.

---

## 14. Antes de abrir un PR

- [ ] `git pull origin main` sin conflictos
- [ ] `mvn clean package` pasa (compila y pruebas en verde)
- [ ] El servicio arranca contra Supabase (sin errores de `validate`)
- [ ] Los endpoints que tocaste ya no responden 501
- [ ] Requests y responses con los nombres exactos del contrato
- [ ] Errores con el formato `codigo`, `mensaje`, `timestamp`, `detalles`
- [ ] Ningún estado o canal escrito como texto suelto: siempre su enum
- [ ] Si tu entidad usa una columna nueva, el líder del proyecto ya la aplicó en Supabase
- [ ] Probado a mano al menos el caso feliz y un error
- [ ] Descripción del PR: qué endpoints, qué ESP, cómo probarlo

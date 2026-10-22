# Acuerdo con G7 — Seguridad y Usuarios

Confirmado con el equipo de Seguridad (contacto: Sergio Osorio, PO). Última actualización: 2026-10-11. Registrado en su repo como acuerdo **A10** (issue #42, `Taller-SW-Web/Modulo-de-Seguridad`) — **fuente oficial: su `kit-integracion.md` §5**; si algo de este documento no coincide con el suyo, manda el de ellos.

## Qué consumimos de ellos

Validación local de JWT (JWKS), emisión de tokens de servicio (`client_credentials`) para `modulo-ventas` y `modulo-postventa`, y consulta de estado de cuenta (`GET /usuarios/{clienteId}`) antes de operaciones sensibles.

## Qué consumen ellos de nosotros

Nada — Seguridad no consume ninguna API de Ventas/Postventa. Es puramente un proveedor de identidad para nosotros y para los demás módulos.

## A10 — Asignación final de scopes

**De `api-ventas` / `api-postventa` (las definimos nosotros, Seguridad las registra y emite):**

| Cliente | Scopes concedidos |
|---|---|
| `modulo-marketplace` | `ventas:pedidos:crear`, `ventas:pedidos:anular`, `postventa:devoluciones:escribir`, `postventa:reclamos:escribir` |
| `modulo-chatbot` | lo mismo que `modulo-marketplace` + `ventas:pagos:webhook` |
| `modulo-retail` | lo mismo que `modulo-marketplace` |
| `modulo-despacho` | `ventas:pedidos:estado` |
| `simulador-pasarela` | `ventas:pagos:webhook` |
| `modulo-ventas` | `postventa:reembolsos:procesar` |
| `modulo-postventa` | `ventas:pedidos:consultar` (solo `GET /api/v1/pedidos/{id}`) — **registrado** (issue de Seguridad #51, PR #60 fusionado ~2026-10-16/17, verificado 2026-10-21 directo en GitHub — nunca lo confirmaron por comentario, solo con el merge); `ventas:pedidos:reemplazar` (1.11, orden de reemplazo de un `CAMBIO`) — **propuesto 2026-10-16, pendiente de que Seguridad lo registre** (ver pendientes) |

**De `api-seguridad` (las consumimos nosotros):**

| Cliente | Scopes concedidos |
|---|---|
| `modulo-ventas` | `usuarios:leer` |
| `modulo-postventa` | `usuarios:leer` |

**De `api-despacho` (las define Despacho, Seguridad solo registra — Despacho ya las publicó en su `api-contract.md` §3.4 con Ventas como consumidor autorizado):**

| Cliente | Scopes concedidos |
|---|---|
| `modulo-ventas` | `despachos:crear`, `despachos:cancelar` |

**De `api-productos` (las define Productos/G6, Seguridad solo registra):**

| Cliente | Scopes concedidos |
|---|---|
| `modulo-ventas` | `inventario:reservar`, `inventario:consumir`, `inventario:liberar` — **registrados 2026-10-16** (issue #54 de Seguridad); ya acordados con Productos, ver `integraciones/ACUERDO_G6_PRODUCTOS.md`. `inventario:operaciones:leer` — **detectado 2026-10-21** (issue G6 #51, sección 4 de G6), para `GET /inventario/operaciones/{operationId}` cuando M1 necesite recuperar el resultado de una operación perdida; **falta mandarlo a Seguridad** |
| `modulo-postventa` | `inventario:reintegrar` — **registrado 2026-10-16** (issue #54), falta la provisión real de credenciales; `inventario:disponibilidad:leer` — **propuesto 2026-10-16, pendiente de que Seguridad lo registre** (ver pendientes), ya aprobado explícitamente por Productos (issue G6 #100) |

**Retirados del acuerdo (no son necesarios):** `ventas:pedidos:leer`, `ventas:admin` (no son scopes reales, se resuelven por rol), `postventa:devoluciones:leer`, `postventa:reclamos:leer` (reemplazados por `/devoluciones/me` y `/reclamos/me`, sin scope), `tokens:introspeccion` para Ventas/Postventa (reemplazado por `usuarios:leer`), scope adicional para el simulador de pasarela (declinado, decisión nuestra), **`postventa:csat:escribir`** (corrección 2026-10-12, **confirmado retirado por Seguridad** — issue #44, `modulo-marketplace`/`modulo-chatbot`/`modulo-retail`, sin reemplazo), **`usuarios:leer:documento`** (resuelto 2026-10-12, ver pendientes — la emisión de comprobantes es de Retail, no de Ventas, ver `ACUERDO_G4_RETAIL.md` R6).

## Decisiones confirmadas

| # | Fecha | Qué se acordó | Dónde quedó documentado |
|---|---|---|---|
| — | 2026-10-10 | El rol real de "Gestor" es `ADMIN_VENTAS` (catálogo cerrado de 6 roles: `CLIENTE`, `VENDEDOR`, `ADMIN_VENTAS`, `GESTOR_DESPACHO`, `GESTOR_COMERCIAL`, `ADMIN_SISTEMA`). "Gestor" sigue como nombre de interfaz/specs. | `AGENTS.md` sección 2, punto 9 |
| — | 2026-10-10 | La identidad de cualquier usuario es el UUID del claim `sub` del JWT. `id_cliente`, `id_vendedor`, `id_solicitante` e `id_autorizador` migrados de `bigint` a `uuid`. | `AGENTS.md` sección 2, punto 10 |
| — | 2026-10-10 | **Crear pedido (1.1) y anular (1.7) usan el token de servicio del canal**, no uno de cliente reenviado — la identidad del cliente viaja como dato (`clienteId`), no se deriva del token. Única excepción: `/pedidos/me`. | `api-ventas.md`, secciones 1.1 y 1.7; `AGENTS.md` sección 2, punto 11 |
| — | 2026-10-10 | `aud` de nuestros tokens: `api-ventas` (M1) y `api-postventa` (M2, singular). | `api-ventas.md` |
| — | 2026-10-10 | **Regla de confianza y trazabilidad:** el canal es responsable de que `clienteId` sea el `sub` real del usuario autenticado. Ventas/Postventa registran `client_id` del canal + `clienteId` en cada creación y anulación. | `RNF-03-trazabilidad.md`, sección 4 |
| — | 2026-10-10 | `usuarios:leer` reemplaza a `tokens:introspeccion`: verificamos el estado de la cuenta con `GET /usuarios/{clienteId}` antes de anular/reembolsar, porque nunca recibimos el token del propio usuario (salvo `/pedidos/me`). | `api-ventas.md` |
| — | 2026-10-11 | Se adopta el mismo patrón `/me` para devoluciones y reclamos (`GET /devoluciones/me`, `GET /reclamos/me`, identidad por JWT) — `postventa:devoluciones:leer`/`reclamos:leer` quedan retirados; el listado administrativo por `clienteId`/`documento` pasa a requerir rol `ADMIN_VENTAS`, no scope. | `api-postventas.md`, secciones 2.4b y 2.10b |
| — | 2026-10-11 | `modulo-ventas` también necesita `despachos:crear` y `despachos:cancelar` — ya publicados por Despacho en su `api-contract.md` §3.4 con Ventas como consumidor autorizado; no necesita `seguimientos:leer` (lo consultan los canales directo con Despacho). | Esta tabla; `integraciones/ACUERDO_G2_DESPACHO.md` |
| — | 2026-10-11 | Credenciales reales (`client_id` + `client_secret`) de todos los clientes: Hito 4. Mientras tanto, mock con `modulo-ventas` / `secreto-de-prueba` (kit §6). | Kit de integración de Seguridad |
| — | 2026-10-11 | Seguridad avisa directamente a Marketplace, Chatbot, Retail y Despacho sobre sus nuevos scopes, por su propio canal de issues con cada uno. | Issue #42 |
| — | 2026-10-12 | **Retiro confirmado de `postventa:csat:escribir`** de `modulo-marketplace`, `modulo-chatbot` y `modulo-retail`, sin reemplazo — `POST /api/v2/csat` se autoriza con token de usuario, rol `CLIENTE` y validación de titularidad, igual que `/pedidos/me`. No afecta el recorrido de Hito 3 (login real → validación JWT → `/pedidos/me`). | Issue #44, enlazada a #42 |

## Límites del acuerdo (aclarado por Seguridad, para no atribuirles algo que no es suyo)

**Seguridad SÍ:** gestiona usuarios/cuentas/roles, emite tokens (de usuario y de servicio) y publica el JWKS, registra los scopes que cada dueño de API define y los incluye en el token (`aud`, `scope`, 1 hora de vigencia), crea y entrega credenciales en el Hito 4.

**Seguridad NO:** no define qué autoriza un scope de otra API (eso lo definimos nosotros); no valida tokens en nuestras APIs ni responde nuestros `401`/`403` (lo hacemos nosotros: firma, `iss`, `aud`, `tipo`, `exp`, scope); no comprueba que `clienteId` sea correcto (responsabilidad del canal al enviarlo, y nuestra al verificarlo/registrarlo); no autoriza por `ADMIN_VENTAS` ni `CLIENTE` en sus propios endpoints (lo hacemos nosotros con el claim `roles`); no opera ni custodia el simulador de pasarela; no media entre módulos — si un scope es de otra API, el pedido necesita la confirmación de ese dueño primero (como pasó con `despachos:crear`/`cancelar`).

**Proceso futuro:** cualquier scope nuevo de `api-ventas`/`api-postventa` va por issue aparte con la etiqueta `integracion`, con la lista completa y para qué flujo — no se puede simplemente avisar por mensaje.

## Pendiente de confirmar / resolver

- **Retirar `usuarios:leer:documento` de `modulo-ventas`:** resuelto 2026-10-12 — Retail confirmó que la emisión de comprobantes/boletas es responsabilidad exclusiva suya, no de Ventas (ver `ACUERDO_G4_RETAIL.md`, R6). Falta avisarle a Seguridad — va como comentario en la **issue #42** (no #44): ahí mismo quedó la promesa explícita de confirmar este punto en cuanto Retail respondiera.
- ~~Nuevo scope `ventas:pedidos:consultar` para `modulo-postventa`~~ — **registrado, verificado 2026-10-21.** M2 necesita llamar a `GET /api/v1/pedidos/{id}` (1.3) para validar que el pedido esté `ENTREGADO` (F3 y F5); el endpoint solo aceptaba rol `CLIENTE`/`ADMIN_VENTAS`, ningún scope de servicio. Seguridad lo registró en el **PR #60** (fusionado, rama `feature/matriz-chatbot-ventas`) — nunca lo confirmaron con un comentario de texto en el issue #51, solo con el merge; se verificó leyendo el PR directo en GitHub. Limitado a `GET /api/v1/pedidos/{id}`, no reabre `ventas:pedidos:leer`.
- ~~Scopes de `inventario:*` para `modulo-ventas` y `modulo-postventa`~~ — **registrados 2026-10-16** (issue #54 de Seguridad, matriz de scopes audiencia `api-productos`): `inventario:reservar`/`inventario:consumir`/`inventario:liberar` para `modulo-ventas`, `inventario:reintegrar` para `modulo-postventa`. En ese momento Seguridad no registró `inventario:disponibilidad:leer` porque Productos todavía no autorizaba explícitamente a `modulo-postventa` — **eso ya cambió** (ver fila siguiente).
- **Nuevo scope `inventario:disponibilidad:leer` para `modulo-postventa`:** Productos (G6) ya lo aprobó explícitamente (issue G6 #100, 2026-10-16) para `GET /api/v1/inventario/disponibilidad`. Falta mandarlo a Seguridad — se puede sumar como comentario a la misma issue #51 de Seguridad, junto con la precisión pendiente de `ventas:pedidos:consultar` y el scope nuevo de abajo.
- **Nuevo scope `ventas:pedidos:reemplazar` para `modulo-postventa`:** detectado el 2026-10-16 al cerrar con Productos (issue G6 #100) el mecanismo de `CAMBIO` — M2 necesita llamar a `POST /api/v1/pedidos/reemplazos` (1.11) para pedirle a M1 la orden de reemplazo. Falta mandar la issue a Seguridad (nueva o como comentario en la #51 de Seguridad, etiqueta `integracion`).
- **Nuevo scope `inventario:operaciones:leer` para `modulo-ventas`:** detectado 2026-10-21 (issue G6 #51, sección 4 de la respuesta de G6) — para que M1 pueda llamar a `GET /inventario/operaciones/{operationId}` si se le pierde el resultado de una reserva/confirmación. Falta mandarlo a Seguridad, junto con los otros dos de arriba.

## Historial

- 2026-10-10: Se envía el issue #42 con el registro de scopes propios de `modulo-ventas`/`modulo-postventa`.
- 2026-10-10: Seguridad responde con la asignación inicial y dos puntos por resolver (dónde va `postventa:reembolsos:procesar`, y qué token se usa para crear/anular pedidos).
- 2026-10-10: Se detecta que crear/anular pedidos usa el token de servicio del canal, no el del cliente — hueco real no documentado antes. Se piden `ventas:pedidos:crear`/`ventas:pedidos:anular`.
- 2026-10-10: Seguridad corrige que `tokens:introspeccion` no aplica bajo ese modelo; se adopta `usuarios:leer` en su lugar.
- 2026-10-11: Se detecta el mismo problema de `clienteId` por query string en `api-postventas.md` (devoluciones y reclamos); se agregan `/devoluciones/me` y `/reclamos/me`, y se avisa a Seguridad para retirar los scopes de lectura correspondientes.
- 2026-10-11: Se confirma que `modulo-ventas` también necesita `despachos:crear`/`despachos:cancelar`.
- 2026-10-11: Seguridad confirma la asignación A10 final completa y aclara los límites de su rol en el acuerdo. Queda cerrado salvo `usuarios:leer:documento` (pendiente de Retail).
- 2026-10-12: Al responder una consulta de Chatbot (G3) sobre CSAT, se detecta que `postventa:csat:escribir` tampoco debería ser un scope — mismo caso que `devoluciones:leer`/`reclamos:leer`. Se corrige `api-postventas.md` y se manda la issue #44 a Seguridad.
- 2026-10-12: Seguridad confirma el retiro de `postventa:csat:escribir` en la issue #44, sin cambios al recorrido de Hito 3.
- 2026-10-12: Al cerrar el acuerdo con Retail (G4), se confirma que la emisión de comprobantes es responsabilidad de Retail, no de Ventas — `usuarios:leer:documento` para `modulo-ventas` queda retirado. Se agrega como comentario en la issue #42, donde quedó la promesa original de confirmarlo.
- 2026-10-13: Se envía la issue para `ventas:pedidos:consultar` (`modulo-postventa`). Un día después, sin respuesta todavía, se le suman como comentario (y se renombra el título) los scopes de `inventario:*` para `modulo-ventas` (`reservar`/`consumir`/`liberar`) e `inventario:reintegrar` para `modulo-postventa`, detectados al cerrar la integración de stock con Productos (G6). Los tres quedan pendientes de respuesta.
- 2026-10-16: Seguridad responde la issue, pero solo registra los scopes de `inventario:*` (issue #54, matriz `api-productos`) — `ventas:pedidos:consultar` queda sin tocar. Se le pide la precisión en el mismo hilo.
- 2026-10-16: Al cerrar con Productos el mecanismo de `CAMBIO` (orden de reemplazo, issue G6 #100), se detecta un scope nuevo: `ventas:pedidos:reemplazar` para `modulo-postventa` (1.11). Falta mandarlo a Seguridad.
- 2026-10-16: Productos aprueba explícitamente a `modulo-postventa` para `inventario:disponibilidad:leer` (issue G6 #100) — ya se puede pedir a Seguridad; falta mandarlo, junto con `ventas:pedidos:reemplazar` y la precisión pendiente de `ventas:pedidos:consultar`.
- 2026-10-21: Al responder el issue G6 #51 (RabbitMQ/cupones), se detecta un scope pendiente de mandar a Seguridad: `inventario:operaciones:leer` para `modulo-ventas` (consulta de operaciones perdidas). Se verifica además, leyendo directo el PR #60 de Seguridad en GitHub, que `ventas:pedidos:consultar` **sí quedó registrado** (nunca lo confirmaron por comentario) — queda tachado arriba. Quedan 3 pendientes reales sin mandar a Seguridad: `inventario:disponibilidad:leer`, `ventas:pedidos:reemplazar`, `inventario:operaciones:leer`.

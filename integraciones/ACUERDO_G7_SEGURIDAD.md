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

**De `api-seguridad` (las consumimos nosotros):**

| Cliente | Scopes concedidos |
|---|---|
| `modulo-ventas` | `usuarios:leer`, `usuarios:leer:documento` (**provisional**, ver pendientes) |
| `modulo-postventa` | `usuarios:leer` |

**De `api-despacho` (las define Despacho, Seguridad solo registra — Despacho ya las publicó en su `api-contract.md` §3.4 con Ventas como consumidor autorizado):**

| Cliente | Scopes concedidos |
|---|---|
| `modulo-ventas` | `despachos:crear`, `despachos:cancelar` |

**Retirados del acuerdo (no son necesarios):** `ventas:pedidos:leer`, `ventas:admin` (no son scopes reales, se resuelven por rol), `postventa:devoluciones:leer`, `postventa:reclamos:leer` (reemplazados por `/devoluciones/me` y `/reclamos/me`, sin scope), `tokens:introspeccion` para Ventas/Postventa (reemplazado por `usuarios:leer`), scope adicional para el simulador de pasarela (declinado, decisión nuestra), **`postventa:csat:escribir`** (corrección 2026-10-12, ver pendientes — este también debería haberse resuelto por rol `CLIENTE`, no scope, por la verificación de titularidad del acuerdo H-04 con Marketplace).

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
| — | 2026-10-11 | `modulo-ventas` también necesita `despachos:crear` y `despachos:cancelar` — ya publicados por Despacho en su `api-contract.md` §3.4 con Ventas como consumidor autorizado; no necesita `seguimientos:leer` (lo consultan los canales directo con Despacho). | Esta tabla; `integraciones/CONSULTA_G2_DESPACHO.md` |
| — | 2026-10-11 | Credenciales reales (`client_id` + `client_secret`) de todos los clientes: Hito 4. Mientras tanto, mock con `modulo-ventas` / `secreto-de-prueba` (kit §6). | Kit de integración de Seguridad |
| — | 2026-10-11 | Seguridad avisa directamente a Marketplace, Chatbot, Retail y Despacho sobre sus nuevos scopes, por su propio canal de issues con cada uno. | Issue #42 |

## Límites del acuerdo (aclarado por Seguridad, para no atribuirles algo que no es suyo)

**Seguridad SÍ:** gestiona usuarios/cuentas/roles, emite tokens (de usuario y de servicio) y publica el JWKS, registra los scopes que cada dueño de API define y los incluye en el token (`aud`, `scope`, 1 hora de vigencia), crea y entrega credenciales en el Hito 4.

**Seguridad NO:** no define qué autoriza un scope de otra API (eso lo definimos nosotros); no valida tokens en nuestras APIs ni responde nuestros `401`/`403` (lo hacemos nosotros: firma, `iss`, `aud`, `tipo`, `exp`, scope); no comprueba que `clienteId` sea correcto (responsabilidad del canal al enviarlo, y nuestra al verificarlo/registrarlo); no autoriza por `ADMIN_VENTAS` ni `CLIENTE` en sus propios endpoints (lo hacemos nosotros con el claim `roles`); no opera ni custodia el simulador de pasarela; no media entre módulos — si un scope es de otra API, el pedido necesita la confirmación de ese dueño primero (como pasó con `despachos:crear`/`cancelar`).

**Proceso futuro:** cualquier scope nuevo de `api-ventas`/`api-postventa` va por issue aparte con la etiqueta `integracion`, con la lista completa y para qué flujo — no se puede simplemente avisar por mensaje.

## Pendiente de confirmar / resolver

- **`usuarios:leer:documento` para `modulo-ventas`:** sigue **provisional**. Depende de si la emisión de comprobantes/boletas termina siendo responsabilidad de Ventas o de Retail (G4) — ver `integraciones/CONSULTA_G4_RETAIL.md`, punto 6. Apenas Retail responda, confirmamos sí/no a Seguridad en el mismo issue #42.
- **Retirar `postventa:csat:escribir` del acuerdo A10:** detectado el 2026-10-12 al responder una consulta de Chatbot (G3) — este scope no debería existir, `POST /api/v2/csat` necesita el token del propio cliente (verificación de titularidad del acuerdo H-04), no un token de servicio del canal. Falta avisarle a Seguridad en el issue #42 para que lo retiren de `modulo-marketplace`, `modulo-chatbot` y `modulo-retail`.

## Historial

- 2026-10-10: Se envía el issue #42 con el registro de scopes propios de `modulo-ventas`/`modulo-postventa`.
- 2026-10-10: Seguridad responde con la asignación inicial y dos puntos por resolver (dónde va `postventa:reembolsos:procesar`, y qué token se usa para crear/anular pedidos).
- 2026-10-10: Se detecta que crear/anular pedidos usa el token de servicio del canal, no el del cliente — hueco real no documentado antes. Se piden `ventas:pedidos:crear`/`ventas:pedidos:anular`.
- 2026-10-10: Seguridad corrige que `tokens:introspeccion` no aplica bajo ese modelo; se adopta `usuarios:leer` en su lugar.
- 2026-10-11: Se detecta el mismo problema de `clienteId` por query string en `api-postventas.md` (devoluciones y reclamos); se agregan `/devoluciones/me` y `/reclamos/me`, y se avisa a Seguridad para retirar los scopes de lectura correspondientes.
- 2026-10-11: Se confirma que `modulo-ventas` también necesita `despachos:crear`/`despachos:cancelar`.
- 2026-10-11: Seguridad confirma la asignación A10 final completa y aclara los límites de su rol en el acuerdo. Queda cerrado salvo `usuarios:leer:documento` (pendiente de Retail).
- 2026-10-12: Al responder una consulta de Chatbot (G3) sobre CSAT, se detecta que `postventa:csat:escribir` tampoco debería ser un scope — mismo caso que `devoluciones:leer`/`reclamos:leer`. Se corrige `api-postventas.md`; falta avisar a Seguridad en el issue #42.

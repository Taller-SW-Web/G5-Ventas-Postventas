# Acuerdo con G7 — Seguridad y Usuarios

Confirmado con el equipo de Seguridad (contacto: Sergio Osorio, PO). Última actualización: 2026-10-10. Registrado en su repo como acuerdo **A10** (issue #42, `Taller-SW-Web/Modulo-de-Seguridad`).

## Qué consumimos de ellos

Validación local de JWT (JWKS), emisión de tokens de servicio (`client_credentials`) para `modulo-ventas` y `modulo-postventa`, y consulta de estado de cuenta (`GET /usuarios/{clienteId}`) antes de operaciones sensibles.

## Qué consumen ellos de nosotros

Nada — Seguridad no consume ninguna API de Ventas/Postventa. Es puramente un proveedor de identidad para nosotros y para los demás módulos.

## Decisiones confirmadas

| # | Fecha | Qué se acordó | Dónde quedó documentado |
|---|---|---|---|
| — | 2026-10-10 | El rol real de "Gestor" es `ADMIN_VENTAS` (catálogo cerrado de 6 roles de Seguridad: `CLIENTE`, `VENDEDOR`, `ADMIN_VENTAS`, `GESTOR_DESPACHO`, `GESTOR_COMERCIAL`, `ADMIN_SISTEMA`). "Gestor" sigue como nombre de interfaz/specs. | `AGENTS.md` sección 2, punto 9 |
| — | 2026-10-10 | La identidad de cualquier usuario del sistema es el UUID del claim `sub` del JWT. `id_cliente`, `id_vendedor`, `id_solicitante` e `id_autorizador` migrados de `bigint` a `uuid`. | `AGENTS.md` sección 2, punto 10; `diagrama-fisico.md`, `diagrama-logico.md`, `ventas_postventa_schema.sql` |
| A10 | 2026-10-10 | **Scopes de `api-ventas`/`api-postventa` registrados por `client_id`:**<br>• `modulo-marketplace` → `ventas:pedidos:crear`, `ventas:pedidos:anular`<br>• `modulo-chatbot` → `ventas:pedidos:crear`, `ventas:pedidos:anular`, `ventas:pagos:webhook`<br>• `modulo-retail` → `ventas:pedidos:crear`, `ventas:pedidos:anular`<br>• `modulo-despacho` → `ventas:pedidos:estado`<br>• `simulador-pasarela` → `ventas:pagos:webhook`<br>• `modulo-ventas` → `postventa:reembolsos:procesar`<br>**Scopes de `api-seguridad` que consumimos:**<br>• `modulo-ventas` → `usuarios:leer` (+ `usuarios:leer:documento` **provisional**, ver pendientes)<br>• `modulo-postventa` → `usuarios:leer` | `api-ventas.md`, catálogo de scopes; issue #42 |
| — | 2026-10-10 | `ventas:pedidos:leer` y `ventas:admin` **no son scopes reales** — se resuelven por el claim `roles` del token del usuario (`CLIENTE` y `ADMIN_VENTAS` respectivamente), nunca por un scope concedido a un módulo. | `api-ventas.md`, catálogo de scopes |
| — | 2026-10-10 | `aud` de nuestros tokens: `api-ventas` (M1) y `api-postventa` (M2, singular) | `api-ventas.md` |
| — | 2026-10-10 | **Crear pedido (1.1) y anular (1.7) usan el token de servicio del canal** (`modulo-marketplace`/`modulo-chatbot`/`modulo-retail`), no un token de cliente reenviado — la identidad del cliente viaja como dato (`clienteId`) en el body, no se deriva del token. Única excepción: `/pedidos/me` (H-03), donde sí se usa el token del cliente. Por esto se necesitaron los scopes `ventas:pedidos:crear`/`ventas:pedidos:anular` (antes no existían, era un hueco real). | `api-ventas.md`, secciones 1.1 y 1.7 |
| — | 2026-10-10 | **Regla de confianza y trazabilidad:** el canal es responsable de que `clienteId` sea el `sub` real del usuario autenticado (en Retail, el cliente que atiende el vendedor) — nunca un valor escrito libremente. Ventas registra en su log el `client_id` del canal y el `clienteId` en cada creación y anulación. | `RNF-03-trazabilidad.md`, sección 4 |
| — | 2026-10-10 | `usuarios:leer` (`GET /usuarios/{clienteId}`, devuelve `estado` de la cuenta) reemplaza a `tokens:introspeccion` para verificar que el cliente siga activo antes de operaciones sensibles — `tokens:introspeccion` no sirve porque nunca recibimos el token del usuario (salvo en `/pedidos/me`, donde tampoco se considera necesario). | `api-ventas.md` |
| — | 2026-10-10 | El simulador de pasarela **no lleva scope de Seguridad adicional** por ahora (decisión nuestra; Seguridad ofreció la opción, la declinamos por ser un simulador académico sin dinero real de por medio). Se puede reconsiderar más adelante. | Esta tabla |
| — | 2026-10-10 | Credenciales reales (`client_id` + `client_secret`) de todos los clientes se crean en el Hito 4. Mientras tanto, mock con `modulo-ventas` / `secreto-de-prueba` (kit §6). | Kit de integración de Seguridad |
| — | 2026-10-10 | Seguridad avisa directamente a Marketplace, Chatbot, Retail y Despacho sobre sus nuevos scopes, por su propio canal de issues con cada uno — no nos toca avisarles a nosotros. | Issue #42 |

## Pendiente de confirmar / resolver

- **`usuarios:leer:documento` para `modulo-ventas`:** sigue **provisional**. Depende de si la emisión de comprobantes/boletas termina siendo responsabilidad de Ventas o de Retail (G4) — ver `integraciones/CONSULTA_G4_RETAIL.md`, punto 6. Apenas Retail responda, confirmamos sí/no a Seguridad en el mismo issue #42.

## Historial

- 2026-10-10: Se envía el issue #42 con el registro de scopes propios de `modulo-ventas`/`modulo-postventa`.
- 2026-10-10: Seguridad responde con la asignación inicial y dos puntos por resolver (dónde va `postventa:reembolsos:procesar`, y qué token se usa para crear/anular pedidos).
- 2026-10-10: Se detecta, al responder, que crear/anular pedidos usa el token de servicio del canal, no el del cliente — hueco real no documentado antes. Se piden los scopes `ventas:pedidos:crear`/`ventas:pedidos:anular`.
- 2026-10-10: Seguridad corrige además que `tokens:introspeccion` no aplica bajo ese modelo, y propone `usuarios:leer` en su lugar. Se acepta.
- 2026-10-10: Se cierra el acuerdo A10 con la asignación completa de scopes, salvo `usuarios:leer:documento` (pendiente de Retail).

# Acuerdo con G3 — Chatbot

Confirmado con el equipo de Chatbot (contacto: Nikol). Última actualización: 2026-10-12. Registrado en su repo como acuerdo **A15** (issue #9, `Taller-SW-Web/G3-Chatbot-specs`) — PR de sus specs: [#12](https://github.com/Taller-SW-Web/G3-Chatbot-specs/pull/12).

## Qué consumimos de ellos

Nada — Chatbot es quien consume nuestras APIs (M1 y M2).

## Qué consumen ellos de nosotros

`POST /api/v1/pedidos` (1.1), `POST /api/v1/pedidos/{id}/pagos/notificacion` (1.2, con su propio `PaymentSimulator`), `GET /api/v1/pedidos/{id}` (1.3), `GET /api/v1/pedidos/me` (1.4b), `POST /api/v1/pedidos/{id}/anulaciones` (1.7, caso `PAGO_NO_COMPLETADO`), `POST /api/v2/devoluciones` y `GET /api/v2/devoluciones/me` (2.2, 2.4b), `POST /api/v2/reclamos` y `GET /api/v2/reclamos/me` (2.8, 2.10b), `GET /api/v2/reclamos/{codigoSeguimiento}` (2.9), `GET /api/v2/devoluciones/{id}` (2.3), `POST /api/v2/csat` (2.7).

## Decisiones confirmadas

| # | Qué se acordó | Dónde quedó documentado |
|---|---|---|
| G3-1 | **Notificación de pago (1.2) con su propio simulador:** Chatbot procesa el cobro con su `PaymentSimulator` propio y notifica `1.2` directo, `client_id` `modulo-chatbot` (mismo que usan para otras llamadas), scope `ventas:pagos:webhook` — **ya concedido** desde el registro inicial de A10, no hizo falta pedir nada nuevo. | `AGENTS.md` sección 2, punto 8; `api-ventas.md` 1.1/1.2 |
| G3-2 | **`/pedidos/me` en vez del listado administrativo:** cambiaron su proxy de `GET /pedidos?clienteId=` a `GET /pedidos/me`, reenviando el token del cliente (rol `CLIENTE`), no el de servicio del canal — es la única excepción a "el canal usa su propio token" en todo el contrato. | `api-ventas.md` 1.4b |
| G3-3 | **CSAT:** `POST /api/v2/csat` con token del cliente (rol `CLIENTE`), `sub` validado contra el `clienteId` dueño del pedido → `403` si no coincide. Escala `1`/`3`/`5` (mismo acuerdo H-04 que Marketplace) — mapean tres caritas a esos tres valores. Se ofrece en el detalle de un pedido ya `ENTREGADO` (no proactiva, no reciben aviso de entrega). Tienen además una valoración propia de la experiencia del chat que no nos envían. | `api-postventas.md` 2.7; `integraciones/ACUERDO_G1_MARKETPLACE.md` H-04 |
| G3-4 | **`/devoluciones/me` y `/reclamos/me`** en vez de los listados administrativos, mismo patrón que `/pedidos/me` — token del cliente, sin `clienteId` en la URL. | `api-postventas.md` 2.4b, 2.10b |
| G3-5 | **A1–A14 de su propio registro interno** (`docs/contratos-integracion.md` sección 6): sin conversación formal registrada de nuestro lado, pero A8, A9, A13 y A14 ya coinciden con nuestras specs vigentes (A8 actualizado por el cambio a `/me`). Se dan por cerrados con este acuerdo, sin reconstruir la conversación original. | Consulta, punto 4 |
| G3-6 | **Detalle por identificador** (`GET /pedidos/{id}`, `GET /reclamos/{codigoSeguimiento}`, `GET /devoluciones/{id}`): los tres con token del cliente (rol `CLIENTE`), nunca el de servicio del canal — mismo patrón que los `/me`. | `api-ventas.md` 1.3; `api-postventas.md` 2.3, 2.9 |
| G3-7 | **Listado de pedidos sin miniaturas/dirección:** `/pedidos/me` mantiene su formato reducido (acuerdo H-03 con Marketplace, endpoint compartido entre canales) — Chatbot pide el detalle de cada pedido con `GET /pedidos/{id}` cuando necesita más datos, en vez de que ampliemos el listado. | `api-ventas.md` 1.4b |
| G3-8 | No necesitan el webhook de estado de envío (H-05, exclusivo de Marketplace) — consultan el estado bajo demanda, no por eventos. `Idempotency-Key` ya implementado de su lado para todas las operaciones que lo requieren. Reglas de validación de documento (DNI/RUC/CE/PASAPORTE) ya coinciden. Anulación directa por `PAGO_NO_COMPLETADO` ya coincide exactamente con F2 §1.7. | Consulta, "Lo que ya coincide" |

## Pendiente de confirmar / resolver

Ninguno — acuerdo cerrado por completo (2026-10-12).

## Historial

- 2026-10-10: Se envía `integraciones/CONSULTA_G3_CHATBOT.md` con 5 preguntas (credencial de pago, `/pedidos/me`, CSAT, A1–A14, `/devoluciones/me` y `/reclamos/me`).
- 2026-10-12: Chatbot responde los 5 puntos; se detecta que el `client_id` ya tenía `ventas:pagos:webhook` concedido (no hacía falta pedir nada), se confirma el token del cliente para los `/me` y CSAT, y se corrige la escala de CSAT a tres caritas → `1`/`3`/`5`.
- 2026-10-12: Chatbot pregunta por el token de dos endpoints de detalle por ID y por los campos del listado de pedidos. Se confirma el mismo patrón `/me` para los tres detalles, y se recomienda pedir el detalle en vez de ampliar `/pedidos/me` (para no afectar el acuerdo H-03 con Marketplace).
- 2026-10-12: Chatbot confirma que aplicó todos los cambios (PR #12) y registra todo como acuerdo A15 de su lado. Acuerdo cerrado.

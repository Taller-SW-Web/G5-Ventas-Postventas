# AGENTS.md — Contexto de negocio para asistentes de IA

Este documento orienta a cualquier asistente de IA (Claude, Copilot, etc.) que trabaje sobre este repositorio. No sustituye las especificaciones; resume el contexto de negocio y señala qué decisiones ya están cerradas para evitar que un asistente las reabra o las contradiga sin darse cuenta.

---

## 1. Qué es este módulo

**Módulo D — Ventas y Postventa**, parte de una plataforma de e-commerce de productos deportivos dividida en módulos A/B/C (canales de venta), D (este módulo), E (Despacho y Logística), F (Productos y Ofertas) y G (Seguridad y Usuarios).

Cubre de extremo a extremo: creación y ciclo de vida del pedido (F1), anulaciones (F2), devoluciones y cambios (F3), reembolsos (F4), encuesta CSAT (F5) y Libro de Reclamaciones + dashboard (F6).

Arquitectura: dos microservicios independientes bajo **Database-per-Service** —
- **M1 (Ventas)**, esquema `ventas`: F1, F2.
- **M2 (Postventa)**, esquema `postventa`: F3, F4, F5, F6.

Sin esquemas compartidos ni JOINs cruzados entre M1 y M2 (RNF-07). Ver [specs/overview.md](specs/overview.md).

---

## 2. Decisiones arquitecturales cerradas

Estas decisiones están vigentes en la documentación aprobada. Si un documento las contradice, **ese documento es el que está desactualizado**, no estas reglas:

1. **F2 (Anulación de pedidos) pertenece a M1**, no a M2. Así lo dicen README.md, specs/overview.md, specs/glosario.md, CONTRIBUTING.md, [specs/funcionalidades/F2-Anulacion de pedidos.md](specs/funcionalidades/F2-Anulacion%20de%20pedidos.md) y el modelo de datos (tabla `anulacion` vive en el esquema `ventas`).
   - Los documentos de `arquitectura/` (C4 niveles 1, 2 y 3) ya ubican F2 en M1.
2. **El UI Kit del frontend es Mantine UI**, no Tailwind CSS. Así lo dicen README.md, CONTRIBUTING.md y específicamente specs/stack-frontend.md (documento detallado y vigente). El C4 nivel 2 ya usa Mantine UI.
3. **Valores de `historial_estado.actor`**: únicamente `CLIENTE`, `GESTOR`, `CANAL_CHATBOT`, `PASARELA_PAGOS`, `SISTEMA_LOGISTICA`, `SISTEMA_PRODUCTOS` (el `CHECK` real en base de datos, ver diseno/diagramas/bd/diagrama-fisico.md). `SISTEMA_PRODUCTOS` se aprobó el 2026-10-12 para las anulaciones automáticas por rechazo de Productos (stock o cupón) — ver punto 5. ESP-03 ya está alineado a esta lista — no usar `PASARELA`, `CANAL`, `DESPACHO` ni `SISTEMA` sueltos.
4. **Valores cerrados de estados y canal** (cada uno con su `CHECK` en la base y su enum en Java):
   - `pedido.canal`, `reclamo.canal`, `calificacion.canal`: `MARKETPLACE`, `CHATBOT`, `RETAIL`. El canal web se llama `MARKETPLACE`, nunca `WEB`.
   - `pago.estado`: `PENDIENTE`, `CONFIRMADO`, `RECHAZADO` — confirmado en Supabase (migración `huecos_h2_h3_h5_h6_postventa`, 10/10/2026) y en la guía de implementación del backend; manda Supabase si algún documento no coincide. La pasarela envía `resultado: APROBADO`, pero internamente se guarda como `CONFIRMADO`, no `APROBADO`.
   - `anulacion.estado`: `PENDIENTE_AUTORIZACION`, `EJECUTADA`, `RECHAZADA`.
   - `devolucion.estado`: `SOLICITADA`, `EN_EVALUACION`, `APROBADA`, `RECHAZADA`, `COMPLETADA`.
   - `reclamo.estado`: `REGISTRADO`, `EN_PROCESO`, `ATENDIDO`, `DERIVADO`.
   - Los estados se escriben con guion bajo: `EN_PREPARACION`, no `EN PREPARACIÓN`.
5. **Matriz de transiciones del pedido**: la de ESP-03 sección 7.2. Incluye `CREADO → ANULADO` y `PAGADO → ANULADO` directas (sin Gestor) para las solicitudes de F2; solo `EN_PREPARACION → ANULADO` requiere autorización del Gestor. También incluye `PAGADO → ENTREGADO` directa (actor `CLIENTE`, motivo `ENTREGA_INMEDIATA_EN_TIENDA`, sin Gestor ni Despacho) exclusiva del canal `RETAIL`, confirmada 2026-10-12 con G4 — ver punto 8.
   - **Rechazo asíncrono de Productos (aprobado en equipo, 2026-10-12):** cuando Productos rechaza la reserva de stock o el consumo de cupón (respuesta async por RabbitMQ, no en el `202 Accepted` inicial), el pedido se anula automáticamente, actor `SISTEMA_PRODUCTOS`, sin Gestor — `CREADO → ANULADO` (motivo `STOCK_NO_DISPONIBLE` o `CUPON_RECHAZADO`) en el caso general, y `PAGADO → ANULADO` (motivo `STOCK_NO_DISPONIBLE`, con solicitud automática de reembolso a F4) para el caso Chatbot, que cobra antes de que Productos confirme el stock. **Excepción:** si el cupón se rechaza y el pedido ya está `PAGADO`, no se anula — se registra como inconsistencia visible para que el Gestor la revise manualmente, el pedido conserva su estado (ver ESP-01, regla 12).
6. **Gateway**: rutea por recurso (`/api/*/pedidos/**` a M1; devoluciones, reembolsos, csat, reclamos y dashboard a M2). `POST /api/v2/eventos` es interno y no pasa por el Gateway.
7. **Integraciones**: cada servicio tiene un paquete `integracion/` con un cliente por sistema externo. Los eventos de M1 salen por `ventas.outbox_evento` y M2 descarta duplicados con `postventa.evento_recibido`.
8. **Orquestación del cobro simulado**: el endpoint `1.2` (`pagos/notificacion`) solo acepta llamadas de servicios de confianza explícitamente autorizados, cada uno con su propia credencial de servicio y el scope `ventas:pagos:webhook` — no de un canal sin autorizar ni de su frontend. Qué servicio llama a `1.2` depende de si el canal construye su propia simulación de pago o no:
   - **Canales que no construyen su propia simulación de pago (Marketplace, confirmado 2026-10-10):** M1 invoca al simulador de pasarela compartido inmediatamente después de crear el pedido con la reserva confirmada; el canal solo crea el pedido (1.1) y consulta su estado (1.3/1.4b) hasta ver `PAGADO`. No participa en la llamada a `1.2` en absoluto.
   - **Canales cuyo producto exige su propia experiencia de pago (Chatbot, confirmado 2026-10-10 — ver `ADR-0014` de G3, aceptado 2026-09-24):** el backend del canal procesa su propia simulación (tabla de tarjetas de prueba, latencia, etc.) y notifica `1.2` directamente con su propia credencial de servicio (`modulo-chatbot`). No usa el simulador compartido.
   - **Canal cuyo cobro ya ocurrió físicamente antes de la llamada (Retail, confirmado 2026-10-12 — ver `integraciones/ACUERDO_G4_RETAIL.md`):** el cobro ya se realizó en el POS de la tienda antes de que exista el pedido en nuestro sistema. `POST /pedidos` con `canal: RETAIL` persiste el pedido directo en `PAGADO`, no en `CREADO`, con los datos declarados del cobro en el bloque `pago` (`metodoPago`: `EFECTIVO`/`TARJETA_POS`/`MIXTO`, `referenciaOperacion`, y `montoEfectivo`/`montoTarjeta` si es mixto), y en la misma operación transiciona a `ENTREGADO` (actor `CLIENTE`, motivo `ENTREGA_INMEDIATA_EN_TIENDA`, sin que Despacho participe — ver ESP-03 regla 8). No se invoca `1.2` en absoluto, ni se reserva/confirma stock con Productos (F): el POS ya lo descontó directo del inventario central al momento de la venta; M1 solo registra el pedido. El bloque `envio` es opcional para este canal — en su lugar es obligatorio `tiendaId` — porque el cliente se lleva el producto en el momento, sin entrega a domicilio.
   Los tres casos son válidos simultáneamente; no son decisiones contradictorias, responden a requisitos de producto y de operación distintos por canal. Ver `F1-Ciclo de vida del pedido.md` (CA-01b, CA-01c), `ESP-01` (regla 12), `api-ventas.md` (1.1, 1.2).
9. **El rol real de "Gestor" es `ADMIN_VENTAS`, no `GESTOR` ni `ADMIN`** — confirmado en el catálogo cerrado de 6 roles del módulo de Seguridad (`CLIENTE`, `VENDEDOR`, `ADMIN_VENTAS`, `GESTOR_DESPACHO`, `GESTOR_COMERCIAL`, `ADMIN_SISTEMA`; ver `integraciones/CONSULTA_G7_SEGURIDAD.md`). "Gestor" sigue siendo el nombre que usamos en specs e interfaz; la autorización real debe validar el claim `roles` del JWT contra `ADMIN_VENTAS`. No afecta el valor `GESTOR` del enum `historial_estado.actor` (punto 3) — son cosas distintas: ese es un actor de auditoría en nuestro propio dominio, no un rol de Seguridad.
10. **`id_cliente`, `id_vendedor`, `id_solicitante` e `id_autorizador` son `uuid`, no `bigint`** — confirmado por Seguridad (`sub` del JWT es `uuid`, ver `integraciones/CONSULTA_G7_SEGURIDAD.md`). Ya corregido en `diagrama-fisico.md`, `diagrama-logico.md` y `ventas_postventa_schema.sql`; **falta aplicar la migración real en Supabase** (ver nota al inicio de `ventas_postventa_schema.sql`).
11. **Crear pedido (1.1) y anular (1.7) usan el token de servicio del canal, no el del cliente** — acuerdo A10 con Seguridad (2026-10-10, ver `integraciones/ACUERDO_G7_SEGURIDAD.md`). La identidad del cliente viaja como dato (`contacto.clienteId`), no se deriva del token; única excepción: `GET /pedidos/me`. Scopes registrados: `ventas:pedidos:crear`, `ventas:pedidos:anular`, `ventas:pedidos:estado`, `ventas:pagos:webhook` (servicio); `ventas:pedidos:leer` y `ventas:admin` **no son scopes**, se resuelven por `roles` del token de usuario (`CLIENTE`/`ADMIN_VENTAS`). M1/M2 consumen `usuarios:leer` de Seguridad (no `tokens:introspeccion`) para verificar que el cliente siga activo antes de anular/reembolsar. Ver catálogo de scopes en `api-ventas.md`.
12. **M1 se conecta directo al broker RabbitMQ de Productos** (decisión de equipo, 2026-10-11) — para recibir los resultados de reserva/confirmación/liberación de inventario (`po.sales.q`) y manejar el consumo/restauración de cupón (`po.commands.x`/`po.results.x`, evento-only, sin alternativa HTTP). Se descartó pedir un adaptador HTTP propio: no estaba claro que Productos fuera a construirlo por nosotros, así que no evitaba el trabajo, solo lo movía. La topología de Productos sigue en versión candidata (`0.6.0-rc.1`); no la consideran operativa todavía — ver `integraciones/ACUERDO_G6_PRODUCTOS.md`.
13. **Despacho (G2) notifica por un webhook genérico de eventos, no por nuestro `PATCH /estado` original** — confirmado 2026-10-12, acuerdo cerrado, ver `integraciones/ACUERDO_G2_DESPACHO.md`. `POST /api/v1/integraciones/despachos/eventos` reemplaza `api-ventas.md` 1.5 y 1.6 anteriores; mapeo de sus 7 tipos de evento hacia nuestra máquina de estados ya cerrado (ver `api-ventas.md` 1.5), incluyendo `DESPACHO_REPROGRAMADO` (no se ignora, trae `nuevaFechaProgramada`) y `DESPACHO_CANCELADO` (acuse idempotente de una cancelación que ya pedimos nosotros). `guiaRemision` se retira de nuestros contratos — Despacho no la emite; `datos.motivoCierre` es suficiente. Scope: reusamos `ventas:pedidos:estado`, decisión nuestra, no el `despachos:eventos:recibir` que propuso G2. `Idempotency-Key` obligatoria en ambos sentidos. Despacho también confirmó el manejo de `409 Conflict` al cancelar un despacho ya `EN_CAMINO` (rechazo de negocio, no reintentar — ver ESP-06 CA-06, nuevo). Quedan solo tareas de implementación de nuestro lado, no preguntas a G2, ver sección 4.

Si necesitas tocar cualquiera de estos puntos, pregunta antes de asumir que el C4 "propuesta" ya es la versión vigente.

---

## 3. Fuentes de verdad (en orden de consulta)

| Tema | Documento |
|---|---|
| Visión general, arquitectura, RNF | [specs/overview.md](specs/overview.md) |
| Lenguaje del dominio (entidades, estados, actores) | [specs/glosario.md](specs/glosario.md) |
| Contratos de API (M1 y M2) | [specs/api-contract.md](specs/api-contract.md) |
| Modelo de datos (conceptual, lógico, físico, operación) | [specs/modelo-datos.md](specs/modelo-datos.md) |
| Reglas de negocio y criterios de aceptación por RF | `specs/especificaciones/funcionales/` (ESP-01 a ESP-16) |
| Requisitos no funcionales | `specs/especificaciones/no-funcionales/` (RNF-01 a RNF-08) |
| Stack y convenciones de frontend | [specs/stack-frontend.md](specs/stack-frontend.md) |
| Estructura y guía de implementación del backend | [guias/backend/estructura-backend.md](guias/backend/estructura-backend.md), [guias/backend/guia-backend.md](guias/backend/guia-backend.md) |
| Estructura y guía de implementación del frontend | [guias/frontend/estructura-frontend.md](guias/frontend/estructura-frontend.md), [guias/frontend/guia-frontend.md](guias/frontend/guia-frontend.md) |
| Flujo de ramas, commits y PRs | [CONTRIBUTING.md](CONTRIBUTING.md) |

Los documentos bajo `arquitectura/` (C4 niveles 1, 2 y 3) siguen siendo **propuestas en discusión** en lo que respecta a proveedores de despliegue (Vercel, Render, Supabase). Su contenido funcional (F1 y F2 en M1; F3 a F6 en M2; Mantine UI) está alineado con la sección 2.

---

## 4. Puntos todavía sin definir

No inventes valores ni contenido para estos puntos; si hace falta, pregunta o deja el gap explícito:

- Dónde se despliega `simulador-pasarela` (Render u otro). En local corre como aplicación propia en el puerto 8083 (ver la guía del backend, sección 9.3).
- Mecanismo técnico de entrega del webhook `pedidos.envio.estado_actualizado` hacia Marketplace (acuerdo H-05, ver `api-ventas.md` 1.10) — reintentos, backoff, cola de salida. El contrato ya está cerrado; falta el diseño de implementación, a cargo de quien construya F1.
- `integraciones/` (acuerdos con otros módulos): con G1 (Marketplace), G2 (Despacho), G3 (Chatbot), G4 (Retail), G6 (Productos) y G7 (Seguridad) ya hay acuerdo formal — ver `integraciones/ACUERDO_G1_MARKETPLACE.md`, `ACUERDO_G2_DESPACHO.md`, `ACUERDO_G3_CHATBOT.md`, `ACUERDO_G4_RETAIL.md`, `ACUERDO_G6_PRODUCTOS.md` y `ACUERDO_G7_SEGURIDAD.md`.
- Pendientes de implementación de F1/F2 con Despacho (G2) — ya no hay nada que preguntarles, son tareas internas (ver `integraciones/ACUERDO_G2_DESPACHO.md`):
  1. Qué señal de nuestro lado dispara `POST /api/v1/despachos` — Despacho confirmó que debe ser cuando el paquete esté físicamente preparado y sellado, no apenas `EN_PREPARACION` (ver `api-ventas.md` 1.5, `F1-Ciclo de vida del pedido.md`). Falta decidir la acción concreta (¿botón del Gestor?, ¿checklist?).
  2. Agregar la columna `pedido.fecha_estimada_entrega` al modelo de datos — confirmada necesaria por G2 para `datos.nuevaFechaProgramada` de `DESPACHO_REPROGRAMADO`.
- **Pregunta suelta a G2, todavía sin mandar formalmente:** si `LISTO_PARA_RECOJO` es un sub-estado propio de Despacho (surgió de la consulta a Retail, 2026-10-12, ver `integraciones/ACUERDO_G4_RETAIL.md` R10) — no se incluyó en `CONSULTA_G2_DESPACHO.md` ni la respondieron; no bloquea el acuerdo ya cerrado con G2, pero sigue abierta.
- Migración real en Supabase de `id_cliente`/`id_vendedor`/`id_solicitante`/`id_autorizador` de `bigint` a `uuid` (punto 10 de la sección 2): las specs y el script ya están corregidos, falta aplicarla sobre la base real.

---

## 5. Convenciones de trabajo

- Responsables por funcionalidad y ramas personales: ver tabla en [CONTRIBUTING.md](CONTRIBUTING.md).
- Mensajes de commit: `<tipo>(<alcance opcional>): <descripción breve>` (`feat`, `fix`, `docs`, `style`, `refactor`, `test`, `rename`, `delete`).
- Toda acción administrativa o dictamen debe registrar actor/autorizador, motivo y timestamp UTC ISO-8601 (RNF-03).
- Toda solicitud de reembolso requiere `X-Idempotency-Key` (RNF-08).

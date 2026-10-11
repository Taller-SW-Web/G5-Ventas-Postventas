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
3. **Valores de `historial_estado.actor`**: únicamente `CLIENTE`, `GESTOR`, `CANAL_CHATBOT`, `PASARELA_PAGOS`, `SISTEMA_LOGISTICA` (el `CHECK` real en base de datos, ver diseno/diagramas/bd/diagrama-fisico.md). ESP-03 ya está alineado a esta lista — no usar `PASARELA`, `CANAL`, `DESPACHO` ni `SISTEMA` sueltos.
4. **Valores cerrados de estados y canal** (cada uno con su `CHECK` en la base y su enum en Java):
   - `pedido.canal`, `reclamo.canal`, `calificacion.canal`: `MARKETPLACE`, `CHATBOT`, `RETAIL`. El canal web se llama `MARKETPLACE`, nunca `WEB`.
   - `pago.estado`: `PENDIENTE`, `CONFIRMADO`, `RECHAZADO` — confirmado en Supabase (migración `huecos_h2_h3_h5_h6_postventa`, 10/10/2026) y en la guía de implementación del backend; manda Supabase si algún documento no coincide. La pasarela envía `resultado: APROBADO`, pero internamente se guarda como `CONFIRMADO`, no `APROBADO`.
   - `anulacion.estado`: `PENDIENTE_AUTORIZACION`, `EJECUTADA`, `RECHAZADA`.
   - `devolucion.estado`: `SOLICITADA`, `EN_EVALUACION`, `APROBADA`, `RECHAZADA`, `COMPLETADA`.
   - `reclamo.estado`: `REGISTRADO`, `EN_PROCESO`, `ATENDIDO`, `DERIVADO`.
   - Los estados se escriben con guion bajo: `EN_PREPARACION`, no `EN PREPARACIÓN`.
5. **Matriz de transiciones del pedido**: la de ESP-03 sección 7.2. Incluye `CREADO → ANULADO` y `PAGADO → ANULADO` directas (sin Gestor) para las solicitudes de F2; solo `EN_PREPARACION → ANULADO` requiere autorización del Gestor.
6. **Gateway**: rutea por recurso (`/api/*/pedidos/**` a M1; devoluciones, reembolsos, csat, reclamos y dashboard a M2). `POST /api/v2/eventos` es interno y no pasa por el Gateway.
7. **Integraciones**: cada servicio tiene un paquete `integracion/` con un cliente por sistema externo. Los eventos de M1 salen por `ventas.outbox_evento` y M2 descarta duplicados con `postventa.evento_recibido`.
8. **Orquestación del cobro simulado**: el endpoint `1.2` (`pagos/notificacion`) solo acepta llamadas de servicios de confianza explícitamente autorizados, cada uno con su propia credencial de servicio y el scope `ventas:pagos:webhook` — no de un canal sin autorizar ni de su frontend. Qué servicio llama a `1.2` depende de si el canal construye su propia simulación de pago o no:
   - **Canales que no construyen su propia simulación de pago (Marketplace, confirmado 2026-10-10):** M1 invoca al simulador de pasarela compartido inmediatamente después de crear el pedido con la reserva confirmada; el canal solo crea el pedido (1.1) y consulta su estado (1.3/1.4b) hasta ver `PAGADO`. No participa en la llamada a `1.2` en absoluto.
   - **Canales cuyo producto exige su propia experiencia de pago (Chatbot, confirmado 2026-10-10 — ver `ADR-0014` de G3, aceptado 2026-09-24):** el backend del canal procesa su propia simulación (tabla de tarjetas de prueba, latencia, etc.) y notifica `1.2` directamente con su propia credencial de servicio (`modulo-chatbot`). No usa el simulador compartido.
   Ambos casos son válidos simultáneamente; no son decisiones contradictorias, responden a requisitos de producto distintos por canal. Ver `F1-Ciclo de vida del pedido.md` (CA-01b), `ESP-01` (regla 12), `api-ventas.md` (1.1, 1.2).

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
| Flujo de ramas, commits y PRs | [CONTRIBUTING.md](CONTRIBUTING.md) |

Los documentos bajo `arquitectura/` (C4 niveles 1, 2 y 3) siguen siendo **propuestas en discusión** en lo que respecta a proveedores de despliegue (Vercel, Render, Supabase). Su contenido funcional (F1 y F2 en M1; F3 a F6 en M2; Mantine UI) está alineado con la sección 2.

---

## 4. Puntos todavía sin definir

No inventes valores ni contenido para estos puntos; si hace falta, pregunta o deja el gap explícito:

- Dónde se despliega `simulador-pasarela` (Render u otro). En local corre como aplicación propia en el puerto 8083 (ver la guía del backend, sección 9.3).
- Mecanismo técnico de entrega del webhook `pedidos.envio.estado_actualizado` hacia Marketplace (acuerdo H-05, ver `api-ventas.md` 1.10) — reintentos, backoff, cola de salida. El contrato ya está cerrado; falta el diseño de implementación, a cargo de quien construya F1.
- `integraciones/` (acuerdos con otros módulos): con G1 (Marketplace) ya hay contenido real — ver `integraciones/ACUERDO_G1_MARKETPLACE.md`. Con G2, G3, G6 y G7 sigue en pausa: solo crear su documento si existe una negociación real que documentar, nunca como placeholder vacío.
- Liberación del cupón aplicado cuando un pedido se anula desde `CREADO` (por timeout/abandono del canal o por rechazo de la pasarela, ver `F1-Ciclo de vida del pedido.md` CA-12 y CA-07b): no existe integración documentada con Productos y Ofertas (F) para esto, a diferencia de la reposición de stock que sí la tiene. Gap preexistente, detectado el 2026-10-10 al homologar el pago simulado con Marketplace.

---

## 5. Convenciones de trabajo

- Responsables por funcionalidad y ramas personales: ver tabla en [CONTRIBUTING.md](CONTRIBUTING.md).
- Mensajes de commit: `<tipo>(<alcance opcional>): <descripción breve>` (`feat`, `fix`, `docs`, `style`, `refactor`, `test`, `rename`, `delete`).
- Toda acción administrativa o dictamen debe registrar actor/autorizador, motivo y timestamp UTC ISO-8601 (RNF-03).
- Toda solicitud de reembolso requiere `X-Idempotency-Key` (RNF-08).

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

Si necesitas tocar cualquiera de estos tres puntos, pregunta antes de asumir que el C4 "propuesta" ya es la versión vigente.

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

- `reclamo.canal`: el contrato (`api-postventas.md` 2.8) ya lo envía al registrar un reclamo, pero ninguna tabla tiene todavía la columna — ver "Pendientes" en diseno/diagramas/bd/diagrama-logico.md y diagrama-fisico.md. Es el único valor de enum que sigue sin definirse; `pago.estado`, `devolucion.estado`, `anulacion.estado`, `reclamo.estado` y `pedido.canal`/`calificacion.canal` ya están confirmados (ver diagrama-fisico.md, sección 5).
- `integraciones/` (acuerdos con G1/G2/G3): en pausa. Solo crear contenido ahí si existe una negociación real que documentar — nunca como placeholder vacío.

---

## 5. Convenciones de trabajo

- Responsables por funcionalidad y ramas personales: ver tabla en [CONTRIBUTING.md](CONTRIBUTING.md).
- Mensajes de commit: `<tipo>(<alcance opcional>): <descripción breve>` (`feat`, `fix`, `docs`, `style`, `refactor`, `test`, `rename`, `delete`).
- Toda acción administrativa o dictamen debe registrar actor/autorizador, motivo y timestamp UTC ISO-8601 (RNF-03).
- Toda solicitud de reembolso requiere `X-Idempotency-Key` (RNF-08).

# Contrato de API (OpenAPI / REST) — Módulo D: Ventas y Postventa

**Versión:** 1.4.0

**Fecha:** Septiembre 2026

---

## 1. Propósito

Este documento es el **punto de entrada formal** al contrato de API del Módulo D. El contrato real está dividido en dos archivos, uno por microservicio, siguiendo el aislamiento definido en RNF-07 (ver [specs/overview.md](overview.md)):

| Microservicio | Contrato | Funcionalidades |
|---|---|---|
| M1 — Ventas / Pedidos | [specs/api/api-ventas.md](api/api-ventas.md) | F1 — Ciclo de vida del pedido, F2 — Anulación de pedidos |
| M2 — Postventa | [specs/api/api-postventas.md](api/api-postventas.md) | F3 — Devoluciones y cambios, F4 — Reembolsos y extornos, F5 — Calificación CSAT, F6 — Reclamos y dashboard |

Códigos y condiciones de error de ambos contratos, consolidados: [specs/api/catalogo-errores.md](api/catalogo-errores.md).

Cualquier referencia a `specs/api-contract.md` en el resto del repositorio (README, CONTRIBUTING, especificaciones funcionales y no funcionales) debe entenderse como una referencia a este índice y, a través de él, a los dos contratos específicos.

---

## 2. Convenciones globales

Ambos contratos comparten las siguientes convenciones:

- **Formato de datos:** `application/json; charset=utf-8` (y `multipart/form-data` únicamente en la subida de evidencias de F3).
- **Timestamps:** ISO-8601 en UTC (`YYYY-MM-DDTHH:mm:ssZ`).
- **Autenticación:** cabecera HTTP `Authorization: Bearer <JWT>`, emitido por el Módulo G (Seguridad y Usuarios).
- **Idempotencia financiera (RNF-08):** toda solicitud de reembolso incluye la cabecera `X-Idempotency-Key`.
- **Estándar de error:**

```json
{
  "codigo": "RECURSO_NO_ENCONTRADO",
  "mensaje": "Descripción legible del error",
  "timestamp": "2026-09-23T00:05:00Z",
  "detalles": []
}
```

### Códigos HTTP usados

| Código | Uso típico |
|---|---|
| `200 OK` | Consulta o actualización exitosa |
| `201 Created` | Creación de un recurso (pedido, devolución, reembolso, reclamo, calificación) |
| `202 Accepted` | Solicitud aceptada pero pendiente de autorización (p. ej. anulación en `EN_PREPARACION`) |
| `400 Bad Request` | Datos inválidos o incompletos |
| `401 Unauthorized` | Token ausente o inválido |
| `403 Forbidden` | El solicitante no es titular del recurso u origen no permitido |
| `404 Not Found` | Recurso inexistente |
| `409 Conflict` | Transición de estado no permitida, conflicto de idempotencia o estado incompatible |

---

## 3. Dónde buscar cada cosa

- Scopes OAuth2/JWT por microservicio: ver la sección "Catálogo de Scopes" de cada contrato.
- Endpoints, payloads y respuestas de cada funcionalidad (F1–F6): ver la sección "Endpoints" del contrato correspondiente.
- Reglas de negocio y criterios de aceptación detrás de cada endpoint: ver `specs/especificaciones/funcionales/` (ESP-01 a ESP-16).

## 4. Otros documentos relacionados

- [specs/overview.md](overview.md) — visión general de arquitectura y RNF.
- [specs/glosario.md](glosario.md) — lenguaje ubicuo del dominio.
- [diseno/diagramas/bd/diagrama-logico.md](../diseno/diagramas/bd/diagrama-logico.md) — modelo de datos detrás de estos contratos.

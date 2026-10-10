# ADR-004: Markdown como fuente de verdad de los contratos de API

**Fecha:** 2026-10-09
**Estado:** Aceptado
**Decisor:** Joseph (F3 — Devoluciones y cambios, Product Owner)
**Alcance:** Transversal — [specs/api/api-ventas.md](../../specs/api/api-ventas.md), [specs/api/api-postventas.md](../../specs/api/api-postventas.md), [specs/api-contract.md](../../specs/api-contract.md)

---

## Contexto

Al revisar cómo otros equipos del curso documentan sus contratos de API, surgió la opción de agregar una especificación formal OpenAPI (`openapi.yaml`) para M1 y M2, que permitiría generar Swagger UI o mocks automáticamente.

Sin embargo, el módulo ya tiene dos contratos de API detallados en Markdown ([api-ventas.md](../../specs/api/api-ventas.md) y [api-postventas.md](../../specs/api/api-postventas.md)), más un índice ([api-contract.md](../../specs/api-contract.md)) y un catálogo de errores ([catalogo-errores.md](../../specs/api/catalogo-errores.md)) recién consolidados. Mantener una segunda descripción en paralelo (YAML) de los mismos endpoints, sin una jerarquía clara entre ambas, reproduciría el mismo problema que dejó roto a `api-contract.md` durante un tiempo: cuando dos documentos describen lo mismo, uno de los dos queda desactualizado sin que nadie lo note.

RNF-06-02 exige que los contratos de API estén "documentados y versionados por sus responsables", pero aclara explícitamente que "no prescribe una herramienta ni un esquema de versionado concreto" — por lo tanto, no exige OpenAPI como formato.

## Decisión

Se definen los contratos de API directamente en especificaciones Markdown (`api-ventas.md` y `api-postventas.md`) como **SSOT** (Single Source of Truth / Fuente Única de Verdad), para evitar duplicidad, divergencias y sobrecosto de mantenimiento frente a un esquema OpenAPI YAML paralelo, en la fase actual de diseño (sin backend implementado todavía).

## Consecuencias

**Positivas:**
- Un único lugar por microservicio para describir endpoints, payloads y errores, sin riesgo de que Markdown y YAML diverjan.
- Cumple RNF-06-02 sin necesidad de herramientas ni procesos adicionales.

**Negativas / trade-offs:**
- No hay Swagger UI ni generación automática de mocks o clientes a partir de un esquema máquina-legible, mientras no se implemente el backend.

## Revisión futura

Esta decisión debe revisarse cuando el equipo inicie la implementación del backend. Si en ese momento se necesita Swagger UI, mocks automáticos o validación de contratos en CI, el YAML debe generarse **a partir de** estos Markdown (o reemplazarlos formalmente como nueva fuente de verdad) — nunca mantenerse en paralelo sin una jerarquía definida.

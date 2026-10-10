# Registro de ADR — Módulo D: Ventas y Postventa

Un ADR (Architecture Decision Record / Registro de Decisión Arquitectural) es un archivo corto por cada decisión de arquitectura relevante: su contexto, la decisión tomada y sus consecuencias. No reemplaza las especificaciones — las explica y deja registro de *por qué* se decidió algo, para que no se vuelva a discutir sin ese contexto.

Formato de archivo: `ADR-NNN-titulo-corto.md`, con las secciones **Contexto**, **Decisión** y **Consecuencias** (ver [ADR-004](ADR-004-fuente-verdad-contratos-api.md) como referencia).

---

## Registro

| ADR | Título | Estado | Encargado | Rama |
|---|---|---|---|---|
| ADR-001-f2-anulaciones-en-m1.md | F2 (Anulación de pedidos) pertenece a M1, no a M2 | Pendiente | Luis Arroyo (F2, Software Architect) | `Luis-Arroyo` |
| ADR-002-frontend-mantine-ui.md | UI Kit del frontend: Mantine UI, no Tailwind CSS | Pendiente | Luis Alejandro (F4, Developer Frontend) | `Luis-Alejandro` |
| ADR-003-aislamiento-esquemas-m1-m2.md | Aislamiento estricto de esquemas entre M1 y M2 (Database-per-Service) | Pendiente | Luis Arroyo (Software Architect) | `Luis-Arroyo` |
| [ADR-004-fuente-verdad-contratos-api.md](ADR-004-fuente-verdad-contratos-api.md) | Markdown como fuente de verdad de los contratos de API | **Aceptado** | Joseph (F3, Product Owner) | `Joseph` |

Los nombres de archivo de ADR-001 a ADR-003 todavía no existen como links porque nadie los ha subido aún — se enlazan solos cuando cada responsable los cree, para no dejar enlaces rotos mientras tanto.

### Qué debe capturar cada uno

- **ADR-001:** por qué la anulación (F2) ejecuta su transición de estado a través de M1 y no vive como entidad de M2, a pesar de que la propuesta C4 original la ubicaba ahí. Contexto relevante: `specs/funcionalidades/F2-Anulacion de pedidos.md`, tabla `anulacion` en el esquema `ventas`.
- **ADR-002:** por qué el frontend usa Mantine UI como librería de componentes en vez de Tailwind CSS (que aparecía en una versión anterior del C4 nivel 2). Contexto relevante: `specs/stack-frontend.md`.
- **ADR-003:** por qué M1 y M2 no comparten esquema, tablas ni claves foráneas (Database-per-Service), y cómo se resuelven las referencias cruzadas por API en vez de JOIN. Contexto relevante: RNF-07, `diseno/diagramas/bd/diagrama-fisico.md`.

### Por qué solo estos cuatro

Son las únicas decisiones de arquitectura que ya se cerraron o se discutieron formalmente en este repositorio hasta ahora (ver [AGENTS.md](../../AGENTS.md), sección 2). No se proponen ADRs para F1, F5 o F6 porque, por ahora, no hay ninguna decisión de ese tipo pendiente de documentar en esas funcionalidades — se agregan ADRs nuevos cuando surge una decisión real que lo amerite, no para completar la lista.

### Cómo subir un ADR pendiente

1. El responsable asignado redacta su ADR en su propia rama, siguiendo el formato de [ADR-004](ADR-004-fuente-verdad-contratos-api.md).
2. Se sube como Pull Request hacia `main`, igual que cualquier otro cambio (ver [CONTRIBUTING.md](../../CONTRIBUTING.md)).
3. Al fusionarse, se actualiza su fila en esta tabla: estado a "Aceptado" y el nombre de archivo se convierte en link.

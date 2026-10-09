# Modelo de Datos — Módulo D: Ventas y Postventa

## 1. Propósito

Este documento es el **punto de entrada formal** al modelo de datos del Módulo D. El modelo real está detallado en otros documentos, cada uno con un nivel de abstracción distinto (ver sección 3). Aquí solo se resume la estrategia de persistencia y se enlaza a cada uno.

Cualquier referencia a `specs/modelo-datos.md` en el resto del repositorio (README, CONTRIBUTING, especificaciones no funcionales) debe entenderse como una referencia a este índice.

---

## 2. Estrategia de persistencia (Database-per-Service)

Siguiendo el aislamiento de microservicios (**RNF-07**, ver [specs/overview.md](overview.md)):

- **M1 — Ventas** usa el esquema `ventas`: `pedido`, `detalle_pedido`, `pago`, `historial_estado`, `anulacion`.
- **M2 — Postventa** usa el esquema `postventa`: `devolucion`, `evidencia_devolucion`, `reembolso`, `reclamo`, `calificacion`, `agregado_ventas`.
- No existen claves foráneas ni JOINs entre ambos esquemas. Cuando M2 necesita un dato de M1 (por ejemplo `id_pedido`), lo guarda como columna simple y lo valida contra la API de M1, nunca por acceso directo a su base de datos.
- Los campos que referencian a otros módulos (G — Seguridad y Usuarios, E — Despacho y Entrega, F — Productos y Catálogo) se guardan como identificadores sin clave foránea.

---

## 3. Documentos de referencia

Cada nivel del modelo se detalla en un documento distinto; estas son las ubicaciones donde se da la información de forma más específica:

| Documento | Nivel | Contenido |
|---|---|---|
| [diagrama-conceptual.md](../diseno/diagramas/bd/diagrama-conceptual.md) | Conceptual | Entidades, atributos y relaciones, sin tipos de datos ni claves foráneas. |
| [diagrama-logico.md](../diseno/diagramas/bd/diagrama-logico.md) | Lógico | Tablas, columnas, tipos, PK/FK/UK, reglas de negocio por tabla y pendientes de definición. |
| [diagrama-fisico.md](../diseno/diagramas/bd/diagrama-fisico.md) | Físico | Implementación real en PostgreSQL 17 (Supabase): tipos exactos, defaults, restricciones CHECK, índices y seguridad (RLS). |
| [base-de-datos-ventas-postventa.md](../infra/bd/base-de-datos-ventas-postventa.md) | Operación | Cómo se aplicó el script como migración en Supabase, pruebas realizadas y pendientes operativos (usuarios de BD, bucket de evidencias, etc.). |

Para reglas de negocio y criterios de aceptación detrás de cada entidad, ver `specs/especificaciones/funcionales/` (ESP-01 a ESP-16).

---

## 4. Otros documentos relacionados

- [specs/overview.md](overview.md) — visión general de arquitectura y RNF.
- [specs/glosario.md](glosario.md) — lenguaje ubicuo del dominio (entidades, estados, actores).
- [specs/api-contract.md](api-contract.md) — contratos de API que exponen estas entidades.

# ADR-001: F2 (Anulación de pedidos) pertenece a M1, no a M2

**Fecha:** 2026-10-09
**Estado:** Aceptado
**Decisor:** Luis Arroyo (F2 — Anulación de pedidos, Software Architect)
**Alcance:** [specs/funcionalidades/F2-Anulacion de pedidos.md](../../specs/funcionalidades/F2-Anulacion%20de%20pedidos.md), [specs/api/api-ventas.md](../../specs/api/api-ventas.md), [diseno/diagramas/bd/diagrama-logico.md](../../diseno/diagramas/bd/diagrama-logico.md), `arquitectura/c4-nivel-1` y `c4-nivel-2`

---

## Contexto

En las primeras versiones de los documentos de arquitectura C4 (niveles 1 y 2), F2 (Anulación de pedidos) aparecía ubicada dentro de M2 — Postventa, junto con F3 a F6. Sin embargo, el resto de la documentación del módulo — README.md, specs/overview.md, specs/glosario.md, CONTRIBUTING.md, la propia especificación de F2 ([specs/funcionalidades/F2-Anulacion de pedidos.md](../../specs/funcionalidades/F2-Anulacion%20de%20pedidos.md)) y el modelo de datos (la tabla `anulacion` vive en el esquema `ventas`, no en `postventa`) — siempre ubicó F2 dentro de M1 — Ventas.

Esto generó una contradicción, documentada explícitamente como pendiente en `diseno/diagramas/bd/diagrama-logico.md` e `infra/bd/base-de-datos-ventas-postventa.md`: *"anulación está en M1 porque cambia el estado del pedido, pero el C4 nivel 2 pone F2 en M2. Hay que alinear ambos documentos."*

La razón de fondo es conceptual, no solo de documentación: F2 decide y coordina la anulación (motivo, autorización del Gestor cuando corresponde), pero quien ejecuta la transición real del estado del pedido a `ANULADO` y quien escribe el historial (`historial_estado`) es siempre M1, nunca M2 directamente — *"F2 nunca escribe directamente sobre las tablas de pedido"* (ver F2-Anulacion de pedidos.md, sección 7, "Backend"). Poner F2 en M2 habría obligado a M2 a escribir en tablas de M1, violando el aislamiento de esquemas (ver [ADR-003](ADR-003-aislamiento-esquemas-m1-m2.md)).

## Decisión

F2 (Anulación de pedidos) se mantiene como parte de **M1 — Ventas**, en el mismo esquema (`ventas`) y microservicio que F1. Los documentos de arquitectura C4 (niveles 1, 2 y 3) se corrigen para reflejar esta ubicación, en vez de modificar F1/F2, el modelo de datos o las especificaciones ya existentes.

## Consecuencias

**Positivas:**
- F2 reutiliza directamente el motor de transición de estados y el historial de F1, sin necesidad de llamadas inter-servicio para una operación que de todos modos termina escribiendo en las tablas de M1.
- El modelo de datos no requiere mover la tabla `anulacion` de esquema ni introducir una relación cruzada `ventas`/`postventa` para una operación que es, en esencia, parte del ciclo de vida del pedido.
- Evita que M2 necesite escribir en tablas de M1, lo cual habría violado el aislamiento de esquemas (RNF-07).

**Negativas / trade-offs:**
- M1 concentra tanto el ciclo de vida "feliz" del pedido (F1) como sus excepciones tempranas (F2), haciéndolo algo más grande que si F2 se hubiera separado; se acepta porque ambas comparten el mismo dueño del estado del pedido.

## Revisión futura

Si en algún momento F2 necesita lógica de negocio sustancialmente distinta de F1 (por ejemplo, reglas de aprobación mucho más complejas), podría evaluarse extraerla a su propio microservicio — siempre que quien ejecute la transición final del pedido siga siendo M1, nunca M2.

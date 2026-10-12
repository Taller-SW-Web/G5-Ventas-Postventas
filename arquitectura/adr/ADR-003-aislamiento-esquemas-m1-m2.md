# ADR-003: Aislamiento estricto de esquemas entre M1 y M2 (Database-per-Service)

**Fecha:** 2026-10-09
**Estado:** Aceptado
**Decisor:** Luis Arroyo (Software Architect)
**Alcance:** RNF-07, [diseno/diagramas/bd/diagrama-fisico.md](../../diseno/diagramas/bd/diagrama-fisico.md), [infra/bd/base-de-datos-ventas-postventa.md](../../infra/bd/base-de-datos-ventas-postventa.md)

---

## Contexto

El módulo D está compuesto por dos microservicios independientes, M1 (Ventas, esquema `ventas`) y M2 (Postventa, esquema `postventa`), desplegados ambos en el mismo proyecto de Supabase/PostgreSQL por razones prácticas del curso (un único proyecto con dos esquemas aislados, ver `arquitectura/c4-nivel-2-contenedores-ventas-postventa.md`, sección 8). Esto plantea el riesgo de que, por conveniencia, se termine haciendo JOINs directos o claves foráneas cruzadas entre ambos esquemas simplemente porque conviven en la misma base de datos física.

RNF-07 (Aislamiento) exige explícitamente que `M1_VENTAS` y `M2_POSTVENTA` "no comparten tablas, esquemas ni llaves foráneas físicas" y que "M2 referencia al `idPedido` de M1 exclusivamente por API REST, nunca por consulta directa a la base de datos". El modelo físico ([diagrama-fisico.md](../../diseno/diagramas/bd/diagrama-fisico.md)) y la implementación real en Supabase ([base-de-datos-ventas-postventa.md](../../infra/bd/base-de-datos-ventas-postventa.md)) ya siguen esta regla: las columnas que referencian al otro esquema (`devolucion.id_pedido`, `reclamo.id_pedido`, `calificacion.id_pedido`, `reembolso.id_origen`) se guardan como columnas simples sin clave foránea, nunca como FK real.

## Decisión

M1 (`ventas`) y M2 (`postventa`) no comparten tablas, esquemas, triggers ni claves foráneas físicas, aunque convivan en el mismo proyecto de base de datos. Toda referencia de un esquema al otro se guarda como un identificador simple (sin FK) y se valida mediante la API REST del microservicio dueño del dato, nunca por acceso directo o JOIN cruzado.

## Consecuencias

**Positivas:**
- Cada microservicio puede evolucionar su esquema, migrar o incluso separarse a un proyecto de base de datos distinto sin romper al otro.
- Fuerza a que toda regla de negocio que cruce el límite M1/M2 (por ejemplo, "solo se puede devolver un pedido `ENTREGADO`") se valide explícitamente vía API, dejando constancia de esa validación en vez de depender implícitamente de un JOIN.

**Negativas / trade-offs:**
- No se pueden hacer consultas SQL de un solo esquema para reportes que crucen pedidos y postventa (por ejemplo, "pedidos con devolución"); hay que combinarlos a nivel de aplicación o con tablas agregadas alimentadas por eventos (ver `agregado_ventas` para el caso del dashboard).
- Mayor latencia relativa para operaciones que necesitan un dato del otro esquema, al depender de una llamada API en vez de una consulta local.

## Revisión futura

Si el curso requiere separar M1 y M2 en proyectos de base de datos físicamente distintos (no solo esquemas distintos dentro del mismo proyecto), esta decisión ya cubre ese escenario sin cambios adicionales, porque nunca se asumió clave foránea física entre ambos esquemas.

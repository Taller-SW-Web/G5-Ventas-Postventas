# ADR-002: UI Kit del frontend: Mantine UI, no Tailwind CSS

**Fecha:** 2026-10-09
**Estado:** Aceptado
**Decisor:** Luis Alejandro (F4 — Reembolsos y extornos, Developer Frontend)
**Alcance:** [specs/stack-frontend.md](../../specs/stack-frontend.md), `diseno/wireframes/`, `diseno/mockups/`, `arquitectura/c4-nivel-2`

---

## Contexto

[specs/stack-frontend.md](../../specs/stack-frontend.md) define en detalle el stack de frontend del portal del Gestor: React + TypeScript + Vite + **Mantine UI**, con una relación explícita *Figma → Theme de Mantine → Componentes reutilizables → Pantallas del módulo* (sección 2.1). README.md y CONTRIBUTING.md citan Mantine UI de la misma forma.

Sin embargo, una versión anterior de `arquitectura/c4-nivel-2-contenedores-ventas-postventa.md` (documento marcado como "Propuesta para discusión, no aprobada") describía la Consola del Gestor como "React + Vite + Tailwind CSS", contradiciendo la especificación de frontend ya detallada.

Mantine UI ya tiene definida una integración completa con el sistema de diseño de Figma (paleta, tipografía, espaciado, radios de borde — ver `diseno/guia_ux_ui/`) a través de su sistema de theming, y los wireframes (W01–W08) y mockups fueron pensados asumiendo los componentes de Mantine (tablas con paginación, modales de confirmación, badges de estado, etc. — ver stack-frontend.md, sección 3.1).

## Decisión

El UI Kit del frontend del portal del Gestor es **Mantine UI**, no Tailwind CSS. Se corrige `arquitectura/c4-nivel-2-contenedores-ventas-postventa.md` para reflejar esto, en vez de reescribir specs/stack-frontend.md y los wireframes/mockups ya elaborados sobre la base de Mantine.

## Consecuencias

**Positivas:**
- No hay que rehacer specs/stack-frontend.md (documento extenso y ya detallado) ni los wireframes W01–W08, que ya asumen componentes de Mantine (tablas, modales, badges, loaders).
- Mantine ya resuelve de fábrica gran parte de los "Elementos base" exigidos en stack-frontend.md (botones, inputs, selectores, tablas con paginación, modales, alertas, skeletons), reduciendo el trabajo de construir componentes desde cero.

**Negativas / trade-offs:**
- Mantine impone su propio sistema de theming (CSS-in-JS / CSS modules), menos flexible para personalización profunda que las utility classes de Tailwind; se acepta porque la guía UX/UI ya fue pensada para reflejarse en un theme de Mantine, no en clases utilitarias.

## Revisión futura

Si el equipo de diseño UX/UI decide migrar a un sistema basado en utility-first CSS en una fase posterior, este ADR debe revisarse junto con specs/stack-frontend.md completo, no solo el C4.

# Superficies, alternancia y motivo gráfico

El sitio alterna entre dos fondos base, `color/surface/cloud` y `color/surface/ink`, entre secciones, en lugar de usar un único fondo blanco en toda la página. Esta alternancia crea ritmo visual y evita que el color de acción principal (naranja) sea el único elemento con contraste en la pantalla.

## Reglas de alternancia

- Las pantallas **transaccionales** (catálogo, carrito, checkout, formularios) usan `cloud` como fondo por defecto, priorizando la legibilidad y el foco en la tarea.
- Las secciones de **mayor impacto emocional** (hero de home, banners de campaña, footer) pueden usar `ink`, siempre con texto en `color/text/inverse`.
- No se alternan fondos dentro de un mismo componente o tarjeta.

## Motivo gráfico: líneas de velocidad

Se aprueba el uso de **líneas diagonales delgadas** (ángulo aproximado de 110°–120°) en tonos de `color/action/primary`, `color/accent/volt` y `color/accent/signal` como recurso decorativo de fondo en secciones hero o divisores entre secciones.

Este recurso es **puramente decorativo** y no debe usarse para comunicar estado, jerarquía o información. Los estados siguen comunicándose con los colores semánticos definidos en la [paleta de colores](paleta-colores.md).

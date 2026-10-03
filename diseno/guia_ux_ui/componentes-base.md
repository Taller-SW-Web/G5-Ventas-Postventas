# Componentes reutilizables: base y reglas comunes

## Base de implementación

El UI Kit utiliza **Mantine 9.6.2** sobre **React y TypeScript**. Mantine es la biblioteca base para los componentes visuales y permite centralizar colores, tipografía, espaciado, radios, breakpoints y configuración global mediante `MantineProvider` y el objeto de tema.

La configuración principal del sistema de diseño se almacena en:

```
src/theme/theme.ts
```

- Los componentes de Figma deben representar las mismas propiedades, tamaños, variantes y estados disponibles en la implementación.
- Siempre que Mantine tenga un componente que cubra la necesidad, se usa antes de crear uno personalizado.
- Los componentes personalizados se crean únicamente cuando:
  - exista un patrón reutilizable específico del proyecto;
  - el comportamiento requerido no pueda representarse directamente con un componente de Mantine;
  - sea necesario combinar varios componentes básicos para formar un componente propio del marketplace.
- La personalización se realiza mediante el sistema de temas y la **Styles API** de Mantine, evitando modificar la implementación interna de la biblioteca.

### Configuración inicial

| Parámetro | Valor |
|---|---|
| Mantine | 9.6.2 |
| Tema | Claro |
| Color de acción principal | `orange.7` — `#F76707` |
| Hover de acción principal | `#C2410C` |
| Acento de alto impacto | `volt` — `#C3E504` |
| Acento secundario | `signal` — `#4361EE` |
| Superficie oscura principal | `ink` — `#1B1812` |
| Superficie clara principal | `cloud` — `#F7F5F0` |
| Tipografía de cuerpo | Inter |
| Tipografía de títulos H1, H2 y H3 | Oswald |
| Radio predeterminado | 8 px |
| Contraste automático de Mantine | Habilitado |

Los colores semánticos de éxito, alerta, error e información siguen usando las familias `green`, `yellow`, `red` y `blue` de Mantine. No se sustituyen por los acentos de marca `volt` o `signal`.

> **Pendiente:** enlace directo al archivo `src/theme/theme.ts` en GitHub.

## Reglas comunes

Todos los componentes reutilizables deben cumplir lo siguiente:

- Cada componente de Figma se crea como **componente principal** y usa *Component Properties* para representar variantes y estados.
- Las propiedades de Figma usan nombres equivalentes a las del código siempre que sea posible.
- Se usan exclusivamente los tokens de Foundations para colores, tipografía, espaciado y radios. No se usan colores, radios o espacios arbitrarios dentro de un componente.
- `color/action/primary` se usa para las acciones principales.
- `color/accent/volt` se usa para promociones, disponibilidad, destacados y momentos de celebración visual.
- `color/accent/signal` se usa para el indicador de foco de teclado, acciones de confirmación o pago diferenciadas y elementos nuevos.
- Los colores `success`, `warning`, `error` e `info` se reservan para estados semánticos y no se sustituyen por colores de marca.
- Todos los componentes interactivos incluyen los estados aplicables: `default`, `hover`, `focus`, `disabled`, `loading`, `selected`, `open` y `error`. No todos aplican a todos los componentes (por ejemplo, `error` corresponde principalmente a campos de formulario y `loading` a componentes que esperan una operación).
- Los componentes conservan un **indicador de foco visible** al usarse con teclado. El indicador global usa `color/accent/signal`.
- Los estados de error, alerta o éxito no dependen únicamente del color.
- Los controles sin texto visible tienen un nombre accesible mediante `aria-label` u otro mecanismo apropiado.
- El estado `loading` impide acciones repetidas cuando la operación no puede ejecutarse varias veces.
- Los componentes documentan su comportamiento responsive.
- No se duplica un componente existente solo para cambiar una propiedad visual.
- Los cambios que afectan a varios módulos se realizan desde el tema o desde el componente reutilizable correspondiente.

## Nomenclatura de propiedades

Se usan preferentemente términos equivalentes a Mantine:

`variant`, `size`, `color`, `radius`, `disabled`, `loading`, `error`, `checked`, `searchable`, `clearable`.

Ejemplo para un botón:

```
Button
  variant: filled | outline | subtle
  intent:  primary | confirmation | destructive
  size:    sm | md | lg
  state:   default | hover | focus | disabled | loading
  icon:    none | left | right
```

La propiedad `intent` representa la función del botón y se traduce a los siguientes colores:

- `primary` → `color/action/primary`
- `confirmation` → `color/accent/signal`
- `destructive` → `color/error/default`

El objetivo es que, al revisar un componente en Figma, se pueda identificar directamente cómo debe construirse en React.

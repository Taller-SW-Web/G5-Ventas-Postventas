# Paleta de colores

La paleta del Marketplace Multicanal se organiza en **colores de acción, acentos de marca, superficies, texto y colores semánticos de estado**. Se basa en la paleta de Mantine 9.6.2 y en colores personalizados del proyecto, para mantener correspondencia directa entre el sistema de diseño en Figma y la implementación en React.

- **Naranja:** representa la acción principal de la interfaz (llamadas a la acción, botones principales y elementos interactivos prioritarios).
- **Volt** (verde lima): acento de alto impacto para promociones, disponibilidad, destacados y momentos de celebración visual.
- **Signal** (azul índigo): acento secundario para foco de teclado, confirmación o pago y elementos identificados como nuevos.
- **Ink y cloud:** superficies principales. `cloud` es el fondo claro predeterminado de las pantallas transaccionales; `ink` se usa en secciones de mayor contraste como heroes, banners y footer.
- **Colores semánticos** (éxito, alerta, error e información): mantienen una función independiente de los colores de marca. `volt` y `signal` no los sustituyen cuando se necesita comunicar un estado del sistema.

En Figma, todos los colores se registran como **Variables** con nombres semánticos que describen su función y no solo su apariencia. En desarrollo se utilizan los colores equivalentes del tema de Mantine.

## Tabla de variables

| Variable de Figma | Función | HEX | RGB | Equivalente Mantine |
|---|---|---|---|---|
| `color/action/primary` | Acción principal: CTA, botones, enlaces activos | `#F76707` | 247, 103, 7 | `orange.7` |
| `color/action/primary-hover` | Hover de la acción principal | `#C2410C` | 194, 65, 12 | naranja personalizado |
| `color/action/primary-soft` | Fondo suave de la acción principal sobre fondos claros | `#FCE3D0` | 252, 227, 208 | naranja personalizado |
| `color/accent/volt` | Acento de alto impacto: promociones, disponibilidad, destacados y celebración visual | `#C3E504` | 195, 229, 4 | personalizado `volt` |
| `color/accent/volt-soft` | Fondo suave del acento volt | `#EEF7B0` | 238, 247, 176 | `volt` (tono claro) |
| `color/accent/signal` | Acento secundario: foco de teclado, confirmación o pago, elementos "nuevo" | `#4361EE` | 67, 97, 238 | `indigo.6` (aprox.) |
| `color/accent/signal-soft` | Fondo suave del acento signal | `#E1E6FB` | 225, 230, 251 | `indigo.0` (aprox.) |
| `color/surface/ink` | Fondo oscuro para secciones de alto contraste (hero, headers) | `#1B1812` | 27, 24, 18 | personalizado `ink` |
| `color/surface/ink-soft` | Superficie elevada sobre ink (cards e inputs en modo oscuro) | `#26221A` | 38, 34, 26 | `ink` (tono claro) |
| `color/surface/cloud` | Fondo claro principal de páginas | `#F7F5F0` | 247, 245, 240 | personalizado `cloud` |
| `color/surface/cloud-subtle` | Fondo secundario sobre cloud | `#EDEAE2` | 237, 234, 226 | `cloud` (tono oscuro) |
| `color/text/primary` | Texto principal sobre fondo claro | `#1B1812` | 27, 24, 18 | — |
| `color/text/inverse` | Texto principal sobre fondo oscuro (ink) | `#F7F5F0` | 247, 245, 240 | — |
| `color/text/secondary` | Texto secundario y descripciones | `#495057` | 73, 80, 87 | `gray.7` |
| `color/text/disabled` | Texto deshabilitado o de baja prioridad | `#868E96` | 134, 142, 150 | `gray.6` |
| `color/border/default` | Bordes sobre fondo claro | `#DEE2E6` | 222, 226, 230 | `gray.3` |
| `color/border/inverse` | Bordes sobre fondo oscuro (ink) | `#3A362C` | 58, 54, 44 | `ink` (tono medio) |
| `color/success/default` | Indicadores de éxito y confirmación | `#2F9E44` | 47, 158, 68 | `green.8` |
| `color/success/background` | Fondo de mensajes de éxito | `#EBFBEE` | 235, 251, 238 | `green.0` |
| `color/warning/default` | Alertas y advertencias | `#F08C00` | 240, 140, 0 | `yellow.8` |
| `color/warning/background` | Fondo de alertas | `#FFF9DB` | 255, 249, 219 | `yellow.0` |
| `color/error/default` | Errores y acciones destructivas | `#E03131` | 224, 49, 49 | `red.8` |
| `color/error/background` | Fondo de mensajes de error | `#FFF5F5` | 255, 245, 245 | `red.0` |
| `color/info/default` | Información y mensajes informativos | `#1971C2` | 25, 113, 194 | `blue.8` |
| `color/info/background` | Fondo de mensajes informativos | `#E7F5FF` | 231, 245, 255 | `blue.0` |

## Uso de los colores

### Acción principal

- `color/action/primary` se utiliza para la acción principal de una pantalla o sección. Ejemplos: *Comprar ahora*, *Guardar cambios*, *Continuar al pago* y *Aplicar filtros*.
- `color/action/primary-hover` se utiliza únicamente cuando el usuario posiciona el cursor sobre una acción principal.
- `color/action/primary-soft` se utiliza como fondo de elementos seleccionados, mensajes informativos o componentes que necesiten comunicar relación con el color principal sin utilizar un fondo intenso.

### Acentos de marca

- `color/accent/volt` se reserva para elementos de alto impacto visual: promociones, indicadores de disponibilidad y momentos donde se busca energía o celebración. **No sustituye** a `color/action/primary` como color de interacción principal.
- `color/accent/signal` se utiliza para:
  - el indicador de foco de teclado en todo el sitio,
  - la acción de continuar al pago o confirmación cuando se quiera diferenciarla de la acción principal,
  - los elementos marcados como "nuevo".

  Es un color de marca y no un color semántico de estado; no debe confundirse con `color/info/default`.

### Color en el logotipo

- El logo principal utiliza `surface/ink`.
- El logo Volt utiliza `accent/volt`.
- El logo Signal utiliza `accent/signal`.

### Superficies

`color/surface/ink` y `color/surface/cloud` son los dos fondos base del sistema. Ver [superficies y alternancia](superficies-y-motivo-grafico.md).

### Neutros

- `color/text/primary` es el color predeterminado del texto.
- `color/text/secondary` se utiliza para información complementaria.
- `color/surface/cloud` se utiliza como fondo principal.
- `color/surface/cloud-subtle` permite separar secciones sin introducir un nuevo color.
- `color/border/default` se utiliza en inputs, tarjetas y divisores.

### Colores semánticos

Los colores de éxito, alerta, error e información tienen significado semántico y **no deben utilizarse con fines decorativos**. Un estado nunca se comunicará únicamente mediante color: deberá acompañarse de texto y, cuando corresponda, iconografía.

## Correspondencia con Mantine 9.6.2

Mantine organiza cada familia de colores en diez tonalidades numeradas de 0 a 9, desde las más claras hasta las más oscuras. `primaryColor` establece la familia principal y `primaryShade` determina qué tonalidad utiliza normalmente el componente principal.

Para este proyecto, la familia principal es `orange` y la tonalidad principal es `orange.7`, equivalente a `color/action/primary`. Los colores `volt`, `signal`, `ink` y `cloud` se registran como colores personalizados del tema.

```ts
const theme = createTheme({
  primaryColor: 'orange',
  primaryShade: 7,
  autoContrast: true,
  colors: {
    // Reemplazar los valores de ejemplo por las
    // 10 tonalidades definitivas del proyecto.
    volt:   ['#FBFEE0', '...', '#C3E504', '...', '#5C6B00'],
    signal: ['#EEF0FE', '...', '#4361EE', '...', '#1B2A99'],
    ink:    ['#F5F4F2', '...', '#26221A', '...', '#1B1812'],
    cloud:  ['#FFFFFF', '...', '#EDEAE2', '...', '#D6D2C4'],
  },
});
```

Ejemplos de uso:

```tsx
<Button>Comprar ahora</Button>                    {/* naranja principal */}
<Button color="signal">Continuar al pago</Button> {/* confirmación o pago */}
<Button color="red">Eliminar</Button>             {/* acción destructiva */}
<Badge color="green">Pago aprobado</Badge>
<Alert color="yellow">Quedan pocas unidades</Alert>
```

### Equivalencias Figma ↔ React/Mantine

| Figma | React / Mantine |
|---|---|
| `color/action/primary` | `orange.7` |
| `color/action/primary-hover` | Naranja personalizado `#C2410C` |
| `color/action/primary-soft` | Naranja personalizado `#FCE3D0` |
| `color/accent/volt` | `volt` personalizado |
| `color/accent/signal` | `signal` personalizado |
| `color/surface/ink` | `ink` personalizado |
| `color/surface/cloud` | `cloud` personalizado |
| `color/success/default` | `green.8` |
| `color/warning/default` | `yellow.8` |
| `color/error/default` | `red.8` |
| `color/info/default` | `blue.8` |
| `color/border/default` | `gray.3` |

De esta forma, en Figma y en React se habla del mismo sistema.

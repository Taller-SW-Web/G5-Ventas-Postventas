# Tipografía

La tipografía del Marketplace Multicanal utiliza una jerarquía común para títulos, subtítulos, cuerpo, etiquetas y textos auxiliares. El sistema usa **dos familias con roles distintos**:

- **Oswald** para títulos (H1, H2, H3) y elementos de alto impacto. Es una tipografía condensada que evoca marcadores deportivos y tipografía de camiseta, y refuerza el carácter de la marca en los títulos.
- **Inter** para todo el texto de cuerpo, formularios y contenido general, por su legibilidad en interfaces digitales y su variedad de pesos.

Esta combinación es una decisión deliberada de marca y **no debe extenderse**: labels de formulario, texto de cuerpo y etiquetas auxiliares siempre usan Inter, nunca Oswald.

## Familias en desarrollo

Como respaldo se utilizan las fuentes del sistema operativo, para evitar problemas de visualización si la fuente principal no carga.

```css
/* Cuerpo */
font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;

/* Títulos H1, H2 y H3 */
font-family: Oswald, "Segoe UI", sans-serif;
```

Ambas fuentes se cargan desde Google Fonts con este enlace, agregado en el `<head>` del documento:

```
https://fonts.googleapis.com/css2?family=Oswald:wght@500;700&family=Inter:wght@400;500;600;700&display=swap
```

## Tratamiento de los títulos

Los títulos en Oswald se escriben en **mayúscula** y en **peso 700**. Este tratamiento es exclusivo de H1, H2 y H3; no debe aplicarse a subtítulos, labels, badges de texto largo ni contenido de cuerpo.

## Pesos permitidos

| Peso | Nombre | Uso |
|---|---|---|
| 400 | Regular | Texto de cuerpo, descripciones y contenido general |
| 500 | Medium | Elementos que requieren énfasis moderado |
| 600 | SemiBold | Etiquetas, botones y subtítulos |
| 700 | Bold | Títulos y encabezados |

No se utilizan otros pesos salvo que se incorpore una nueva necesidad al sistema de diseño.

## Escala tipográfica

| Estilo de Figma | Tamaño | Peso | Interlineado | Espaciado | Uso |
|---|---|---|---|---|---|
| `Typography/Heading/H1` | 32 px | 700 | 40 px | 0 | Título principal de página |
| `Typography/Heading/H2` | 28 px | 700 | 36 px | 0 | Secciones principales |
| `Typography/Heading/H3` | 24 px | 700 | 32 px | 0 | Subsecciones |
| `Typography/Heading/H4` | 20 px | 700 | 28 px | 0 | Tarjetas, modales y bloques |
| `Typography/Subtitle` | 18 px | 600 | 26 px | 0 | Subtítulos y encabezados secundarios |
| `Typography/Body` | 16 px | 400 | 24 px | 0 | Texto principal de la interfaz |
| `Typography/Body/Small` | 14 px | 400 | 20 px | 0 | Información secundaria y contenido compacto |
| `Typography/Label` | 14 px | 600 | 20 px | 0 | Labels de formularios y controles |
| `Typography/Auxiliary` | 12 px | 400 | 16 px | 0 | Ayuda, metadatos y texto auxiliar |

## Reglas de uso

- La jerarquía tipográfica debe conservarse entre los módulos. No se utiliza un tamaño únicamente por preferencia visual; cada estilo corresponde al propósito definido.
- Los títulos de página utilizan preferentemente **H1**. Las secciones internas usan **H2** o **H3**. **H4** puede usarse para títulos de tarjetas, modales o bloques pequeños.
- El texto de cuerpo usa **16 px** como tamaño predeterminado.
- Los textos de **14 px** se reservan para información secundaria y componentes de mayor densidad.
- El tamaño de **12 px** se utiliza únicamente para información auxiliar, no para contenido principal ni acciones.

## Implementación en Mantine 9.6.2

La tipografía se configura mediante el objeto global del tema (`fontFamily`, `headings` y `fontSizes`).

```ts
import { createTheme } from '@mantine/core';

export const theme = createTheme({
  fontFamily:
    'Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  headings: {
    fontFamily: 'Oswald, "Segoe UI", sans-serif',
    fontWeight: '700',
    textTransform: 'uppercase',
    sizes: {
      h1: { fontSize: '2rem',    lineHeight: '2.5rem'  },
      h2: { fontSize: '1.75rem', lineHeight: '2.25rem' },
      h3: { fontSize: '1.5rem',  lineHeight: '2rem'    },
      h4: { fontSize: '1.25rem', lineHeight: '1.75rem' },
    },
  },
  fontSizes: {
    xs: '0.75rem',
    sm: '0.875rem',
    md: '1rem',
    lg: '1.125rem',
    xl: '1.25rem',
  },
});
```

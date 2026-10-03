# Espaciado y grilla

El Marketplace Multicanal utiliza una escala de espaciado **basada en 4 px**. Los márgenes, paddings y separaciones entre elementos se construyen con los valores definidos por el sistema de diseño, para evitar valores arbitrarios entre componentes y mantener consistencia entre Figma y la implementación.

## Escala de espaciado

| Token | Valor | Uso recomendado |
|---|---|---|
| `spacing/xs` | 4 px | Separación mínima entre elementos relacionados |
| `spacing/sm` | 8 px | Separación entre icono y texto, controles relacionados |
| `spacing/md` | 16 px | Padding y separación estándar |
| `spacing/lg` | 24 px | Separación entre grupos o bloques |
| `spacing/xl` | 32 px | Separación entre secciones |

- El valor predeterminado para la separación interna de componentes es **16 px** cuando no existe una necesidad específica.
- No se introducen valores arbitrarios como 7 px, 13 px, 19 px o 27 px. Si aparece una necesidad que la escala no cubre, primero se revisa si corresponde ampliar el sistema de tokens.

### Implementación en Mantine

Se configura mediante `theme.spacing`, que controla paddings, márgenes y otras propiedades de espaciado.

```ts
const theme = createTheme({
  spacing: {
    xs: '0.25rem', // 4 px
    sm: '0.5rem',  // 8 px
    md: '1rem',    // 16 px
    lg: '1.5rem',  // 24 px
    xl: '2rem',    // 32 px
  },
});
```

## Grilla responsive

El layout usa una **grilla de 12 columnas** para escritorio, tablet y móvil. Los componentes ocupan diferente cantidad de columnas según el ancho disponible. Los breakpoints se basan en los valores predeterminados de Mantine 9.6.2, que usa `em` y equivale a 576, 768, 992, 1200 y 1408 px.

| Breakpoint | Ancho de referencia | Columnas | Margen lateral | Gutter | Ancho máximo |
|---|---|---|---|---|---|
| Base | < 576 px | 12 | 16 px | 16 px | Fluido |
| `xs` | ≥ 576 px | 12 | 20 px | 16 px | 540 px |
| `sm` | ≥ 768 px | 12 | 24 px | 20 px | 720 px |
| `md` | ≥ 992 px | 12 | 32 px | 24 px | 960 px |
| `lg` | ≥ 1200 px | 12 | 32 px | 24 px | 1140 px |
| `xl` | ≥ 1408 px | 12 | 40 px | 24 px | 1320 px |

La cantidad de columnas permanece en 12 en todos los tamaños; lo que cambia es cuánto ocupa cada elemento. Por ejemplo, una **tarjeta de producto** puede ocupar:

- **Móvil:** 12 columnas → 1 tarjeta por fila.
- **Tablet:** 6 columnas → 2 tarjetas por fila.
- **Desktop:** 3 columnas → 4 tarjetas por fila.

```tsx
<Grid gutter={{ base: 16, md: 24 }}>
  <Grid.Col span={{ base: 12, sm: 6, lg: 3 }}>Producto</Grid.Col>
  <Grid.Col span={{ base: 12, sm: 6, lg: 3 }}>Producto</Grid.Col>
</Grid>
```

Los diseños en Figma deben mostrar al menos una **versión móvil y una de escritorio** de los componentes o patrones cuyo comportamiento cambie de forma relevante.

# Radios de borde

Los radios de borde se definen mediante tokens compartidos para evitar valores diferentes entre botones, campos, tarjetas, badges y modales.

## Tokens

| Token | Valor | Uso |
|---|---|---|
| `radius/xs` | 4 px | Elementos pequeños y controles compactos |
| `radius/sm` | 8 px | Botones, inputs, dropdowns y controles |
| `radius/md` | 12 px | Tarjetas y contenedores |
| `radius/lg` | 16 px | Modales y superficies destacadas |
| `radius/full` | 999 px | Badges, tags y elementos tipo pill |

## Reglas

- El radio predeterminado del sistema es **8 px** (`radius/sm`).
- Botones, inputs, checkboxes personalizados y dropdowns usan generalmente `radius/sm`.
- Las tarjetas usan `radius/md`.
- Los modales o paneles destacados pueden usar `radius/lg`.
- Los badges, tags y otros componentes completamente redondeados usan `radius/full`.
- No se utilizan valores intermedios arbitrarios como 5 px, 10 px o 14 px.

## Implementación en Mantine

Mantine permite definir estos tokens mediante `theme.radius`; los componentes que exponen la propiedad `radius` usan los valores del tema.

```ts
const theme = createTheme({
  radius: {
    xs: '0.25rem', // 4 px
    sm: '0.5rem',  // 8 px
    md: '0.75rem', // 12 px
    lg: '1rem',    // 16 px
    xl: '999px',
  },
  defaultRadius: 'sm',
});
```

```tsx
<Button radius="sm">Comprar ahora</Button>
<Card radius="md">...</Card>
<Badge radius="xl">Disponible</Badge>
```

En Figma se usan los mismos nombres conceptuales y valores para conservar la correspondencia con el desarrollo.

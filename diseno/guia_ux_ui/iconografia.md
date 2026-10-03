# Iconografía

El Marketplace Multicanal utiliza **Tabler Icons** como set único de iconografía. Tabler usa un lienzo base de 24 × 24 px y un trazo estándar de 2 px, lo que mantiene consistencia visual entre los iconos.

En desarrollo se utiliza el paquete:

```
@tabler/icons-react
```

Los nombres usados en Figma deben corresponder, siempre que sea posible, al nombre del icono utilizado en `@tabler/icons-react`.

## Especificaciones

- Lienzo oficial: **24 × 24 px**.
- Grosor de trazo estándar: **2 px**.
- Separación entre un icono y su texto: **8 px**.

## Tamaños aprobados

| Tamaño | Uso |
|---|---|
| 16 × 16 px | Controles pequeños, badges y elementos compactos |
| 20 × 20 px | Botones, inputs y controles estándar |
| 24 × 24 px | Iconos independientes, navegación y acciones destacadas |

El tamaño estándar dentro de botones e inputs es **20 × 20 px**.

## Color

Los iconos deben usar preferentemente `currentColor`, de forma que hereden el color del elemento que los contiene (compatible con los SVG de Tabler). No se usan colores diferentes para iconos de un mismo control, salvo que exista un significado semántico definido.

## Iconos decorativos

Los iconos que solo acompañan visualmente un texto no reciben foco ni se anuncian de forma independiente en tecnologías de asistencia.

```tsx
<Button leftSection={<IconShoppingCart size={20} />}>
  Agregar al carrito
</Button>
```

## Iconos interactivos

Cuando un icono representa por sí solo una acción, debe usarse dentro de un componente interactivo y tener un **nombre accesible**.

```tsx
<ActionIcon aria-label="Agregar a favoritos" variant="subtle">
  <IconHeart size={20} />
</ActionIcon>
```

No se usan iconos sueltos con eventos `onClick` si pueden representarse mediante `Button`, `ActionIcon` u otro control accesible.

# Combinaciones permitidas de fondo y texto

Para garantizar legibilidad, las combinaciones de texto y fondo utilizadas por el sistema deben cumplir como mínimo el nivel **AA de WCAG** para texto normal.

| Fondo | Texto | Uso recomendado | Contraste aproximado |
|---|---|---|---|
| `#F76707` action/primary | `#1B1812` ink | Botón principal y CTA | 5.82:1 |
| `#C2410C` action/primary-hover | `#F7F5F0` cloud | Hover de botón principal | 4.75:1 |
| `#1B1812` ink | `#F7F5F0` cloud | Texto sobre secciones oscuras | 16.25:1 |
| `#F7F5F0` cloud | `#1B1812` ink | Texto sobre secciones claras | 16.25:1 |
| `#EDEAE2` cloud-subtle | `#1B1812` ink | Superficies secundarias | 14.73:1 |
| `#C3E504` volt | `#1B1812` ink | Promociones, disponibilidad y destacados | 12.25:1 |
| `#4361EE` signal | `#FFFFFF` blanco | Confirmación, pago y elementos nuevos | 5.02:1 |
| `#EBFBEE` success/background | `#1B1812` ink | Mensajes de éxito | 16.50:1 |
| `#FFF9DB` warning/background | `#1B1812` ink | Mensajes de alerta | 16.72:1 |
| `#FFF5F5` error/background | `#1B1812` ink | Mensajes de error | 16.55:1 |
| `#E7F5FF` info/background | `#1B1812` ink | Mensajes informativos | 15.94:1 |

## Reglas derivadas

- El **botón principal no utiliza texto blanco** sobre `color/action/primary` para etiquetas de tamaño normal, ya que la combinación no alcanza el contraste AA requerido. El texto predeterminado sobre el naranja principal es `color/text/primary` (ink).
- Cuando el botón principal cambia a `color/action/primary-hover`, se utiliza `color/text/inverse`, porque el fondo es más oscuro.
- Los elementos con fondo `color/accent/volt` utilizan **siempre** texto `color/text/primary`. No se utiliza texto blanco sobre volt.
- Los elementos con fondo `color/accent/signal` pueden utilizar texto blanco, porque la combinación cumple el contraste requerido.
- Los fondos semánticos de éxito, alerta, error e información utilizan preferentemente `color/text/primary` para el contenido y el color semántico correspondiente para iconos o indicadores.
- Los estados **nunca** se comunican únicamente mediante color: deben acompañarse de texto y, cuando corresponda, iconografía.

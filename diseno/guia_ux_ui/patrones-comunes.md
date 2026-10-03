# Organismos y patrones comunes

> **Estado:** documento en construcción. Los patrones están descritos a nivel de principios; los detalles definitivos se completarán cuando las pantallas de cada módulo estén definidas.

## Tarjeta de producto

Reúne la información necesaria para reconocer un artículo, comparar opciones y continuar hacia el detalle o la compra. Su estructura se mantiene consistente en catálogo, resultados de búsqueda y recomendaciones.

- Imagen del producto con texto alternativo definido en implementación.
- Nombre del producto y datos secundarios necesarios para diferenciarlo.
- Precio y promoción cuando corresponda.
- Disponibilidad o estado del stock.
- Acción principal y acciones secundarias autorizadas.

**Por definir:** información definitiva de la tarjeta, proporción de imagen, número máximo de líneas, variantes, estados y comportamiento responsive.

## Barra de navegación

Permite identificar la marca, acceder a las áreas principales y localizar productos o funciones frecuentes. Debe conservar la prioridad de las acciones cuando cambia entre escritorio y móvil.

**Por definir:** elementos de la navbar, su orden, comportamiento sticky si aplica, breakpoint de cambio y versión móvil. Estados de navegación activa, búsqueda abierta, menú abierto, carga y error.

## Filtros de catálogo

Permiten reducir el catálogo y deben mostrar con claridad qué opciones están activas. El usuario puede aplicar, limpiar o retirar filtros sin perder el contexto de los resultados.

**Por definir:** filtros reales del catálogo (orden, tipo de control, valores disponibles, combinación entre filtros, comportamiento en web y móvil) y cómo se muestran la cantidad de resultados, los filtros activos, la acción *Limpiar* y el estado sin resultados.

## Modales

Se reservan para acciones que requieren atención antes de continuar. Incluyen título, contenido, acción principal, alternativa o cancelación y un método claro para cerrarlos cuando la tarea lo permita.

**Por definir:** tamaños, tipos de modal, reglas de cierre, comportamiento en móvil, casos del proyecto que realmente necesitan este patrón y variantes (confirmación, información, error y contenido con formulario).

## Pantallas de carga y skeletons

Los skeletons representan la estructura que aparecerá cuando termine la carga. Deben aproximarse al tamaño del contenido final para reducir movimientos inesperados y mantener visible el contexto de la pantalla.

**Por definir:** skeletons para tarjeta de producto, listado, detalle, filtros y otras pantallas asíncronas; cuándo usar skeleton, spinner o mensaje de progreso; y cómo se presentan los estados de carga prolongada y error.

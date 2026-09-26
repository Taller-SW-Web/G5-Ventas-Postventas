# W04 — Anulaciones

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W04 — Anulaciones  
**Página de referencia en Figma:** Page 4  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F2 — Anulación de pedidos y F1 — Ciclo de vida del pedido

---

## 1. Contexto del wireframe

W04 representa la bandeja administrativa utilizada para revisar y resolver solicitudes de anulación dentro del **Módulo D — Ventas y Postventa**

La pantalla concentra los pedidos que pueden requerir una decisión del Gestor, mostrando el estado actual, motivo de la solicitud, condición de autorización y resultado esperado antes de ejecutar la operación

F2 valida si la anulación corresponde según el estado del pedido, mientras que F1 es responsable de aplicar la transición real a `ANULADO` y registrar el cambio en el historial

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda identificar rápidamente qué solicitudes necesitan revisión, conocer el motivo de cada anulación y tomar una decisión cuando la regla de negocio exige autorización

Además, permite anticipar los efectos que tendrá la anulación sobre el estado del pedido, stock, despacho y reembolso antes de confirmar la acción

---

## 3. Actor y alcance de acceso

El usuario principal de W04 es el **Gestor o Administrador de ventas**

No todas las anulaciones necesitan intervención manual. De acuerdo con F2, los pedidos `CREADO` o `PAGADO` pueden tener anulaciones directas según el actor y motivo, mientras que una solicitud sobre un pedido `EN PREPARACIÓN` requiere autorización expresa del Gestor

Los pedidos `DESPACHADO` o `ENTREGADO` no deben anularse desde este flujo y deben continuar por los procesos de postventa correspondientes

---

## 4. Estructura general de la interfaz

La pantalla se organiza en cinco zonas principales:

| Zona | Función |
|---|---|
| **Menú lateral** | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Facilitan la búsqueda por pedido, estado y canal |
| **Solicitudes de anulación** | Presentan las solicitudes disponibles para revisión |
| **Detalle de solicitud** | Resume la información del caso seleccionado |
| **Resultado y acciones** | Muestra los efectos previstos y permite aprobar, rechazar o volver al pedido |

La estructura mantiene la lista de solicitudes separada del análisis individual para evitar sobrecargar la tabla con demasiada información

---

## 5. Filtros y bandeja de solicitudes

El wireframe incorpora los filtros:

- **Buscar:** permite localizar por código de pedido o cliente
- **Estado:** permite revisar solicitudes según su situación actual
- **Canal:** diferencia Marketplace, Chatbot, Retail o todos los canales

Las acciones **Aplicar filtros** y **Limpiar** controlan la consulta

La tabla principal muestra:

| Campo | Información mostrada |
|---|---|
| **Código** | Identificador del pedido |
| **Fecha** | Fecha asociada a la solicitud |
| **Cliente** | Cliente y referencia relacionada |
| **Estado actual** | Estado del pedido antes de la anulación |
| **Motivo** | Razón indicada para cancelar el pedido |
| **Autorización** | Indica si requiere decisión del Gestor |
| **Acción** | Permite revisar el caso seleccionado |

El listado incluye ordenamiento por fecha y paginación

### Detalle visual: filtros y bandeja de solicitudes

---

## 6. Detalle de la solicitud

El panel lateral permite revisar el caso sin abandonar la bandeja

En el wireframe se muestran datos como:

- Pedido
- Estado actual
- Cliente
- Canal
- Motivo
- Solicitante
- Fecha
- Condición de autorización

Esta información permite diferenciar solicitudes directas de aquellas que requieren intervención del Gestor

En el ejemplo seleccionado, el pedido se encuentra en estado `PAGADO` y la autorización figura como **No requerida**, lo que representa un caso cuya anulación puede ejecutarse directamente según las reglas de F2

---

## 7. Resultado esperado

Antes de ejecutar una anulación, la pantalla presenta los efectos previstos sobre otros componentes del sistema

| Elemento | Resultado representado |
|---|---|
| **Estado del pedido** | Cambiar a `ANULADO` |
| **Stock** | Reintegrar cuando corresponda |
| **Despacho** | Cancelar si existe una operación programada |
| **Reembolso** | Aplicar según la existencia de un pago confirmado |

F2 coordina estos efectos, pero no modifica directamente las tablas del pedido. La transición a `ANULADO` se solicita a F1

Cuando existe un pago confirmado, F2 origina la solicitud hacia F4 para el reembolso correspondiente

---

## 8. Reglas de autorización

La autorización depende del estado actual del pedido:

| Estado | Comportamiento esperado |
|---|---|
| `CREADO` | Puede anularse directamente según actor y motivo |
| `PAGADO` | Puede anularse directamente y origina reembolso cuando corresponde |
| `EN PREPARACIÓN` | Requiere autorización explícita del Gestor |
| `DESPACHADO` | No anulable desde F2 |
| `ENTREGADO` | No anulable desde F2 y debe gestionarse mediante postventa |

Cuando una solicitud en `EN PREPARACIÓN` es aprobada, el pedido puede pasar a `ANULADO` y se coordinan los efectos derivados

Si el Gestor rechaza la solicitud, el pedido conserva su estado anterior

---

## 9. Acciones disponibles

El panel inferior presenta las acciones principales:

| Acción | Comportamiento |
|---|---|
| **Aprobar anulación** | Confirma la solicitud cuando requiere decisión del Gestor |
| **Rechazar solicitud** | Mantiene el pedido en su estado operativo y registra la decisión |
| **Volver al pedido** | Regresa a W03 para revisar nuevamente el detalle del pedido |

La pantalla debe mostrar las acciones de acuerdo con el caso seleccionado y evitar opciones incompatibles con su estado o tipo de autorización

Si una acción secundaria como la reposición de stock o cancelación del despacho falla, la inconsistencia debe quedar visible para permitir seguimiento o reintento

---

## 10. Relación con funcionalidades y navegación

| Funcionalidad | Relación con W04 |
|---|---|
| **F1 — Ciclo de vida del pedido** | Ejecuta la transición real a `ANULADO` y registra el historial |
| **F2 — Anulación de pedidos** | Valida la solicitud, autorización y coordina los efectos derivados |
| **F3 — Devoluciones y cambios** | Recibe los casos que ya no pueden anularse por estar despachados o entregados |
| **F4 — Reembolsos** | Procesa el reembolso cuando existe pago confirmado |
| **Productos y Ofertas** | Recibe la solicitud de reposición de stock |
| **Despacho y Entrega** | Cancela el envío cuando corresponde |

La navegación principal prevista es:

**W03 Detalle del pedido → W04 Anulaciones → W03 al finalizar**

---

## 11. Consideraciones funcionales y de diseño

W04 debe mostrar únicamente la información necesaria para tomar una decisión sobre la anulación, evitando duplicar todo el detalle disponible en W03

La autorización, el estado actual y el resultado esperado deben ser visibles antes de ejecutar una acción para reducir errores operativos

El frontend puede ocultar o deshabilitar acciones inválidas, pero toda regla debe ser validada nuevamente en el backend

Los componentes de filtros, tablas, estados, botones y paneles laterales deben mantener coherencia con los patrones utilizados en W01, W02 y W03

---

## 12. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 4 del archivo Figma del Módulo D, pantalla **Anulaciones**
- Especificación de W04 definida para el Hito 1
- Especificación de F2 — Anulación de pedidos
- Especificación de F1 — Ciclo de vida del pedido
- Reglas de navegación entre W03, W04 y los procesos de postventa

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=31-6`

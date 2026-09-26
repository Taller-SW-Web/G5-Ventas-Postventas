# W05 — Devoluciones y cambios

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W05 — Devoluciones y cambios  
**Página de referencia en Figma:** Page 6  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F3 — Devoluciones y cambios

---

## 1. Contexto del wireframe

W05 representa la bandeja de gestión de solicitudes de devolución y cambio dentro del **Módulo D — Ventas y Postventa**

La pantalla pertenece al flujo de postventa y se utiliza cuando un cliente ya recibió su pedido y solicita devolver un producto o cambiarlo. El Gestor revisa el expediente, la evidencia presentada y las condiciones de elegibilidad antes de aprobar o rechazar la solicitud

F3 se ejecuta dentro de M2 — Postventa y no modifica directamente las tablas de pedido de M1. Para validar el caso consulta a F1 y, dependiendo de la resolución, puede coordinar un nuevo despacho o derivar el expediente hacia F4 para gestionar un reembolso

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

La pantalla busca centralizar la evaluación de solicitudes de devolución y cambio para que el Gestor pueda revisar cada expediente sin ingresar a diferentes vistas

Desde W05 se puede localizar una solicitud, identificar su estado, revisar el motivo y la evidencia presentada y decidir si corresponde aprobarla, rechazarla o derivarla a un reembolso

---

## 3. Actor y alcance de acceso

El usuario principal de W05 es el **Gestor o Administrador de ventas**

El cliente inicia la solicitud desde el canal correspondiente, mientras que el Gestor utiliza esta pantalla administrativa para evaluarla

Para que un expediente sea elegible, el pedido debe encontrarse en estado `ENTREGADO`, estar dentro del plazo definido por el proyecto y contar con un motivo válido. Cuando el motivo requiere evidencia, esta debe estar disponible para revisión

---

## 4. Estructura general de la interfaz

La pantalla se divide en cinco zonas principales:

| Zona | Función |
|---|---|
| **Menú lateral** | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Facilitan la búsqueda por expediente, estado, tipo y canal |
| **Bandeja de solicitudes** | Presenta los expedientes registrados y su situación actual |
| **Evidencia** | Muestra fotos y comprobantes adjuntos al expediente |
| **Detalle y acciones** | Resume el caso, presenta la evaluación y permite resolver la solicitud |

La organización separa claramente el listado general del análisis individual del expediente

---

## 5. Filtros y bandeja de solicitudes

El wireframe incorpora los filtros:

- **Buscar:** código de expediente, pedido o cliente
- **Estado:** permite filtrar según el estado del expediente
- **Tipo:** diferencia solicitudes de cambio y devolución
- **Canal:** permite consultar solicitudes provenientes de Marketplace, Chatbot o Retail

Las acciones **Aplicar filtros** y **Limpiar** controlan la consulta

La tabla principal presenta:

| Campo | Información mostrada |
|---|---|
| **Código / Fecha** | Identificador del expediente y fecha de registro |
| **Pedido** | Pedido relacionado con la solicitud |
| **Tipo** | Cambio o devolución |
| **Motivo** | Razón registrada por el cliente |
| **Estado** | Situación actual del expediente |
| **Acción** | Permite abrir el expediente para revisión |

Los estados representados en el wireframe incluyen `SOLICITADA`, `EN EVALUACIÓN`, `APROBADA` y `RECHAZADA`

### Detalle visual: filtros y bandeja de solicitudes

---

## 6. Detalle del expediente

Al seleccionar una solicitud, el panel lateral presenta la información necesaria para evaluar el caso:

- Código del expediente
- Pedido relacionado
- Tipo de solicitud
- Cliente
- Canal
- Fecha de entrega
- Motivo
- Evidencia disponible
- Estado actual

La fecha de entrega es relevante porque F3 debe verificar que el pedido ya haya sido entregado y que la solicitud se encuentre dentro del plazo establecido

En el ejemplo mostrado, el expediente corresponde a un **Cambio** por talla incorrecta y se encuentra en estado `EN EVALUACIÓN`

---

## 7. Evidencia del cliente

El bloque **Evidencia** permite revisar los archivos adjuntos asociados al expediente, como fotografías o comprobantes

El wireframe muestra archivos de ejemplo y una opción para consultar todos los adjuntos

La evidencia es especialmente importante cuando la solicitud se origina por un producto defectuoso o dañado. F3 establece que estos casos no deben aprobarse automáticamente si falta la evidencia requerida

### Detalle visual: evidencia y archivos adjuntos

---

## 8. Resolución y evaluación

El panel **Resolución / evaluación** resume la decisión propuesta y las condiciones necesarias para ejecutarla

En el ejemplo se muestran:

| Elemento | Resultado representado |
|---|---|
| **Resolución propuesta** | CAMBIO |
| **Stock para cambio** | Disponible |
| **Logística** | Nuevo despacho |
| **Reembolso** | No aplica |

Cuando el expediente corresponde a un cambio, el sistema debe consultar disponibilidad de producto y coordinar el nuevo despacho

Cuando la resolución corresponde a una devolución con dinero, F3 no ejecuta directamente el extorno, sino que origina una solicitud hacia F4

Cambio y devolución con reembolso son resoluciones excluyentes para un mismo expediente

---

## 9. Acciones disponibles

El wireframe presenta cuatro acciones principales:

| Acción | Comportamiento esperado |
|---|---|
| **Aprobar solicitud** | Cambia el expediente a `APROBADA` y ejecuta la resolución correspondiente |
| **Rechazar solicitud** | Registra la decisión como `RECHAZADA` y exige un fundamento |
| **Derivar a reembolso** | Envía el origen del caso hacia F4 cuando corresponde devolver dinero |
| **Volver al pedido** | Regresa al detalle W03 del pedido relacionado |

Al abrir una solicitud en estado `SOLICITADA`, F3 puede pasarla a `EN EVALUACIÓN`

Si se aprueba un cambio y existe disponibilidad, se coordina un nuevo despacho. Si no existe stock, el expediente debe resolverse mediante la alternativa definida por el proyecto y no quedar indefinidamente pendiente

---

## 10. Relación con funcionalidades y navegación

| Funcionalidad | Relación con W05 |
|---|---|
| **F1 — Ciclo de vida del pedido** | Confirma que el pedido asociado se encuentre `ENTREGADO` |
| **F3 — Devoluciones y cambios** | Gestiona el expediente, su evaluación, evidencia y resolución |
| **F4 — Reembolsos y extornos** | Recibe el origen del reembolso cuando la resolución implica devolución de dinero |
| **Productos y Ofertas** | Confirma disponibilidad cuando la resolución corresponde a un cambio |
| **Despacho y Entrega** | Coordina recojo o nuevo despacho cuando corresponde |

La navegación principal prevista es:

**Postventa → W05 Devoluciones y cambios → W03 Detalle del pedido / W07 Reembolsos**

---

## 11. Consideraciones funcionales y de diseño

W05 debe permitir revisar primero el contexto del expediente antes de ejecutar una resolución

La tabla muestra únicamente la información necesaria para localizar y diferenciar solicitudes, mientras que el detalle, evidencia y acciones se concentran en los paneles específicos

El frontend puede restringir acciones según el estado del expediente, pero las reglas de elegibilidad y transición deben ser validadas nuevamente por el backend

Los componentes de filtros, estados, tablas, archivos y botones deben mantener coherencia con las demás pantallas del módulo

---

## 12. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 6 del archivo Figma del Módulo D, pantalla **Devoluciones y Cambios**
- Especificación de W05 definida para el Hito 1
- Especificación de F3 — Devoluciones y cambios
- Reglas de integración con F1, F4, Productos y Despacho
- Lineamientos de navegación y frontend del Módulo D

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=48-210`

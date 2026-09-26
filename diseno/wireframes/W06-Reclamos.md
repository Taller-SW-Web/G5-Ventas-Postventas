# W06 — Reclamos

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W06 — Reclamos  
**Página de referencia en Figma:** Page 7  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F6 — Reclamos, dashboard y reportes

---

## 1. Contexto del wireframe

W06 representa la bandeja administrativa utilizada para consultar, atender y dar seguimiento a los reclamos registrados dentro del **Módulo D — Ventas y Postventa**

La pantalla forma parte de F6 y concentra la información operativa del Libro de Reclamaciones, incluyendo código del reclamo, pedido asociado cuando existe, datos de contacto, motivo, fechas, control del SLA, respuesta del Gestor y estado de atención

El pedido asociado es opcional, ya que un reclamo también puede registrarse como una queja general sin relación directa con una compra específica

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda identificar reclamos pendientes de atención, conocer su prioridad según el SLA y revisar toda la información necesaria antes de emitir una respuesta formal

W06 también permite conservar la trazabilidad del expediente, generar el formato de respuesta y cerrar el reclamo cuando la atención haya sido registrada correctamente

---

## 3. Actor y alcance de acceso

El usuario principal de W06 es el **Gestor o Administrador de ventas**

El cliente registra el reclamo desde los canales habilitados y posteriormente puede consultar su estado mediante el código de seguimiento y su documento

Dentro del backoffice, el Gestor revisa el expediente, controla el plazo de atención y registra la respuesta correspondiente

---

## 4. Estructura general de la interfaz

La pantalla se organiza en seis zonas principales:

| Zona | Función |
|---|---|
| **Menú lateral** | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Facilitan la búsqueda por código, pedido, cliente, estado y fecha |
| **Bandeja de reclamos** | Presenta los reclamos registrados y su situación de atención |
| **Historial de atención** | Muestra cronológicamente las acciones realizadas sobre el expediente |
| **Detalle del reclamo** | Reúne datos de contacto, descripción, fechas, SLA y respuesta |
| **Archivos y acciones** | Permite consultar documentos y ejecutar las acciones disponibles |

La distribución permite revisar primero el listado general y luego profundizar en un reclamo seleccionado sin abandonar la pantalla

---

## 5. Filtros y bandeja de reclamos

El wireframe incorpora los filtros:

- **Buscar:** permite localizar por código de reclamo, pedido o cliente
- **Estado:** restringe los reclamos según su situación actual
- **Fecha de creación:** permite consultar un rango determinado

Las acciones **Aplicar filtros** y **Limpiar** controlan la consulta

La tabla principal presenta:

| Campo | Información mostrada |
|---|---|
| **Código** | Identificador único del reclamo |
| **Fecha** | Fecha de creación |
| **Pedido** | Pedido relacionado cuando existe |
| **Motivo** | Razón principal del reclamo |
| **Estado** | Situación visible del expediente |
| **SLA** | Tiempo restante o condición del plazo |
| **Acción** | Permite abrir el reclamo para revisión |

El listado incluye ordenamiento por fecha y paginación para mantener una vista limpia

### Detalle visual: filtros y bandeja de reclamos

---

## 6. Detalle del reclamo y control SLA

El panel lateral presenta la información necesaria para revisar el expediente:

- Código del reclamo
- Pedido asociado
- Cliente
- Motivo
- Fecha de creación
- Fecha límite
- Estado
- Contador SLA
- Datos de contacto
- Descripción
- Respuesta registrada

F6 establece un plazo de atención de **15 días hábiles**, cuya fecha límite debe calcularse y conservarse en `fechaLimiteSLA`

El sistema debe mantener visible la situación del plazo para que el Gestor pueda priorizar los casos próximos a vencer o ya vencidos

---

## 7. Historial de atención

El bloque **Historial de atención** presenta cronológicamente las acciones realizadas sobre el reclamo

En el wireframe se representan eventos como:

- Reclamo creado
- Revisión inicial
- Respuesta enviada

Este historial permite conservar trazabilidad sobre cuándo se registró el expediente, cuándo fue tomado por el área de postventa y cuándo se emitió una respuesta

La fecha y hora de atención deben quedar registradas para poder auditar el cumplimiento del SLA

---

## 8. Respuesta y archivos

La respuesta del Gestor debe quedar registrada como información visible para el cliente

Según F6, el campo obligatorio de cierre es `respuestaVisibleCliente`. Un reclamo no debe pasar a `ATENDIDO` si esta respuesta se encuentra vacía

El bloque **Archivos** permite conservar documentos asociados a la atención, como el PDF generado con la respuesta formal del reclamo

### Detalle visual: historial, respuesta y archivos

---

## 9. Acciones disponibles

El wireframe presenta cuatro acciones principales:

| Acción | Comportamiento esperado |
|---|---|
| **Responder reclamo** | Permite registrar la respuesta formal del Gestor |
| **Generar PDF** | Genera el documento asociado a la atención del reclamo |
| **Marcar como atendido** | Cierra el expediente cuando existe una respuesta válida |
| **Volver al pedido** | Regresa a W03 cuando el reclamo tiene un pedido asociado |

La acción **Volver al pedido** solo tiene sentido cuando existe una referencia a un pedido, ya que F6 permite registrar reclamos sin `pedidoId`

---

## 10. Estados y consistencia funcional

La especificación funcional de F6 define el ciclo de vida:

`REGISTRADO → EN PROCESO → ATENDIDO`

con una rama opcional `DERIVADO`

El wireframe utiliza etiquetas visuales como **PENDIENTE**, **EN ATENCIÓN**, **ATENDIDO** y **VENCIDO** para facilitar la lectura operativa

Durante la implementación estas etiquetas deben mantenerse coherentes con los estados canónicos del backend y con la condición del SLA, evitando tratar un SLA vencido como una transición independiente del ciclo de vida del reclamo

---

## 11. Relación con funcionalidades y navegación

| Funcionalidad | Relación con W06 |
|---|---|
| **F6 — Reclamos, dashboard y reportes** | Registra, atiende y controla el SLA del reclamo |
| **F1 — Ciclo de vida del pedido** | Permite consultar el pedido cuando existe una referencia asociada |
| **Dashboard W01** | Recibe indicadores relacionados con reclamos y cumplimiento de SLA |
| **Canales Marketplace, Chatbot y Retail** | Permiten que el cliente registre y consulte sus reclamos |

La navegación principal prevista es:

**Postventa → W06 Reclamos → W03 Detalle del pedido si existe pedido asociado**

---

## 12. Consideraciones funcionales y de diseño

W06 debe priorizar visualmente los reclamos que requieren atención y mostrar el SLA de forma clara sin saturar la bandeja con toda la información del expediente

El detalle, historial, archivos y acciones se mantienen separados para facilitar la lectura y reducir errores durante la atención

El frontend puede orientar al Gestor mediante estados y alertas, pero el backend debe validar el cierre y exigir `respuestaVisibleCliente` antes de registrar el reclamo como `ATENDIDO`

Los componentes de filtros, tablas, estados, archivos y botones deben conservar coherencia con las demás pantallas del módulo

---

## 13. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 7 del archivo Figma del Módulo D, pantalla **Reclamos**
- Especificación de W06 definida para el Hito 1
- Especificación de F6 — Reclamos, dashboard y reportes
- Requisitos de registro, atención y control SLA del Libro de Reclamaciones
- Lineamientos de navegación y frontend del Módulo D

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=56-322`

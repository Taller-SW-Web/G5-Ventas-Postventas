# W02 — Bandeja de pedidos

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W02 — Bandeja de pedidos  
**Página de referencia en Figma:** Page 2
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F1 — Ciclo de vida del pedido y F2 — Anulación de pedidos

---

## 1. Contexto del wireframe

W02 representa la bandeja principal para la consulta y seguimiento de pedidos dentro del **Módulo D — Ventas y Postventa**. Esta pantalla permite al Gestor revisar los pedidos recibidos desde los canales Marketplace, Chatbot y Retail, conocer su estado actual y acceder a las acciones disponibles según cada caso

La información mostrada corresponde principalmente a F1, responsable del ciclo de vida del pedido y de mantener sus estados e historial. Cuando corresponde iniciar una anulación, W02 también se relaciona con F2, que aplica las reglas de negocio antes de solicitar cualquier transición a `ANULADO`

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

La Bandeja de pedidos busca centralizar la consulta operativa de los pedidos para que el Gestor pueda localizar un registro, identificar rápidamente su estado y acceder a su detalle sin recorrer diferentes pantallas

También permite detectar qué pedidos se encuentran pendientes, pagados, despachados o entregados y facilita la navegación hacia el detalle completo o hacia el flujo de anulación cuando el estado del pedido lo permite

---

## 3. Actor y alcance de acceso

El usuario principal de W02 es el **Gestor o Administrador de ventas**. Los clientes no ingresan directamente a esta bandeja administrativa, ya que sus pedidos se originan y consultan mediante los canales correspondientes

F1 establece que las operaciones administrativas de consulta general requieren permisos de Gestor o Administrador, mientras que los canales externos interactúan con los pedidos mediante los contratos definidos por el sistema

---

## 4. Estructura general de la interfaz

La pantalla se organiza en cinco zonas principales:

| Zona | Función |
|---|---|
| **Menú lateral** | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Facilitan la búsqueda y segmentación de pedidos |
| **Indicadores de pedidos** | Presentan una lectura rápida de los estados principales |
| **Listado de pedidos** | Muestra los registros disponibles de manera paginada |
| **Detalle rápido** | Resume la información del pedido seleccionado y presenta acciones disponibles |

La distribución prioriza primero la búsqueda y el estado general de la operación, dejando el detalle de cada pedido disponible sin abandonar la bandeja

---

## 5. Filtros de consulta

El wireframe incorpora los siguientes filtros:

- **Buscar:** permite localizar por código, cliente o referencia
- **Estado:** restringe el listado según el estado actual del pedido
- **Canal:** permite consultar Marketplace, Chatbot, Retail o todos los canales
- **Fecha:** delimita el rango temporal de los registros

Las acciones **Aplicar filtros** y **Limpiar** permiten ejecutar o restablecer la búsqueda. Esta estructura responde a la necesidad definida en F1 de consultar pedidos y disponer de listados filtrables para la gestión administrativa

---

## 6. Indicadores principales

La parte superior de W02 contiene cinco indicadores que resumen la bandeja:

| Indicador | Ejemplo mostrado | Propósito |
|---|---:|---|
| **Total pedidos** | 2,880 | Mostrar el total de registros considerados |
| **Pendientes** | 426 | Identificar pedidos que todavía requieren avance operativo |
| **Pagados** | 1,320 | Mostrar pedidos cuyo pago ya fue confirmado |
| **Despachados** | 740 | Identificar pedidos que ya se encuentran en proceso de entrega |
| **Entregados** | 394 | Mostrar pedidos que completaron el flujo de entrega |

Estos indicadores complementan el listado y permiten al Gestor obtener una referencia rápida de la distribución actual de los pedidos

### Detalle visual: filtros e indicadores

---

## 7. Listado de pedidos y detalle rápido

### 7.1. Listado de pedidos

La tabla constituye el componente principal de la pantalla y presenta las columnas:

| Campo | Información mostrada |
|---|---|
| **Código** | Identificador único del pedido |
| **Fecha** | Fecha asociada al registro |
| **Cliente / Ref.** | Nombre del cliente y referencia relacionada |
| **Canal** | Marketplace, Chatbot o Retail |
| **Total** | Importe asociado al pedido |
| **Estado** | Estado actual dentro del ciclo de vida |
| **Acción** | Acceso al detalle del registro |

El listado incorpora ordenamiento por fecha y paginación, lo que permite trabajar con un volumen mayor de pedidos sin saturar la interfaz

### 7.2. Estados representados

El wireframe muestra estados como:

- `CREADO`
- `PAGADO`
- `EN PREPARACIÓN`
- `DESPACHADO`
- `ENTREGADO`
- `ANULADO`

Estos estados corresponden al ciclo de vida administrado por F1. La interfaz únicamente representa el estado actual, mientras que las transiciones válidas deben ser verificadas y ejecutadas por la lógica del backend

### 7.3. Detalle rápido

Al seleccionar un pedido se presenta un resumen lateral con código, estado, canal, cliente, total y fecha de última actualización

En el ejemplo del wireframe se visualiza el pedido `PED-2026-1042` en estado `PAGADO`, asociado al canal Marketplace y al cliente Ana López. Desde este panel se ofrecen las acciones **Ver detalle completo** e **Iniciar anulación**

### Detalle visual: listado y panel lateral

---

## 8. Acciones y reglas operativas

La acción **Ver detalle completo** dirige hacia W03, donde se consulta la información completa del pedido, incluidos sus datos asociados e historial de estados

La acción **Iniciar anulación** se relaciona con F2 y debe estar disponible únicamente cuando el estado permita iniciar dicho proceso. De acuerdo con las reglas del módulo, los pedidos `CREADO`, `PAGADO` o `EN PREPARACIÓN` pueden participar en un flujo de anulación según las condiciones establecidas, mientras que un pedido `DESPACHADO` o `ENTREGADO` debe derivarse al flujo correspondiente de postventa

La interfaz puede ocultar o deshabilitar acciones que sean claramente inválidas según el estado actual, pero el backend debe volver a validar siempre la regla antes de ejecutar cualquier transición

---

## 9. Relación con las funcionalidades y navegación

| Funcionalidad | Relación con W02 |
|---|---|
| **F1 — Ciclo de vida del pedido** | Proporciona el listado, estado actual, detalle e historial del pedido |
| **F2 — Anulación de pedidos** | Recibe el flujo cuando desde un pedido elegible se inicia una anulación |
| **F3 — Devoluciones y cambios** | Se relaciona con pedidos ya entregados cuando corresponde gestionar una devolución |
| **F6 — Dashboard y reportes** | Consume eventos de F1 para mantener indicadores y agregados administrativos |

La navegación principal prevista es:

**W01 Dashboard → W02 Pedidos → W03 Detalle del pedido / W04 Anulaciones**

W02 funciona como punto de entrada operativo para localizar el pedido antes de acceder a un nivel mayor de detalle o iniciar un proceso asociado

---

## 10. Consideraciones funcionales y de diseño

La pantalla debe conservar una lectura rápida y ordenada debido a que puede concentrar una cantidad elevada de pedidos. Los filtros, indicadores y tabla deben permitir reconocer el estado de cada registro sin introducir información que corresponda exclusivamente al detalle completo

La columna de estado y el panel lateral deben mantenerse sincronizados con la información entregada por F1. W02 no modifica directamente la persistencia de los pedidos ni decide transiciones por cuenta propia

En la implementación del frontend se debe mantener la coherencia visual y de componentes con las demás pantallas W01–W08, reutilizando patrones para filtros, estados, tablas, paginación y acciones

---

## 11. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 2 del archivo Figma del Módulo D, pantalla **Pedidos**
- Wireframe W02 proporcionado para el Hito 1
- Especificación de F1 — Ciclo de vida del pedido
- Especificación de F2 — Anulación de pedidos
- Lineamientos de frontend definidos para el panel del Gestor

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=2-28`

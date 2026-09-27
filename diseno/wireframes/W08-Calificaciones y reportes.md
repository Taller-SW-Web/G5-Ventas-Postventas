# W08 — Calificaciones y reportes

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W08 — Calificaciones y reportes  
**Página de referencia en Figma:** Page 9  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F5 — Calificación de experiencia y F6 — Reclamos, dashboard y reportes

---

## 1. Contexto del wireframe

W08 representa la vista analítica del **Módulo D — Ventas y Postventa**, orientada a consultar la satisfacción del cliente y el desempeño comercial desde una misma pantalla

La información de satisfacción proviene principalmente de F5, que registra calificaciones de 1 a 5 y comentarios después de una entrega confirmada. F6 consume estos agregados junto con eventos del resto del módulo para presentar indicadores, gráficos, tablas y reportes filtrables

La pantalla no modifica pedidos ni crea reclamos automáticamente a partir de una calificación baja. Su propósito es de consulta, análisis y apoyo a la toma de decisiones del Gestor

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

W08 busca concentrar en una sola vista los principales indicadores de satisfacción y ventas para facilitar la comparación entre periodos, canales y vendedores

El Gestor puede revisar el CSAT, comentarios recientes, ventas por canal, desempeño comercial y productos más vendidos, además de exportar la información correspondiente a los filtros aplicados

---

## 3. Actor y alcance de acceso

El usuario principal de W08 es el **Gestor o Administrador de ventas**

El cliente participa de manera indirecta mediante las encuestas de satisfacción de F5, registrando una puntuación de 1 a 5 y un comentario opcional después de la entrega de su pedido

W08 corresponde al backoffice y presenta información consolidada. No es la pantalla donde el cliente responde la encuesta

---

## 4. Estructura general de la interfaz

La pantalla se organiza en cinco zonas principales:

| Zona | Función |
|---|---|
| **Menú lateral** | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes |
| **Filtros y acciones** | Permiten delimitar la información y ejecutar comparación o exportación |
| **Indicadores clave** | Presentan un resumen de satisfacción, ventas y reclamos |
| **Bloques analíticos** | Muestran distribución de calificaciones y desempeño comercial |
| **Tablas de detalle** | Presentan comentarios recientes y productos más vendidos |

La distribución prioriza primero el resumen general y luego permite revisar información más específica

---

## 5. Filtros y acciones de consulta

El wireframe incorpora los filtros:

- **Periodo:** restringe la información al rango temporal seleccionado
- **Canal:** permite consultar Marketplace, Chatbot, Retail o todos los canales
- **Vendedor:** permite segmentar el desempeño comercial
- **Reporte / Vista:** permite seleccionar el tipo de visualización disponible

Las acciones principales son:

| Acción | Propósito |
|---|---|
| **Aplicar filtros** | Actualiza los indicadores según los criterios seleccionados |
| **Comparar** | Permite contrastar la información disponible según la vista definida |
| **Exportar** | Genera un reporte con los datos correspondientes a los filtros aplicados |

F6 establece que la exportación debe mantener coherencia con la información mostrada en pantalla

---

## 6. Indicadores principales

La parte superior presenta cuatro indicadores:

| Indicador | Ejemplo mostrado | Propósito |
|---|---:|---|
| **CSAT promedio** | 4.3 / 5 | Resume la satisfacción promedio registrada |
| **Ticket promedio** | S/ 148.90 | Representa el valor promedio de las ventas |
| **Ventas del periodo** | S/ 18,540 | Muestra el importe consolidado del periodo |
| **Reclamos abiertos** | 5 | Identifica casos que aún requieren atención |

Los indicadores incluyen una referencia comparativa respecto al periodo anterior para facilitar la lectura de tendencias

### Detalle visual: filtros e indicadores

---

## 7. Satisfacción del cliente

El bloque **Satisfacción del cliente** presenta dos formas de visualizar la información de F5:

- Distribución de calificaciones entre 1 y 5
- CSAT promedio consolidado

F5 establece que cada respuesta válida debe quedar asociada al canal y fecha correspondientes y actualizar el agregado de CSAT consumido por F6

Una puntuación baja se contabiliza dentro del indicador, pero no modifica el estado del pedido ni genera automáticamente un reclamo

---

## 8. Desempeño comercial

El bloque **Desempeño comercial** complementa la satisfacción con información de ventas

El wireframe presenta:

- **Ventas por canal:** comparación entre Marketplace, Chatbot y Retail
- **Comparativa de vendedores:** permite observar el desempeño relativo de los vendedores según el criterio seleccionado

Estos datos forman parte de los agregados utilizados por F6 y permiten analizar el comportamiento comercial sin consultar directamente cada pedido individual

---

## 9. Comentarios y productos más vendidos

### 9.1. Últimos comentarios de clientes

La tabla muestra respuestas registradas por F5 con:

- Fecha
- Canal
- Puntuación
- Comentario
- Acción de detalle

El comentario es opcional dentro de la encuesta, mientras que la puntuación de 1 a 5 es obligatoria

### 9.2. Productos más vendidos

La tabla de productos presenta:

- Posición
- Producto
- Unidades vendidas
- Participación sobre el total

Este bloque permite complementar los indicadores generales con una lectura rápida de los productos con mayor movimiento comercial

### Detalle visual: analítica y tablas

---

## 10. Origen y tratamiento de la información

W08 combina información de F5 y F6

F5 mantiene actualizado el agregado de CSAT después de cada respuesta válida. F6 mantiene agregados analíticos a partir de eventos generados por M1 y M2 para construir indicadores por periodo, canal, vendedor y producto

La pantalla debe consultar estos agregados y no recalcular todas las métricas recorriendo directamente la base transaccional cada vez que el Gestor ingresa a la vista

---

## 11. Relación con funcionalidades y navegación

| Funcionalidad | Relación con W08 |
|---|---|
| **F5 — Calificación de experiencia** | Proporciona puntuaciones, comentarios y el agregado CSAT |
| **F6 — Reclamos, dashboard y reportes** | Consolida indicadores, filtros, gráficos, tablas y exportaciones |
| **F1 — Ciclo de vida del pedido** | Publica eventos de pedidos utilizados por los agregados |
| **F2 a F4 — Postventa** | Aportan eventos de anulaciones, devoluciones y reembolsos |
| **W01 — Dashboard** | Comparte indicadores generales y sirve como punto de navegación relacionado |

La navegación prevista es:

**Reportes → W08 Calificaciones y reportes → W01 Dashboard / detalle relacionado**

---

## 12. Consideraciones funcionales y de diseño

W08 debe mantener una lectura rápida aun cuando concentre diferentes tipos de información. Los indicadores, gráficos y tablas deben estar agrupados por objetivo para evitar sobrecargar al Gestor

Los filtros deben afectar únicamente la información correspondiente a la selección realizada y la exportación debe conservar esos mismos criterios

Los componentes visuales deben mantener coherencia con las demás pantallas del módulo y conservar el enfoque de baja fidelidad definido para el Hito 1

---

## 13. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 9 del archivo Figma del Módulo D, pantalla **Calificaciones y Reportes**
- Especificación de W08 definida para el Hito 1
- Especificación de F5 — Calificación de experiencia
- Especificación de F6 — Reclamos, dashboard y reportes
- Reglas de filtros, agregados y exportación definidas para el Módulo D

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=70-76`

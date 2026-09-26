# W01 — Dashboard general

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W01 — Dashboard general  
**Página de referencia en Figma:** Page 1
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F6 — Reclamos, dashboard y reportes

---

## 1. Contexto del wireframe

W01 representa la pantalla principal de consulta del **Módulo D — Ventas y Postventa**. Su finalidad es ofrecer al Gestor una lectura rápida del comportamiento general de ventas y de los procesos de postventa, sin obligarlo a ingresar primero a cada bandeja operativa

La pantalla funciona principalmente como un punto de **monitoreo y navegación**. Los indicadores se construyen a partir de información consolidada de pedidos y postventa. De acuerdo con la especificación de F6, el dashboard debe consultar **agregados previamente actualizados por eventos de M1 y M2**, en lugar de recorrer toda la base transaccional cada vez que se abre la vista

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

El Dashboard busca que el Gestor pueda identificar en pocos segundos el estado general de la operación. Para ello concentra indicadores de ventas, anulaciones, devoluciones y reclamos, además de alertas que requieren atención

La pantalla también sirve como punto de entrada hacia las áreas principales del módulo: **Pedidos, Postventa y Reportes**

---

## 3. Actor y alcance de acceso

El usuario principal de W01 es el **Gestor o Administrador de ventas**. Esta pantalla forma parte del backoffice del Módulo D y no corresponde a una interfaz de compra para el cliente

Los clientes interactúan con el sistema mediante los canales definidos por el proyecto, como Marketplace, Chatbot o Retail. El Gestor, en cambio, utiliza el Dashboard para consultar información consolidada y acceder a los procesos administrativos

---

## 4. Estructura general de la interfaz

La pantalla se divide en cuatro zonas principales:

| Zona                   | Función                                                                |
| ---------------------- | ---------------------------------------------------------------------- |
| **Menú lateral**       | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes         |
| **Filtros superiores** | Permiten restringir la información por período y canal                 |
| **Indicadores KPI**    | Presentan un resumen cuantitativo de la operación                      |
| **Zona analítica**     | Muestra tendencias, alertas SLA, ventas por canal y un resumen tabular |

La jerarquía mantiene primero los datos de mayor importancia y luego presenta el detalle analítico

---

## 5. Filtros del Dashboard

El wireframe incluye dos filtros principales:

- **Período:** define el intervalo de fechas sobre el cual se consultarán los indicadores
- **Canal:** permite visualizar información de todos los canales o de uno específico

Las acciones disponibles son **Aplicar filtros** y **Limpiar**. Según F6, al aplicar un período y canal determinados, el sistema debe mostrar únicamente los agregados correspondientes a esa selección

---

## 6. Indicadores principales

La fila superior contiene cinco tarjetas KPI:

| Indicador              | Ejemplo mostrado | Propósito                                                |
| ---------------------- | ---------------: | -------------------------------------------------------- |
| **Ventas**             |       S/ 128,450 | Mostrar el importe total de ventas del período           |
| **Ticket promedio**    |           S/ 214 | Representar el valor promedio de las ventas              |
| **Tasa de anulación**  |             3.8% | Mostrar la proporción de pedidos anulados                |
| **Tasa de devolución** |             2.4% | Mostrar la proporción asociada a devoluciones            |
| **Reclamos abiertos**  |               18 | Mostrar la cantidad de reclamos aún pendientes de cierre |

Cada tarjeta también presenta una variación respecto de un período anterior, lo que permite detectar rápidamente incrementos o disminuciones

### Detalle visual: filtros e indicadores

---

## 7. Componentes analíticos

### 7.1. Tendencia de ventas

El gráfico de línea permite observar la evolución de las ventas a lo largo del tiempo. Su función es facilitar la identificación de aumentos, disminuciones o cambios relevantes durante el período analizado

### 7.2. Alertas SLA

El bloque **Alertas SLA** prioriza expedientes que necesitan seguimiento. El wireframe contempla estados como:

- **En plazo**
- **Próximo a vencer**
- **Vencido**

Para cada alerta se presenta un código, tipo de caso, estado del SLA, fecha límite y una acción para revisar el expediente

En el caso de los reclamos, F6 establece que el SLA debe ser controlado a partir de la fecha límite calculada y que su cumplimiento o incumplimiento debe quedar disponible para el Dashboard

### 7.3. Ventas por canal

El gráfico de barras compara el volumen de ventas entre **Marketplace, Chatbot y Retail**. Esta vista permite reconocer visualmente qué canal tiene mayor participación dentro del período consultado

### 7.4. Resumen por canal

Complementa el gráfico anterior con una tabla que muestra:

| Canal       |         Ventas | Participación |   Pedidos |
| ----------- | -------------: | ------------: | --------: |
| Marketplace |      S/ 62,450 |           48% |     1,260 |
| Chatbot     |      S/ 38,200 |           30% |       940 |
| Retail      |      S/ 27,800 |           22% |       680 |
| **Total**   | **S/ 128,450** |      **100%** | **2,880** |

### Detalle visual: analítica y SLA

---

## 8. Relación con las funcionalidades del módulo

W01 pertenece principalmente a **F6 — Reclamos, dashboard y reportes**, pero su información depende de eventos generados por otras funcionalidades del Módulo D

| Funcionalidad                           | Relación con W01                                                                     |
| --------------------------------------- | ------------------------------------------------------------------------------------ |
| **F1 — Ciclo de vida del pedido**       | Aporta eventos de pedidos pagados, anulados y entregados utilizados en los agregados |
| **F2 — Anulaciones**                    | Alimenta información relacionada con anulaciones y su comportamiento                 |
| **F3 — Devoluciones y cambios**         | Aporta información de solicitudes y resoluciones de postventa                        |
| **F4 — Reembolsos**                     | Contribuye con información de operaciones de reembolso cuando corresponde            |
| **F5 — Calificación de experiencia**    | Mantiene el agregado CSAT utilizado posteriormente en las vistas analíticas          |
| **F6 — Reclamos, dashboard y reportes** | Consolida los eventos, mantiene agregados y presenta los indicadores del Dashboard   |

Esta separación evita que el frontend calcule métricas recorriendo directamente toda la información transaccional

---

## 9. Navegación prevista

Desde W01 el Gestor puede desplazarse mediante el menú lateral hacia:

**Dashboard → Pedidos / Postventa / Reportes**

Además, las alertas SLA cuentan con una acción **Ver**, que debe conducir al expediente correspondiente para que el Gestor pueda revisar el caso y tomar una acción desde la pantalla específica

W01 no reemplaza las pantallas operativas. Su función es resumir, alertar y dirigir al usuario hacia el flujo adecuado

---

## 10. Consideraciones funcionales y de diseño

El Dashboard debe mantener una presentación simple porque corresponde al primer nivel de consulta del sistema. La información prioritaria debe poder reconocerse sin revisar grandes cantidades de datos

En la implementación posterior se debe conservar la consistencia con el sistema visual definido por UX/UI y con los componentes reutilizables del frontend. Los filtros, tarjetas, tablas, alertas y gráficos deben mantener un comportamiento uniforme con las demás pantallas W02–W08

También debe respetarse la regla de F6 según la cual el Dashboard trabaja sobre **agregados precalculados**, permitiendo una consulta rápida y evitando acoplar la interfaz a las tablas internas de los microservicios

---

## 11. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 1 del archivo Figma del Módulo D, frame **Dashboard**
- Wireframe W01 proporcionado para el Hito 1
- Especificaciones funcionales F1–F6 del Módulo D
- Definición de F6 para dashboard, filtros, alertas SLA y agregados
- Lineamientos de frontend definidos para el backoffice del Gestor

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=0-1`

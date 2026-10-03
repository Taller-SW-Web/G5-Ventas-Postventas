# Dashboard general

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Dashboard general  
**Página de referencia en Figma:** Page 1  
**Frame principal:** Dashboard  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F6 — Gestión de reclamos, dashboard y reportes

---

## 1. Contexto del mockup

El Dashboard representa la pantalla principal de consulta del **Módulo D — Ventas y Postventa**, desde ella el Gestor obtiene una visión general de las ventas y de los casos que requieren seguimiento antes de ingresar a las bandejas de trabajo

El mockup conserva la finalidad del wireframe del Hito 1 y desarrolla su presentación mediante colores, tipografía, tarjetas, gráficos y controles interactivos, de esta manera permite comprender tanto la distribución de la información como la respuesta de la pantalla ante las acciones del usuario

Su relación principal es con F6, que reúne los indicadores operativos y los reportes del módulo, para la implementación estos datos deben consultarse desde agregados precalculados que se actualizan con los eventos de pedidos y postventa

> **Nota:** Las cifras y los expedientes mostrados son datos de demostración, las interacciones de Figma representan escenarios preparados y no acreditan una conexión con el backend ni con información real de producción

---

## 2. Objetivo de la pantalla

El Dashboard busca que el Gestor identifique rápidamente cómo se comportan las ventas y qué situaciones necesitan atención, para ello reúne el importe vendido, el ticket promedio, las tasas de anulación y devolución y la cantidad de reclamos abiertos

Los filtros permiten delimitar esta lectura por periodo y canal, mientras que los gráficos ayudan a interpretar la evolución de las ventas y la distribución de los pedidos

La pantalla también conecta la consulta general con el seguimiento de casos mediante **Ver** y **Ver todas**, así el usuario puede pasar de un resumen a una bandeja con mayor información

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien utiliza esta consola para supervisar la operación y acceder a los procesos administrativos

Según el diagrama de contexto y la sección de actores de la especificación, el Cliente y el Vendedor interactúan desde sus respectivos canales, por ello el Dashboard no corresponde a una pantalla de compra ni a una vista de autoservicio del cliente

En el sistema implementado el acceso debe estar protegido mediante la autenticación del Módulo G y la validación de token y rol en el API Gateway, el mockup representa la vista de un usuario que ya ingresó a la consola

---

## 4. Estructura general de la interfaz

La pantalla se organiza en las siguientes zonas

| Zona | Función dentro del Dashboard |
|---|---|
| **Menú lateral** | Identifica el módulo y presenta los accesos a Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Permiten seleccionar periodo y canal antes de actualizar la consulta |
| **Tarjetas de indicadores** | Resumen las ventas y los principales resultados de la operación |
| **Tendencia de ventas** | Representa la evolución de los importes durante el periodo |
| **Atención prioritaria** | Presenta una muestra de reclamos y expedientes de postventa que requieren seguimiento |
| **Ventas por canal** | Compara los importes de Marketplace, Chatbot y Retail |
| **Distribución de pedidos** | Muestra la composición de los pedidos mediante un gráfico circular y un detalle por estado |

El fondo claro y las tarjetas blancas separan los bloques de consulta, el menú oscuro mantiene visible la navegación y el color naranja destaca la acción principal **Aplicar filtros**

Los títulos tienen mayor peso visual que las etiquetas y los textos de apoyo, esta jerarquía permite reconocer primero el bloque y luego revisar sus cifras o controles

---

## 5. Filtros del Dashboard

### 5.1. Selección del periodo

Al hacer clic en el campo **Periodo** se despliega una lista debajo del control con tres opciones preparadas para la demostración

| Opción | Rango representado |
|---|---|
| **Septiembre 2026** | 01/09/2026 – 30/09/2026 |
| **Agosto 2026** | 01/08/2026 – 31/08/2026 |
| **Últimos 15 días** | 08/09/2026 – 22/09/2026 |

Al elegir una opción se actualiza el texto del campo y se cierra la lista, la opción **Últimos 15 días** utiliza un rango fijo de ejemplo dentro del prototipo

La selección prepara el criterio de consulta, los indicadores se actualizan cuando el usuario presiona **Aplicar filtros**

### 5.2. Selección del canal

El campo **Canal** permite elegir entre **Todos**, **Marketplace**, **Chatbot** y **Retail**

**Todos** corresponde a la consulta consolidada, las otras opciones permiten revisar el escenario de un canal específico sin abandonar el Dashboard

Al seleccionar un canal se actualiza su etiqueta y se cierra el desplegable, además al abrir este control se oculta la lista de periodos si estaba abierta, el mismo comportamiento se aplica en sentido inverso

### 5.3. Botón Aplicar filtros

**Aplicar filtros** utiliza conjuntamente el periodo y el canal seleccionados para mostrar la vista de datos correspondiente, el prototipo contiene doce combinaciones preparadas a partir de los tres periodos y los cuatro canales

La actualización incluye las tarjetas KPI y los bloques analíticos de la vista seleccionada, al terminar también se cierran los desplegables

Por ejemplo al seleccionar **Septiembre 2026** y **Marketplace** y luego aplicar la consulta, el mockup presenta ventas por **S/ 62,450**, ticket promedio de **S/ 228** y **9 reclamos abiertos**, junto con una distribución de **1,260 pedidos**

El botón incorpora cambios visuales al pasar el cursor y al presionarlo, estos estados ayudan a reconocer que el control responde a la interacción

### 5.4. Botón Limpiar

**Limpiar** elimina las selecciones visibles de periodo y canal, cierra las listas abiertas y recupera la vista general de datos utilizada como base en el prototipo

Esta vista corresponde al escenario consolidado de septiembre, por ello limpiar los campos no representa una consulta histórica de todos los periodos

La acción solo restablece la consulta visual y no elimina pedidos, reclamos ni información del módulo

### 5.5. Relación entre los controles

El recorrido de consulta se realiza en el siguiente orden

1. Abrir **Periodo** y elegir el intervalo que se desea revisar
2. Abrir **Canal** y seleccionar el origen de las ventas
3. Presionar **Aplicar filtros** para actualizar la información
4. Revisar las tarjetas y los gráficos del escenario seleccionado
5. Utilizar **Limpiar** cuando se necesite retirar los criterios y recuperar la vista base

Después de limpiar conviene seleccionar nuevamente ambos campos antes de aplicar una consulta específica, ya que los escenarios del prototipo están preparados para combinaciones completas

---

## 6. Indicadores principales

La vista inicial presenta cinco tarjetas con el resultado del periodo y una referencia comparativa

| Indicador | Ejemplo mostrado | Comparación visible | Utilidad |
|---|---:|---:|---|
| **Ventas** | S/ 128,450 | +12% | Conocer el importe vendido y su variación respecto del periodo anterior |
| **Ticket promedio** | S/ 214 | +5% | Revisar el importe promedio de las ventas consideradas en el indicador |
| **Tasa de anulación** | 3.8% | −0.6 pp | Observar la proporción de anulaciones y su variación |
| **Tasa de devolución** | 2.4% | −0.3 pp | Reconocer la incidencia de devoluciones en el periodo |
| **Reclamos abiertos** | 18 | −25% | Identificar la cantidad de casos que todavía requieren atención |

La abreviatura **pp** representa puntos porcentuales, permite diferenciar una variación de tasa de una variación porcentual del importe o de la cantidad de casos

Las tarjetas son elementos informativos, en el Dashboard revisado no tienen una acción de clic para abrir registros o cambiar estados, su contenido responde a la consulta aplicada

Las cifras se presentan como ejemplos del diseño, para la implementación deben definirse las bases de cálculo de cada indicador y no asumir que todos utilizan el mismo conjunto de pedidos

---

## 7. Componentes analíticos

### 7.1. Tendencia de ventas

El gráfico de línea muestra la evolución de las ventas mediante puntos distribuidos a lo largo del periodo, en la vista inicial aparecen referencias desde el **01 Sep** hasta el **30 Sep**

El bloque también presenta el pico de **S/ 42.2k**, una variación de **+12%** y una etiqueta final de **S/ 32.0k**, la letra **k** expresa valores en miles

Su finalidad es complementar el total vendido con una lectura de los aumentos y disminuciones del periodo, no presenta controles para editar la serie ni una navegación independiente desde sus puntos

### 7.2. Atención prioritaria

Este bloque reúne una muestra de casos para que el Gestor identifique situaciones que necesitan seguimiento, combina reclamos sujetos a control de SLA con solicitudes de devolución y cambio

La vista inicial muestra los siguientes ejemplos

| Tipo de caso | Situación visible | Fecha límite mostrada |
|---|---|---|
| **Reclamo** | Próximo a vencer | 19/09/2026 |
| **Devolución** | Pendiente | 17/09/2026 |
| **Cambio** | En evaluación | 22/09/2026 |

Los distintivos **1 reclamo**, **1 devolución** y **1 cambio** resumen las filas de esta muestra, no representan el total general de reclamos abiertos indicado en la tarjeta KPI

En los reclamos la situación se relaciona con el plazo de atención, en devoluciones y cambios describe la evaluación del expediente, estas referencias deben interpretarse según el tipo de caso

### 7.3. Botón Ver de cada caso

El botón **Ver** abre la pantalla complementaria **Atención prioritaria** con una selección del tipo correspondiente, si el usuario elige un reclamo se muestran reclamos, si elige una devolución se muestran devoluciones y si elige un cambio se muestran cambios

Las filas del resumen también tienen configurada esta misma acción, así el acceso puede realizarse desde el registro o desde su botón

En el comportamiento actual este acceso filtra por tipo de caso y no abre directamente el expediente individual del código mostrado en el Dashboard

### 7.4. Acceso Ver todas y regreso al Dashboard

**Ver todas** abre Atención prioritaria con su vista general de casos, a diferencia de **Ver** no restringe la entrada a uno de los tres tipos

Desde esa pantalla el usuario puede consultar un caso mediante su botón **Ver**, que presenta un detalle superpuesto con código, fecha, tipo, cliente, contexto, situación y prioridad

El control **×** cierra ese detalle y mantiene al usuario en la bandeja, la flecha **Atrás** de Atención prioritaria regresa al Dashboard

Esta descripción se limita a la continuidad del acceso iniciado desde el Dashboard, los filtros y demás componentes de la bandeja complementaria se documentarán en su pantalla correspondiente

### 7.5. Ventas por canal

El gráfico de barras compara los importes de los tres canales, su lectura complementa la tarjeta de ventas y permite identificar cuál tiene mayor participación económica

| Canal | Importe mostrado en la vista consolidada |
|---|---:|
| **Marketplace** | S/ 62,450 |
| **Chatbot** | S/ 38,200 |
| **Retail** | S/ 27,800 |
| **Total** | **S/ 128,450** |

Cuando se aplica un canal específico el escenario preparado concentra el importe en ese canal, las barras funcionan como una representación informativa y no como botones de navegación

### 7.6. Distribución de pedidos y detalle por estado

El gráfico circular presenta un total de **2,880 pedidos** y se acompaña de una tabla con cantidades, porcentajes y barras horizontales

| Categoría visible | Cantidad | Porcentaje mostrado |
|---|---:|---:|
| **Pagados** | 1,320 | 46% |
| **Despachados** | 740 | 26% |
| **Pendientes** | 426 | 15% |
| **Entregados** | 394 | 14% |

El gráfico permite reconocer la composición general y la tabla facilita una lectura precisa de las cantidades, ambos pertenecen al mismo bloque de consulta

**Pendientes** es una categoría de presentación del Dashboard y no sustituye por sí sola un estado de la máquina de pedidos, su agrupación deberá definirse al implementar los agregados

Las cantidades suman el total mostrado, los porcentajes están redondeados de manera independiente y por eso suman 101%, este detalle debe tenerse en cuenta al presentar la composición del periodo

---

## 8. Relación con las funcionalidades y los diagramas

### 8.1. Aporte de las funcionalidades del módulo

El Dashboard pertenece principalmente a **F6 — Gestión de reclamos, dashboard y reportes**, aunque la información que resume se origina en distintas funcionalidades

| Funcionalidad | Relación con el Dashboard |
|---|---|
| **F1 — Ciclo de vida del pedido** | Aporta los datos y eventos utilizados para consultar ventas y distribución de pedidos |
| **F2 — Anulación de pedidos** | Proporciona información para el indicador de anulaciones |
| **F3 — Devoluciones y cambios** | Aporta solicitudes y resoluciones utilizadas en el seguimiento de postventa |
| **F4 — Reembolsos y extornos** | Alimenta la información financiera de postventa cuando corresponde, aunque el Dashboard no presenta una tarjeta específica de reembolsos |
| **F5 — Calificación de experiencia** | Produce calificaciones y agregados de satisfacción utilizados en reportes, sin una tarjeta CSAT visible en este Dashboard |
| **F6 — Gestión de reclamos, dashboard y reportes** | Consolida indicadores y permite consultar reclamos y situaciones relacionadas con su atención |

### 8.2. Relación con la arquitectura del módulo

El diagrama de arquitectura interna ubica **F1 y F2 en M1 — Pedidos** y **F3, F4, F5 y F6 en M2 — Postventa**, por ello la ubicación de un indicador en el Dashboard no cambia la responsabilidad de la funcionalidad que genera sus datos

M1 conserva el control del pedido y publica eventos de dominio, M2 utiliza esa información para mantener los agregados de análisis y consulta

El diagrama de comunicación establece que la integración entre módulos se realiza mediante APIs y eventos, en consecuencia el frontend debe solicitar la información a los servicios autorizados sin acceder directamente a bases de datos ajenas

### 8.3. Relación con la máquina de estados del pedido

La distribución de pedidos resume información del ciclo de vida definido por F1, su propósito es mostrar la composición del periodo y no ejecutar transiciones

Presionar **Aplicar filtros**, **Limpiar**, **Ver** o **Ver todas** no debe cambiar un pedido a pagado, anulado o entregado, las operaciones sobre el pedido se realizan en las pantallas correspondientes y deben respetar las transiciones permitidas por M1

Esta separación mantiene la función de consulta del Dashboard y permite que el Gestor revise el contexto antes de realizar una acción operativa

---

## 9. Botones y navegación de la pantalla

### 9.1. Menú lateral y control de contracción

El menú presenta cuatro accesos principales y mantiene **Dashboard** destacado para identificar la sección actual

| Acceso | Destino funcional |
|---|---|
| **Dashboard** | Vista general de indicadores y casos prioritarios |
| **Pedidos** | Bandeja para consultar pedidos y acceder a su detalle |
| **Postventa** | Panel de entrada a los procesos de postventa |
| **Reportes** | Pantalla de calificaciones y reportes |

El botón con el icono de **tres líneas** contrae el menú a una versión compacta con iconos, al presionarlo nuevamente recupera la versión expandida con los nombres de las secciones

Este control modifica la presentación del menú y no aplica filtros ni cambia los datos de las tarjetas

**Alcance de las conexiones:** En el frame individual de **Page 1** está configurada la interacción de contraer y expandir el menú, los enlaces hacia **Pedidos**, **Postventa** y **Reportes** están conectados en la copia del Dashboard de la página **Mockup Flujo**, donde se presenta la navegación integrada del módulo

### 9.2. Relación entre las acciones del Dashboard

| Control | Acción del usuario | Resultado |
|---|---|---|
| **Periodo** | Abrir y seleccionar una opción | Preparar el intervalo de consulta |
| **Canal** | Abrir y seleccionar una opción | Preparar el origen de las ventas |
| **Aplicar filtros** | Confirmar ambos criterios | Mostrar el escenario correspondiente y cerrar los desplegables |
| **Limpiar** | Retirar los criterios | Vaciar los campos y recuperar la vista base |
| **Menú de tres líneas** | Contraer o expandir | Alternar la presentación del menú lateral |
| **Ver** | Seleccionar una fila de Atención prioritaria | Abrir la bandeja complementaria filtrada por tipo |
| **Ver todas** | Consultar el conjunto de casos | Abrir la bandeja complementaria con su vista general |

La relación principal entre los controles consiste en delimitar la consulta, interpretar sus resultados y decidir si se necesita revisar un caso con mayor detalle

El recorrido de seguimiento desde la página 1 es

**Dashboard → Ver o Ver todas → Atención prioritaria → Ver caso → Detalle del caso → Cerrar detalle → Atrás → Dashboard**

---

## 10. Consideraciones funcionales y de diseño

### 10.1. Requisitos funcionales relacionados

La consulta por periodo y canal responde al alcance de F6 y al contrato de reportes descrito en la especificación, la implementación debe devolver indicadores consistentes con los criterios aplicados

Atención prioritaria relaciona el monitoreo general con F6 para reclamos y con F3 para devoluciones y cambios, las decisiones sobre estos expedientes se mantienen en sus procesos específicos

Las etiquetas de SLA deben distinguirse de los estados del expediente, por ejemplo **Próximo a vencer** describe una condición de plazo y no una nueva transición del pedido

### 10.2. Requisitos no funcionales aplicables

| Requisito de la especificación | Aplicación en el Dashboard |
|---|---|
| **Rendimiento** | El Dashboard implementado debe responder en menos de 2 segundos con al menos 5,000 pedidos de prueba, utilizando agregados precalculados |
| **Seguridad** | La consulta debe estar protegida por token y por el acceso autorizado del Gestor |
| **Usabilidad** | Los filtros deben ser comprensibles y la jerarquía visual debe facilitar la lectura de indicadores y acciones |
| **Disponibilidad** | Una falla de consulta debe comunicarse de forma comprensible sin presentar información incompleta como si estuviera actualizada |
| **Mantenibilidad** | Los componentes de filtros, tarjetas y navegación deben conservar un comportamiento uniforme con las demás pantallas |

El mockup permite revisar la apariencia y las interacciones configuradas, el cumplimiento de rendimiento, seguridad y disponibilidad debe comprobarse posteriormente con el sistema integrado

La composición revisada corresponde a una vista de escritorio de **1440 × 1024**, la adaptación responsive requerida por la especificación debe verificarse en la implementación

### 10.3. Consistencia de los datos de demostración

Los indicadores y gráficos deben conservar la misma selección de periodo y canal cuando se integren con los servicios, también deben definirse las bases de cálculo del ticket promedio y de las tasas para evitar comparaciones entre conjuntos distintos

En la vista inicial existen identificadores con prefijo **RCL** para filas de devolución y cambio, mientras que la bandeja ampliada utiliza otros códigos, estos ejemplos deben armonizarse para que el usuario pueda reconocer un mismo expediente durante su recorrido

El acceso **Ver** del resumen actualmente selecciona un tipo de caso, por ello la navegación no garantiza la apertura del mismo código mostrado en la fila inicial

Tras utilizar **Limpiar** el prototipo contempla la vista base y las combinaciones completas de filtros, el comportamiento de una consulta con solo uno de los campos seleccionado deberá definirse para la implementación

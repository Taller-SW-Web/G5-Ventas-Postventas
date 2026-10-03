# Calificaciones y reportes

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Calificaciones y reportes  
**Página en Figma:** Page 9  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidades relacionadas:** F5 — Calificación de experiencia y F6 — Reclamos, dashboard y reportes

---

## 1. Contexto del mockup

La pantalla **Calificaciones y reportes** presenta la información de satisfacción y desempeño operativo del **Módulo D — Ventas y Postventa** desde una misma vista de análisis

Las calificaciones provienen de F5 y permiten conocer la percepción del cliente después de la entrega, F6 consolida esa información junto con los datos de pedidos y postventa para presentar indicadores y reportes

El mockup desarrolla la propuesta del wireframe mediante filtros desplegables, indicadores, gráficos y ventanas de consulta, también incorpora recorridos para comparar periodos y preparar una exportación

La página actual organiza el análisis alrededor de satisfacción, operación, comentarios y distribución por canal, su propósito es apoyar la revisión del Gestor sin modificar pedidos ni resolver expedientes desde los gráficos

> **Nota:** Los indicadores y comentarios son datos de demostración, las interacciones representan la consulta de la interfaz y no acreditan cálculos sobre una base de producción ni la descarga de archivos reales

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda reconocer cómo se relacionan la experiencia del cliente y los resultados operativos del periodo consultado

Los indicadores superiores ofrecen una lectura breve, los gráficos permiten revisar la distribución de calificaciones y el volumen de operaciones y las tablas complementan el análisis con comentarios y datos por canal

El usuario puede seleccionar criterios de consulta, abrir detalles y comparar los valores representados con un periodo anterior, después puede revisar el contenido previsto para la exportación

Esta organización permite pasar del resumen a la información específica sin abandonar el panel analítico

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien utiliza los reportes para consultar resultados y reconocer situaciones que requieren seguimiento

El Cliente participa de manera indirecta mediante las encuestas de F5, registra una puntuación de 1 a 5 y puede añadir un comentario después de una entrega confirmada

La página corresponde al backoffice y no contiene el formulario que utiliza el cliente para responder la encuesta

El acceso y la exportación deben validar los permisos del usuario, los datos consolidados deben conservar la segmentación por periodo y canal para que las consultas puedan interpretarse correctamente

Una calificación baja aporta información al análisis pero no cambia el estado del pedido ni crea automáticamente un reclamo

---

## 4. Estructura general de la interfaz

La pantalla organiza primero el resumen y después las áreas de análisis

| Zona | Función dentro de la pantalla |
|---|---|
| **Menú lateral** | Mantiene visibles las áreas generales y destaca Reportes |
| **Filtros y acciones** | Permiten seleccionar periodo, canal y vista y acceder a comparación o exportación |
| **Indicadores superiores** | Resumen satisfacción, pedidos, monto reembolsado y reclamos pendientes |
| **Satisfacción del cliente** | Presenta la distribución de puntuaciones y el promedio representado |
| **Desempeño operativo** | Compara el volumen de pedidos y operaciones de postventa |
| **Comentarios recientes** | Muestra respuestas cualitativas con acceso a una consulta ampliada |
| **Distribución por canal** | Presenta volumen y participación de Marketplace, Chatbot y Retail |
| **Vistas y ventanas de detalle** | Amplían la consulta sin modificar operaciones del módulo |

Las tarjetas blancas sobre el fondo claro separan las áreas, cada indicador utiliza un icono y un color de apoyo para facilitar su identificación

**Aplicar filtros** utiliza naranja como acción principal, **Comparar** conserva una presentación secundaria y **Exportar** se distingue mediante un fondo oscuro

La página incorpora vistas de satisfacción y operación que reemplazan el contenido central, las consultas de detalle utilizan ventanas superpuestas con un botón de cierre

---

## 5. Filtros y acciones de consulta

### 5.1. Selección de criterios

| Control | Opciones disponibles |
|---|---|
| **Periodo** | Septiembre 2026, Últimos 15 días y Agosto 2026 |
| **Canal** | Todos, Marketplace, Chatbot y Retail |
| **Reporte / Vista** | Vista general, Satisfacción y Operación Postventa |

Al pulsar un control se abre su desplegable, seleccionar una opción actualiza el valor mostrado y cierra el menú, abrir otro control cierra los anteriores

El periodo se selecciona mediante opciones preparadas y no mediante un calendario con fechas libres, la página actual tampoco presenta un filtro de vendedor

Los controles aparecen vacíos en la presentación inicial aunque el panel muestra datos de ejemplo, por ello seleccionar un criterio y aplicarlo constituye un paso distinto de observar el resumen inicial

### 5.2. Aplicar filtros

**Aplicar filtros** cierra los menús y actualiza las métricas y el contenido mediante escenarios preparados

La combinación **Septiembre 2026** con **Todos** utiliza el conjunto general del periodo, las demás combinaciones comparten un segundo conjunto de demostración con cifras y comentarios de Marketplace

Seleccionar **Satisfacción** y aplicar abre la vista especializada de calificaciones, las demás opciones conducen a la vista de operación en la interacción actual

La selección representa el comportamiento previsto de la consulta, no se ejecuta un cálculo independiente para cada combinación de periodo, canal y vista

### 5.3. Limpiar

**Limpiar** cierra los desplegables, restablece las cifras generales de demostración y devuelve el contenido a la vista general

Al terminar la interacción los tres controles quedan vacíos, el botón permite recuperar el punto de partida de la consulta sin modificar los registros que originan los indicadores

### 5.4. Comparar

**Comparar** abre la ventana **Comparar resultados**, presenta el periodo actual, el periodo anterior y el canal junto con una tabla de valores

La comparación incluye pedidos, entregados, anulados, devoluciones aprobadas, monto reembolsado, CSAT y reclamos pendientes

El ejemplo general utiliza **Agosto 2026** como periodo anterior, permite contrastar cifras como **5,420** pedidos actuales frente a **5,180** anteriores y **4.62 / 5** frente a **4.44 / 5** en satisfacción

La ventana muestra los valores disponibles en el prototipo y no solicita un nuevo periodo de comparación, **Cerrar** permite regresar al panel

### 5.5. Exportar

**Exportar** abre una ventana para revisar los filtros y las métricas que se incluirían en el reporte

El contenido se agrupa en pedidos y postventa e incluye volumen, entregados, anulaciones, devoluciones aprobadas, monto reembolsado, CSAT y reclamos pendientes

**Cerrar** permite regresar sin continuar, **Preparar** abre el mensaje **Exportación preparada** y **Finalizar** cierra ese mensaje para volver a la consulta

El recorrido representa la preparación del reporte, no se genera una descarga ni se selecciona un formato concreto, la implementación debe conservar los criterios y valores correspondientes a la consulta aplicada

---

## 6. Indicadores principales

La fila superior presenta cuatro indicadores

| Indicador | Ejemplo inicial | Finalidad |
|---|---:|---|
| **CSAT promedio** | 4.62 / 5 | Resume la puntuación de satisfacción representada |
| **Pedidos del periodo** | 5,420 | Presenta el volumen consolidado de pedidos |
| **Monto reembolsado** | S/ 5,890.50 | Muestra el importe representado en extornos del periodo |
| **Reclamos pendientes** | 3 | Identifica los casos pendientes de atención |

Estas tarjetas son informativas y no contienen acciones de navegación propias, los botones de consulta se encuentran en los bloques analíticos

El monto reembolsado representa dinero mientras que pedidos y reclamos representan cantidades, sus valores deben interpretarse según la unidad indicada

La página actual utiliza pedidos y reembolsos en lugar de los indicadores de ticket promedio e importe de ventas presentes en la propuesta anterior

---

## 7. Satisfacción del cliente

### 7.1. Distribución de calificaciones

El bloque **Satisfacción del cliente** presenta barras horizontales para las puntuaciones de 1 a 5

| Puntuación | Participación mostrada |
|---|---:|
| **5 estrellas** | 46% |
| **4 estrellas** | 28% |
| **3 estrellas** | 14% |
| **2 estrellas** | 8% |
| **1 estrella** | 4% |

La longitud de cada barra representa la participación de esa puntuación dentro de las respuestas, el gráfico permite reconocer tanto las valoraciones favorables como las críticas

El indicador circular presenta el promedio **4.62 / 5** y un **92%** de avance sobre el máximo de la escala, ese porcentaje no equivale directamente a la proporción de clientes que calificaron favorablemente

### 7.2. Ver detalle

**Ver detalle** abre la ventana **Detalle de satisfacción**, reúne el periodo, canal, promedio y distribución junto con información sobre la trazabilidad de las respuestas

La ventana explica que cada calificación conserva su pedido, canal y fecha y que el comentario aporta información opcional

También presenta las reglas de escala válida, control de duplicados y segmentación, estas reglas describen el tratamiento esperado y no constituyen una prueba de que el prototipo ejecute su validación

**Cerrar** devuelve al panel sin cambiar las calificaciones

### 7.3. Vista Satisfacción

Elegir **Satisfacción** en **Reporte / Vista** y aplicar muestra un análisis ampliado de calificaciones

La vista agrupa las respuestas como **Favorables**, **Neutras** y **Críticas** y conserva la distribución por estrellas y el promedio

Los porcentajes de ejemplo son **74%**, **14%** y **12%**, permiten resumir la lectura de las cinco puntuaciones en tres grupos

**Volver a vista general** recupera el panel con los bloques de satisfacción, operación, comentarios y canales y actualiza el selector de vista

---

## 8. Desempeño operativo

### 8.1. Gráfico de volumen

El bloque **Desempeño operativo** utiliza barras verticales para comparar las cantidades representadas

| Categoría | Ejemplo inicial |
|---|---:|
| **Pedidos** | 5,420 |
| **Entregados** | 4,980 |
| **Anulados** | 115 |
| **Devoluciones** | 45 |

Las etiquetas permiten conocer cada cantidad sin depender únicamente de la altura de las barras, estas categorías no deben sumarse como si fueran grupos independientes porque los entregados forman parte del total de pedidos y las devoluciones pertenecen al seguimiento de postventa

**Ver detalle** abre el desglose operativo con pedidos, entregados, anulados, devoluciones aprobadas, reembolsos, reclamos pendientes y CSAT

La ventana explica que la consulta utiliza agregados precalculados, **Cerrar** permite regresar al panel

### 8.2. Vista Operación Postventa

Elegir **Operación Postventa** y aplicar muestra tarjetas para pedidos totales, entregados, anulados, devoluciones aprobadas, monto reembolsado y reclamos pendientes

El bloque **Lectura del periodo** complementa esos datos con las tasas de entrega y anulación y con la cantidad de devoluciones aprobadas

El ejemplo presenta una tasa de entrega de **91.9%** y una tasa de anulación de **2.1%**, estos valores permiten interpretar proporciones además del volumen

**Volver a vista general** devuelve al panel principal, esta acción cambia la presentación de la consulta y no modifica las operaciones registradas

---

## 9. Comentarios y distribución por canal

### 9.1. Comentarios recientes

La tabla **Comentarios recientes** presenta fecha, canal, puntuación, comentario y acción de consulta

Combina valoraciones favorables con observaciones sobre demoras y seguimiento, esto permite complementar el promedio con la experiencia descrita por los clientes

**Ver todos** abre la ventana **Comentarios de clientes**, añade la referencia de pedido y presenta una lista más amplia de respuestas

Los botones **Ver** de las filas y la selección de esas filas conducen a la misma ventana general de comentarios, no abren un detalle individual diferente para cada respuesta

**Cerrar** retira la ventana y devuelve al panel, estas consultas no crean reclamos ni modifican las puntuaciones

La puntuación es obligatoria dentro del registro de F5 mientras que el comentario es opcional, una respuesta válida sin comentario debe seguir formando parte del cálculo

### 9.2. Distribución por canal

El bloque **Distribución por canal** presenta el total del periodo, el canal líder y la participación de cada canal mediante barras horizontales

| Canal | Pedidos iniciales | Participación mostrada |
|---|---:|---:|
| **Marketplace** | 2,560 | 47% |
| **Chatbot** | 1,740 | 32% |
| **Retail** | 1,120 | 21% |

Los pedidos suman **5,420** y los porcentajes se presentan redondeados, Marketplace figura como canal líder en el ejemplo

**Ver detalle** abre una tabla ampliada con pedidos, participación, CSAT y monto reembolsado por canal, **Cerrar** permite regresar al panel

La distribución permite comparar la participación de los canales en el periodo, su interpretación debe distinguirse de una consulta filtrada a un solo canal

La página actual no incluye una tabla de productos más vendidos ni una comparativa de vendedores, el análisis disponible se concentra en comentarios y canales

---

## 10. Origen y tratamiento de la información

F5 registra las calificaciones después de una entrega confirmada y conserva su relación con el pedido y el canal, cada respuesta válida aporta al cálculo de satisfacción

F6 utiliza agregados alimentados por eventos del módulo para presentar pedidos, anulaciones, devoluciones, reembolsos y seguimiento de reclamos

La pantalla debe consultar los datos consolidados por periodo y canal sin recorrer toda la base transaccional en cada ingreso, esta separación permite mantener la consulta analítica independiente del procesamiento de cada operación

Los valores del resumen, detalles, comparación y exportación deben referirse a los mismos criterios aplicados, cambiar una selección en el control antes de aplicarla no debe producir un reporte que combine encabezados nuevos con cifras de una consulta anterior

La distribución de estrellas y el promedio deben calcularse sobre el mismo conjunto de respuestas, las tasas y longitudes de las barras deben actualizarse junto con sus etiquetas

En el prototipo estas relaciones se representan mediante valores y escenarios preparados, no se ejecuta una agregación de registros reales

---

## 11. Relación con funcionalidades y navegación

| Funcionalidad o área | Relación con Calificaciones y reportes |
|---|---|
| **F5 — Calificación de experiencia** | Proporciona puntuaciones, comentarios y datos de satisfacción |
| **F6 — Reclamos, dashboard y reportes** | Consolida indicadores, consultas analíticas y exportaciones |
| **F1 — Ciclo de vida del pedido** | Aporta los eventos y referencias de pedidos utilizados en los agregados |
| **F2 — Anulación de pedidos** | Aporta información de anulaciones |
| **F3 — Devoluciones y cambios** | Aporta información de devoluciones y sus resoluciones |
| **F4 — Reembolsos y extornos** | Aporta el resultado y monto de las operaciones monetarias |
| **Dashboard** | Comparte el contexto de indicadores generales del módulo |

El recorrido comienza con la selección de periodo, canal y vista, después de aplicar el usuario puede consultar detalles, comparar resultados o revisar el contenido de exportación

Las ventanas utilizan **Cerrar** para regresar, la exportación concluye mediante **Finalizar** y las vistas especializadas utilizan **Volver a vista general**

El menú lateral destaca **Reportes** y su control permite cambiar la presentación de la barra, la instancia de esta página no contiene conexiones propias de navegación hacia las otras áreas

La pantalla no incluye una flecha de regreso en el encabezado, el retorno dentro del análisis se realiza mediante los controles de las vistas y ventanas

---

## 12. Consideraciones funcionales y de diseño

Los indicadores, gráficos y tablas deben conservar una lectura coherente para que el Gestor pueda relacionar el resumen con los detalles, la consulta y la exportación deben utilizar el mismo conjunto de datos

Los menús deben permanecer visibles sobre el contenido y las ventanas deben permitir un regreso claro al panel, las etiquetas y unidades deben acompañar los gráficos para facilitar su interpretación

La implementación debe validar las puntuaciones, evitar que respuestas duplicadas alteren el agregado y actualizar los indicadores mediante los servicios de F5 y F6

Para interpretar correctamente la demostración se consideran los siguientes alcances

- **Filtros iniciales:** Los controles aparecen vacíos aunque se muestran indicadores, conviene definir una selección inicial explícita para identificar el periodo y canal de esas cifras
- **Escenarios compartidos:** Aplicar filtros utiliza el escenario general de septiembre o un segundo escenario de Marketplace, no calcula cada combinación disponible
- **Selección de vista:** La opción Satisfacción abre su vista especializada mientras que las demás opciones aplicadas conducen a Operación Postventa, la vista general se recupera mediante los botones de retorno o Limpiar
- **Promedio y distribución:** Los porcentajes por estrellas mostrados equivalen a un promedio ponderado de 4.04 / 5 y no al 4.62 / 5 del indicador, ambos deben provenir del mismo conjunto de respuestas antes de validar el reporte
- **Porcentajes de satisfacción:** El 92% del círculo representa avance sobre el máximo y el 74% representa respuestas favorables en el ejemplo, la vista especializada incluye además un texto fijo de 94% que debe mantenerse coherente con la consulta
- **Gráficos y tasas:** Algunos porcentajes, tasas y dimensiones gráficas son valores preparados, deben actualizarse junto con las cantidades cuando cambian los filtros
- **Comparación preparada:** El periodo anterior utiliza Agosto 2026 en los escenarios inspeccionados, no se determina de forma independiente para todas las opciones de periodo
- **Comentarios ampliados:** Ver todos y Ver por fila abren la misma lista general, no representan una consulta individual del comentario seleccionado
- **Exportación simulada:** Preparar y Finalizar muestran una confirmación dentro del prototipo, no generan un archivo descargable

La versión implementada debe distinguir los criterios seleccionados de los ya aplicados y conservar la consistencia del periodo, canal, promedio, gráficos y datos exportados

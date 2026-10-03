# Hub Postventa

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Hub Postventa  
**Página en Figma:** Page 5  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidades relacionadas:** F3 — Devoluciones y cambios, F4 — Reembolsos y extornos y F6 — Gestión de reclamos, dashboard y reportes

---

## 1. Contexto del mockup

El Hub Postventa funciona como punto de entrada a los procesos de devolución, cambio, reclamo y reembolso del **Módulo D — Ventas y Postventa**

La pantalla presenta un resumen de la carga de atención y permite elegir el área en la que se desea trabajar, así el Gestor puede reconocer los pendientes antes de ingresar a una bandeja específica

El mockup organiza estos accesos mediante tarjetas de indicadores, botones de ingreso y un bloque de Atención prioritaria, su finalidad es conectar la consulta general con la gestión de los expedientes

La página 5 también contiene una pantalla complementaria de Atención prioritaria, en este documento se describe únicamente su relación con los accesos del Hub y el regreso al panel principal de Postventa

> **Nota:** Las cantidades y los casos mostrados son datos de demostración, la navegación de Figma representa el recorrido de la interfaz y no acredita operaciones reales sobre los servicios del módulo

---

## 2. Objetivo de la pantalla

El Hub busca que el Gestor pueda identificar qué procesos tienen casos pendientes y decidir por dónde comenzar su trabajo

Los indicadores ofrecen una lectura breve de las devoluciones, reclamos y reembolsos, los accesos centrales permiten ingresar a cada área y el bloque inferior orienta la revisión de los casos que necesitan atención prioritaria

Esta organización evita que el usuario tenga que recorrer todas las bandejas para reconocer el volumen general de trabajo, después de consultar el resumen puede ingresar directamente al proceso correspondiente

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien utiliza la consola interna para evaluar solicitudes, atender reclamos y revisar operaciones de reembolso

El Cliente inicia sus solicitudes desde los canales habilitados, el Hub reúne el acceso administrativo a esa información y no corresponde a una pantalla de autoservicio del cliente

En la implementación el acceso debe estar protegido por token y rol, las decisiones sobre expedientes y dinero deben validar los permisos establecidos para cada funcionalidad

Ingresar a un área desde el Hub no concede por sí mismo autorización para aprobar solicitudes o ejecutar reembolsos

---

## 4. Estructura general de la interfaz

La pantalla se organiza en cuatro zonas principales

| Zona | Función dentro del Hub |
|---|---|
| **Menú lateral** | Mantiene visibles los accesos generales del módulo y destaca Postventa |
| **Indicadores superiores** | Resumen devoluciones pendientes, reclamos abiertos y reembolsos en proceso |
| **Accesos a módulos** | Permiten ingresar a Devoluciones y cambios, Reclamos y Reembolsos |
| **Atención prioritaria** | Orienta la revisión de casos por plazo de atención y expedientes pendientes de evaluación |

Las tres áreas operativas se presentan en tarjetas del mismo tamaño para facilitar su identificación, cada una utiliza un icono y un color de apoyo que se repite en su indicador superior

Los botones **Ir al módulo** utilizan naranja para destacar la acción de ingreso, el botón **Ver casos prioritarios** tiene una presentación secundaria dentro del bloque de seguimiento

El Hub no contiene filtros de consulta, una tabla de expedientes ni formularios de decisión, esos controles se encuentran en las pantallas a las que se accede desde este panel

---

## 5. Indicadores principales y accesos desde las tarjetas

### 5.1. Resumen de la carga de atención

La fila superior presenta tres indicadores con una cantidad principal y una etiqueta de apoyo

| Indicador | Cantidad mostrada | Etiqueta complementaria |
|---|---:|---|
| **Devoluciones pendientes** | 12 | +2 hoy |
| **Reclamos abiertos** | 5 | 2 por SLA |
| **Reembolsos en proceso** | 3 | 1 por ejecutar |

Estas cifras permiten reconocer el volumen de casos representado en cada área, las etiquetas complementan la lectura sin reemplazar la revisión de los expedientes

**+2 hoy** representa una variación de ejemplo, **2 por SLA** destaca casos relacionados con el plazo de atención y **1 por ejecutar** señala una operación pendiente dentro del resumen de reembolsos

En el prototipo estos valores son fijos y no se recalculan a partir de la fecha actual ni de acciones realizadas en otras pantallas

### 5.2. Tarjeta Devoluciones pendientes

La tarjeta **Devoluciones pendientes** tiene una acción de clic que abre **Atención prioritaria** con el tipo **Devoluciones** seleccionado

Este acceso permite revisar una selección de casos de ese tipo dentro de la bandeja consolidada, no abre directamente el módulo completo de Devoluciones y cambios

Al ingresar se prepara la vista correspondiente y se cierran los desplegables de la pantalla de destino para iniciar la consulta desde un contexto definido

La cifra **12** resume el ejemplo del Hub y no debe confundirse con la cantidad de filas de la muestra de Atención prioritaria

### 5.3. Tarjeta Reclamos abiertos

La tarjeta **Reclamos abiertos** abre **Atención prioritaria** con el tipo **Reclamos** seleccionado

La etiqueta **2 por SLA** orienta la atención de los plazos, el acceso configurado selecciona el tipo de caso y no un expediente individual ni un filtro adicional exclusivo de vencimiento

Desde la bandeja complementaria el usuario puede revisar la situación de cada reclamo y consultar sus datos

### 5.4. Tarjeta Reembolsos en proceso

La tarjeta **Reembolsos en proceso** presenta la cantidad **3** y la etiqueta **1 por ejecutar**

En el frame individual de la página 5 esta tarjeta no tiene una acción de clic configurada, en la copia de **Mockup Flujo** está conectada con la pantalla **Reembolsos**

Ese acceso abre la bandeja del proceso y no ejecuta una devolución de dinero, la expresión **En proceso** funciona como un resumen operativo cuya agrupación debe definirse al integrar los datos

---

## 6. Accesos a los procesos de postventa

### 6.1. Devoluciones y cambios

La tarjeta **Devoluciones y cambios** presenta el distintivo **12 pendientes** y el botón **Ir al módulo**

En el flujo integrado el botón conduce a la bandeja donde se consultan las solicitudes y se revisan sus datos, evidencia y condiciones de evaluación

Este recorrido corresponde a F3, que diferencia un cambio de producto de una devolución que puede originar un reembolso, las decisiones se realizan en esa pantalla y no desde el Hub

El pedido debe cumplir las condiciones de entrega y elegibilidad antes de resolver una solicitud, ingresar al módulo no implica aprobar automáticamente el caso

### 6.2. Reclamos

La tarjeta **Reclamos** presenta **5 abiertos** y el botón **Ir al módulo**

En el flujo integrado este botón abre la bandeja de reclamos, donde el Gestor puede revisar los expedientes, consultar el plazo de atención y continuar el registro de una respuesta

El acceso se relaciona con F6, que concentra la gestión de reclamos y el seguimiento de sus indicadores

Un reclamo puede tener un pedido asociado o corresponder a una queja sin relación directa con una compra, por ello este acceso no depende de seleccionar previamente un pedido en el Hub

### 6.3. Reembolsos

La tarjeta **Reembolsos** presenta **3 en proceso** y el botón **Ir al módulo**

En el flujo integrado el botón conduce a la bandeja de operaciones de reembolso para consultar su origen, monto, situación y acciones disponibles

Este proceso corresponde a F4 y requiere un origen válido, como una anulación con pago confirmado o una devolución aprobada que implique devolver dinero

El Hub no permite crear un reembolso aislado ni confirmar una operación financiera mediante el botón de ingreso

### 6.4. Relación entre las tarjetas y sus botones

| Área | Indicador superior | Botón de acceso al proceso |
|---|---|---|
| **Devoluciones y cambios** | Abre casos prioritarios del tipo Devoluciones | Ir al módulo abre la bandeja de Devoluciones y cambios en el flujo integrado |
| **Reclamos** | Abre casos prioritarios del tipo Reclamos | Ir al módulo abre la bandeja de Reclamos en el flujo integrado |
| **Reembolsos** | Abre Reembolsos en el flujo integrado | Ir al módulo abre esa misma bandeja |

Las tarjetas superiores de devoluciones y reclamos facilitan una consulta por prioridad, los botones centrales permiten ingresar al espacio de gestión de cada proceso

En la página individual los tres botones **Ir al módulo** están presentes en el diseño pero no tienen una conexión configurada, la navegación entre esas pantallas está disponible en **Mockup Flujo**

---

## 7. Atención prioritaria

### 7.1. Finalidad del bloque

El bloque **Atención prioritaria** presenta la indicación de revisar primero los reclamos por SLA y luego los expedientes pendientes de evaluación

Esta orientación permite comenzar por situaciones que requieren seguimiento del plazo y después continuar con la carga de evaluación de postventa

El SLA expresa el plazo de atención del reclamo, no representa un estado del pedido ni debe aplicarse automáticamente como la misma regla temporal para todos los tipos de expediente

### 7.2. Botón Ver casos prioritarios

**Ver casos prioritarios** abre la pantalla **Atención prioritaria** con su vista general preparada, a diferencia de los indicadores superiores de devoluciones y reclamos no restringe la entrada a un único tipo

El acceso restablece los criterios de esa pantalla y presenta la muestra consolidada de casos

La vista general de demostración incluye **seis casos**, distribuidos en **dos reclamos**, **dos devoluciones** y **dos cambios**, esta muestra no equivale al total de pendientes mostrado en las tarjetas del Hub

### 7.3. Consulta del caso y regreso

Desde Atención prioritaria el botón **Ver** permite consultar un detalle superpuesto con código, fecha, tipo, cliente, contexto, situación y prioridad

El control **×** cierra ese detalle y mantiene al usuario en la bandeja, la flecha **Atrás** de Atención prioritaria regresa al Hub Postventa

Este recorrido permite ampliar la consulta iniciada desde los indicadores o desde **Ver casos prioritarios** sin ejecutar una decisión sobre el expediente

Los filtros y las acciones internas de la bandeja complementaria corresponden a su propia pantalla, aquí se describe la continuidad necesaria para comprender los accesos del Hub

---

## 8. Relación con las funcionalidades y la arquitectura

### 8.1. Funcionalidades relacionadas

| Funcionalidad | Relación con el Hub |
|---|---|
| **F3 — Devoluciones y cambios** | Proporciona el contexto de solicitudes que deben evaluarse y resolverse |
| **F4 — Reembolsos y extornos** | Proporciona el contexto de las operaciones financieras de postventa |
| **F6 — Gestión de reclamos, dashboard y reportes** | Aporta la consulta de reclamos y el seguimiento de sus indicadores y plazos |
| **F1 — Ciclo de vida del pedido** | Proporciona los datos y estados necesarios para validar los procesos relacionados con una venta |
| **F2 — Anulación de pedidos** | Puede originar una operación de reembolso cuando se anula un pedido pagado |

El Hub no constituye una nueva funcionalidad independiente, organiza el acceso a los procesos y presenta un resumen de su carga de trabajo

### 8.2. Separación entre M1 y M2

La arquitectura ubica F3, F4 y F6 dentro de **M2 — Postventa**, mientras que F1 y F2 pertenecen a **M1 — Pedidos**

M1 conserva el control del estado del pedido y M2 consulta sus datos o solicita las transiciones correspondientes mediante API, esta relación evita que un acceso desde Postventa modifique directamente el pedido

Los indicadores deben obtenerse desde los servicios y agregados autorizados, el frontend no debe recorrer bases de datos ajenas ni calcular la carga operativa a partir de las filas visibles de una muestra

### 8.3. Condiciones de los procesos

Las devoluciones y cambios requieren un pedido entregado y una evaluación de elegibilidad, los reembolsos requieren un origen válido y una ejecución idempotente y los reclamos necesitan una respuesta trazable y control del plazo

Estas condiciones se validan dentro de cada proceso, el Hub facilita el ingreso pero no reemplaza la revisión de los datos ni la autorización de las operaciones

---

## 9. Botones y navegación de la pantalla

### 9.1. Menú lateral

El menú presenta **Dashboard**, **Pedidos**, **Postventa** y **Reportes**, la opción **Postventa** permanece destacada para identificar la ubicación actual

El botón con el icono de **tres líneas** alterna entre el menú expandido con nombres y la versión compacta con iconos, esta interacción cambia su presentación y no modifica los indicadores

En el frame individual está configurada la contracción del menú, los accesos a Dashboard, Pedidos y Reportes están conectados en la copia del flujo integrado

### 9.2. Relación entre los controles

| Control | Resultado del acceso |
|---|---|
| **Devoluciones pendientes** | Abre Atención prioritaria con Devoluciones seleccionado |
| **Reclamos abiertos** | Abre Atención prioritaria con Reclamos seleccionado |
| **Reembolsos en proceso** | Abre Reembolsos en el flujo integrado |
| **Ir al módulo de Devoluciones y cambios** | Abre la bandeja de evaluación de solicitudes en el flujo integrado |
| **Ir al módulo de Reclamos** | Abre la bandeja de atención de reclamos en el flujo integrado |
| **Ir al módulo de Reembolsos** | Abre la bandeja de operaciones financieras en el flujo integrado |
| **Ver casos prioritarios** | Abre la vista general de Atención prioritaria |
| **Menú de tres líneas** | Contrae o expande el menú lateral |

El usuario puede comenzar por el indicador cuando necesita revisar prioridades o por **Ir al módulo** cuando desea ingresar directamente al proceso de gestión

### 9.3. Recorridos y regreso al Hub

El recorrido de revisión prioritaria es

**Hub Postventa → Indicador o Ver casos prioritarios → Atención prioritaria → Ver caso → Cerrar detalle → Atrás → Hub Postventa**

El recorrido de ingreso a un proceso es

**Hub Postventa → Ir al módulo → Devoluciones y cambios / Reclamos / Reembolsos → Atrás → Hub Postventa**

En el flujo integrado las tres bandejas operativas tienen conectado su botón de regreso al Hub, el acceso **Postventa** del menú también permite retornar a este panel

Regresar al Hub no aprueba solicitudes, no cierra reclamos y no revierte operaciones financieras, solo cambia la pantalla que se consulta

---

## 10. Consideraciones funcionales y de diseño

### 10.1. Consistencia de los indicadores

Los valores de las tarjetas superiores y los distintivos de acceso deben corresponder al mismo alcance de consulta cuando se integren con los servicios

El sistema debe definir qué solicitudes se consideran pendientes, qué reclamos se consideran abiertos y qué operaciones forman parte del resumen de reembolsos en proceso

Las etiquetas **+2 hoy**, **2 por SLA** y **1 por ejecutar** deben calcularse con criterios claros, no deben interpretarse como resultados actuales mientras se utilicen los datos fijos del prototipo

Las cantidades de la bandeja de prioridad pueden representar una selección del total operativo, esa diferencia debe mantenerse comprensible para el usuario

### 10.2. Requisitos no funcionales aplicables

| Requisito | Aplicación en el Hub |
|---|---|
| **Seguridad** | Restringir el acceso a la consola y conservar la validación de permisos al ingresar a cada proceso |
| **Rendimiento** | Consultar resúmenes desde datos consolidados y mantener una navegación fluida |
| **Usabilidad** | Diferenciar los accesos por prioridad de los accesos a gestión y mantener un regreso claro al Hub |
| **Disponibilidad** | Comunicar una falla de consulta sin presentar valores incompletos como un resumen válido |
| **Mantenibilidad** | Reutilizar tarjetas, botones y navegación con un comportamiento uniforme |

La vista revisada tiene dimensiones de escritorio de **1440 × 1024**, la adaptación responsive y el funcionamiento de los servicios deben comprobarse con la aplicación integrada

### 10.3. Alcance del prototipo interactivo

La página individual permite revisar el Hub y sus conexiones con Atención prioritaria, la copia de **Mockup Flujo** completa los accesos a las bandejas operativas y la navegación general del módulo

Los indicadores no se actualizan automáticamente como resultado de decisiones tomadas en otras pantallas, esa sincronización debe implementarse mediante las consultas y eventos del sistema

El propósito del Hub es orientar la consulta y el ingreso a cada proceso, las aprobaciones, respuestas y ejecuciones financieras se mantienen en las pantallas específicas y deben respetar sus reglas de negocio

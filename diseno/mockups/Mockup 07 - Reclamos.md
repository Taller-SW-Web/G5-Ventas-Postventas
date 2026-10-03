# Reclamos

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Reclamos  
**Página en Figma:** Page 7  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F6 — Reclamos, dashboard y reportes

---

## 1. Contexto del mockup

La pantalla **Reclamos** concentra la consulta y atención administrativa de los reclamos registrados dentro del **Módulo D — Ventas y Postventa**

Pertenece a F6 y permite revisar el expediente, conocer la situación del plazo de respuesta y registrar la atención brindada al cliente

El mockup desarrolla la propuesta del wireframe con una bandeja interactiva, filtros desplegables, paneles de consulta y ventanas para responder o confirmar el cierre, estos elementos representan el recorrido del Gestor desde la selección del caso hasta su atención

El pedido asociado es opcional, una queja sobre la atención recibida puede registrarse sin vincularse a una compra específica, por ello la pantalla adapta el acceso al pedido según la información del expediente

Al ingresar se presenta la tabla en el área central, el detalle y los bloques complementarios aparecen después de pulsar **Ver** en uno de los reclamos

> **Nota:** Los nombres, fechas y reclamos mostrados son datos de demostración, las interacciones del prototipo no acreditan el envío de respuestas al cliente ni el registro de operaciones en los servicios del módulo

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda identificar los reclamos pendientes, comprender el problema presentado y emitir una respuesta con seguimiento del plazo de atención

La bandeja facilita una revisión general mediante el estado y el indicador SLA, el detalle reúne la información necesaria para atender el caso y el historial permite reconocer las etapas por las que ha pasado

La respuesta y el cierre se presentan como acciones distintas, primero se registra el contenido que debe conocer el cliente y después se confirma que el expediente fue atendido

Esta organización ayuda a conservar la trazabilidad de la atención y evita interpretar una respuesta pendiente como un reclamo ya resuelto

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien consulta los expedientes, inicia su atención y registra la respuesta correspondiente

El Cliente presenta el reclamo desde los canales habilitados, esta pantalla pertenece a la consola interna y no contiene el formulario de registro o seguimiento que utilizaría el cliente

La atención requiere revisar el motivo, la descripción y los datos de contacto antes de formular una respuesta, cuando existe un pedido asociado también corresponde consultar su contexto

En la implementación el acceso debe estar protegido por token y rol, las acciones de respuesta y cierre deben validar los permisos y las reglas del expediente en el servicio responsable

---

## 4. Estructura general de la interfaz

La interfaz separa la consulta de la bandeja del análisis de un reclamo seleccionado

| Zona | Función dentro de la pantalla |
|---|---|
| **Menú lateral** | Mantiene visibles Dashboard, Pedidos, Postventa y Reportes y destaca Postventa como área actual |
| **Encabezado** | Presenta el título Reclamos y la flecha de regreso |
| **Filtros superiores** | Agrupan búsqueda, estado y fecha de creación junto con las acciones de consulta |
| **Bandeja de reclamos** | Muestra los casos con ordenamiento, paginación y acceso al detalle |
| **Detalle del reclamo** | Reúne datos del cliente, motivo, fechas, plazo, descripción y respuesta |
| **Historial de atención** | Presenta las etapas de registro, atención y cierre del expediente |
| **Archivos** | Permite consultar el formato representado para el reclamo |
| **Acciones disponibles** | Presenta los botones habilitados según la etapa de atención |

La vista inicial concentra la tabla en el centro, al seleccionar un reclamo aparece la distribución de revisión con el detalle, historial, archivos y acciones dentro de la misma pantalla

El fondo claro y las tarjetas blancas mantienen separados los bloques de información, la barra lateral oscura permite reconocer el contexto general del módulo

El naranja destaca **Aplicar filtros** mientras que las etiquetas de estado y SLA utilizan colores de apoyo, cada etiqueta conserva su texto para que la interpretación no dependa únicamente del color

---

## 5. Filtros y bandeja de reclamos

### 5.1. Controles de consulta

Los filtros se encuentran sobre la tabla y permiten preparar la consulta antes de abrir un expediente

| Control | Opciones y finalidad |
|---|---|
| **Buscar** | Representa la búsqueda por código de reclamo, pedido o cliente mediante coincidencias rápidas |
| **Estado** | Presenta Todos, REGISTRADO, EN PROCESO y ATENDIDO |
| **Fecha de creación** | Presenta Todos y los periodos 15–21 septiembre, 08–14 septiembre y 01–07 septiembre |
| **Aplicar filtros** | Confirma la selección y presenta la vista de resultados preparada |
| **Limpiar** | Restablece los controles y recupera la primera página de la bandeja |

Al pulsar **Buscar** se abre el listado de coincidencias rápidas, entre las opciones figuran códigos de reclamo, pedidos y nombres de clientes, seleccionar una opción actualiza el valor mostrado y cierra el menú

La búsqueda del prototipo se realiza mediante ejemplos seleccionables, no se representa la escritura libre de un texto ni una consulta a una base de datos

**Estado** permite elegir la etapa del reclamo y **Fecha de creación** ofrece periodos definidos, el icono de calendario identifica este último control aunque la interacción disponible corresponde a una lista y no a un calendario con fechas libres

Abrir un filtro cierra los demás desplegables, de esta manera el usuario puede concentrarse en una selección a la vez

### 5.2. Aplicar y limpiar

**Aplicar filtros** cierra los menús y devuelve la pantalla a la consulta de la tabla, la página revisada utiliza vistas de demostración y no resuelve de forma completa las combinaciones de búsqueda, estado y fecha

**Limpiar** vacía la búsqueda, devuelve **Estado** y **Fecha de creación** a **Todos** y restablece **Más recientes** con la primera página, también cierra la revisión del reclamo seleccionado

Ambos botones controlan la consulta de la bandeja, no cambian el estado de atención de los expedientes

### 5.3. Información de la tabla

La tabla permite identificar el caso y su prioridad antes de ingresar a la revisión

| Columna | Información mostrada |
|---|---|
| **Código / Fecha** | Identificador del reclamo y fecha de creación |
| **Pedido** | Código del pedido relacionado o un guion cuando no existe asociación |
| **Cliente** | Nombre de la persona que presenta el reclamo |
| **Motivo** | Razón principal de la solicitud |
| **Estado** | Etapa de atención del expediente |
| **SLA** | Condición del plazo de respuesta |
| **Acción** | Botón Ver para abrir el caso |

La primera página muestra cinco casos y el pie indica **Mostrando 1–5 de 14 reclamos**, se representan motivos como incumplimiento de plazo, cobro indebido, atención inadecuada y producto defectuoso

El expediente **REC-2026-0052** figura como **REGISTRADO** y **En plazo**, **REC-2026-0051** aparece **EN PROCESO** y **Próximo**, estas dos columnas permiten reconocer tanto la etapa del caso como su situación de atención

### 5.4. Ordenamiento, páginas y apertura

El selector **Más recientes** ofrece también **Más antiguos**, elegir una alternativa presenta la primera página del orden correspondiente

Los botones **1**, **2** y **3** permiten consultar los grupos de reclamos preparados, las flechas acompañan la navegación entre esas páginas

La segunda página presenta los casos del 6 al 10 y la tercera los casos del 11 al 14, entre ellos se incluyen expedientes con plazo vencido para representar distintas situaciones de atención

Cambiar de página o de orden cierra la revisión abierta, el usuario debe pulsar **Ver** para consultar un expediente de la nueva vista

**Ver** carga los datos del caso y muestra los paneles de revisión sin salir de la pantalla

---

## 6. Detalle del reclamo y control SLA

### 6.1. Datos del expediente

El panel **Detalle del reclamo** reúne la información necesaria para comprender el caso seleccionado

- Código del reclamo
- Pedido asociado cuando existe
- Cliente
- Motivo
- Fecha de creación
- Fecha límite de respuesta
- Estado actual
- Condición SLA
- Datos de contacto
- Descripción del problema
- Respuesta registrada

Al abrir **REC-2026-0052** se presenta el reclamo de **Lucía Fernández** relacionado con **PED-2026-1050**, el motivo es **Incumplimiento de plazo** y la respuesta se muestra como **Pendiente de respuesta formal**

El control de cierre del detalle oculta los paneles de revisión y recupera la presentación central de la bandeja, cerrar la vista no cambia la situación del reclamo

Seleccionar otro caso carga sus propios datos, antes de responder conviene comprobar el código, el cliente y el motivo para evitar atender un expediente distinto

### 6.2. Lectura del plazo de atención

El indicador **SLA** representa la situación del reclamo respecto de su fecha límite de respuesta

| Etiqueta | Interpretación dentro del mockup |
|---|---|
| **En plazo** | El expediente se presenta dentro del periodo de atención |
| **Próximo** | El caso requiere prioridad por su cercanía al vencimiento |
| **Vencido** | El expediente continúa pendiente y se representa fuera del plazo |
| **Cumplido** | La atención se presenta como realizada dentro del plazo |
| **Excedido** | El reclamo aparece atendido con el plazo excedido |

El estado describe la etapa del expediente y el SLA describe el cumplimiento del plazo, un reclamo puede estar **EN PROCESO** y tener un SLA **Vencido** sin que esto constituya una etapa adicional de su ciclo de vida

El detalle muestra la fecha límite para apoyar la priorización, los valores del prototipo son ejemplos fijos y no corresponden a un contador que se recalcula con la fecha actual

En la implementación el plazo debe calcularse conforme a la regla definida para el proyecto y conservarse junto con la fecha efectiva de atención

---

## 7. Historial de atención

El bloque **Historial de atención** presenta tres momentos del recorrido del expediente

| Etapa | Información representada |
|---|---|
| **Reclamo registrado** | Generación del código y cálculo del plazo |
| **Atención en proceso** | Inicio del análisis por parte del Gestor |
| **Reclamo atendido** | Registro de la respuesta formal como parte del cierre |

Los casos preparados muestran fechas y horas en las etapas que ya han ocurrido, las etapas pendientes utilizan un guion para indicar que todavía no cuentan con un registro de demostración

**Iniciar atención** actualiza el estado y la representación del historial, **Confirmar cierre** destaca la etapa de reclamo atendido

El historial complementa el detalle porque permite reconocer cómo avanzó la atención, en el sistema implementado debe conservar los eventos anteriores y registrar el responsable y la fecha de cada acción

Las nuevas acciones del prototipo utilizan textos preparados como **Atención iniciada por el Gestor** o **Respuesta registrada en UTC**, estos textos representan el evento y no acreditan la captura de una fecha y hora real

---

## 8. Respuesta y archivos

### 8.1. Respuesta visible al cliente

El campo **Respuesta** del detalle muestra si el reclamo está pendiente de respuesta o si ya cuenta con un contenido registrado

**Responder reclamo** abre una ventana que indica que la respuesta será visible para el cliente y quedará trazable, el área **Respuesta visible al cliente** presenta el contenido que se guardará

El ejemplo utiliza el texto **Se revisó el caso y se comunicó una respuesta formal al cliente**, al pulsar **Guardar respuesta** ese contenido se incorpora al detalle

La implementación debe permitir una respuesta específica para el caso y exigir que exista un contenido válido antes del cierre, guardar un texto de demostración no equivale a enviar una comunicación real al cliente

### 8.2. Formato del reclamo

El bloque **Archivos** presenta una tarjeta de **Formato / respuesta del reclamo**, pulsarla abre la misma vista previa utilizada por **Generar PDF**

La ventana muestra el código, pedido, cliente, motivo, estado y respuesta del expediente abierto, estos valores están vinculados con la información seleccionada en el detalle

Si se consulta el formato antes de guardar una respuesta se muestra la condición pendiente, después de guardarla la vista previa incorpora el texto registrado

**Cerrar** permite regresar al expediente sin modificar su estado

En esta página se representa una vista previa del formato, no se ejecuta la descarga de un archivo PDF, la generación descargable debe conservar el contenido y la trazabilidad del caso en la implementación

---

## 9. Acciones disponibles

### 9.1. Botones según la etapa

Las acciones se adaptan al estado del reclamo y a la existencia de una respuesta

| Situación | Acciones principales representadas |
|---|---|
| **REGISTRADO** | Iniciar atención, Generar PDF y acceso al pedido cuando existe |
| **EN PROCESO sin respuesta guardada** | Responder reclamo, Generar PDF y acceso al pedido cuando existe |
| **EN PROCESO con respuesta guardada** | Responder reclamo, Generar PDF y Marcar como atendido |
| **ATENDIDO** | Consulta del expediente, Generar PDF y acceso al pedido cuando existe |

Cuando no existe un pedido asociado el bloque muestra **Sin pedido asociado** en lugar de ofrecer el retorno a un pedido

### 9.2. Iniciar atención

**Iniciar atención** se presenta para un reclamo **REGISTRADO**, al pulsarlo cambia el estado a **EN PROCESO** y actualiza la etapa representada en el historial

El botón se retira y se habilita **Responder reclamo**, esta transición indica que el caso fue tomado para su análisis y todavía requiere una respuesta

### 9.3. Responder reclamo

**Responder reclamo** abre la ventana de respuesta, **Cancelar** permite regresar sin aplicar el contenido y **Guardar respuesta** incorpora el texto preparado al expediente

Después de guardar se habilita **Marcar como atendido**, el estado se mantiene **EN PROCESO** hasta que el Gestor confirme el cierre

El botón de respuesta permanece disponible mientras el caso sigue en proceso, la interacción actual utiliza el mismo texto de ejemplo y no representa su edición libre

### 9.4. Generar PDF

**Generar PDF** abre el formato del expediente actual en una ventana superpuesta, el usuario puede revisar la información y utilizar **Cerrar** para continuar la atención

Este botón permite consultar el documento en distintas etapas del reclamo, no guarda la respuesta ni marca el caso como atendido

### 9.5. Marcar como atendido

**Marcar como atendido** abre una ventana de confirmación, el usuario puede pulsar **Cancelar** para continuar revisando el caso o **Confirmar cierre** para finalizar la atención representada

Al confirmar el estado cambia a **ATENDIDO**, se actualiza el historial y se retiran los botones de respuesta y cierre

El prototipo cambia el SLA a **Excedido** cuando el caso abierto estaba **Vencido**, para las demás condiciones lo presenta como **Cumplido**, esta operación ilustra el resultado y no calcula el cumplimiento a partir de una fecha real

En la implementación el cierre debe comprobar que la respuesta visible al cliente no esté vacía y conservar la fecha efectiva de atención, la ocultación de un botón en la interfaz no sustituye esa validación

### 9.6. Volver al pedido

**Volver al pedido** aparece cuando el reclamo contiene una referencia de compra, su propósito es conectar la atención con el detalle del pedido relacionado

En esta página individual abre un aviso con el destino previsto, el aviso se cierra al pulsarlo y no realiza el traslado efectivo a otra pantalla

Cuando el reclamo no tiene pedido asociado se muestra una indicación sin acción de navegación, esto permite atender quejas generales sin exigir una compra como condición de registro

---

## 10. Estados y consistencia funcional

El mockup utiliza los estados **REGISTRADO**, **EN PROCESO** y **ATENDIDO** para representar el avance de la atención

| Estado | Significado en el recorrido |
|---|---|
| **REGISTRADO** | El reclamo tiene un código y está pendiente de ser tomado para atención |
| **EN PROCESO** | El Gestor analiza el expediente y prepara o registra la respuesta |
| **ATENDIDO** | La respuesta se encuentra registrada y el cierre fue confirmado |

El recorrido principal es **REGISTRADO → EN PROCESO → ATENDIDO**, guardar la respuesta constituye un paso previo al cierre y no cambia por sí solo el estado a atendido

Las etiquetas **Próximo**, **Vencido**, **Cumplido** y **Excedido** pertenecen al control del plazo y se presentan en una columna distinta, esta separación facilita priorizar casos sin confundir su situación temporal con su estado

La página no incluye un botón ni un filtro para una etapa de derivación, el documento describe las acciones representadas en este recorrido de atención

---

## 11. Relación con funcionalidades y navegación

### 11.1. Relación con el módulo

| Funcionalidad o área | Relación con Reclamos |
|---|---|
| **F6 — Reclamos, dashboard y reportes** | Gestiona el expediente, su respuesta, el plazo y los indicadores de atención |
| **F1 — Ciclo de vida del pedido** | Proporciona el contexto del pedido cuando existe una referencia asociada |
| **Hub Postventa** | Funciona como punto de ingreso a la bandeja de reclamos |
| **Dashboard y Reportes** | Permiten consultar los indicadores derivados de la atención y del cumplimiento del plazo |
| **Canales de atención** | Reciben el registro del cliente y permiten comunicar o consultar su respuesta |

Reclamos pertenece a M2 — Postventa, la información del pedido se consulta mediante la integración con M1 y no requiere modificar directamente sus tablas

Los resultados de atención pueden alimentar los indicadores de F6, los servicios deben conservar contratos claros para consultar el expediente y comunicar los cambios que afectan al seguimiento del módulo

### 11.2. Recorrido dentro de la pantalla

El usuario localiza un caso en la bandeja y pulsa **Ver**, después consulta el detalle y el historial y utiliza la acción correspondiente a su etapa

Para un caso registrado inicia la atención, registra la respuesta y confirma el cierre, durante la revisión puede consultar el formato sin abandonar el expediente

**Cancelar** devuelve al panel desde las ventanas de respuesta y cierre, **Cerrar** retira la vista previa del formato y el control del detalle recupera la bandeja central

### 11.3. Regreso y menú lateral

La flecha del encabezado representa el regreso al **Hub Postventa**, en la página individual abre un aviso del destino preparado que se cierra al pulsarlo

El menú lateral mantiene el contexto de **Postventa** y su control permite cambiar entre las presentaciones expandida y compacta de la barra

Los accesos laterales de esta página no tienen conexiones propias hacia las demás áreas, su presencia identifica la estructura general del módulo mientras que los retornos entre pantallas se representan mediante avisos

---

## 12. Consideraciones funcionales y de diseño

La alta fidelidad permite recorrer las etapas de atención y reconocer la relación entre la respuesta, el historial y el cierre, la distribución mantiene la consulta general separada de la revisión del caso

Los desplegables deben permanecer visibles sobre la tabla y alineados con su control, las ventanas de respuesta, formato y cierre deben conservar una salida clara hacia el expediente

El servicio debe validar la respuesta y la autorización del Gestor antes de cerrar el reclamo, también debe registrar fechas, responsables y cambios de estado para conservar una atención auditable

El cálculo del SLA debe distinguir los expedientes pendientes de los ya atendidos, la evaluación del cumplimiento debe utilizar las fechas reales y la regla de plazo definida para el proyecto

Para interpretar la demostración se consideran los siguientes alcances

- **Filtros preparados:** Aunque existen opciones de búsqueda, estado y periodo, Aplicar filtros utiliza una selección simplificada entre las vistas de más recientes y más antiguos, no ejecuta todos los resultados específicos sugeridos por los controles
- **Respuesta de ejemplo:** Guardar respuesta utiliza un texto fijo y no representa la edición o validación de una respuesta personalizada
- **Formato en pantalla:** Generar PDF y la tarjeta de Archivos abren una vista previa vinculada al expediente, no producen una descarga
- **Fechas de demostración:** El historial y las etiquetas de plazo utilizan valores preparados, no acreditan un cálculo de tiempo ni una bitácora real
- **Cambios del detalle:** Las acciones actualizan el panel y sus botones, no representan una modificación persistente de todos los registros de la bandeja
- **Retorno entre pantallas:** La flecha de regreso y Volver al pedido muestran avisos de los destinos previstos en la página individual

La implementación debe conservar la coherencia entre la tabla, el expediente y el formato, un caso atendido debe mostrar la misma respuesta y situación de plazo en todas sus consultas

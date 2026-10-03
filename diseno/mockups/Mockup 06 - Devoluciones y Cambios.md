# Devoluciones y cambios

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Devoluciones y cambios  
**Página en Figma:** Page 6  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F3 — Devoluciones y cambios

---

## 1. Contexto del mockup

La pantalla **Devoluciones y cambios** reúne las solicitudes de postventa que requieren revisar un producto recibido por el cliente, permite consultar el expediente y decidir cómo atenderlo según el motivo presentado

Forma parte de M2 — Postventa y diferencia dos resultados principales, el cambio de producto y la devolución que puede originar un reembolso

El mockup desarrolla la propuesta del wireframe mediante una bandeja interactiva, filtros desplegables, paneles de revisión y ventanas de confirmación, estos elementos permiten representar el recorrido del Gestor desde la búsqueda de una solicitud hasta su resolución

Al ingresar se presenta la tabla de solicitudes en el área central, los paneles del expediente aparecen después de seleccionar **Revisar**, así el usuario puede comenzar por localizar un caso y luego concentrarse en su evaluación

> **Nota:** Los expedientes y archivos mostrados son ejemplos de demostración, las interacciones representan el comportamiento de la interfaz y no ejecutan operaciones reales sobre pedidos, stock, despachos o dinero

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda localizar una solicitud, comprender su contexto y resolverla con la información necesaria a la vista

La tabla ofrece una lectura general del tipo de solicitud y su estado, el detalle permite revisar el pedido y el motivo mientras que la evidencia y el bloque de evaluación ayudan a sustentar la decisión

Los botones de resolución se presentan según la etapa del expediente, una solicitud recién registrada necesita iniciar su evaluación antes de aprobarse o rechazarse, un caso aprobado habilita la acción que corresponde a su resolución

Esta secuencia organiza la atención y permite distinguir la revisión del caso de las acciones necesarias para ejecutar un cambio o gestionar la devolución del dinero

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien consulta los expedientes y toma las decisiones administrativas de postventa

El Cliente presenta la solicitud desde su canal de atención, esta pantalla corresponde a la gestión interna del caso y no incluye un formulario para que el cliente registre directamente una devolución

Para evaluar la elegibilidad se debe comprobar que el pedido haya sido entregado, que la solicitud cumpla el plazo definido y que cuente con un motivo válido, cuando el motivo exige evidencia también corresponde verificar los archivos adjuntos

En la implementación estas condiciones deben validarse en los servicios del módulo junto con el token y el rol del usuario, la presencia de un botón en la interfaz no reemplaza la autorización para ejecutar la operación

---

## 4. Estructura general de la interfaz

La pantalla se organiza en zonas que acompañan las dos tareas principales del usuario, consultar la bandeja y revisar un expediente

| Zona | Función dentro de la pantalla |
|---|---|
| **Menú lateral** | Identifica las áreas Dashboard, Pedidos, Postventa y Reportes y destaca Postventa como contexto actual |
| **Encabezado** | Presenta el nombre de la pantalla y la flecha de regreso |
| **Filtros superiores** | Agrupan la búsqueda y los criterios de estado, tipo y canal |
| **Bandeja de solicitudes** | Muestra los expedientes con ordenamiento, paginación y acceso a revisión |
| **Detalle del expediente** | Reúne los datos del caso seleccionado y permite cerrar la revisión |
| **Evidencia** | Ofrece acceso a la fotografía y al comprobante asociados al caso |
| **Resolución / evaluación** | Resume la propuesta de atención y sus condiciones operativas |
| **Acciones disponibles** | Presenta las decisiones y los pasos habilitados según el estado |

La vista inicial aprovecha el espacio central para mostrar la tabla, al abrir un expediente se utiliza una distribución con la bandeja y los paneles de revisión dentro de la misma pantalla

El fondo claro y las tarjetas blancas separan los bloques de contenido, los bordes suaves ayudan a reconocer cada área sin recargar la vista

El naranja destaca acciones principales como **Aplicar filtros**, los botones secundarios conservan una presentación más discreta y las etiquetas de estado combinan texto y color para facilitar su lectura

---

## 5. Filtros y bandeja de solicitudes

### 5.1. Búsqueda y selección de criterios

Los filtros se encuentran sobre la tabla para que el Gestor pueda preparar la consulta antes de abrir un expediente

| Control | Opciones y finalidad |
|---|---|
| **Buscar** | Representa la búsqueda por código de expediente, pedido o cliente mediante coincidencias rápidas |
| **Estado** | Incluye Todos, SOLICITADA, EN EVALUACIÓN, APROBADA, RECHAZADA y COMPLETADA |
| **Tipo** | Permite elegir Todos, Cambio o Devolución |
| **Canal** | Permite elegir Todos, Marketplace, Chatbot o Retail |
| **Aplicar filtros** | Confirma los criterios seleccionados y presenta una vista de resultados |
| **Limpiar** | Restablece la búsqueda y los filtros para recuperar la bandeja inicial |

Al pulsar **Buscar** se abre el listado de coincidencias rápidas, el usuario puede seleccionar una de las opciones preparadas y el valor elegido se muestra en el control, la interacción disponible corresponde a una selección de ejemplos y no a un buscador con escritura libre

Los controles **Estado**, **Tipo** y **Canal** abren su respectivo menú, seleccionar una opción actualiza el valor del filtro y cierra el desplegable, al abrir otro control se cierran los menús anteriores

**Aplicar filtros** cierra los desplegables y retira el detalle que pudiera estar abierto para mostrar los resultados en la bandeja, en esta página la consulta utiliza casos preparados y no resuelve todas las combinaciones posibles de criterios

**Limpiar** devuelve los filtros a **Todos**, vacía la búsqueda y restablece **Más recientes** junto con la primera página, también cierra la revisión del expediente para recuperar la vista general

### 5.2. Información presentada en la tabla

La tabla se titula **Solicitudes de devolución y cambio** y reúne los datos necesarios para identificar cada expediente antes de abrirlo

| Columna | Información mostrada |
|---|---|
| **Código / Fecha** | Identificador de la solicitud y fecha de registro |
| **Pedido** | Código del pedido relacionado |
| **Tipo** | Cambio o devolución |
| **Motivo** | Razón registrada para solicitar la atención |
| **Estado** | Etapa actual del expediente |
| **Acción** | Botón Revisar para consultar el caso |

La primera página presenta cinco registros y el pie indica **Mostrando 1–5 de 14 expedientes**, entre los ejemplos se encuentran solicitudes por talla incorrecta, producto defectuoso, color equivocado y producto dañado

El expediente **DEV-2026-0214** corresponde a un cambio en evaluación mientras que **DEV-2026-0213** representa una devolución solicitada, estos casos permiten recorrer etapas diferentes dentro de la misma interfaz

### 5.3. Ordenamiento y paginación

El selector **Más recientes** ofrece también la opción **Más antiguos**, al elegir una alternativa cambia el orden representado en la tabla y se vuelve al inicio de la bandeja correspondiente

Los botones **1**, **2** y **3** permiten consultar los grupos de expedientes preparados, las flechas del pie acompañan el recorrido entre páginas

Cambiar la página o el orden cierra el detalle abierto, por ello el Gestor debe seleccionar nuevamente **Revisar** cuando desea consultar un expediente de la nueva vista

### 5.4. Apertura de una solicitud

El botón **Revisar** carga los datos del expediente seleccionado y muestra los bloques de detalle, evidencia, evaluación y acciones

La fila del expediente también tiene una interacción de apertura, ambos accesos conducen a la revisión del mismo caso sin requerir que el usuario abandone la bandeja

---

## 6. Detalle del expediente

El panel **Detalle del expediente** permite comprobar que se está atendiendo la solicitud correcta antes de ejecutar una decisión

Presenta la siguiente información

- Código del expediente
- Pedido relacionado
- Estado actual
- Tipo de solicitud
- Cliente
- Canal de origen
- Fecha de entrega
- Motivo registrado
- Cantidad de archivos de evidencia

Al abrir **DEV-2026-0214** se muestra el pedido **PED-2026-1042**, el cliente **Ana López** y el motivo **Talla incorrecta**, el caso se presenta como un cambio en estado **EN EVALUACIÓN** con dos archivos de evidencia

La fecha de entrega aporta el contexto necesario para revisar la elegibilidad, el motivo y el tipo de solicitud permiten interpretar la resolución propuesta

El control de cierre del panel oculta la revisión y devuelve la tabla a su presentación central, cerrar el detalle no equivale a aprobar, rechazar o cancelar el expediente

Seleccionar otro registro carga la información de ese nuevo caso, por ello conviene verificar siempre el código y el pedido antes de confirmar una acción

---

## 7. Evidencia del cliente

El bloque **Evidencia** presenta dos tarjetas de consulta, una para la fotografía del producto y otra para el comprobante adjunto

| Botón | Comportamiento en el mockup |
|---|---|
| **Ver foto** | Abre una ventana con la vista previa de evidencia visual |
| **Abrir PDF** | Abre una ventana con la representación del comprobante de compra |
| **Cerrar** | Cierra la vista previa y permite continuar la revisión del expediente |

Estas ventanas se muestran sobre la pantalla actual, el usuario puede revisar el archivo y regresar al panel sin perder de vista el proceso que está atendiendo

La fotografía sirve de apoyo para comprobar el estado del producto, el comprobante aporta información de respaldo sobre la compra

En una solicitud por producto defectuoso o dañado la evidencia debe revisarse antes de decidir, la cantidad de archivos indicada en el detalle no garantiza por sí sola que estos sean suficientes o válidos

Las vistas previas del prototipo utilizan contenido de ejemplo, en la implementación cada archivo debe corresponder al expediente seleccionado y contar con los permisos de consulta adecuados

---

## 8. Resolución y evaluación

El panel **Resolución / evaluación** resume cómo se propone atender el caso y qué condiciones intervienen en su ejecución

| Campo | Función en la evaluación |
|---|---|
| **Resolución** | Indica si el caso está pendiente o si corresponde un cambio, reembolso o rechazo |
| **Stock cambio** | Presenta la disponibilidad representada para atender un cambio |
| **Logística** | Identifica la coordinación de recojo o nuevo despacho según el caso |
| **Reembolso** | Indica si la devolución de dinero aplica y su relación con F4 |

Para el cambio **DEV-2026-0214** se representa una resolución **CAMBIO** con stock disponible y nuevo despacho, el reembolso aparece como **No aplica**

Cuando se aprueba un cambio desde el panel de acciones la logística pasa a **Pendiente coordinación**, esto permite distinguir la autorización de la solicitud del paso posterior de coordinar su atención

Cuando se aprueba una devolución el prototipo presenta la resolución **REEMBOLSO** y el indicador **Pendiente F4**, en ese momento se habilita la derivación hacia la funcionalidad encargada de gestionar el dinero

El cambio requiere comprobar la disponibilidad del producto y coordinar un nuevo despacho, la devolución con dinero debe contar con un origen aprobado antes de continuar hacia F4

Ambas resoluciones son excluyentes para un mismo expediente, la interfaz debe mostrar la acción que corresponde al resultado de la evaluación

---

## 9. Acciones disponibles

### 9.1. Acciones según el estado

El bloque **Acciones disponibles** cambia según el expediente abierto, no todos los casos presentan los mismos botones

| Situación del expediente | Acciones representadas |
|---|---|
| **SOLICITADA** | Iniciar evaluación y Volver al pedido |
| **EN EVALUACIÓN** | Aprobar solicitud, Rechazar solicitud y Volver al pedido |
| **APROBADA con resolución de cambio** | Coordinar cambio y Volver al pedido |
| **APROBADA con resolución de reembolso** | Derivar a reembolso y Volver al pedido |
| **RECHAZADA o cambio completado** | Consulta del resultado y Volver al pedido |

### 9.2. Iniciar evaluación

**Iniciar evaluación** cambia el estado mostrado de **SOLICITADA** a **EN EVALUACIÓN** y reemplaza ese botón por las opciones de aprobación y rechazo

Este paso representa el inicio de la revisión administrativa, no implica que la solicitud ya cumpla todas las condiciones para aprobarse

### 9.3. Aprobar solicitud

**Aprobar solicitud** abre la ventana **Confirmar aprobación**, el usuario puede elegir **Cancelar** para regresar sin aplicar la decisión o **Confirmar** para continuar

Al confirmar el expediente pasa a **APROBADA** y se retiran los botones de evaluación, el tipo de solicitud determina la siguiente acción

- Para un **Cambio** se habilita **Coordinar cambio**
- Para una **Devolución** se habilita **Derivar a reembolso**

La aprobación y la ejecución se muestran como pasos distintos, aprobar una solicitud no acredita que el nuevo producto haya sido entregado ni que el dinero se haya devuelto

### 9.4. Rechazar solicitud

**Rechazar solicitud** abre la ventana **Confirmar rechazo** con un espacio para el fundamento de la decisión

El mockup presenta el texto de ejemplo **Evidencia insuficiente para validar la solicitud**, **Cancelar** cierra la ventana y **Confirmar rechazo** cambia el expediente a **RECHAZADA**

Después de confirmar se retiran las acciones de aprobación, cambio y reembolso, el panel conserva la consulta del resultado y el acceso al pedido

El fundamento debe ser obligatorio en la implementación para que la decisión sea comprensible y auditable, en esta página el texto está preparado y no se representa su edición ni una validación de campo vacío

### 9.5. Coordinar cambio

**Coordinar cambio** abre la ventana **Confirmar cambio**, **Cancelar** permite volver al expediente y **Confirmar** representa la coordinación del nuevo despacho

La interacción cambia el estado del panel a **COMPLETADA** y la logística a **Nuevo despacho coordinado**, luego retira el botón de coordinación

Este resultado corresponde a una simplificación del recorrido de demostración, el cierre real del expediente debe depender de las confirmaciones logísticas y de las condiciones establecidas para completar el cambio

### 9.6. Derivar a reembolso

**Derivar a reembolso** abre una ventana de confirmación para enviar el origen aprobado hacia F4

Al pulsar **Confirmar** el panel muestra **Origen enviado a F4** y oculta el botón de derivación, el expediente mantiene el estado aprobado representado en el detalle

La interacción permanece en esta pantalla y no abre la bandeja de Reembolsos, tampoco simula el abono del dinero, su finalidad es representar el envío del caso al proceso responsable

**Cancelar** cierra la ventana sin aplicar la derivación

### 9.7. Volver al pedido

**Volver al pedido** permite reconocer la relación entre el expediente y el detalle del pedido que originó la solicitud

En la página individual el botón abre un aviso con el destino previsto y el aviso se cierra al pulsarlo, la interacción no realiza el traslado efectivo hacia otra pantalla dentro de esta página

---

## 10. Relación con funcionalidades y navegación

### 10.1. Relación con los procesos del módulo

| Funcionalidad o área | Relación con Devoluciones y cambios |
|---|---|
| **F1 — Ciclo de vida del pedido** | Proporciona el estado y los datos necesarios para validar el pedido relacionado |
| **F3 — Devoluciones y cambios** | Gestiona la solicitud, la evidencia, la evaluación y su resolución |
| **F4 — Reembolsos y extornos** | Recibe el origen de una devolución aprobada cuando corresponde devolver dinero |
| **Productos y Ofertas** | Proporciona la disponibilidad necesaria para resolver un cambio |
| **Despacho y Entrega** | Participa en la coordinación del recojo o nuevo despacho |

F3 pertenece a M2 y consulta la información del pedido mediante la integración con M1, la gestión del expediente no debe modificar directamente las tablas del ciclo de vida del pedido

Las consultas y operaciones entre áreas deben utilizar los contratos de API y eventos definidos, esta separación mantiene la responsabilidad de cada proceso y permite seguir el origen de las decisiones

### 10.2. Recorrido dentro de la pantalla

El recorrido principal consiste en localizar la solicitud, pulsar **Revisar**, consultar el detalle y los adjuntos y utilizar la acción habilitada para su estado

Si el expediente está solicitado se inicia la evaluación, después se aprueba o rechaza y una aprobación habilita la coordinación del cambio o la derivación del reembolso

Las ventanas de confirmación permiten regresar mediante **Cancelar**, las vistas de evidencia utilizan **Cerrar** y el control del detalle devuelve al usuario a la bandeja

### 10.3. Regreso y menú lateral

La flecha del encabezado representa el regreso al **Hub Postventa**, en esta página abre un aviso de retorno preparado que se cierra al pulsarlo

El menú lateral mantiene visibles las áreas generales y destaca **Postventa**, su control de expansión permite cambiar la presentación de la barra lateral

En la página individual revisada los accesos laterales no contienen conexiones de navegación propias hacia las otras áreas, los destinos del recorrido general deben distinguirse de las interacciones de demostración disponibles aquí

---

## 11. Consideraciones funcionales y de diseño

La alta fidelidad permite reconocer la jerarquía de la información y recorrer varias etapas de atención, la tabla sirve para seleccionar el caso mientras que el detalle, la evidencia y las acciones concentran su revisión

Los desplegables deben mantenerse visibles sobre la bandeja y alineados con su control de origen, las ventanas de evidencia y confirmación deben permitir un regreso claro al expediente

La habilitación de acciones según el estado ayuda a orientar al Gestor, aun así el servicio debe validar nuevamente la elegibilidad, los permisos y la transición antes de registrar una decisión

Cada aprobación, rechazo o derivación debe conservar el usuario responsable, la fecha y el fundamento cuando corresponda, las operaciones que afectan stock, despacho o dinero deben tolerar reintentos sin duplicar sus efectos

Para interpretar correctamente la demostración se consideran los siguientes alcances

- **Consulta preparada:** Aplicar filtros muestra el caso de búsqueda de DEV-2026-0214 cuando se selecciona ese código y otro caso preparado para las demás selecciones, no representa una búsqueda completa por todas las combinaciones de estado, tipo y canal
- **Cambios en el panel:** Las decisiones actualizan los valores y botones del detalle, no representan una actualización persistente de todos los registros de la tabla
- **Fundamento de rechazo:** El texto está definido como ejemplo y no incluye edición o validación interactiva
- **Archivos de ejemplo:** Las vistas de foto y comprobante son representaciones preparadas, no demuestran la carga o recuperación de adjuntos reales por expediente
- **Coordinación de cambio:** La confirmación simplifica el cierre al marcar el caso como completado, la implementación debe esperar la condición de cierre que corresponda al proceso logístico
- **Retorno entre pantallas:** La flecha de regreso y Volver al pedido muestran avisos del destino previsto en esta página individual

Los datos de demostración también deben mantener coherencia entre las pantallas del módulo, antes de una aprobación real corresponde verificar que el pedido relacionado esté entregado y que la evidencia consultada pertenezca al caso abierto

La pantalla conserva una distinción necesaria para el proceso de postventa, evaluar la solicitud permite decidir su atención y ejecutar la resolución exige coordinar con el área responsable del producto, despacho o dinero

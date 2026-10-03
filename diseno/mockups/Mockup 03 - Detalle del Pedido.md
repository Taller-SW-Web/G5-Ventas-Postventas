# Detalle del pedido

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Detalle del pedido  
**Página en Figma:** Page 3  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidades relacionadas:** F1 — Ciclo de vida del pedido y F2 — Anulación de pedidos

---

## 1. Contexto del mockup

La pantalla Detalle del pedido reúne la información comercial y operativa de una venta para que el Gestor pueda revisar su situación antes de continuar con una acción

Dentro del recorrido del módulo se accede desde la Bandeja de pedidos mediante **Ver detalle completo**, esta vista amplía el resumen lateral y presenta los productos, los datos del cliente, el pago, el despacho y el historial de estados

El mockup desarrolla la propuesta del wireframe con tarjetas diferenciadas, una línea de estados y botones que cambian según el avance del pedido, así permite observar cómo se relacionan los datos con las acciones disponibles

Su relación principal es con F1, que administra el ciclo de vida del pedido, también se vincula con F2 cuando corresponde revisar una solicitud de anulación

> **Nota:** La pantalla utiliza el pedido PED-2026-1042 como ejemplo, los cambios de estado del prototipo son una simulación visual y no ejecutan operaciones sobre el backend ni sobre servicios de pago o despacho

---

## 2. Objetivo de la pantalla

El Detalle del pedido busca que el Gestor comprenda el contexto completo de una venta sin sobrecargar la bandeja principal

La información permite verificar qué productos se compraron, cuánto se pagó, dónde se realizará la entrega y en qué etapa se encuentra el pedido

El bloque de acciones relaciona esta lectura con el siguiente paso del proceso, mientras que el historial y las notas ayudan a reconocer qué cambió después de cada interacción

La pantalla también permite iniciar la revisión de anulación cuando el estado lo admite y regresar a Pedidos para continuar la consulta de otros registros

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien consulta esta información desde la consola interna del Módulo D

El Cliente y el Vendedor interactúan mediante los canales Marketplace, Chatbot y Retail, esta vista corresponde al seguimiento administrativo del pedido

En la implementación el acceso debe estar protegido por token y rol, las operaciones disponibles deben respetar los permisos del usuario y las reglas del ciclo de vida

M1 mantiene la responsabilidad de modificar el pedido, el frontend presenta la información y solicita las operaciones permitidas mediante los contratos del sistema

---

## 4. Estructura general de la interfaz

La pantalla se organiza en los siguientes bloques

| Zona | Función dentro del detalle |
|---|---|
| **Menú lateral** | Mantiene los accesos principales del módulo y destaca la sección Pedidos |
| **Encabezado y botón Atrás** | Identifican la pantalla y permiten reconocer el regreso a la bandeja |
| **Resumen superior** | Presenta código, estado, canal, fecha y total |
| **Datos del pedido** | Reúne cliente, referencia, registro, dirección y observación |
| **Ítems del pedido** | Muestra los productos y el resumen económico de la venta |
| **Pago** | Presenta método, confirmación y monto |
| **Despacho** | Muestra situación logística, guía, fecha estimada y dirección |
| **Historial de estados** | Identifica la etapa actual dentro del recorrido del pedido |
| **Acciones disponibles** | Presenta el siguiente avance y la opción de anulación cuando corresponde |
| **Notas / trazabilidad** | Resume la última actualización, el responsable y el movimiento reciente |

El contenido principal se concentra en la columna izquierda y el seguimiento del estado y las acciones se ubican a la derecha, esta separación permite revisar primero los datos y luego decidir cómo continuar

Las tarjetas blancas y los separadores organizan la información sobre un fondo claro, el color naranja destaca el botón principal y el estado actual de la línea de seguimiento

---

## 5. Resumen y datos del pedido

### 5.1. Resumen superior

Las cinco tarjetas superiores permiten identificar rápidamente el pedido que se está consultando

| Campo | Valor inicial del ejemplo |
|---|---|
| **Código** | PED-2026-1042 |
| **Estado** | PAGADO |
| **Canal** | Marketplace |
| **Fecha** | 18/09/2026 |
| **Total** | S/ 214.00 |

La tarjeta de estado cambia durante la simulación del avance del pedido, el código, canal, fecha y total permanecen como datos del caso de demostración

Estas tarjetas son informativas y no funcionan como botones para editar el pedido o cambiar de registro

### 5.2. Datos generales

El bloque **Datos del pedido** amplía el resumen con la información necesaria para reconocer al cliente y el destino de la compra

| Campo | Información mostrada |
|---|---|
| **Cliente** | Ana López |
| **Referencia** | REF-00123 |
| **Canal** | Marketplace |
| **Fecha de registro** | 18/09/2026 03:15 |
| **Dirección de entrega** | Av. Universitaria 123, Lima |
| **Observación** | Entrega estándar |

Los datos se presentan para consulta y no incluyen controles de edición en esta pantalla, permiten verificar el contexto antes de avanzar el estado o revisar una anulación

---

## 6. Ítems, pago y despacho

### 6.1. Ítems del pedido

La tabla permite revisar los productos y relacionar cantidades y precios con los importes mostrados

| Producto | SKU | Cantidad | Precio unitario | Descuento mostrado | Importe mostrado |
|---|---|---:|---:|---:|---:|
| **Zapatilla Urbana** | ZAP-001 | 1 | S/ 159.00 | S/ 0.00 | S/ 159.00 |
| **Polo Básico** | POL-002 | 2 | S/ 29.50 | S/ 5.00 | S/ 59.00 |

Debajo de la tabla se presenta el resumen económico

| Concepto | Importe |
|---|---:|
| **Subtotal** | S/ 218.00 |
| **Descuento** | − S/ 4.00 |
| **Total** | **S/ 214.00** |

El total coincide con el importe presentado en el resumen y en el bloque de pago, los valores de descuento de las filas y del resumen deben armonizarse antes de utilizar el ejemplo como cálculo definitivo

La tabla no incorpora acciones para modificar cantidades, eliminar productos o editar precios, su función es explicar el contenido de la venta

### 6.2. Pago

El bloque **Pago** presenta el método **Tarjeta Visa**, el estado **Confirmado** y el monto **S/ 214.00**

Esta información permite comprender por qué el pedido inicia la demostración en estado **PAGADO**, no incluye un botón para cobrar nuevamente ni para ejecutar un reembolso desde esta pantalla

Si una anulación pagada origina la devolución de dinero, el proceso debe continuar mediante F2 y F4 según las condiciones del módulo

### 6.3. Despacho

El bloque **Despacho** presenta el estado logístico, la guía o referencia, la fecha estimada y la dirección de entrega

En la vista inicial el estado logístico es **Pendiente de preparación** y la guía y la fecha estimada se muestran con un guion porque todavía no tienen un valor representado

Durante la simulación estos campos se actualizan junto con el avance del pedido

| Etapa | Estado logístico mostrado | Información complementaria |
|---|---|---|
| **PAGADO** | Pendiente de preparación | Sin guía ni fecha estimada en la vista inicial |
| **EN PREPARACIÓN** | En preparación | Se mantiene la dirección de entrega |
| **DESPACHADO** | Despachado | Se presenta GUI-2026-01042 y la fecha estimada 19/09/2026 |
| **ENTREGADO** | Entregado | Se conserva la información logística del caso |

En el sistema implementado la operación logística corresponde al Módulo E, sus notificaciones deben ser utilizadas por F1 para actualizar el pedido sin realizar cambios directos sobre datos ajenos

---

## 7. Historial de estados

El panel **Historial de estados** representa la secuencia principal del pedido

**CREADO → PAGADO → EN PREPARACIÓN → DESPACHADO → ENTREGADO**

La etapa actual se diferencia mediante un marcador naranja y una etiqueta **Estado actual**, al avanzar el pedido esta identificación se desplaza a la nueva etapa

La línea es informativa y no permite seleccionar directamente cualquier estado, el avance se realiza mediante el botón disponible para la etapa correspondiente

En la vista inicial el pedido se encuentra en **PAGADO**, después de las acciones de demostración puede pasar a **EN PREPARACIÓN**, **DESPACHADO** y **ENTREGADO**

Este panel muestra el recorrido principal y no todas las ramas de la máquina de estados, la anulación y otros resultados del proceso deben mantenerse coherentes con las reglas definidas para M1

El historial visual tampoco sustituye la bitácora completa, en la implementación cada transición debe registrar usuario, fecha y hora, estado anterior, estado nuevo y motivo cuando corresponda

---

## 8. Acciones disponibles y reglas de negocio

### 8.1. Botón Pasar a preparación

**Pasar a preparación** se muestra cuando el pedido está en **PAGADO**, al presionarlo el mockup cambia el estado a **EN PREPARACIÓN**

La interacción actualiza la tarjeta superior, el marcador del historial y el estado logístico a **En preparación**, también registra como movimiento reciente **Pedido enviado a preparación** y muestra la actualización **18/09/2026 03:22**

Después de este avance el botón principal cambia a **Marcar como despachado**, la opción de anulación permanece visible porque todavía corresponde revisar su elegibilidad

La transición representa el siguiente paso de un pedido cuyo pago ya está confirmado, no permite saltar directamente de pagado a entregado

### 8.2. Botón Marcar como despachado

**Marcar como despachado** aparece cuando el pedido se encuentra en **EN PREPARACIÓN**, al presionarlo cambia la representación a **DESPACHADO**

El mockup actualiza el resumen y el historial, incorpora la guía **GUI-2026-01042** y la fecha estimada **19/09/2026** y presenta el movimiento **Pedido entregado al operador logístico** con actualización **18/09/2026 11:40**

El siguiente botón pasa a ser **Marcar como entregado**, la acción de anulación se oculta y se presenta **Anulación no disponible**

Este botón permite demostrar la respuesta de la interfaz, en la aplicación el cambio debe ser validado por M1 y respaldado por la operación o notificación logística correspondiente

### 8.3. Botón Marcar como entregado

**Marcar como entregado** se presenta cuando el pedido está en **DESPACHADO**, al presionarlo la simulación cambia el estado a **ENTREGADO**

También actualiza el estado logístico a **Entregado**, desplaza el marcador del historial y registra **Entrega confirmada al cliente** con actualización **19/09/2026 16:25**

El botón de avance es reemplazado por el mensaje **Pedido entregado**, este mensaje informa el resultado y no tiene una acción de clic para continuar avanzando

La entrega habilita los procesos de postventa que correspondan según sus reglas, no significa que se genere automáticamente una devolución ni un reembolso

### 8.4. Botón Iniciar anulación

**Iniciar anulación** se presenta durante las etapas **PAGADO** y **EN PREPARACIÓN** del recorrido demostrado

En el frame individual de la página 3 este botón abre un aviso de **Solicitud de anulación** que se cierra automáticamente, en la copia de **Mockup Flujo** está conectado con la pantalla **Anulaciones**

Presionarlo inicia la revisión del caso y no cambia inmediatamente el pedido a **ANULADO**, F2 debe validar el estado, el motivo y la autorización que corresponda

Un pedido **EN PREPARACIÓN** requiere autorización expresa del Gestor, cuando ya está **DESPACHADO** o **ENTREGADO** la anulación desde F2 no está disponible

### 8.5. Relación entre los estados y los botones

| Estado representado | Acción principal visible | Opción de anulación |
|---|---|---|
| **PAGADO** | Pasar a preparación | Iniciar anulación |
| **EN PREPARACIÓN** | Marcar como despachado | Iniciar anulación con revisión de autorización |
| **DESPACHADO** | Marcar como entregado | Anulación no disponible |
| **ENTREGADO** | Pedido entregado como mensaje informativo | Anulación no disponible |

Los botones mantienen una relación directa con el estado actual, cada avance modifica la información de seguimiento y presenta la siguiente acción del recorrido

En el sistema real estas restricciones deben validarse nuevamente en el backend, ocultar un botón en la interfaz no reemplaza la validación de permisos y transiciones

---

## 9. Notas y trazabilidad

El bloque **Notas / trazabilidad** presenta la última actualización, el usuario responsable y el movimiento reciente

| Momento de la demostración | Última actualización | Movimiento reciente |
|---|---|---|
| **Vista inicial** | 18/09/2026 03:17 | Pago confirmado por pasarela |
| **Paso a preparación** | 18/09/2026 03:22 | Pedido enviado a preparación |
| **Paso a despacho** | 18/09/2026 11:40 | Pedido entregado al operador logístico |
| **Confirmación de entrega** | 19/09/2026 16:25 | Entrega confirmada al cliente |

El usuario responsable mostrado es **Gestor / Administrador**, las fechas y los movimientos están preparados como parte del ejemplo y no se generan a partir de la hora real de interacción

Este bloque ayuda a reconocer el efecto del último avance sin reemplazar el historial auditable de F1, en la implementación debe reflejar los datos registrados por el servicio

---

## 10. Relación con funcionalidades y navegación

### 10.1. Relación funcional

| Funcionalidad o componente | Relación con el detalle |
|---|---|
| **F1 — Ciclo de vida del pedido** | Proporciona los datos, valida las transiciones y conserva el historial |
| **F2 — Anulación de pedidos** | Evalúa la solicitud y coordina los efectos de una anulación permitida |
| **F3 — Devoluciones y cambios** | Utiliza el pedido entregado como contexto cuando se registra una solicitud de postventa |
| **F4 — Reembolsos y extornos** | Gestiona la devolución de dinero originada por una anulación pagada o una devolución aprobada |
| **F5 — Calificación de experiencia** | Se relaciona con la entrega para activar la encuesta de experiencia según el flujo previsto |
| **Módulo E — Despacho y Entrega** | Aporta la información y los eventos logísticos utilizados por F1 |

La arquitectura mantiene F1 y F2 dentro de **M1 — Pedidos**, las funciones de postventa pertenecen a M2 y solicitan los cambios de pedido mediante API cuando corresponde

La vista concentra información de estas relaciones sin acceder directamente a las bases de datos de otros módulos

### 10.2. Botón Atrás

La flecha ubicada junto al título identifica el regreso desde el detalle hacia la bandeja de Pedidos

En el flujo integrado este botón está conectado con **Pedidos** y la navegación está configurada para no reiniciar el desplazamiento al regresar, permite retomar la consulta sin utilizar una acción de avance del pedido

En el frame individual de la página 3 la flecha está presente como parte del diseño pero no tiene una conexión de navegación configurada

Regresar no representa una anulación ni una transición inversa del estado, la acción solo cambia la pantalla que se está consultando

### 10.3. Menú lateral

El menú conserva **Pedidos** destacado porque el detalle pertenece a ese recorrido y presenta los accesos a **Dashboard**, **Pedidos**, **Postventa** y **Reportes**

El botón de **tres líneas** permite contraer y expandir el menú, esta interacción cambia su presentación y no modifica los datos del pedido

Los accesos entre pantallas están conectados en **Mockup Flujo**, desde allí **Pedidos** permite volver a la bandeja y las demás opciones llevan a sus áreas correspondientes

### 10.4. Recorridos principales

El recorrido de consulta es

**Pedidos → Detalle rápido → Ver detalle completo → Detalle del pedido → Atrás → Pedidos**

La demostración del avance dentro del detalle sigue la secuencia

**PAGADO → Pasar a preparación → EN PREPARACIÓN → Marcar como despachado → DESPACHADO → Marcar como entregado → ENTREGADO**

La revisión de anulación se inicia mediante **Iniciar anulación** y continúa en **Anulaciones** dentro del flujo integrado, su disponibilidad depende de la etapa del pedido

---

## 11. Consideraciones funcionales y de diseño

### 11.1. Consistencia de la información

El resumen, el historial, el despacho y las notas deben representar el mismo estado después de cada acción, esta relación permite que el Gestor comprenda el efecto del avance sin encontrar información contradictoria entre bloques

La pantalla utiliza datos fijos del pedido de ejemplo, actualmente el código, cliente, productos e importes no se sustituyen por los de cualquier registro seleccionado en la bandeja

Al implementar la consulta será necesario conservar el identificador del pedido seleccionado y cargar toda la información correspondiente a ese registro

Los descuentos también requieren coherencia entre ítems y resumen, el ejemplo muestra **S/ 5.00** en la fila del polo y **S/ 4.00** como descuento general, por lo que no deben interpretarse como un cálculo definitivo ya validado

### 11.2. Requisitos no funcionales aplicables

| Requisito | Aplicación en la pantalla |
|---|---|
| **Seguridad** | Validar token, rol y permisos antes de consultar o solicitar una transición |
| **Rendimiento** | Cumplir el criterio de consulta de pedido en menos de 500 ms establecido para el sistema |
| **Trazabilidad** | Registrar usuario, fecha y hora, estados y motivo de los cambios realizados |
| **Usabilidad** | Mostrar el estado actual, diferenciar las acciones y mantener una salida clara hacia la bandeja |
| **Disponibilidad** | Informar los errores y conservar un estado coherente si falla una operación o dependencia |
| **Mantenibilidad** | Reutilizar los componentes de tarjetas, estados y navegación del módulo |

El diseño revisado corresponde a una vista de escritorio de **1440 × 1024**, la adaptación responsive y las condiciones de rendimiento y seguridad deben verificarse con la aplicación integrada

### 11.3. Alcance de la simulación

El mockup permite observar la secuencia de avance y la actualización coordinada de sus bloques, los botones de despacho y entrega representan el resultado de esas etapas y no demuestran una integración real con el operador logístico

Las fechas y los datos del caso son valores preparados, los cambios no acreditan persistencia ni la publicación de eventos de dominio

En la implementación M1 debe rechazar los saltos de estado no permitidos y comprobar que la operación se realizó correctamente antes de actualizar la vista, la simulación sirve para revisar cómo se comunica ese resultado al Gestor

# Reembolsos

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Reembolsos  
**Página en Figma:** Page 8  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F4 — Reembolsos y extornos

---

## 1. Contexto del mockup

La pantalla **Reembolsos** reúne las operaciones de devolución de dinero del **Módulo D — Ventas y Postventa**, permite consultar su origen y seguir las etapas necesarias para procesarlas

Pertenece a F4 y recibe solicitudes desde una anulación válida de F2 o una devolución aprobada de F3, el reembolso debe conservar esa referencia porque no se origina como una operación aislada

El mockup desarrolla la propuesta del wireframe mediante filtros desplegables, una bandeja interactiva, paneles de detalle y ventanas de confirmación, estas interacciones representan la autorización, ejecución, consulta de resultado y preparación de un reintento

Al ingresar se muestra la tabla en el área central, los paneles operativos aparecen después de seleccionar **Ver** en una operación

> **Nota:** Los códigos, montos y resultados son datos de demostración, las interacciones de Figma representan el recorrido de la interfaz y no ejecutan devoluciones reales de dinero

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda identificar el origen de un reembolso, comprobar su monto y reconocer qué paso corresponde según su situación actual

La tabla ofrece una consulta general mientras que el detalle reúne la referencia de pago, el tipo de monto y el resultado representado, la trazabilidad y el historial permiten relacionar la operación con su cliente y con las etapas de procesamiento

Los botones se adaptan al avance del caso, una solicitud pendiente de autorización presenta una acción distinta de una operación ya enviada cuyo resultado todavía no se ha confirmado

Esta organización facilita revisar la información antes de actuar y ayuda a evitar que una operación pendiente o fallida se interprete como un reembolso exitoso

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien revisa y procesa las operaciones habilitadas para su rol

Las solicitudes tienen dos posibles orígenes funcionales

- **F2 — Anulación de pedidos:** genera el origen del reembolso cuando una anulación válida corresponde a un pedido con pago confirmado
- **F3 — Devoluciones y cambios:** genera el origen cuando una devolución aprobada implica devolver dinero al cliente

F4 procesa el movimiento monetario a partir de ese origen, la pantalla no contiene un botón para crear un reembolso independiente ni para decidir nuevamente si procede la anulación o devolución

En la implementación el token y el rol deben validarse en los servicios, la autorización del movimiento debe quedar vinculada con el usuario responsable

---

## 4. Estructura general de la interfaz

La interfaz separa la consulta de la bandeja de la revisión de una operación específica

| Zona | Función dentro de la pantalla |
|---|---|
| **Menú lateral** | Identifica Dashboard, Pedidos, Postventa y Reportes y destaca Postventa como área actual |
| **Encabezado** | Presenta el título Reembolsos y la flecha de regreso |
| **Filtros superiores** | Agrupan búsqueda, estado, origen y fecha de creación |
| **Bandeja de reembolsos** | Presenta las operaciones con ordenamiento, paginación y acceso al detalle |
| **Detalle del reembolso** | Reúne el origen, monto, pago, autorización y resultado |
| **Trazabilidad** | Presenta cliente, canal y clave de idempotencia |
| **Historial del reembolso** | Representa las etapas de registro, autorización, envío y confirmación |
| **Acciones disponibles** | Muestra los pasos operativos y los accesos relacionados con el caso |

La tabla ocupa el área central durante la consulta inicial, al abrir una operación se muestra una distribución de revisión con los paneles complementarios dentro de la misma pantalla

El fondo claro y las tarjetas blancas separan las zonas de trabajo, el naranja destaca **Aplicar filtros** y las etiquetas combinan texto y color para diferenciar los estados

La alineación de las columnas permite comparar los datos de cada fila, el monto y el estado permanecen separados del botón **Ver** para facilitar la lectura de la operación antes de abrirla

---

## 5. Filtros y bandeja de reembolsos

### 5.1. Controles de consulta

Los filtros se encuentran sobre la tabla para preparar la consulta antes de revisar un reembolso

| Control | Opciones y finalidad |
|---|---|
| **Buscar** | Presenta coincidencias rápidas por código de reembolso, pedido o cliente |
| **Estado** | Incluye Todos, PENDIENTE, EXITOSO y FALLIDO |
| **Origen** | Incluye Todos, ANULACIÓN y DEVOLUCIÓN |
| **Fecha de creación** | Incluye Todos y los periodos 15–23 septiembre, 08–14 septiembre y 01–07 septiembre |
| **Aplicar filtros** | Confirma la consulta mediante las vistas preparadas del prototipo |
| **Limpiar** | Restablece los controles y recupera la bandeja inicial |

Al pulsar **Buscar** aparece un listado de coincidencias rápidas, seleccionar una opción actualiza el valor del control y activa la vista de búsqueda preparada para ese ejemplo

Entre las opciones se encuentran **REB-2026-0094**, **PED-2026-1052** y nombres como **María Torres**, el control representa una selección de ejemplos y no un buscador con escritura libre

**Estado**, **Origen** y **Fecha de creación** permiten elegir un criterio mediante un desplegable, al seleccionar una opción se actualiza el control y se cierra su menú

El icono de calendario identifica el filtro de fecha aunque la interacción utiliza periodos definidos, no se representa la selección libre de un rango en un calendario

Abrir uno de estos controles cierra los demás menús para mantener una sola selección visible

### 5.2. Aplicar y limpiar

**Aplicar filtros** cierra los desplegables y devuelve la pantalla a la consulta de la tabla, su interacción utiliza una selección simplificada entre la primera y la segunda página de demostración

Aunque los controles muestran criterios de búsqueda, la acción no ejecuta todas sus combinaciones, una selección de coincidencia rápida puede activar una vista específica que posteriormente cambia al pulsar **Aplicar filtros**

**Limpiar** vacía la búsqueda, restablece los filtros a **Todos** y devuelve el orden a **Más recientes** junto con la primera página, también cierra el detalle abierto

Ambos botones actúan sobre la consulta y no autorizan ni ejecutan operaciones monetarias

### 5.3. Información de la tabla

La bandeja se titula **Reembolsos** e incluye la descripción **Operaciones registradas**

| Columna | Información mostrada |
|---|---|
| **Código / Fecha** | Identificador de la operación y fecha de creación |
| **Pedido** | Pedido relacionado con el reembolso |
| **Cliente** | Persona asociada a la operación |
| **Origen** | Anulación o devolución que genera la solicitud |
| **Monto** | Importe representado en soles |
| **Estado** | PENDIENTE, EXITOSO o FALLIDO |
| **Acción** | Botón Ver para consultar el detalle |

La vista inicial presenta cuatro operaciones y el pie indica **Mostrando 4 resultados**, tres figuran como pendientes y una como fallida

El ejemplo **REB-2026-0094** corresponde a una anulación por **S/ 214.00**, **REB-2026-0093** corresponde a una devolución por **S/ 89.90** y **REB-2026-0091** representa una devolución fallida por **S/ 45.00**

### 5.4. Ordenamiento, paginación y apertura

El selector **Más recientes** ofrece también **Más antiguos**, elegir una alternativa activa la primera página del orden correspondiente

Los botones **1**, **2** y **3** y las flechas permiten recorrer las páginas de operaciones preparadas, cambiar la página o el orden cierra la revisión seleccionada

**Ver** carga los datos del reembolso y muestra los bloques de detalle, trazabilidad, historial y acciones sin abandonar esta pantalla

---

## 6. Detalle del reembolso

El panel **Detalle del reembolso** reúne los datos que permiten verificar la operación antes de continuar su procesamiento

- Código del reembolso
- Pedido relacionado
- Origen
- Monto
- Tipo de monto parcial o total
- Referencia de pago
- Identificador de operación
- Autorizador
- Resultado del simulador
- Fecha de creación
- Estado actual

Al abrir **REB-2026-0094** se presenta el pedido **PED-2026-1053**, el origen **ANULACIÓN** y el monto total de **S/ 214.00**, la referencia de pago es **PAY-2026-1053** y la operación está pendiente de autorización

El ejemplo **REB-2026-0093** muestra un monto parcial y una autorización ya registrada, por ello permite continuar directamente con la ejecución representada

El ejemplo **REB-2026-0092** conserva un identificador de operación y presenta un resultado externo aún no confirmado, esto permite distinguir un envío pendiente de confirmación de una solicitud que todavía no se ha ejecutado

El control de cierre del detalle oculta la revisión y recupera la bandeja central, cerrar el panel no cancela el reembolso ni cambia su estado

Seleccionar otra operación carga sus datos de demostración, el Gestor debe comprobar siempre el código, el origen y el monto antes de confirmar una acción

---

## 7. Historial y trazabilidad del reembolso

### 7.1. Historial de procesamiento

El bloque **Historial del reembolso** presenta cuatro etapas del recorrido

| Etapa | Información representada |
|---|---|
| **Solicitud registrada** | Referencia al origen, pago, monto y clave de idempotencia |
| **Autorización aprobada** | Registro de la autorización cuando corresponde |
| **Extorno enviado** | Envío de la operación al simulador |
| **Resultado confirmado** | Registro del resultado exitoso o fallido |

Los ejemplos incluyen fechas y horas para las etapas ya realizadas, las pendientes se muestran con un guion

Las acciones actualizan la etapa destacada y los textos del historial, estas actualizaciones ayudan a comprender el avance del caso durante la demostración

En la implementación el historial debe conservar los eventos anteriores y registrar los intentos realizados, un reintento no debe eliminar la evidencia del fallo previo

### 7.2. Datos de trazabilidad

El bloque **Trazabilidad** presenta el cliente, el canal y la **Clave idempotente** del expediente

Para **REB-2026-0094** se representan **Ana López**, **Marketplace** y la clave **IDEMP-REB-0094**, esta clave permite explicar que los intentos pertenecen a la misma operación

La referencia de pago relaciona el reembolso con la transacción original, el identificador de operación permite seguir el procesamiento y la clave de idempotencia permite reconocer solicitudes repetidas

Estos datos cumplen funciones distintas y deben conservarse durante el recorrido de autorización, ejecución y consulta

---

## 8. Procesamiento, simulador e idempotencia

F4 procesa la devolución del dinero mediante el simulador de pasarela definido para el proyecto, el mockup representa ese intercambio mediante cambios en el estado y en el resultado mostrado

Antes de ejecutar una operación corresponde verificar las condiciones del proceso

- El origen proviene de una anulación válida o una devolución aprobada
- Existe una referencia de pago original
- El monto y la moneda corresponden a la operación que se debe devolver
- El importe cumple los límites establecidos respecto del pago y los reembolsos previos
- La autorización está disponible cuando el caso la requiere
- La operación conserva una clave de idempotencia

El reembolso puede ser total o parcial según su origen, en esta pantalla el monto se consulta como un dato del expediente y no se edita mediante un formulario

La idempotencia significa que repetir una solicitud correspondiente a la misma operación no debe generar una segunda devolución de dinero, si el reembolso ya fue confirmado se debe recuperar su resultado

Un tiempo de espera agotado no demuestra por sí solo que la operación haya fallado, por ello el caso enviado permite **Consultar resultado** antes de plantear un nuevo procesamiento

El prototipo conserva visualmente la clave del expediente durante el reintento, la garantía de no duplicar movimientos debe implementarse en los servicios y en la integración con la pasarela

---

## 9. Acciones disponibles

### 9.1. Acciones según la situación operativa

Un mismo estado pendiente puede corresponder a diferentes etapas, los botones permiten reconocer el paso que sigue

| Situación del reembolso | Acción principal representada |
|---|---|
| **Pendiente de autorización** | Autorizar reembolso |
| **Autorizado y listo para procesar** | Ejecutar reembolso |
| **Enviado con resultado pendiente** | Consultar resultado |
| **FALLIDO** | Consultar resultado y Reintento seguro |
| **EXITOSO** | Consultar resultado |

Los grupos de acciones también mantienen **Volver al pedido** y **Ver expediente origen** para relacionar el movimiento con su contexto

### 9.2. Autorizar reembolso

**Autorizar reembolso** abre una ventana que solicita confirmar que el origen está aprobado y que el monto corresponde al pago original

**Cancelar** cierra la ventana sin aplicar cambios, **Confirmar autorización** registra al autorizador como **Gestor / Administrador** y muestra que la operación está lista para ejecutarse

La autorización actualiza el historial y habilita **Ejecutar reembolso**, el estado continúa **PENDIENTE** porque todavía no existe un resultado confirmado del extorno

### 9.3. Ejecutar reembolso

**Ejecutar reembolso** abre una ventana que indica que se conservará la misma clave idempotente del expediente

**Cancelar** permite regresar al detalle y **Ejecutar** representa el envío al simulador, después se muestra un identificador de operación de ejemplo y el resultado **Enviado al simulador · resultado pendiente**

La operación permanece **PENDIENTE**, se actualiza la etapa de envío y se habilita **Consultar resultado**

Ejecutar el envío y confirmar su éxito son pasos separados, el mensaje de envío no acredita que el dinero ya haya sido devuelto

### 9.4. Consultar resultado

**Consultar resultado** abre una ventana con el código, pedido, origen, monto, identificador de operación, estado y resultado del expediente

Para el grupo de operaciones enviadas la interacción representa una confirmación exitosa, cambia el estado del panel a **EXITOSO** y muestra **Extorno confirmado por el simulador**

En los casos fallidos o exitosos la acción abre la información que ya se encuentra representada en el expediente

**Cerrar** retira la ventana y permite continuar la consulta, el código, pedido, monto, identificador, estado y resultado están vinculados con los datos del reembolso seleccionado

### 9.5. Reintento seguro

**Reintento seguro** aparece para el caso fallido y abre una ventana que explica que se continuará con el mismo expediente y la misma clave de idempotencia

**Cancelar** mantiene la situación actual, **Preparar reintento** cambia el panel a **PENDIENTE** y muestra que el reintento fue preparado

Después se habilita **Ejecutar reembolso**, la preparación no envía automáticamente la operación y tampoco confirma su resultado

El recorrido continúa con la ejecución y la consulta, en la implementación debe verificarse si el fallo admite reintento y conservarse la evidencia de cada intento

### 9.6. Volver al pedido y ver expediente origen

**Volver al pedido** representa el acceso al detalle de la compra relacionada, **Ver expediente origen** representa la consulta de la anulación o devolución que generó el reembolso

En esta página individual ambos botones abren avisos de destino que se cierran al pulsarlos, no realizan el traslado efectivo a las otras pantallas

Los dos accesos aportan contextos diferentes, el pedido permite revisar la compra mientras que el expediente de origen permite comprender la decisión que justificó la devolución del dinero

---

## 10. Estados y consistencia funcional

El mockup utiliza los estados **PENDIENTE**, **EXITOSO** y **FALLIDO** para representar el resultado del procesamiento

| Estado | Interpretación |
|---|---|
| **PENDIENTE** | La operación todavía requiere autorización, ejecución o confirmación de resultado |
| **EXITOSO** | El resultado se presenta como confirmado por el simulador |
| **FALLIDO** | El expediente presenta un error de procesamiento y permite revisar el resultado |

La autorización y el envío se distinguen mediante los datos del detalle y los grupos de acciones, no se presentan como estados independientes de persistencia

El flujo de demostración permite autorizar, ejecutar y consultar hasta obtener un resultado exitoso, para un caso fallido permite preparar un reintento y continuar con el procesamiento

La pantalla utiliza únicamente **ANULACIÓN** y **DEVOLUCIÓN** como orígenes de consulta, esto mantiene la relación de F4 con los procesos F2 y F3

Un reembolso exitoso conserva la consulta del resultado y retira las acciones de ejecución y reintento, en el servicio también debe impedirse una segunda devolución para la misma operación

---

## 11. Relación con funcionalidades y navegación

### 11.1. Relación con los procesos del módulo

| Funcionalidad o área | Relación con Reembolsos |
|---|---|
| **F2 — Anulación de pedidos** | Proporciona el origen cuando una anulación válida involucra un pago confirmado |
| **F3 — Devoluciones y cambios** | Proporciona el origen cuando una devolución aprobada requiere devolver dinero |
| **F4 — Reembolsos y extornos** | Procesa la operación y conserva el resultado y su trazabilidad |
| **F1 — Ciclo de vida del pedido** | Proporciona el contexto del pedido y la referencia necesaria para validar la operación |
| **Simulador de pasarela** | Representa el procesamiento del extorno y su resultado |
| **Hub Postventa** | Funciona como punto de ingreso y regreso de la bandeja |

Reembolsos pertenece a M2 — Postventa, la consulta del pedido y las operaciones relacionadas deben utilizar los contratos de integración del módulo sin modificar directamente las tablas de M1

La referencia de origen debe mantenerse durante todo el recorrido para vincular el movimiento monetario con la decisión que lo generó

### 11.2. Recorrido dentro de la pantalla

El Gestor localiza una operación y pulsa **Ver**, revisa el monto, origen, pago e historial y utiliza el botón disponible para continuar su procesamiento

Las ventanas de autorización, ejecución y reintento permiten regresar mediante **Cancelar**, la ventana de resultado utiliza **Cerrar** y el control del detalle recupera la bandeja central

La flecha del encabezado representa el regreso al **Hub Postventa**, en esta página abre un aviso del destino previsto que se cierra al pulsarlo

El menú lateral mantiene el contexto de **Postventa** y permite cambiar la presentación de la barra mediante su control de expansión, los accesos generales de la instancia no contienen conexiones propias hacia las otras áreas en esta página individual

---

## 12. Consideraciones funcionales y de diseño

La pantalla debe permitir reconocer el origen, el monto y la situación operativa antes de ejecutar una acción, la separación entre autorización, envío y resultado facilita comprender qué ocurrió y qué permanece pendiente

Los desplegables deben mostrarse sobre la bandeja y alineados con su control, las confirmaciones deben conservar una salida clara hacia el detalle

El servicio debe validar la autorización, la referencia original y el importe permitido antes del procesamiento, la garantía de idempotencia y la conservación de los intentos corresponden al backend

Para interpretar la demostración se consideran los siguientes alcances

- **Consulta simplificada:** Aplicar filtros selecciona entre la primera y la segunda página preparada, no ejecuta todas las combinaciones de estado, origen y fecha
- **Búsqueda por ejemplos:** Las coincidencias rápidas activan vistas específicas al seleccionarse, no representan una consulta con texto libre
- **Procesamiento simulado:** Autorizar y Ejecutar actualizan los valores y botones del panel, no llaman a una pasarela real
- **Resultado preparado:** Consultar resultado en una operación enviada representa una confirmación exitosa fija, no recupera una respuesta externa
- **Origen en la ventana de resultado:** La etiqueta de origen conserva el ejemplo ANULACIÓN y no está vinculada al caso seleccionado, debe actualizarse también para las operaciones procedentes de una devolución
- **Reintento representado:** La clave permanece vinculada al expediente pero la interacción no demuestra una garantía real de idempotencia
- **Historial de ejemplo:** Las acciones utilizan textos preparados y el reintento reemplaza algunos valores de las etapas, la implementación debe conservar la bitácora completa y sus fechas reales
- **Cambios del detalle:** Los resultados del panel no representan una actualización persistente de todas las filas de la bandeja
- **Retorno entre pantallas:** Los accesos al pedido, expediente de origen y Hub Postventa muestran avisos de destino en la página individual

La implementación debe mantener coherencia entre la tabla, el detalle y el resultado consultado, cada operación debe conservar su origen y los datos necesarios para explicar cómo se procesó el dinero

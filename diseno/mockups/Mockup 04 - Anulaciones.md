# Anulaciones

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Anulaciones  
**Página en Figma:** Page 4  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidades relacionadas:** F2 — Anulación de pedidos y F1 — Ciclo de vida del pedido

---

## 1. Contexto del mockup

La pantalla Anulaciones reúne las solicitudes de cancelación de pedidos y permite al Gestor revisar su situación antes de tomar una decisión

El mockup desarrolla la propuesta del wireframe mediante una bandeja con etiquetas de autorización y solicitud, paneles de revisión y ventanas de confirmación para aprobar o rechazar un caso

La información permite distinguir solicitudes pendientes de autorización de otras que ya fueron aprobadas, rechazadas o ejecutadas, así el usuario reconoce si debe intervenir o consultar el resultado de una decisión anterior

Su relación principal es con F2, que valida la anulación y coordina sus efectos, F1 mantiene el control del estado del pedido y registra las transiciones que correspondan dentro de M1

> **Nota:** Los registros y resultados son datos de demostración, confirmar una decisión en Figma actualiza la representación del caso y no ejecuta una anulación real ni operaciones de stock, despacho o dinero

---

## 2. Objetivo de la pantalla

La pantalla busca que el Gestor pueda localizar una solicitud, revisar su motivo y comprobar si necesita autorización antes de aprobarla o rechazarla

El detalle permite reconocer el pedido y el solicitante, mientras que el bloque de resultado muestra los efectos relacionados con el estado, el stock, el despacho y el reembolso

Las confirmaciones añaden un paso de revisión antes de aplicar la decisión representada, el usuario también puede cancelar esa confirmación o volver al pedido para consultar su información completa

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien utiliza la consola interna para evaluar las solicitudes que requieren su intervención

El cliente solicita la anulación desde el canal correspondiente, algunas operaciones pueden resolverse sin autorización manual según el estado y las reglas del módulo

Los pedidos **CREADO** y **PAGADO** pueden participar en anulaciones directas según las condiciones de F2, un pedido **EN PREPARACIÓN** requiere autorización expresa del Gestor

En la implementación el acceso debe estar protegido mediante token y rol, la disponibilidad de un botón no reemplaza la validación de permisos y elegibilidad en el backend

---

## 4. Estructura general de la interfaz

La pantalla se organiza en las siguientes zonas

| Zona | Función dentro de Anulaciones |
|---|---|
| **Menú lateral** | Presenta los accesos principales y mantiene Pedidos destacado como contexto del proceso |
| **Encabezado** | Identifica la pantalla y presenta la flecha de regreso |
| **Filtros superiores** | Permiten preparar la consulta por pedido o cliente, estado de solicitud y canal |
| **Solicitudes de anulación** | Muestra los casos con su motivo, autorización, situación y botón Revisar |
| **Detalle de solicitud** | Reúne los datos del caso seleccionado |
| **Resultado / efectos** | Presenta lo previsto o representado para pedido, stock, despacho y reembolso |
| **Acciones disponibles** | Permite aprobar, rechazar o volver al pedido según el caso |
| **Ventanas de confirmación** | Solicitan confirmar o cancelar la decisión antes de actualizar el resultado |

Al ingresar se presenta la bandeja y los paneles de revisión permanecen ocultos, estos aparecen al seleccionar una solicitud

El listado ocupa la zona izquierda y la revisión se presenta a la derecha, las tarjetas blancas y los separadores permiten distinguir la información del caso de las acciones que pueden realizarse

El color naranja destaca las acciones principales y las etiquetas de texto ayudan a diferenciar los estados sin depender únicamente del color

---

## 5. Filtros y bandeja de solicitudes

### 5.1. Campo Buscar

El campo **Buscar** está orientado a localizar una solicitud por código de pedido o cliente, al hacer clic presenta una lista de **Coincidencias rápidas** con ejemplos preparados

| Opción | Caso identificado en la lista |
|---|---|
| **PED-2026-1041** | Pendiente |
| **Carlos Ramírez** | Pendiente |
| **PED-2026-1036** | Rechazada |
| **PED-2026-1035** | Automática |
| **PED-2026-1032** | Aprobada |
| **PED-2026-1038** | Ejecutada |
| **PED-2026-1034** | Pendiente del canal Retail |

Seleccionar una opción actualiza el campo y cierra la lista, el prototipo utiliza estos ejemplos en lugar de una búsqueda libre conectada con una base de datos

### 5.2. Filtro Estado

El filtro **Estado** presenta **Todos**, **Pendiente**, **Aprobada**, **Rechazada** y **Ejecutada**

Este control corresponde al **estado de la solicitud de anulación**, no al estado del pedido, por ello sus opciones son diferentes de creado, pagado o en preparación

Su finalidad es permitir que el Gestor prepare una consulta de casos por situación de atención

### 5.3. Filtro Canal

El filtro **Canal** permite seleccionar **Todos**, **Marketplace**, **Chatbot** o **Retail** para expresar el origen de los casos que se desea consultar

Al elegir un valor se actualiza la etiqueta y se cierra el desplegable, los controles de búsqueda, estado, canal y orden cierran las otras listas cuando se abren

### 5.4. Botón Aplicar filtros

**Aplicar filtros** cierra los desplegables y oculta los paneles del caso seleccionado antes de presentar el resultado configurado

En la versión revisada ambas ramas de la interacción muestran el escenario pendiente de **PED-2026-1041**, por ello cambiar estado, canal o coincidencia de búsqueda todavía no produce una consulta completa según todos los criterios

La implementación deberá utilizar conjuntamente los filtros y devolver únicamente las solicitudes que correspondan a la selección del usuario

### 5.5. Botón Limpiar

**Limpiar** vacía la búsqueda, restablece **Estado** y **Canal** a **Todos** y recupera el orden **Más recientes**

También cierra las listas, oculta los paneles de revisión y restablece la primera página general de solicitudes

Esta acción permite comenzar otra consulta y no elimina solicitudes ni revierte una anulación

### 5.6. Información de la tabla

La bandeja presenta las siguientes columnas

| Columna | Información mostrada |
|---|---|
| **Pedido / Fecha** | Código del pedido y fecha relacionada con el caso |
| **Cliente** | Nombre y referencia del cliente |
| **Estado** | Estado del pedido consignado en el registro |
| **Motivo** | Razón de la solicitud de anulación |
| **Autorización** | Condición de autorización del caso |
| **Solicitud** | Situación de la solicitud de anulación |
| **Acción** | Botón Revisar |

La primera página incluye cinco solicitudes y muestra casos con autorización **No requerida**, **Pendiente** y **Aprobada**, estas etiquetas permiten reconocer qué registros necesitan una decisión

### 5.7. Ordenamiento y paginación

El selector situado sobre la tabla permite elegir **Más recientes** o **Más antiguos**, la selección cambia a la primera vista preparada para ese orden y cierra la lista

La bandeja incorpora tres páginas y las flechas **‹** y **›** para recorrer los registros

| Página | Intervalo representado |
|---|---|
| **1** | 1–5 de 14 solicitudes |
| **2** | 6–10 de 14 solicitudes |
| **3** | 11–14 de 14 solicitudes |

El número activo se diferencia mediante un fondo oscuro, los escenarios de orden antiguo también presentan sus intervalos para facilitar la lectura del recorrido

Estos controles organizan la consulta y no aprueban ni rechazan solicitudes

---

## 6. Detalle de la solicitud

### 6.1. Botón Revisar y selección del caso

El usuario puede seleccionar una solicitud desde su fila o mediante **Revisar**, la interacción carga los datos del caso y presenta los bloques de detalle, resultado y acciones

Revisar un registro no aplica una decisión, permite conocer primero el estado del pedido, el motivo y la situación de autorización

Al seleccionar otro caso se reemplaza la información de los paneles para continuar su consulta dentro de la misma bandeja

### 6.2. Datos del caso pendiente

El ejemplo de **PED-2026-1041** presenta la siguiente información

| Campo | Valor mostrado |
|---|---|
| **Pedido** | PED-2026-1041 |
| **Estado actual** | EN PREPARACIÓN |
| **Cliente** | Carlos Ramírez |
| **Canal** | Chatbot |
| **Motivo** | Dirección incorrecta |
| **Solicitante** | Carlos Ramírez |
| **Fecha** | 17/09/2026 16:12 |
| **Autorización** | Pendiente |
| **Solicitud** | PENDIENTE |

Este caso permite demostrar la intervención del Gestor porque el pedido se encuentra en preparación y la solicitud todavía necesita una decisión

### 6.3. Diferencia entre los estados mostrados

El **estado del pedido** indica su posición en el ciclo de vida, la **autorización** expresa si existe una decisión o si no se requiere intervención y el **estado de la solicitud** describe la situación del expediente de anulación

Una solicitud aprobada no debe interpretarse automáticamente como evidencia de que todos los efectos externos ya se completaron, el sistema debe distinguir la decisión de su ejecución

### 6.4. Control Cerrar

El control de cierre del detalle oculta también el resultado y las acciones asociadas, así el Gestor recupera la consulta de la bandeja

Cerrar la revisión no equivale a rechazar la solicitud ni a cancelar el pedido, solo retira los paneles de la vista

---

## 7. Resultado y efectos de la anulación

El bloque **Resultado / efectos** permite revisar qué debe ocurrir con el pedido y sus procesos relacionados

| Elemento | Interpretación |
|---|---|
| **Estado pedido** | Indica si el caso está pendiente de decisión, representa ANULADO o conserva el pedido sin cambios |
| **Stock** | Informa la reposición prevista o la ausencia de cambios |
| **Despacho** | Presenta la cancelación cuando corresponde o mantiene la operación sin cambios |
| **Reembolso** | Indica si debe originarse una operación de F4 o si no aplica |

En el caso pendiente el resultado del pedido figura como **Pendiente de decisión**, los efectos de stock, despacho y reembolso deben interpretarse como consecuencias previstas si se aprueba la solicitud

Para una anulación de un pedido con pago confirmado puede originarse un reembolso, un ejemplo creado sin pago completado presenta **No aplica** en ese campo

F2 coordina las operaciones necesarias con Productos y Ofertas, Despacho y Entrega y F4, la presencia de estas etiquetas en el mockup no acredita que las integraciones se hayan ejecutado

Si se rechaza la solicitud el resultado presenta el pedido sin cambios y no se originan los efectos de una anulación aprobada

---

## 8. Reglas de autorización

La elegibilidad depende del estado del pedido y de las condiciones establecidas por F2

| Estado del pedido | Regla de anulación |
|---|---|
| **CREADO** | Puede admitir anulación directa según actor y motivo |
| **PAGADO** | Puede admitir anulación directa y originar un reembolso cuando corresponde |
| **EN PREPARACIÓN** | Requiere autorización expresa del Gestor |
| **DESPACHADO** | No admite anulación desde F2 |
| **ENTREGADO** | Debe revisarse mediante los procesos de postventa que correspondan |
| **ANULADO** | No corresponde ejecutar nuevamente la misma anulación |

Los casos pendientes de decisión presentan **Aprobar anulación**, **Rechazar solicitud** y **Volver al pedido**

En los casos ya resueltos o que no requieren una nueva decisión el panel presenta únicamente **Volver al pedido**, esta diferencia evita ofrecer nuevamente la misma aprobación o rechazo

Las anulaciones y las devoluciones tienen condiciones distintas, que un pedido despachado ya no pueda anularse no significa que cumpla la condición de pedido entregado requerida para una devolución

La validación final debe realizarse en M1 y las transiciones deben respetar la máquina de estados, ocultar una acción en el frontend no sustituye estas reglas

---

## 9. Acciones disponibles y confirmaciones

### 9.1. Botón Aprobar anulación

**Aprobar anulación** abre una ventana con el título **Confirmar aprobación**, el cambio representado se aplica cuando el usuario presiona **Confirmar aprobación** dentro de esa ventana

La confirmación actualiza los paneles del caso con los siguientes valores

| Campo | Resultado de la simulación |
|---|---|
| **Autorización** | Aprobada |
| **Solicitud** | APROBADA |
| **Estado del pedido** | ANULADO |
| **Resultado del pedido** | ANULADO |
| **Stock** | Reintegrar |
| **Despacho** | Cancelar si aplica |
| **Reembolso** | Originar F4 |

Después se cierra la ventana y se ocultan los botones de aprobación y rechazo, queda disponible **Volver al pedido**

Esta secuencia permite representar la decisión sobre un caso pendiente y visualizar sus efectos, el resultado real debe depender de la respuesta de los servicios y no de una actualización visual anticipada

### 9.2. Botón Rechazar solicitud

**Rechazar solicitud** abre la ventana **Confirmar rechazo**, el usuario debe presionar **Confirmar rechazo** para aplicar la decisión representada

El mockup actualiza la autorización a **Rechazada** y la solicitud a **RECHAZADA**, el resultado del pedido muestra **Pedido sin cambios**

Los campos de stock y despacho pasan a **Sin cambios** y el reembolso a **No aplica**, se cierra la ventana y el panel conserva únicamente el regreso al pedido

El rechazo corresponde a la solicitud de anulación y no implica una transición del pedido a un estado llamado rechazado

### 9.3. Botón Cancelar en las confirmaciones

Ambas ventanas incluyen **Cancelar**, este botón cierra la confirmación sin aplicar los cambios de aprobación o rechazo

El usuario permanece en la revisión del caso y puede volver a evaluar la información antes de decidir

Cancelar la ventana no cancela el pedido ni rechaza automáticamente la solicitud

### 9.4. Botón Volver al pedido

**Volver al pedido** permite continuar la consulta de la venta relacionada con la solicitud, se presenta tanto durante una decisión pendiente como después de resolver el caso

En la página individual el botón muestra un aviso de destino que se cierra automáticamente, en **Mockup Flujo** está conectado con **Detalle del pedido**

El regreso no aprueba ni rechaza por sí mismo la solicitud y no ejecuta una nueva anulación

### 9.5. Relación entre los controles

| Control | Función dentro del recorrido |
|---|---|
| **Aplicar filtros** | Presenta el escenario de consulta preparado |
| **Limpiar** | Recupera los criterios iniciales y la primera página general |
| **Orden y paginación** | Organizan los registros que se consultan |
| **Revisar o seleccionar fila** | Abre el detalle, resultado y acciones del caso |
| **Aprobar anulación** | Abre la confirmación de aprobación |
| **Rechazar solicitud** | Abre la confirmación de rechazo |
| **Confirmar aprobación o rechazo** | Actualiza la representación del resultado y retira las acciones de decisión |
| **Cancelar** | Cierra la confirmación sin aplicar la decisión |
| **Cerrar detalle** | Oculta los paneles y mantiene la bandeja |
| **Volver al pedido** | Continúa hacia el detalle en el flujo integrado |

---

## 10. Relación con funcionalidades y navegación

### 10.1. Relación funcional y arquitectura

| Funcionalidad o componente | Relación con Anulaciones |
|---|---|
| **F1 — Ciclo de vida del pedido** | Ejecuta la transición válida a ANULADO y conserva el historial |
| **F2 — Anulación de pedidos** | Valida el estado, el motivo y la autorización y coordina los efectos derivados |
| **F4 — Reembolsos y extornos** | Recibe el origen del reembolso cuando existe un pago que debe devolverse |
| **F3 — Devoluciones y cambios** | Gestiona los casos de postventa que cumplen sus condiciones posteriores a la entrega |
| **Productos y Ofertas** | Recibe la operación de reposición de stock cuando corresponde |
| **Despacho y Entrega** | Coordina la cancelación logística cuando corresponde |

F1 y F2 pertenecen a **M1 — Pedidos**, F4 pertenece a **M2 — Postventa**, esta separación mantiene al pedido bajo un único control y permite coordinar el dinero mediante el proceso autorizado

La comunicación entre módulos se realiza por APIs y eventos, la pantalla no debe modificar directamente datos de otros componentes

### 10.2. Menú lateral y flecha de regreso

El menú mantiene **Pedidos** destacado porque la anulación se relaciona con el ciclo de vida de la venta, el botón de **tres líneas** permite contraer y expandir su presentación

Los accesos a **Dashboard**, **Pedidos**, **Postventa** y **Reportes** están conectados en el flujo integrado

La flecha junto al título representa visualmente un regreso pero no tiene una conexión configurada en la página individual ni en la copia de Anulaciones revisada del flujo integrado, el retorno conectado desde la revisión se realiza mediante **Volver al pedido**

### 10.3. Recorrido de revisión

El recorrido de decisión es

**Anulaciones → Revisar solicitud → Detalle y resultado → Aprobar o rechazar → Confirmar decisión → Volver al pedido**

Si el usuario necesita revisar nuevamente el caso puede utilizar **Cancelar** dentro de la confirmación y continuar en los paneles sin aplicar la decisión

Para una solicitud ya resuelta el recorrido se limita a consultar sus datos y utilizar **Volver al pedido** cuando se requiera ampliar la información

---

## 11. Consideraciones funcionales y de diseño

### 11.1. Consistencia de la decisión

El pedido, la autorización y la solicitud deben conservar una relación clara antes y después de una decisión, la aprobación no debe presentarse como ejecución completa si todavía existen efectos pendientes o fallidos

En los ejemplos resueltos la tabla y el detalle conservan estados de contexto como pagado o en preparación mientras el bloque de resultado puede mostrar anulado, la implementación debe aclarar qué datos corresponden al estado previo y cuáles al estado actual

El motivo de la solicitud ya se presenta en el detalle, las ventanas revisadas no incluyen un campo para ingresar la justificación del rechazo, ese dato deberá incorporarse al proceso cuando se registre una decisión que lo requiera

### 11.2. Requisitos no funcionales aplicables

| Requisito | Aplicación en la pantalla |
|---|---|
| **Seguridad** | Validar token, rol y autorización antes de ejecutar una decisión |
| **Trazabilidad** | Conservar solicitante, autorizador, fecha y motivo de la operación |
| **Usabilidad** | Diferenciar los estados y solicitar confirmación antes de ejecutar una acción irreversible |
| **Disponibilidad** | Mostrar las fallas de dependencias y permitir su seguimiento sin perder la operación |
| **Idempotencia de efectos** | Evitar que los reintentos dupliquen reposiciones, cancelaciones o devoluciones de dinero |
| **Mantenibilidad** | Reutilizar los patrones de filtros, tablas, estados y confirmaciones del módulo |

El diseño revisado corresponde a una vista de escritorio de **1440 × 1024**, la adaptación responsive y la validación de los servicios deben comprobarse con la aplicación integrada

### 11.3. Alcance del prototipo interactivo

Las confirmaciones actualizan los campos de los paneles mediante datos preparados, no demuestran persistencia ni sincronización automática de la tabla y del detalle externo del pedido

El retorno del flujo integrado conduce a la pantalla de detalle del caso fijo de demostración, la implementación debe conservar el identificador seleccionado para mostrar el pedido correspondiente a cada solicitud

El filtrado combinado debe completarse para responder a búsqueda, estado y canal, la consulta no debe presentar el mismo caso pendiente para criterios diferentes

La reposición de stock, la cancelación del despacho y el reembolso requieren sus propias validaciones e integraciones, si una operación falla su situación debe quedar visible para seguimiento o reintento

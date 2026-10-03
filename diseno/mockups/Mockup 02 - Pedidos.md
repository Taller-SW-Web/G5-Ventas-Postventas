# Bandeja de pedidos

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Mockup de alta fidelidad con interacciones de prototipo  
**Entrega:** Hito 2  
**Pantalla:** Bandeja de pedidos  
**Página en Figma:** Page 2  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidades relacionadas:** F1 — Ciclo de vida del pedido y F2 — Anulación de pedidos

---

## 1. Contexto del mockup

La Bandeja de pedidos reúne los registros de venta recibidos desde **Marketplace**, **Chatbot** y **Retail**, el Gestor utiliza esta pantalla para localizar un pedido, conocer su estado y revisar sus datos principales antes de continuar con una consulta más detallada

El mockup desarrolla la propuesta del wireframe mediante una tabla con estados diferenciados por color, tarjetas de resumen, filtros desplegables y un panel de detalle rápido que aparece al seleccionar un registro

Su relación principal es con F1, que administra los datos y el ciclo de vida del pedido, también se vincula con F2 cuando el usuario necesita revisar la posibilidad de iniciar una anulación

> **Nota:** Los pedidos y las cifras son datos de demostración, las interacciones representan escenarios preparados para revisar el funcionamiento de la interfaz y no corresponden a operaciones sobre un sistema de producción

---

## 2. Objetivo de la pantalla

La pantalla busca facilitar el seguimiento de los pedidos desde una sola bandeja, permite reconocer el código, cliente, canal, importe y estado de cada registro sin abrir primero su detalle completo

Los filtros ayudan a preparar la consulta y las tarjetas resumen ofrecen una lectura general de los pedidos considerados, la tabla permite seleccionar un caso y el detalle rápido concentra los datos necesarios para decidir cómo continuar

Esta organización mantiene una secuencia de trabajo clara para el Gestor, primero localiza el pedido, luego revisa su situación y finalmente accede al detalle o a la revisión de anulación cuando corresponde

---

## 3. Actor y alcance de acceso

El usuario principal es el **Gestor o Administrador de ventas**, quien utiliza la consola interna para consultar pedidos y dar seguimiento a la operación

El Cliente y el Vendedor interactúan desde los canales del proyecto, sus acciones originan información que posteriormente puede revisarse en esta bandeja administrativa

En la implementación el acceso debe estar protegido por la validación de token y rol del API Gateway, la autenticación corresponde al Módulo G y la consulta de pedidos se realiza mediante los servicios autorizados de M1

---

## 4. Estructura general de la interfaz

La pantalla se organiza en cinco zonas principales

| Zona | Función dentro de la bandeja |
|---|---|
| **Menú lateral** | Presenta los accesos a Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Permiten preparar la búsqueda por código, cliente o referencia y seleccionar estado, canal y fecha |
| **Indicadores de pedidos** | Resumen el total y las cantidades de las principales categorías operativas |
| **Listado de pedidos** | Presenta los registros con acciones de consulta, ordenamiento y paginación |
| **Detalle rápido** | Muestra los datos del pedido seleccionado y las opciones para continuar su revisión |

El menú oscuro identifica la sección **Pedidos** mediante un fondo claro y un acento naranja, el área principal utiliza tarjetas blancas sobre un fondo suave para separar los filtros, indicadores y registros

El color naranja destaca **Aplicar filtros**, los estados de la tabla se muestran con etiquetas de texto y colores que permiten diferenciarlos sin depender únicamente de la tonalidad

El panel de detalle rápido permanece oculto al ingresar a la pantalla y se presenta a la derecha del listado cuando el usuario selecciona un pedido

---

## 5. Filtros de consulta

### 5.1. Campo Buscar

El campo **Buscar** está orientado a localizar pedidos mediante código, cliente o referencia, al hacer clic se despliega una lista de **Coincidencias rápidas** con ejemplos preparados

| Opción de búsqueda | Caso representado |
|---|---|
| **PED-2026-1042** | Pedido pagado |
| **PED-2026-1040** | Pedido despachado |
| **María Torres** | Pedido entregado |
| **REF-00987** | Pedido creado |
| **PED-2026-1041** | Pedido en preparación |

Al elegir una opción se actualiza el contenido del campo y se cierra el desplegable, la interacción del mockup utiliza esta selección de ejemplos y no una entrada libre de texto con búsqueda sobre una base de datos

### 5.2. Filtro Estado

El filtro **Estado** presenta las opciones **Todos**, **CREADO**, **PAGADO**, **EN PREPARACIÓN**, **DESPACHADO**, **ENTREGADO** y **ANULADO**

Su finalidad es delimitar la consulta según la situación del pedido, seleccionar un estado en este control no modifica el estado real de ningún registro

Las opciones se relacionan con el ciclo de vida administrado por F1, la selección permite expresar qué pedidos desea revisar el Gestor

### 5.3. Filtro Canal

El filtro **Canal** permite elegir **Todos**, **Marketplace**, **Chatbot** o **Retail**

Este criterio ayuda a diferenciar el origen de las ventas, resulta útil cuando el Gestor necesita revisar pedidos de un canal específico sin cambiar de pantalla

Al seleccionar una opción se actualiza su etiqueta y se cierra la lista

### 5.4. Filtro Fecha

El control **Fecha** incorpora un icono de calendario y despliega tres rangos de demostración

- **01/09/2026 – 30/09/2026** para representar el mes completo
- **08/09/2026 – 22/09/2026** para representar un intervalo intermedio
- **01/09/2026 – 07/09/2026** para representar la primera semana

La interacción consiste en seleccionar uno de estos rangos, el mockup no presenta un calendario para elegir libremente las fechas

Los controles de búsqueda, estado, canal, fecha y ordenamiento cierran las otras listas al abrirse, de esta manera el usuario trabaja con un desplegable a la vez

### 5.5. Botón Aplicar filtros

**Aplicar filtros** confirma la consulta preparada, cierra los desplegables y oculta el detalle rápido para presentar el resultado del escenario configurado

En la versión actual de la página 2 este botón diferencia la búsqueda **PED-2026-1041** del escenario restante, la primera muestra un pedido en preparación y actualiza los indicadores a **1 pedido**, **1 pendiente** y **0** en las demás categorías

La otra rama presenta el ejemplo **PED-2026-1042**, con **1 pedido pagado** y las demás categorías en **0**, por ello las selecciones de estado, canal y fecha todavía no constituyen una consulta combinada completa

Para la implementación el resultado deberá responder a todos los criterios seleccionados, conservando la relación entre listado e indicadores

### 5.6. Botón Limpiar

**Limpiar** vacía los campos de búsqueda, estado, canal y fecha y restablece el orden visible a **Más recientes**, también cierra las listas abiertas y oculta el detalle rápido

La acción está preparada para recuperar la primera página de la bandeja y los indicadores generales de **2,880 pedidos**, **426 pendientes**, **1,320 pagados**, **740 despachados** y **394 entregados**

Este botón permite comenzar otra consulta y no elimina información de los pedidos

---

## 6. Indicadores principales

La fila de indicadores contiene cinco tarjetas con iconos y valores destacados

| Indicador | Valor inicial | Propósito |
|---|---:|---|
| **Total pedidos** | 2,880 | Mostrar la cantidad general de pedidos considerada en la bandeja |
| **Pendientes** | 426 | Resumir los pedidos agrupados como pendientes de avance operativo |
| **Pagados** | 1,320 | Identificar los pedidos con pago confirmado |
| **Despachados** | 740 | Mostrar los pedidos que ya se encuentran en proceso de entrega |
| **Entregados** | 394 | Identificar los pedidos cuya entrega fue completada |

Estas tarjetas son informativas y no tienen una acción de clic para filtrar el listado, la interacción de consulta se realiza desde los controles superiores

La categoría **Pendientes** corresponde a una agrupación de presentación, su definición debe mantener coherencia con los estados que realmente administra F1

Los indicadores resumen el conjunto de consulta y no únicamente las seis filas visibles de la primera página, en los escenarios de búsqueda configurados sus valores cambian para representar el resultado mostrado

---

## 7. Listado de pedidos y detalle rápido

### 7.1. Información de la tabla

El bloque **Listado de pedidos** presenta una indicación para seleccionar una fila y consultar su detalle rápido

| Columna | Información mostrada |
|---|---|
| **Código** | Identificador del pedido |
| **Fecha** | Fecha asociada al registro |
| **Cliente / Ref.** | Nombre del cliente o entidad y referencia relacionada |
| **Canal** | Origen del pedido |
| **Total** | Importe de la venta |
| **Estado** | Situación actual del pedido |
| **Acción** | Botón Ver detalle |

La primera página muestra seis registros, entre ellos el pedido **PED-2026-1042** de Ana López en estado **PAGADO** y el pedido **PED-2026-1041** de Carlos Ramírez en estado **EN PREPARACIÓN**

Las etiquetas de estado permiten identificar cada caso dentro de la tabla, la información completa permanece disponible mediante el panel lateral

### 7.2. Selector de ordenamiento

El control ubicado sobre la tabla permite elegir **Más recientes** o **Más antiguos**, al seleccionar una opción se actualiza la etiqueta y se cierra el desplegable

En la versión revisada esta interacción cambia la selección visible pero no contiene una acción que reorganice las filas, el orden efectivo de los registros debe completarse en la implementación

El ordenamiento tiene como finalidad cambiar la secuencia de presentación y no el contenido ni el estado de los pedidos

### 7.3. Paginación

La parte inferior incorpora los botones **1**, **2**, **3** y **4** y las flechas **‹** y **›** para recorrer las páginas preparadas

| Página | Intervalo mostrado |
|---|---|
| **1** | 1–6 |
| **2** | 7–12 |
| **3** | 13–18 |
| **4** | 19–24 |

El número seleccionado se diferencia mediante un fondo oscuro, las flechas permiten avanzar o retroceder dentro de las páginas configuradas

Al cambiar de página se oculta el detalle rápido para evitar mantener abierto el resumen de un registro que ya no pertenece a la vista seleccionada

Los **2,880 pedidos** representan el total de ejemplo de la bandeja, el prototipo dispone de cuatro páginas preparadas y no reproduce todos esos registros

### 7.4. Selección de un pedido y botón Ver detalle

El usuario puede hacer clic en una fila o en su botón **Ver detalle**, ambas acciones actualizan los datos seleccionados y muestran el mismo panel de detalle rápido

Seleccionar otro pedido reemplaza el contenido del panel por los datos del nuevo registro, así el Gestor puede revisar diferentes casos sin abandonar la bandeja

La acción es de consulta y no modifica el estado del pedido

### 7.5. Contenido del detalle rápido

El panel presenta código, estado, canal, cliente, total y fecha de última actualización

| Campo | Ejemplo del pedido seleccionado |
|---|---|
| **Código** | PED-2026-1042 |
| **Estado** | PAGADO |
| **Canal** | Marketplace |
| **Cliente** | Ana López |
| **Total** | S/ 214.00 |
| **Última actualización** | 18/09/2026 03:15 |

Debajo de esta información se encuentran **Ver detalle completo** y la opción de anulación que corresponda al estado del registro

### 7.6. Control Cerrar

El control de cierre ubicado en la parte superior del detalle rápido oculta el panel y mantiene al usuario en el listado

Cerrar el panel no anula el pedido ni cambia sus datos, permite recuperar la consulta de la bandeja antes de seleccionar otro caso

---

## 8. Acciones y reglas operativas

### 8.1. Botón Ver detalle completo

**Ver detalle completo** permite continuar desde el resumen hacia la pantalla que reúne los datos del pedido, sus productos, pago, despacho e historial

En el frame individual de la página 2 el botón presenta un aviso breve de destino que se cierra automáticamente, en la copia de **Mockup Flujo** está conectado con la pantalla **Detalle del pedido**

Dentro del flujo integrado el botón **Atrás** del detalle devuelve al usuario a la bandeja de Pedidos, de esta manera la consulta conserva una continuidad entre listado y detalle

### 8.2. Opción de anulación

En la página individual el panel presenta **Iniciar anulación** para los pedidos elegibles, al presionarlo se muestra un aviso breve que representa la continuación del proceso

En el flujo integrado el acceso se presenta como **Revisar para anular** y conduce primero al detalle del pedido, desde allí se continúa la revisión correspondiente

Esta entrada no ejecuta una anulación inmediata, su finalidad es revisar el pedido y las condiciones que deben cumplirse antes de confirmar una operación

### 8.3. Disponibilidad según el estado

| Estado del pedido | Condición para la anulación |
|---|---|
| **CREADO** | Puede participar en el flujo de anulación según actor y motivo |
| **PAGADO** | Puede participar en el flujo y origina un reembolso cuando corresponde |
| **EN PREPARACIÓN** | Requiere autorización expresa del Gestor |
| **DESPACHADO** | No admite anulación desde F2 |
| **ENTREGADO** | Debe continuar por el proceso de postventa que corresponda |
| **ANULADO** | No corresponde iniciar nuevamente la misma anulación |

El panel alterna entre la acción disponible y el mensaje **Anulación no disponible**, por ejemplo un pedido pagado muestra la opción de anulación y un pedido despachado muestra la restricción

F2 valida las condiciones de la solicitud y M1 conserva la responsabilidad de modificar el estado del pedido, la interfaz puede orientar al Gestor pero la autorización y las transiciones deben validarse nuevamente en el backend

Una devolución gestionada por F3 requiere un pedido entregado, por ello impedir la anulación de un pedido despachado no significa que ya cumpla las condiciones para aprobar una devolución

---

## 9. Relación con las funcionalidades y navegación

### 9.1. Relación funcional

| Funcionalidad | Relación con la bandeja |
|---|---|
| **F1 — Ciclo de vida del pedido** | Proporciona datos, estados e historial y mantiene el control de las transiciones |
| **F2 — Anulación de pedidos** | Recibe la solicitud cuando se inicia la revisión de un pedido elegible |
| **F3 — Devoluciones y cambios** | Gestiona solicitudes posteriores a la entrega cuando se cumplen las condiciones de postventa |
| **F6 — Gestión de reclamos, dashboard y reportes** | Utiliza eventos del pedido para mantener indicadores y agregados de análisis |

La arquitectura ubica F1 y F2 en **M1 — Pedidos**, mientras que F3 y F6 pertenecen a **M2 — Postventa**, esta separación permite consultar información de distintas funciones sin trasladar al frontend la responsabilidad de modificar los pedidos

Los datos deben obtenerse mediante APIs y eventos de los servicios autorizados, sin acceso directo a bases de datos ajenas

### 9.2. Menú lateral

El menú mantiene **Pedidos** destacado y presenta accesos a **Dashboard**, **Postventa** y **Reportes**

El botón con el icono de **tres líneas** alterna entre la versión expandida y la versión compacta del menú, cambia su presentación sin aplicar filtros ni modificar los registros

En la página individual está configurada esta interacción del menú, los accesos hacia las demás pantallas están conectados en **Mockup Flujo**

### 9.3. Relación entre los botones

| Control | Resultado dentro del recorrido |
|---|---|
| **Buscar, Estado, Canal y Fecha** | Preparan los criterios de consulta |
| **Aplicar filtros** | Presenta el escenario configurado y cierra los desplegables |
| **Limpiar** | Restablece los campos y los valores generales de la bandeja |
| **Más recientes / Más antiguos** | Cambia la selección visible del orden |
| **Números y flechas de página** | Permiten recorrer los grupos de registros preparados |
| **Fila o Ver detalle** | Presenta el detalle rápido del pedido seleccionado |
| **Cerrar** | Oculta el detalle rápido y mantiene la consulta del listado |
| **Ver detalle completo** | Continúa hacia la información completa del pedido en el flujo integrado |
| **Opción de anulación** | Permite iniciar la revisión de elegibilidad sin anular directamente |

El recorrido principal de consulta es

**Pedidos → Seleccionar registro → Detalle rápido → Ver detalle completo → Detalle del pedido → Atrás → Pedidos**

La revisión de anulación parte del mismo contexto y continúa por las acciones permitidas para el estado del pedido

---

## 10. Consideraciones funcionales y de diseño

### 10.1. Coherencia con el ciclo de vida

El estado mostrado en la tabla y en el detalle rápido debe corresponder al mismo pedido, la selección de otro registro debe actualizar también la disponibilidad de la acción de anulación

Los filtros y los controles de navegación son acciones de consulta, no representan transiciones como pagar, preparar, despachar o entregar

La máquina de estados establece que M1 es el único responsable de ejecutar los cambios válidos, cada transición debe conservar la información de trazabilidad definida por el módulo

### 10.2. Requisitos no funcionales aplicables

| Requisito | Aplicación en la pantalla |
|---|---|
| **Seguridad** | Restringir la consulta administrativa al usuario autorizado y validar el rol antes de una operación que lo requiera |
| **Rendimiento** | Mantener una consulta fluida mediante listados filtrables y paginación, la especificación establece menos de 500 ms para la consulta de un pedido |
| **Usabilidad** | Diferenciar filtros, estados y acciones y permitir cerrar el resumen o regresar desde el detalle |
| **Trazabilidad** | Mostrar información de seguimiento y conservar usuario, fecha y motivo cuando se ejecute una transición |
| **Disponibilidad** | Comunicar los errores de consulta y evitar presentar resultados incompletos como una consulta válida |
| **Mantenibilidad** | Reutilizar los patrones de filtros, tablas, botones y navegación del módulo |

El diseño revisado corresponde a una vista de escritorio de **1440 × 1024**, la adaptación responsive y el cumplimiento de rendimiento y seguridad deben comprobarse con el sistema implementado

### 10.3. Alcance del prototipo interactivo

La página 2 permite revisar desplegables, selección de registros, detalle rápido y paginación con datos preparados, los avisos de destino de sus botones se complementan con las conexiones de la página de flujo integrado

El filtrado combinado y el ordenamiento efectivo todavía deben completarse, seleccionar un criterio visible no garantiza que el resultado actual responda a todas las opciones elegidas

También debe comprobarse la recuperación de la bandeja después de cualquier búsqueda para evitar que permanezca visible un resultado anterior junto con la vista general

Estas condiciones permiten distinguir la propuesta de interacción del funcionamiento que deberá ofrecer la aplicación al integrarse con los servicios del módulo

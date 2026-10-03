# Mockups — Módulo D: Ventas y Postventa

## Contexto y flujo general del sistema

**Tipo de artefacto:** Documentación general de mockups de alta fidelidad  
**Entrega:** Hito 2  
**Módulo:** D — Ventas y Postventa  
**Actor principal:** Gestor / Administrador de ventas  
**Alcance:** Nueve pantallas principales con interacciones de consulta, gestión y navegación integrada

---

## 1. Presentación

Los mockups representan la interfaz administrativa del **Módulo D — Ventas y Postventa**, reúnen el seguimiento de pedidos, la atención posterior a la compra y la consulta de resultados

La propuesta continúa el trabajo de los wireframes e incorpora una presentación visual más definida con colores, iconos, tablas, indicadores y ventanas de confirmación, también desarrolla las interacciones necesarias para comprender cómo utiliza el sistema el Gestor

Este documento presenta el funcionamiento conjunto del módulo y la relación entre sus pantallas, los detalles de cada control se desarrollan en los MD individuales

La navegación entre pantallas se reúne en **Mockup Flujo**, las páginas individuales permiten revisar el diseño y sus interacciones internas

> **Nota:** Los datos y cambios del prototipo son ejemplos de demostración, no representan operaciones reales sobre pedidos, productos, despachos o dinero

---

## 2. Objetivo y usuarios

La propuesta busca que el Gestor pueda partir de una visión general, localizar un caso, revisar su información y continuar con la acción correspondiente sin perder el contexto del proceso

El **Gestor o Administrador de ventas** utiliza la consola interna, el **Cliente** participa desde los canales habilitados para comprar, solicitar atención y responder encuestas

Marketplace, Chatbot y Retail aportan el contexto de canal utilizado en las consultas, el mockup no representa todas las interfaces externas del cliente ni las herramientas propias de los demás módulos

---

## 3. Organización funcional del módulo

| Bloque             | Funcionalidades | Responsabilidad                                                                    |
| ------------------ | --------------- | ---------------------------------------------------------------------------------- |
| **M1 — Pedidos**   | F1 y F2         | Controla el ciclo de vida del pedido y las anulaciones permitidas                  |
| **M2 — Postventa** | F3, F4, F5 y F6 | Gestiona devoluciones, cambios, reembolsos, calificaciones, reclamos e indicadores |

M1 conserva el control del estado del pedido, M2 consulta su información y solicita los cambios que correspondan mediante los servicios autorizados

La integración utiliza APIs para consultas y operaciones que necesitan respuesta y eventos para comunicar cambios y actualizar los procesos relacionados, cada área conserva sus responsabilidades sin acceder directamente a las tablas de otra

---

## 4. Pantallas que componen la propuesta

| Página | Pantalla                      | Función en el recorrido                                                           |
| ------ | ----------------------------- | --------------------------------------------------------------------------------- |
| **1**  | **Dashboard**                 | Resume indicadores y permite consultar situaciones prioritarias                   |
| **2**  | **Pedidos**                   | Localiza pedidos y presenta su detalle rápido                                     |
| **3**  | **Detalle del pedido**        | Reúne productos, pago, logística e historial y representa las acciones por estado |
| **4**  | **Anulaciones**               | Permite revisar y resolver solicitudes de anulación                               |
| **5**  | **Hub Postventa**             | Organiza el ingreso a los procesos y la consulta de prioridades                   |
| **6**  | **Devoluciones y cambios**    | Reúne expediente, evidencia, evaluación y resolución                              |
| **7**  | **Reclamos**                  | Permite iniciar atención, registrar respuesta y confirmar el cierre               |
| **8**  | **Reembolsos**                | Representa autorización, ejecución, resultado y reintento seguro                  |
| **9**  | **Calificaciones y reportes** | Presenta satisfacción, operación, comentarios, comparación y exportación          |

El Dashboard y el Hub incluyen accesos a **Atención prioritaria**, esta vista complementaria permite consultar casos y regresar al panel de origen

---

## 5. Navegación y controles comunes

El menú lateral organiza cuatro accesos, **Dashboard**, **Pedidos**, **Postventa** y **Reportes**, la sección activa permite reconocer la ubicación del usuario y el botón de tres líneas alterna la presentación expandida y compacta

| Recorrido                                       | Continuidad de la consulta                                                                        |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Dashboard → Atención prioritaria**            | Ver o Ver todas permite revisar casos y regresar al Dashboard                                     |
| **Pedidos → Detalle rápido → Detalle completo** | Ver detalle completo amplía la consulta y Atrás permite volver a Pedidos                          |
| **Detalle del pedido → Anulaciones**            | Iniciar anulación abre la revisión y Volver al pedido recupera el contexto de la compra           |
| **Postventa → Hub → Bandeja operativa**         | Ir al módulo permite ingresar a devoluciones, reclamos o reembolsos y regresar al Hub             |
| **Hub → Atención prioritaria**                  | Los indicadores y Ver casos prioritarios permiten revisar pendientes antes de entrar a un proceso |
| **Reportes → Vista o detalle analítico**        | Los botones de cierre y Volver a vista general recuperan el panel de análisis                     |

Los filtros delimitan la consulta, el ordenamiento y la paginación organizan los registros y **Ver** o **Revisar** abre el caso seleccionado

**Cerrar detalle** recupera la bandeja, **Cancelar** retira una confirmación sin aplicar la decisión y los botones de regreso cambian la pantalla consultada, ninguna de estas acciones debe revertir por sí sola el estado de una operación

---

## 6. Flujo de ventas y seguimiento del pedido

F1 recibe el pedido desde el canal y valida sus datos y precios antes de registrar el detalle, después confirma el pago y continúa con preparación, despacho y entrega

El recorrido funcional principal es **Crear pedido → Validar y registrar → Confirmar pago → Preparar → Despachar → Entregar → Cerrar cuando corresponda**

Desde **Pedidos** el Gestor localiza la compra y abre su detalle rápido, **Ver detalle completo** permite consultar productos, pago, información logística e historial

El mockup del detalle representa el avance desde **PAGADO** mediante **Pasar a preparación**, **Marcar como despachado** y **Marcar como entregado**, cada paso actualiza la información visible y presenta la siguiente acción

En el sistema las transiciones deben ser validadas por M1 y respaldadas por las confirmaciones operativas correspondientes, cada cambio conserva usuario, fecha, estado anterior, estado nuevo y motivo cuando aplica

La entrega permite iniciar los procesos de postventa que cumplan sus condiciones y activa el flujo de encuesta, el cierre conserva el pedido para consulta histórica

---

## 7. Flujo de anulación

F2 recibe la solicitud y verifica el estado del pedido, el motivo y la autorización necesaria antes de resolverla

Los pedidos **CREADO** y **PAGADO** admiten la revisión de anulación desde el canal, **EN PREPARACIÓN** requiere autorización del Gestor y **DESPACHADO** ya no permite anulación

El recorrido de revisión es **Iniciar anulación → Revisar solicitud → Validar estado y motivo → Aprobar o rechazar → Confirmar decisión**

Si se aprueba corresponde registrar la anulación, liberar o reintegrar stock y cancelar la operación logística cuando aplica, si existe un pago que debe devolverse se origina el proceso de F4

Si se rechaza la solicitud el pedido conserva su situación, **Volver al pedido** permite continuar la consulta después de la decisión

Un pedido despachado debe continuar por la atención de postventa que corresponda, la devolución de F3 requiere que la entrega ya esté confirmada

---

## 8. Flujo de devoluciones y cambios

Desde el Hub el Gestor ingresa a **Devoluciones y cambios**, localiza el expediente y pulsa **Revisar** para consultar pedido, motivo, fecha de entrega y evidencia

F3 valida que el pedido esté entregado y que la solicitud cumpla el plazo, motivo y evidencia requeridos

El recorrido es **Solicitud registrada → Validar elegibilidad → Revisar evidencia → Iniciar evaluación → Aprobar o rechazar → Ejecutar la resolución → Completar cuando corresponda**

**Ver foto** y **Abrir PDF** permiten revisar los adjuntos, una aprobación habilita la acción correspondiente y un rechazo debe conservar su fundamento

| Resolución                | Continuación del proceso                                                          |
| ------------------------- | --------------------------------------------------------------------------------- |
| **Cambio**                | Comprobar disponibilidad y coordinar el nuevo despacho mediante el área logística |
| **Devolución con dinero** | Coordinar el recojo cuando aplica y derivar el origen aprobado hacia Reembolsos   |
| **Rechazo**               | Registrar el fundamento y conservar el expediente para consulta                   |

Cambio y reembolso son resoluciones excluyentes para un mismo expediente, aprobar no equivale a completar la atención, el cierre requiere confirmar la ejecución de la resolución

---

## 9. Flujo de reembolsos

F4 recibe el origen válido desde una anulación pagada o una devolución aprobada, verifica monto, moneda y referencia de la transacción original y establece la clave de idempotencia

El Gestor abre la operación con **Ver** y revisa el detalle, la trazabilidad y el historial antes de continuar

El recorrido es **Recibir origen → Validar pago y monto → Autorizar cuando corresponde → Ejecutar → Consultar resultado → Registrar resultado y actualizar el origen**

La autorización habilita la ejecución pero no devuelve todavía el dinero, el envío permanece pendiente hasta que se confirma el resultado del simulador

La operación puede ser **PENDIENTE**, **EXITOSO** o **FALLIDO**, un resultado no confirmado requiere consulta y un fallo puede continuar mediante **Reintento seguro** cuando sea procedente

El reintento conserva la misma operación y clave para evitar duplicar la devolución, después del resultado se actualiza el proceso de origen y se solicita el cierre correspondiente cuando aplica

---

## 10. Flujo de reclamos y calificaciones

### 10.1. Atención de reclamos

F6 recibe el reclamo o queja desde el canal, genera su código y formato y conserva la fecha límite de respuesta, el pedido asociado puede ser opcional

Desde **Reclamos** el Gestor pulsa **Ver**, consulta descripción, contacto, historial y SLA y continúa con **Iniciar atención → Responder reclamo → Guardar respuesta → Marcar como atendido → Confirmar cierre**

El caso avanza de **REGISTRADO** a **EN PROCESO** y finalmente a **ATENDIDO**, el cierre requiere una respuesta válida y trazable

El SLA expresa la situación del plazo y se distingue del estado de atención, un caso vencido puede seguir en proceso y debe conservar esa condición en su seguimiento

**Generar PDF** permite revisar el formato representado, **Volver al pedido** tiene sentido cuando el expediente cuenta con una compra asociada

### 10.2. Calificación de experiencia

Después de una entrega confirmada F5 genera y envía la encuesta, recibe una puntuación de 1 a 5 con comentario opcional y registra la respuesta asociada al pedido, canal y fecha

La respuesta válida actualiza los agregados de satisfacción utilizados por F6, las puntuaciones inválidas o duplicadas no deben alterar el indicador

El Gestor consulta los resultados en **Calificaciones y reportes**, una valoración baja se incorpora al análisis sin abrir automáticamente un reclamo

---

## 11. Indicadores, reportes y relación entre procesos

F6 consume los eventos de pedidos y postventa y actualiza los agregados que utilizan Dashboard y Reportes, así la consulta reúne resultados de F1 a F5 y el seguimiento de reclamos

En **Calificaciones y reportes** el Gestor selecciona periodo, canal y vista y utiliza **Aplicar filtros**, puede revisar satisfacción, operación, comentarios y distribución por canal

**Ver detalle** amplía el análisis, **Comparar** presenta los valores del periodo anterior y **Exportar → Preparar → Finalizar** representa la preparación del reporte

Los filtros aplicados deben mantenerse coherentes entre indicadores, gráficos, detalles y exportación, los reportes consultan agregados precalculados sin recorrer toda la base transaccional en cada ingreso

La continuidad del módulo relaciona una compra con su entrega, sus solicitudes posteriores y sus resultados, una anulación o devolución puede originar dinero a devolver mientras que la entrega también permite recoger la experiencia del cliente

---

## 12. Alcance del prototipo y uso de la documentación

Los mockups permiten revisar organización visual, navegación, estados, acciones y confirmaciones, las validaciones definitivas de permisos, elegibilidad, transiciones y dinero deben ejecutarse en los servicios

La navegación integrada se revisa en **Mockup Flujo**, algunas páginas individuales utilizan avisos de destino y las consultas internas trabajan con escenarios preparados

Los cambios visuales no representan persistencia completa entre pantallas, las vistas de documentos y exportación tampoco acreditan descargas reales, los detalles de estos alcances se indican en el MD de cada pantalla

El desarrollo debe conservar la trazabilidad, la comunicación por APIs y eventos y la idempotencia de los efectos externos, también debe asegurar que los datos y gráficos representen el mismo conjunto de información

Este documento introduce el recorrido conjunto de las nueve pantallas, los archivos individuales amplían sus controles y comportamientos para mantener la explicación general breve y la documentación de cada proceso completa

Figma:
https://www.figma.com/design/J2KeLP6nl8qlDunNNUAC52/Mockup-Hito-2?node-id=188-260&t=lxZZjIVDAOD228tm-1

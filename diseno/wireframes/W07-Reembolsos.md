# W07 — Reembolsos

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W07 — Reembolsos  
**Página de referencia en Figma:** Page 8  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F4 — Reembolsos y extornos

---

## 1. Contexto del wireframe

W07 representa la bandeja administrativa para consultar y procesar reembolsos dentro del **Módulo D — Ventas y Postventa**

La pantalla pertenece a F4 y se utiliza cuando existe una solicitud de devolución de dinero originada por un flujo previamente validado. Según la especificación funcional, F4 no decide por sí sola si una anulación o devolución procede, sino que recibe el origen desde F2 o F3 y ejecuta el movimiento monetario correspondiente

Debido a que esta funcionalidad maneja operaciones de dinero, el flujo debe conservar trazabilidad completa y evitar duplicados mediante idempotencia

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

La pantalla busca centralizar el seguimiento de los reembolsos para que el Gestor pueda identificar su origen, revisar el monto, conocer el estado de procesamiento y consultar el resultado de la operación

Desde W07 también se puede autorizar, ejecutar, consultar el resultado o realizar un reintento seguro cuando la operación no haya finalizado correctamente

---

## 3. Actor y alcance de acceso

El usuario principal de W07 es el **Gestor o Administrador de ventas**

F2 y F3 actúan como origen funcional de la solicitud:

- **F2 — Anulación de pedidos:** origina el reembolso cuando una anulación válida corresponde a un pedido con pago confirmado
- **F3 — Devoluciones y cambios:** origina el reembolso cuando una devolución aprobada implica devolver dinero al cliente

F4 únicamente procesa el movimiento monetario una vez que el origen ha sido validado

---

## 4. Estructura general de la interfaz

La pantalla se organiza en seis zonas principales:

| Zona | Función |
|---|---|
| **Menú lateral** | Permite navegar entre Dashboard, Pedidos, Postventa y Reportes |
| **Filtros superiores** | Facilitan la búsqueda por reembolso, estado, origen y fecha |
| **Bandeja de reembolsos** | Presenta las operaciones registradas y su situación actual |
| **Historial del reembolso** | Muestra cronológicamente las etapas de la operación |
| **Detalle del reembolso** | Reúne origen, monto, operación, autorizador y resultado |
| **Acciones e información adicional** | Permite operar sobre el reembolso y consultar datos complementarios |

La distribución mantiene separada la consulta general del detalle operativo para reducir errores en una funcionalidad sensible

---

## 5. Filtros y bandeja de reembolsos

El wireframe incorpora los filtros:

- **Buscar:** permite localizar por código de reembolso, pedido o cliente
- **Estado:** restringe la consulta según la situación de la operación
- **Origen:** permite diferenciar el flujo que generó el reembolso
- **Fecha de creación:** delimita el periodo de búsqueda

Las acciones **Aplicar filtros** y **Limpiar** controlan la consulta

La tabla principal presenta:

| Campo | Información mostrada |
|---|---|
| **Código** | Identificador del reembolso |
| **Fecha** | Fecha asociada a la operación |
| **Pedido** | Pedido relacionado |
| **Origen** | Flujo que generó la solicitud |
| **Monto** | Importe a devolver |
| **Estado** | Situación actual del reembolso |
| **Acción** | Permite abrir el detalle |

El listado incluye ordenamiento por fecha y paginación

### Detalle visual: filtros y bandeja de reembolsos

---

## 6. Detalle del reembolso

Al seleccionar una operación, el panel lateral presenta la información necesaria para verificar el caso:

- Código del reembolso
- Pedido relacionado
- Origen
- Monto
- Tipo de monto parcial o total
- Id de operación
- Autorizador
- Resultado del simulador
- Fecha de creación
- Estado

Esta información permite relacionar el movimiento monetario con el flujo que lo originó y mantener trazabilidad durante todo el proceso

En el ejemplo mostrado, el reembolso se origina en una anulación de F2 y corresponde a un monto total

---

## 7. Historial del reembolso

El bloque **Historial del reembolso** presenta cronológicamente las etapas de la operación

En el wireframe se muestran eventos como:

- Solicitud registrada
- Consulta de resultado
- Autorización aprobada
- Reembolso ejecutado

El historial permite verificar qué ocurrió en cada etapa y conservar evidencia de los intentos realizados, especialmente cuando existe un error o un reintento

---

## 8. Procesamiento, simulador e idempotencia

F4 procesa el extorno mediante el simulador de pasarela definido para el proyecto

Antes de ejecutar una operación se debe verificar que:

- Exista un pago original asociado al pedido
- El origen F2 o F3 haya sido validado
- El monto no supere lo pagado originalmente
- Exista una clave única de idempotencia

El reembolso puede ser **total o parcial** según el origen

Si una operación ya fue procesada exitosamente, un reintento con la misma clave debe devolver el resultado existente sin ejecutar una segunda devolución de dinero

---

## 9. Acciones disponibles

El wireframe presenta cuatro acciones principales:

| Acción | Comportamiento esperado |
|---|---|
| **Autorizar reembolso** | Registra la autorización cuando la operación lo requiere |
| **Ejecutar reembolso** | Envía la operación válida al simulador de pasarela |
| **Consultar resultado** | Recupera el resultado asociado a la operación |
| **Reintento seguro** | Reprocesa una operación pendiente o fallida sin duplicar el dinero |

Las acciones disponibles deben depender del estado actual de la operación y de las validaciones realizadas por el backend

---

## 10. Estados y consistencia funcional

El wireframe utiliza etiquetas como **EJECUTADO**, **EN PROCESO**, **APROBADO** y **RECHAZADO** para representar de manera visual las situaciones del reembolso

La especificación funcional de F4 utiliza como estados de persistencia principales `EXITOSO`, `FALLIDO` y `PENDIENTE`

Durante la implementación se debe definir una correspondencia clara entre las etiquetas visuales del frontend y los estados canónicos del backend para evitar interpretaciones diferentes sobre una misma operación

También debe revisarse el ejemplo **Ajuste manual** mostrado como origen en el wireframe, ya que la especificación actual de F4 establece que un reembolso válido debe provenir de F2 o F3

---

## 11. Relación con funcionalidades y navegación

| Funcionalidad | Relación con W07 |
|---|---|
| **F2 — Anulación de pedidos** | Origina reembolsos cuando una anulación válida involucra un pago confirmado |
| **F3 — Devoluciones y cambios** | Origina reembolsos cuando una devolución aprobada requiere devolver dinero |
| **F4 — Reembolsos y extornos** | Valida, autoriza, ejecuta y registra la operación monetaria |
| **F1 — Ciclo de vida del pedido** | Proporciona la referencia del pedido y pago original |
| **Simulador de pasarela** | Procesa el extorno y devuelve el resultado de la operación |

La navegación principal prevista es:

**W04 Anulaciones / W05 Devoluciones → W07 Reembolsos → W03 Detalle del pedido o expediente de origen**

---

## 12. Consideraciones funcionales y de diseño

W07 debe priorizar la seguridad y claridad de la información debido a que representa operaciones monetarias

El Gestor debe poder reconocer el origen, monto y estado antes de ejecutar cualquier acción. El historial debe permanecer visible para facilitar la auditoría y los reintentos no deben generar operaciones duplicadas

El frontend puede prevenir dobles clics y mostrar estados de procesamiento, pero la garantía definitiva de idempotencia debe mantenerse en el backend

Los filtros, tablas, estados, acciones e historial deben conservar coherencia con las demás pantallas del módulo

---

## 13. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 8 del archivo Figma del Módulo D, pantalla **Reembolsos**
- Especificación de W07 definida para el Hito 1
- Especificación de F4 — Reembolsos y extornos
- Reglas de integración con F2, F3, F1 y el simulador de pasarela
- Requisito no funcional de idempotencia definido para las operaciones monetarias

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=65-37`

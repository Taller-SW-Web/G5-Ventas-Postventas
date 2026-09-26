# W03 — Detalle del pedido

## Módulo D: Ventas y Postventa

**Tipo de artefacto:** Wireframe de baja fidelidad  
**Pantalla:** W03 — Detalle del pedido  
**Página de referencia en Figma:** Page 3  
**Actor principal:** Gestor / Administrador de ventas  
**Funcionalidad relacionada:** F1 — Ciclo de vida del pedido y F2 — Anulación de pedidos

---

## 1. Contexto del wireframe

W03 representa la vista de detalle de un pedido seleccionado desde la bandeja W02. Su función es reunir en una sola pantalla la información necesaria para comprender el estado actual de la venta, revisar los productos involucrados, consultar datos de pago y despacho y reconocer qué acciones pueden ejecutarse según el estado del pedido

La pantalla se relaciona principalmente con F1, que mantiene el ciclo de vida y el historial del pedido. También se conecta con F2 cuando el pedido cumple las condiciones necesarias para iniciar una anulación

> **Nota:** Los valores mostrados en el wireframe son datos de ejemplo utilizados para representar la estructura y el comportamiento esperado de la interfaz. No corresponden a datos reales de producción

### Imagen general del wireframe

---

## 2. Objetivo de la pantalla

El Detalle del pedido busca proporcionar al Gestor una visión completa del registro sin sobrecargar la bandeja principal de pedidos

Desde esta vista se puede revisar la información comercial y operativa del pedido, verificar su posición dentro del ciclo de vida y ejecutar únicamente las acciones permitidas para el estado actual

---

## 3. Actor y alcance de acceso

El usuario principal de W03 es el **Gestor o Administrador de ventas** dentro del backoffice del Módulo D

Los canales Marketplace, Chatbot y Retail pueden originar o consultar pedidos mediante los contratos establecidos, pero esta vista está orientada a la supervisión administrativa y al seguimiento interno del pedido

---

## 4. Estructura general de la interfaz

La pantalla se organiza en los siguientes bloques:

| Zona | Función |
|---|---|
| **Resumen superior** | Presenta código, estado, canal, fecha y total del pedido |
| **Datos del pedido** | Muestra cliente, referencia, canal, fecha de registro, dirección y observación |
| **Ítems del pedido** | Detalla productos, cantidades, precios, descuentos e importes |
| **Pago y despacho** | Resume el estado del pago y la situación logística |
| **Historial de estados** | Representa visualmente el avance del pedido |
| **Acciones disponibles** | Muestra únicamente las operaciones permitidas según el estado |
| **Reglas y trazabilidad** | Explica restricciones relevantes y conserva información de seguimiento |

La distribución separa el contenido descriptivo de las acciones operativas para facilitar la lectura del Gestor

---

## 5. Resumen y datos del pedido

La franja superior permite reconocer rápidamente los datos principales del pedido seleccionado

| Campo | Ejemplo mostrado |
|---|---|
| **Código** | PED-2026-1042 |
| **Estado** | PAGADO |
| **Canal** | Marketplace |
| **Fecha** | 18/09/2026 |
| **Total** | S/ 214.00 |

El bloque **Datos del pedido** amplía esta información con cliente, referencia, fecha de registro, dirección de entrega y observaciones relacionadas con la venta

### Detalle visual: resumen y datos generales

---

## 6. Ítems, pago y despacho

### 6.1. Ítems del pedido

La tabla de ítems permite verificar el contenido económico del pedido mediante los campos producto, SKU, cantidad, precio unitario, descuento e importe

Al final del bloque se presenta el resumen de **Subtotal**, **Descuento** y **Total**, permitiendo relacionar los productos registrados con el monto final de la venta

### 6.2. Pago

El panel de pago muestra información básica como:

- Método de pago
- Estado del pago
- Monto confirmado

En el ejemplo se presenta un pago con tarjeta y estado **Confirmado**, coherente con un pedido que ya se encuentra en estado `PAGADO`

### 6.3. Despacho

El bloque de despacho permite revisar el estado logístico, guía o referencia, fecha estimada y dirección de entrega

Esta información es de consulta para el Gestor. La gestión operativa del reparto pertenece al módulo de Despacho y Entrega, mientras que F1 consume sus notificaciones para actualizar el estado del pedido

---

## 7. Historial de estados

El panel lateral representa la secuencia principal del ciclo de vida:

`CREADO → PAGADO → EN PREPARACIÓN → DESPACHADO → ENTREGADO`

El estado actual se identifica visualmente dentro de la línea de tiempo. En el ejemplo, el pedido se encuentra en `PAGADO`

F1 es responsable de validar y registrar las transiciones. Cada cambio debe conservar actor, motivo cuando corresponda y fecha/hora para mantener la trazabilidad del pedido

---

## 8. Acciones disponibles y reglas de negocio

El wireframe muestra dos acciones principales para el pedido seleccionado:

| Acción | Comportamiento esperado |
|---|---|
| **Pasar a preparación** | Solicita una transición válida desde `PAGADO` hacia `EN PREPARACIÓN` |
| **Iniciar anulación** | Abre el flujo de F2 cuando el estado actual permite anular |

Las acciones deben depender siempre del estado actual. El frontend puede ocultar o deshabilitar operaciones inválidas, pero la validación definitiva debe realizarse en el backend

Para el ejemplo mostrado, la regla visible indica que un pedido `PAGADO` puede continuar hacia `EN PREPARACIÓN` o iniciar el proceso de anulación correspondiente

---

## 9. Notas y trazabilidad

El bloque **Notas / trazabilidad** permite mostrar información de seguimiento como última actualización, usuario responsable y motivo reciente

Su finalidad es aportar contexto administrativo sin reemplazar el historial completo de estados. La trazabilidad detallada continúa siendo responsabilidad de F1 y debe conservarse de manera auditable

---

## 10. Relación con funcionalidades y navegación

| Funcionalidad | Relación con W03 |
|---|---|
| **F1 — Ciclo de vida del pedido** | Proporciona estado, datos, historial y valida las transiciones |
| **F2 — Anulación de pedidos** | Recibe el flujo cuando se selecciona Iniciar anulación |
| **F3 — Devoluciones y cambios** | Puede utilizar el pedido como contexto cuando ya se encuentra entregado |
| **Despacho y Entrega** | Aporta eventos y referencias logísticas consumidas por F1 |

La navegación principal prevista es:

**W02 Pedidos → W03 Detalle del pedido → W04 Anulaciones o módulos de postventa**

W03 concentra las acciones complejas que no deben ejecutarse directamente desde el listado de pedidos

---

## 11. Consideraciones funcionales y de diseño

La pantalla debe mantener una jerarquía clara entre información, historial y acciones para que el Gestor comprenda primero el contexto del pedido antes de modificar su flujo

Las acciones disponibles deben actualizarse según el estado actual y conservar coherencia con la máquina de estados definida en F1. W03 no debe permitir saltos de estado ni ejecutar procesos que correspondan a otras funcionalidades

En el frontend se deben reutilizar los mismos patrones de tarjetas, estados, tablas, botones y bloques informativos utilizados en W01 y W02 para mantener consistencia visual dentro del módulo

---

## 12. Fuentes de referencia del proyecto

Este documento se elaboró tomando como referencia:

- Página 3 del archivo Figma del Módulo D, pantalla **Detalle del Pedido**
- Especificación de W03 definida para el Hito 1
- Especificación de F1 — Ciclo de vida del pedido
- Especificación de F2 — Anulación de pedidos
- Lineamientos de navegación y frontend del Módulo D

**Referencia Figma:**  
`https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=3-23`

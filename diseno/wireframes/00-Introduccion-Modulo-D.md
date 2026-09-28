# Wireframes — Módulo D: Ventas y Postventa

## Presentación general del prototipo

**Tipo de artefacto:** Documentación general de wireframes  
**Etapa:** Hito 1  
**Módulo:** D — Ventas y Postventa  
**Actores principales:** Gestor / Administrador de ventas  
**Prototipo de referencia:** Página `Prototipo hito 1` en Figma  
**Alcance visual:** Wireframes de baja fidelidad con navegación básica entre pantallas

---

## 1. Presentación

El presente documento introduce el conjunto de wireframes desarrollados para el **Módulo D — Ventas y Postventa**. Su finalidad es servir como punto de partida para la documentación individual de cada pantalla y explicar de manera breve cómo se organiza el flujo general del módulo

Los wireframes representan la estructura funcional del sistema antes de aplicar el diseño visual definitivo. Por ello, el énfasis se encuentra en la ubicación de la información, navegación, acciones principales, estados y relaciones entre los procesos de ventas y postventa

La página **Prototipo hito 1** reúne las pantallas en un mismo espacio de trabajo y permite visualizar su continuidad como un flujo navegable

---

## 2. Objetivo de los wireframes

El objetivo de esta propuesta es validar tempranamente la organización de las pantallas y comprobar que el Gestor pueda recorrer los procesos principales del módulo de forma comprensible

Los wireframes permiten representar:

- Consulta general de ventas y pedidos
- Seguimiento del ciclo de vida del pedido
- Gestión de anulaciones
- Atención de devoluciones y cambios
- Seguimiento de reclamos
- Procesamiento de reembolsos
- Consulta de calificaciones, indicadores y reportes
- Navegación entre las pantallas relacionadas

El prototipo interactivo no representa todavía el producto final ni reemplaza las validaciones del backend

---

## 3. Organización funcional del módulo

El módulo se divide en dos bloques principales:

| Bloque             | Responsabilidad                                                                     |
| ------------------ | ----------------------------------------------------------------------------------- |
| **M1 — Pedidos**   | Gestiona el ciclo de vida del pedido, sus estados, detalle e historial              |
| **M2 — Postventa** | Gestiona anulaciones, devoluciones, reembolsos, calificaciones, reclamos y reportes |

La interfaz del Gestor integra ambos bloques mediante un menú común con acceso a **Dashboard, Pedidos, Postventa y Reportes**

---

## 4. Pantallas documentadas

Cada wireframe cuenta con un archivo individual donde se especifica su contexto, objetivo, estructura, acciones, reglas principales y relación con otras funcionalidades

| Pantalla                            | Descripción                                                 | Documento                          |
| ----------------------------------- | ----------------------------------------------------------- | ---------------------------------- |
| **W01 — Dashboard**                 | Resumen general de ventas, indicadores y alertas operativas | `W01-Dashboard-wireframe.md`       |
| **W02 — Bandeja de pedidos**        | Consulta, filtros y seguimiento general de pedidos          | `W02-Bandeja-de-pedidos.md`        |
| **W03 — Detalle del pedido**        | Información completa, ítems, pago, despacho e historial     | `W03-Detalle-del-pedido.md`        |
| **W04 — Anulaciones**               | Revisión y resolución de solicitudes de anulación           | `W04-Anulaciones.md`               |
| **W05 — Devoluciones y cambios**    | Evaluación de solicitudes, evidencia y resolución postventa | `W05-Devoluciones-y-cambios.md`    |
| **W06 — Reclamos**                  | Atención de reclamos, control SLA, historial y respuesta    | `W06-Reclamos.md`                  |
| **W07 — Reembolsos**                | Seguimiento y ejecución segura de devoluciones de dinero    | `W07-Reembolsos.md`                |
| **W08 — Calificaciones y reportes** | Consulta de CSAT, comentarios, ventas y desempeño comercial | `W08-Calificaciones-y-reportes.md` |

Además, el prototipo incorpora una vista de acceso a **Postventa** que funciona como punto intermedio hacia W05, W06 y W07

---

## 5. Flujo general de navegación

La navegación fue planteada para que el Gestor pueda desplazarse desde una visión general hacia el detalle de cada proceso

```text
W01 Dashboard
│
├── W02 Pedidos
│   └── W03 Detalle del pedido
│       └── W04 Anulaciones
│
├── Postventa
│   ├── W05 Devoluciones y cambios
│   ├── W06 Reclamos
│   └── W07 Reembolsos
│
└── W08 Calificaciones y reportes
```

Las pantallas mantienen relaciones adicionales cuando el proceso lo requiere. Por ejemplo, una devolución puede derivar hacia W07 si corresponde realizar un reembolso y un reclamo puede regresar a W03 cuando existe un pedido asociado

---

## 6. Relación con las funcionalidades del proyecto

| Funcionalidad                           | Pantallas principales |
| --------------------------------------- | --------------------- |
| **F1 — Ciclo de vida del pedido**       | W02, W03              |
| **F2 — Anulación de pedidos**           | W04                   |
| **F3 — Devoluciones y cambios**         | W05                   |
| **F4 — Reembolsos y extornos**          | W07                   |
| **F5 — Calificación de experiencia**    | W08                   |
| **F6 — Reclamos, dashboard y reportes** | W01, W06, W08         |

Esta relación permite que la documentación visual conserve correspondencia con las especificaciones funcionales desarrolladas para el módulo

---

## 7. Criterios utilizados en el diseño

Los wireframes se desarrollaron siguiendo los criterios establecidos para el Hito 1:

- Priorizar estructura, funcionalidad y organización antes que apariencia visual definitiva
- Mantener una distribución simple y consistente entre pantallas
- Mostrar filtros, tablas, estados, botones y áreas de detalle necesarios para comprender cada proceso
- Evitar incorporar elementos que no tengan una función dentro del flujo
- Representar acciones disponibles de acuerdo con el estado del proceso
- Mantener coherencia de navegación entre las diferentes pantallas
- Utilizar datos de ejemplo únicamente para hacer comprensible la estructura

Los colores, textos y valores mostrados sirven como apoyo visual del wireframe y no representan información real de producción

---

## 8. Prototipo interactivo

Las pantallas fueron reunidas en la página **Prototipo hito 1** para representar la continuidad del módulo mediante navegación entre frames

La interacción se utiliza principalmente para demostrar:

- Acceso desde el Dashboard hacia Pedidos, Postventa y Reportes
- Paso desde la bandeja de pedidos hacia el detalle
- Acceso desde el detalle hacia una solicitud de anulación
- Navegación desde Postventa hacia devoluciones, reclamos y reembolsos
- Retorno hacia pantallas relacionadas cuando existe un pedido o expediente de origen

Las acciones internas que no requieren una nueva pantalla pueden permanecer como representación visual durante esta etapa, ya que el objetivo del Hito 1 es validar el flujo y la estructura antes de implementar la lógica funcional

---

## 9. Uso de esta documentación

Este archivo funciona como introducción al conjunto de wireframes. La información específica de cada pantalla debe consultarse en los documentos W01–W08 correspondientes

De esta manera se evita repetir reglas, componentes y explicaciones generales en cada archivo, manteniendo una documentación ordenada y fácil de relacionar con las especificaciones funcionales del proyecto

---

## 10. Referencia del prototipo

**Figma — Prototipo Hito 1:**

https://www.figma.com/design/6GzOHE5mfItYRTMFtHIPiU/Untitled?node-id=129-787&t=1TBNyETO4gqAVJM3-1

# Matriz de pruebas — F6 Reclamos, dashboard y reportes

**Responsable:** Fabrizio  
**Microservicio:** M2 — Postventa  
**Estado:** Plan de verificación  

## 1. Propósito

Esta matriz reúne los casos que deben verificarse durante la implementación de F6. Su objetivo es comprobar que el Libro de Reclamaciones conserva la trazabilidad del expediente y que el dashboard se alimenta de agregados precalculados, sin modificar el contrato de API vigente.

## 2. Referencias

- [F6 — Reclamos, dashboard y reportes](F6-Reclamo,dashboard%20y%20reportes.md)
- [ESP-13 — Registro del Libro de Reclamaciones](../especificaciones/funcionales/ESP-13-registro-libro-reclamos.md)
- [ESP-14 — Formato y evidencia de atención](../especificaciones/funcionales/ESP-14-formato-evidencia-atencion.md)
- [ESP-15 — Tablas agregadas y optimización](../especificaciones/funcionales/ESP-15-tablas-agregadas-optimizacion.md)
- [ESP-16 — Métricas y exportación del dashboard](../especificaciones/funcionales/ESP-16-metricas-exportacion-dashboard.md)

## 3. Casos de prueba funcionales

| ID | Escenario | Tipo de prueba | Resultado esperado |
|---|---|---|---|
| F6-PR-01 | Registrar un reclamo con datos obligatorios válidos. | Integración | Se crea el expediente con estado `REGISTRADO`, código `REC-YYYY-XXXX` y `fechaLimiteSLA` calculada. |
| F6-PR-02 | Registrar una queja sin `pedidoId`. | Integración | El expediente se registra sin exigir un pedido asociado. |
| F6-PR-03 | Registrar un expediente con un motivo fuera del catálogo. | Integración | La API responde `400 Bad Request` y no genera código de seguimiento. |
| F6-PR-04 | Registrar un expediente con datos incompletos del consumidor. | Integración | La API rechaza la solicitud y no persiste el reclamo. |
| F6-PR-05 | Atender un reclamo con respuesta visible y Gestor identificado. | Integración | El estado cambia a `ATENDIDO`; se guardan respuesta, actor y fecha UTC. |
| F6-PR-06 | Intentar atender un reclamo con respuesta vacía. | Integración | La API responde `400 Bad Request` y conserva el estado anterior. |
| F6-PR-07 | Atender un reclamo antes y después de `fechaLimiteSLA`. | Integración | El cumplimiento del SLA queda identificado como cumplido o excedido según corresponda. |
| F6-PR-08 | Consultar un reclamo atendido. | Integración | Se devuelve el estado actual y la `respuestaVisibleCliente` registrada. |

## 4. Casos de prueba de agregados y dashboard

| ID | Escenario | Tipo de prueba | Resultado esperado |
|---|---|---|---|
| F6-PR-09 | Procesar un evento de pedido pagado. | Integración | Se actualiza el agregado del periodo y canal del evento sin recorrer pedidos históricos. |
| F6-PR-10 | Reprocesar un evento ya consumido. | Integración | Los contadores, montos y promedios no se duplican. |
| F6-PR-11 | Consultar métricas por periodo y canal válidos. | Integración | El dashboard devuelve indicadores correspondientes solo a los filtros solicitados. |
| F6-PR-12 | Consultar métricas sin especificar canal. | Integración | El dashboard devuelve la consolidación de todos los canales del periodo. |
| F6-PR-13 | Simular eventos pendientes por caída temporal del consumidor. | Integración | Se muestra la última consolidación válida y los eventos se procesan al recuperar el consumidor. |
| F6-PR-14 | Consultar el dashboard con 5,000 pedidos de prueba. | Performance | La respuesta se construye desde agregados y tarda menos de dos segundos. |

## 5. Evidencia mínima por ejecución

Cada prueba debe conservar como evidencia:

- Identificador del caso de prueba y fecha de ejecución.
- Request, respuesta HTTP y código de estado cuando aplique.
- Datos de entrada usados, sin incluir información personal real.
- Resultado observado y resultado esperado.
- Captura o registro de rendimiento para el caso `F6-PR-14`.

## 6. Criterio de aceptación de la matriz

F6 estará lista para validación cuando todos los casos aplicables estén ejecutados, sus resultados sean conformes y cualquier incidencia tenga un registro de seguimiento antes de solicitar la revisión del equipo.

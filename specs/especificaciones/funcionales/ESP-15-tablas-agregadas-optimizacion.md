# ESP-15 — Tablas agregadas y optimización

**Funcionalidad:** F6 — Reclamos, dashboard y reportes  
**Referencia:** SPEC-21 / RF-15  
**Microservicio:** M2 — Postventa  
**Responsable:** Fabrizio  
**Estado:** En especificación

## 1. Propósito

Mantener proyecciones analíticas precalculadas a partir de eventos de M1 y M2 para que el dashboard consulte indicadores consolidados sin recorrer las tablas transaccionales completas de pedidos y postventa en cada solicitud.

## 2. Alcance

Esta especificación comprende:

- El consumo de eventos relevantes de Ventas y Postventa.
- La actualización incremental de agregados por periodo y canal.
- La conservación de los valores necesarios para responder `GET /api/v2/dashboard/metricas`.
- El procesamiento idempotente de eventos y la recuperación ante retrasos o caídas temporales.
- La exposición de la última información consolidada disponible mientras existan eventos pendientes.

No comprende la modificación directa de tablas pertenecientes a M1 ni el cálculo completo de indicadores desde datos transaccionales durante una consulta del dashboard.

## 3. Fuentes de información

| Origen | Hecho consumido | Resultado analítico |
|---|---|---|
| F1 — Ciclo de vida del pedido | Pedido creado | Incrementa el total de pedidos del periodo y canal correspondientes. |
| F1 — Ciclo de vida del pedido | `pedido pagado` | Actualiza los agregados de ventas del periodo y canal sin recorrer el historial transaccional. |
| F1 — Ciclo de vida del pedido | `pedido anulado` | Incrementa el total de pedidos anulados. |
| F1 — Ciclo de vida del pedido | `pedido entregado` | Incrementa el total de pedidos entregados. |
| F3 — Devoluciones y cambios | Devolución aprobada | Incrementa `devolucionesAprobadas`. |
| F4 — Reembolsos y extornos | Reembolso exitoso | Acumula el monto confirmado en `montoReembolsadoPEN` cuando la moneda es `PEN`. |
| F5 — Calificación de experiencia | Encuesta CSAT válida | Actualiza el promedio de satisfacción del periodo y canal. |
| F6 — Reclamos | Registro, cambio de estado y atención | Actualiza la cantidad de reclamos cuyo SLA continúa pendiente de atención. |

Los eventos deben aportar el identificador del hecho, su timestamp y las dimensiones necesarias para actualizar el agregado correspondiente. Si una dimensión pertenece a otro microservicio, debe viajar en el evento o recuperarse mediante una interfaz autorizada; F6 no realiza lecturas directas sobre bases de datos ajenas.

## 4. Proyecciones agregadas

Los nombres físicos de tablas no están definidos en el repositorio. La implementación puede elegirlos, pero debe mantener como mínimo las siguientes proyecciones lógicas.

### 4.1. Agregado de pedidos

| Dato lógico | Descripción |
|---|---|
| Periodo | Intervalo temporal al que pertenece el hecho consolidado. |
| Canal | Canal del pedido: `MARKETPLACE`, `CHATBOT` o `RETAIL`. |
| Total de pedidos | Cantidad de pedidos únicos registrados en el periodo y canal. |
| Pedidos anulados | Cantidad de pedidos únicos que alcanzaron el estado `ANULADO`. |
| Pedidos entregados | Cantidad de pedidos únicos que alcanzaron el estado `ENTREGADO`. |
| Última actualización | Timestamp UTC del último evento incorporado a la proyección. |

Esta proyección suministra los campos `pedidos.total`, `pedidos.anulados` y `pedidos.entregados` del contrato del dashboard.

### 4.2. Agregado de postventa

| Dato lógico | Descripción |
|---|---|
| Periodo | Intervalo temporal al que pertenece el hecho consolidado. |
| Canal | Canal asociado al pedido o expediente cuando corresponda. |
| Devoluciones aprobadas | Cantidad de expedientes de devolución que alcanzaron `APROBADA`. |
| Monto reembolsado PEN | Suma de reembolsos con estado `EXITOSO` y moneda `PEN`. |
| Suma de puntuaciones CSAT | Acumulado interno de puntuaciones válidas entre 1 y 5. |
| Cantidad de respuestas CSAT | Número de encuestas válidas incorporadas al agregado. |
| Reclamos pendientes de SLA | Cantidad de reclamos aún no atendidos cuyo plazo debe seguir siendo controlado. |
| Última actualización | Timestamp UTC del último evento incorporado a la proyección. |

`csatPromedio` se obtiene dividiendo la suma de puntuaciones entre la cantidad de respuestas válidas. Se mantienen ambos acumuladores para evitar calcular promedios de promedios.

Esta proyección suministra `postventa.devolucionesAprobadas`, `postventa.montoReembolsadoPEN`, `postventa.csatPromedio` y `postventa.reclamosPendientesSLA`.

### 4.3. Control de eventos procesados

El sistema debe conservar evidencia suficiente para reconocer un evento ya aplicado. El mecanismo físico no está definido en el repositorio, pero debe permitir:

- Identificar de forma estable cada evento procesado.
- Evitar que un reintento incremente dos veces un contador o monto.
- Registrar el resultado y timestamp UTC del procesamiento.
- Reintentar eventos pendientes después de una caída sin perderlos ni corromper los agregados.

## 5. Reglas de actualización

1. Cada evento válido actualiza únicamente la combinación de periodo y canal que le corresponde.
2. Un pedido, devolución, reembolso, encuesta o reclamo no puede aportar dos veces el mismo efecto por el reintento de un evento.
3. Los contadores representan entidades únicas y no el número de mensajes recibidos.
4. `montoReembolsadoPEN` incorpora únicamente reembolsos confirmados como `EXITOSO` y expresados en `PEN`.
5. `csatPromedio` incorpora únicamente puntuaciones válidas de 1 a 5 y utiliza suma y cantidad acumuladas.
6. `reclamosPendientesSLA` incluye reclamos que todavía requieren atención y excluye los que alcanzaron `ATENDIDO`.
7. Los timestamps se almacenan en UTC de acuerdo con las convenciones generales de `specs/api-contract.md`.
8. Los agregados se actualizan de forma incremental; una consulta del dashboard no debe desencadenar un recorrido completo de ventas o expedientes de postventa.
9. Una transición inválida que no modifica la entidad de origen tampoco debe modificar los agregados.

## 6. Consistencia eventual y recuperación

- Si un evento llega con retraso, el dashboard continúa mostrando la última consolidación válida disponible.
- Cuando el consumidor se recupera, procesa los eventos pendientes y actualiza las proyecciones correspondientes.
- Un evento atrasado se atribuye al periodo del hecho informado por su timestamp, no al momento en que fue reintentado.
- El procesamiento fuera de orden no debe disminuir contadores válidos ni devolver una entidad a un estado analítico anterior.
- La recuperación no debe duplicar contadores, montos ni respuestas CSAT.

## 7. Consulta de los agregados

Los agregados son la fuente de lectura de `GET /api/v2/dashboard/metricas`. La consulta combina las proyecciones del periodo solicitado y aplica opcionalmente el filtro de canal definido en el contrato.

El resultado debe poder construir esta estructura sin consultar todas las operaciones transaccionales:

```json
{
  "periodo": {
    "desde": "2026-09-01",
    "hasta": "2026-09-30"
  },
  "pedidos": {
    "total": 5420,
    "anulados": 115,
    "entregados": 4980
  },
  "postventa": {
    "devolucionesAprobadas": 45,
    "montoReembolsadoPEN": 5890.50,
    "csatPromedio": 4.62,
    "reclamosPendientesSLA": 3
  }
}
```

## 8. Validaciones

1. Solo se procesan eventos reconocidos y con la información mínima necesaria para determinar su identidad, timestamp y dimensión de agregación.
2. Un evento duplicado debe reconocerse y finalizar sin aplicar nuevamente su efecto.
3. Un evento incompleto no debe alterar ninguna proyección; debe quedar registrado para diagnóstico o reintento controlado.
4. Un reembolso que no esté en estado `EXITOSO` no incrementa `montoReembolsadoPEN`.
5. Una encuesta con puntuación fuera del rango de 1 a 5 no modifica el agregado de CSAT.
6. La actualización de la proyección y el registro del evento procesado deben comportarse como una única operación consistente.

## 9. Requisitos no funcionales

- **Performance (RNF-01):** la consulta del dashboard debe responder en menos de 2 segundos con un conjunto reproducible de al menos 5,000 pedidos.
- **Disponibilidad (RNF-05):** una caída temporal del consumidor no debe provocar pérdida de eventos; al recuperarse, debe procesar lo pendiente.
- **Aislamiento (RNF-07):** F6 no puede leer ni modificar directamente las bases de datos de M1 u otros componentes; recibe información mediante APIs o eventos.
- **Idempotencia (RNF-08):** un mismo evento produce un solo efecto sobre cada agregado.
- **Trazabilidad:** cada proyección debe permitir conocer al menos su última actualización y distinguir eventos procesados de eventos pendientes o fallidos.

## 10. Criterios de aceptación

### CA-01. Actualización incremental por evento

- **DADO** un evento válido `pedido pagado` publicado por F1.
- **CUANDO** F6 lo consume.
- **ENTONCES** actualiza el agregado del periodo y canal correspondientes sin recorrer las tablas transaccionales completas.

### CA-02. Métricas de pedidos

- **DADO** un conjunto de pedidos creados, anulados y entregados en distintos periodos y canales.
- **CUANDO** sus eventos son procesados.
- **ENTONCES** los agregados reflejan los totales únicos correctos para cada combinación de periodo y canal.

### CA-03. Métricas de postventa

- **DADO** devoluciones aprobadas, reembolsos exitosos en PEN, encuestas CSAT válidas y reclamos pendientes.
- **CUANDO** F6 procesa los hechos correspondientes.
- **ENTONCES** actualiza correctamente `devolucionesAprobadas`, `montoReembolsadoPEN`, `csatPromedio` y `reclamosPendientesSLA`.

### CA-04. Idempotencia

- **DADO** un evento ya procesado.
- **CUANDO** el mismo evento se recibe nuevamente.
- **ENTONCES** el sistema reconoce el reintento y no duplica contadores, montos ni puntuaciones.

### CA-05. Recuperación ante retraso

- **DADO** un consumidor temporalmente inactivo con eventos pendientes.
- **CUANDO** el Gestor consulta el dashboard antes de la recuperación.
- **ENTONCES** se muestra la última consolidación válida sin datos corruptos; al recuperarse el consumidor, incorpora los eventos pendientes una sola vez.

### CA-06. Ausencia de escaneo transaccional

- **DADO** un conjunto de prueba con al menos 5,000 pedidos.
- **CUANDO** se consultan las métricas del dashboard.
- **ENTONCES** la respuesta se construye desde las proyecciones agregadas y no mediante un recorrido completo de las ventas.

## 11. Criterio de completitud

ESP-15 se considera completa cuando las métricas exigidas por el contrato se mantienen incrementalmente por periodo y canal, los reintentos no duplican efectos, una caída temporal puede recuperarse sin pérdida y el dashboard obtiene sus valores exclusivamente desde agregados precalculados.

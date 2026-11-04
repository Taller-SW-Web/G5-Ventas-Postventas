# ESP-16 — Métricas y exportación del dashboard

**Funcionalidad:** F6 — Reclamos, dashboard y reportes  
**Referencia:** SPEC-22 / RF-16  
**Microservicio:** M2 — Postventa  
**Responsable:** Fabrizio  
**Estado:** En especificación

## 1. Propósito

Permitir que un usuario administrador consulte indicadores consolidados de Ventas y Postventa por periodo y canal, y exporte un reporte que reproduzca exactamente los datos visibles con los filtros aplicados.

## 2. Alcance contractual

`specs/api-contract.md` define el endpoint de consulta de métricas, sus filtros y su respuesta. El contrato no define un endpoint de exportación: la exportación de esta entrega es un **CSV generado en el navegador** con los filtros y valores visibles (§8, decisión 2026-11-04), sin ruta HTTP propia.

Por esa razón:

- Esta especificación documenta la consulta exactamente como está contratada.
- La exportación se especifica como comportamiento funcional del dashboard.
- No se inventa una ruta HTTP para exportar; el único formato de esta entrega es el CSV de §8.
- Si la exportación requiere un nuevo endpoint de backend, este deberá incorporarse primero a `specs/api-contract.md` y después reflejarse aquí.

Aunque F6 menciona vistas por vendedor y producto, el contrato vigente solo admite filtros por periodo y canal. Esas dimensiones no forman parte del endpoint actual hasta que sean añadidas formalmente al contrato.

## 3. Consulta de métricas

- **Método y endpoint:** `GET /api/v2/dashboard/metricas`
- **Autenticación:** `Authorization: Bearer <token_admin>`
- **Resultado exitoso:** `200 OK`
- **Fuente de datos:** agregados precalculados mantenidos por ESP-15.

### 3.1. Parámetros de consulta

| Parámetro | Tipo | Obligatorio | Regla |
|---|---|---:|---|
| `desde` | fecha | Sí | Inicio del periodo consultado, con formato `YYYY-MM-DD`. |
| `hasta` | fecha | Sí | Fin del periodo consultado, con formato `YYYY-MM-DD`. Debe ser igual o posterior a `desde`. |
| `canal` | string | No | Filtro opcional: `MARKETPLACE`, `CHATBOT` o `RETAIL`. |

Cuando `canal` no se envía, la consulta devuelve la consolidación del periodo para todos los canales. Cuando se informa, todos los indicadores deben corresponder únicamente a ese canal.

### 3.2. Ejemplo de consulta

```http
GET /api/v2/dashboard/metricas?desde=2026-09-01&hasta=2026-09-30&canal=CHATBOT
Authorization: Bearer <token_admin>
```

## 4. Métricas de respuesta

| Campo | Significado |
|---|---|
| `periodo.desde` | Fecha inicial aplicada a la consulta. |
| `periodo.hasta` | Fecha final aplicada a la consulta. |
| `pedidos.total` | Total de pedidos únicos consolidados para el periodo y canal solicitado. |
| `pedidos.anulados` | Total de pedidos únicos que alcanzaron `ANULADO`. |
| `pedidos.entregados` | Total de pedidos únicos que alcanzaron `ENTREGADO`. |
| `postventa.devolucionesAprobadas` | Total de devoluciones que alcanzaron el estado `APROBADA`. |
| `postventa.montoReembolsadoPEN` | Suma de reembolsos exitosos expresados en `PEN`. |
| `postventa.csatPromedio` | Promedio de puntuaciones CSAT válidas, calculado a partir de valores entre 1 y 5. |
| `postventa.reclamosPendientesSLA` | Cantidad de reclamos aún no atendidos cuyo SLA continúa bajo seguimiento. |

## 5. Ejemplo de response

### `200 OK`

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

## 6. Reglas de consulta

1. Solo un usuario con token administrativo válido puede consultar el dashboard.
2. `desde` y `hasta` delimitan el mismo periodo mostrado en la respuesta.
3. `desde` no puede ser posterior a `hasta`.
4. Si se proporciona `canal`, debe pertenecer al catálogo `MARKETPLACE | CHATBOT | RETAIL`.
5. Todos los indicadores de una respuesta deben utilizar el mismo periodo y filtro de canal.
6. La consulta se resuelve desde las proyecciones de ESP-15 y no mediante un escaneo completo de las tablas transaccionales.
7. Si existen eventos aún pendientes de procesamiento, se muestra la última consolidación válida disponible, sin fabricar ni mezclar valores parciales corruptos.
8. Los errores deben seguir la estructura general definida en `specs/api-contract.md`.

## 7. Presentación en el dashboard

El panel del Gestor debe:

- Permitir seleccionar `desde` y `hasta`.
- Permitir seleccionar opcionalmente un canal.
- Mostrar las métricas de pedidos y postventa recibidas del endpoint.
- Mantener visibles los filtros aplicados para que el usuario conozca el alcance de los indicadores.
- Presentar estados de carga y errores claros sin sustituirlos por valores ficticios.
- Permitir iniciar la exportación de los indicadores actualmente mostrados.

### 7.1. Bases de cálculo de las tasas (definidas 2026-11-02)

El mockup 01 (§6 y §10.3) pide definir la base de cada indicador sin asumir que todos usan el mismo conjunto de pedidos. Hay dos bases de conteo y **cada tasa usa una sola**, con el mismo periodo y canal en numerador y denominador:

| Base | Fuente | Qué cuenta |
|---|---|---|
| Cohorte del periodo | `api-ventas.md` 1.14 (`pedidosTotal`, `pedidosAnulados`, `pedidosEntregados`) | Pedidos de venta **creados** entre `desde` y `hasta`, con su estado actual (sin los que siguen en `CREADO`). |
| Hechos del periodo | 2.12 (`pedidos.*`, `postventa.devolucionesAprobadas`) | Pagos, anulaciones, entregas y aprobaciones **ocurridos** entre `desde` y `hasta`, por la fecha del hecho (ESP-15 §6). |

| Indicador | Cálculo | Base |
|---|---|---|
| Tasa de anulación | `pedidosAnulados / pedidosTotal` | Cohorte (1.14) |
| Distribución de pedidos y conteos de pedidos de Reportes | `pedidosTotal`, `pedidosEntregados`, `pedidosAnulados` (también por canal, con 1.14 filtrado por canal) | Cohorte (1.14) |
| Tasa de devolución | `postventa.devolucionesAprobadas / pedidos.entregados` | Hechos (2.12) |

- La tasa de devolución **no** usa la cohorte: las devoluciones se aprueban días o semanas después de la entrega, así que una aprobación del periodo casi nunca pertenece a un pedido creado en el mismo periodo. Mezclar ambas bases daba tasas sin sentido (denominador vacío o un numerador de otra cohorte).
- Es una **razón de actividad**, no una tasa de cohorte: si en el periodo se aprueban devoluciones de pedidos entregados antes, puede superar el 100%. Se muestra tal cual, junto con sus dos cifras ("3 aprobadas / 2 entregas del periodo"); no se recorta.
- Una tasa de devolución por cohorte (aprobadas de los pedidos entregados en el periodo) exigiría que 2.12 informe la fecha de entrega del pedido de cada devolución; no está en el contrato y queda como mejora a acordar.
- Las fechas `desde`/`hasta` son días UTC en ambas fuentes (1.14 y 2.12), conforme a la convención del contrato.
- "Reclamos abiertos" del Dashboard cuenta los reclamos no `ATENDIDO` de hoy, de todos los canales (2.10 no filtra por canal); no es `reclamosPendientesSLA` de 2.12, que se limita a los que vencen dentro del periodo.

#### 7.1.1. Qué cuenta `pedidos` en 2.12 y en 1.14 (definición cerrada, 2026-11-04)

- **1.14 (cohorte):** pedidos de venta creados en el periodo, con su estado actual, según las reglas vigentes de `api-ventas.md` 1.14. Es la **fuente de las pantallas**: conteos de pedidos, distribución por estado (Dashboard y Reportes), tasa de anulación y conteos exportados.
- **2.12 (actividad):** hechos financieros y operativos del periodo por la fecha del hecho. `pedidos.total` conserva por compatibilidad el significado de **pedidos pagados en el periodo**, no de pedidos creados; `pedidos.anulados` y `pedidos.entregados` son anulaciones y entregas ocurridas en el periodo.
- Los contadores de hechos de 2.12 **no forman una distribución de estados** y `anulados / total` de 2.12 **no debe usarse como tasa de anulación**: un pedido anulado antes de pagarse suma a `anulados` y nunca a `total`, y un pedido creado el 31/10 y pagado el 01/11 está en la cohorte de octubre (1.14) y en el `total` de noviembre (2.12).
- Ejemplo comprobado en local el 2026-11-04, un día, canal Marketplace: P1 creado y pagado, P2 creado y anulado antes del cobro. 1.14 da `pedidosTotal` 2 y `pedidosAnulados` 1 (tasa 50 %); 2.12 da `total` 1 y `anulados` 1, que como "tasa" daría 100 %.
- De 2.12 el frontend solo usa `pedidos.entregados` (base de la tasa de devolución, §7.1) y los indicadores de `postventa`.
- `agregado_metricas.pedidos_anulados_sin_pago` existe en la base pero no se usa (ESP-15 §4.1); no alimenta ningún indicador.

## 8. Exportación del reporte

La exportación debe cumplir las siguientes reglas funcionales:

1. Debe usar exactamente los mismos filtros `desde`, `hasta` y `canal` aplicados a la consulta visible.
2. Debe incluir exactamente las métricas mostradas: periodo, totales de pedidos, anulados, entregados, devoluciones aprobadas, monto reembolsado en PEN, CSAT promedio y reclamos pendientes de SLA.
3. Los valores exportados deben proceder de la misma respuesta o consolidación que el usuario revisó antes de exportar, evitando recalcularlos desde las tablas transaccionales.
4. La exportación no debe alterar los filtros ni incorporar datos de otros periodos o canales.
5. Si la consulta visible cambia antes de iniciar una nueva exportación, el reporte debe corresponder al nuevo conjunto de filtros.
6. La exportación debe estar disponible únicamente para el mismo perfil administrativo autorizado a consultar el dashboard.
7. Formato de esta entrega (decisión 2026-11-04): un **CSV generado en el navegador** a partir de los filtros y valores visibles. No hay endpoint de exportación ni otros formatos (XLSX, PDF).

**Formato del CSV (implementado en `reportes.ts`, `csvReporte`):**

- Se genera en el navegador con la misma consulta que está en pantalla; no llama al backend ni recalcula nada.
- UTF-8 con BOM, separador `;` y fin de línea CRLF, para que Excel en español lo abra con columnas y tildes.
- Encabezado: `Periodo`, `Desde`, `Hasta`, `Canal` y `Última actualización`; luego una fila en blanco y la tabla `Grupo;Indicador;Valor` con los 7 indicadores en el orden de la pantalla.
- Mismos valores y decimales que la pantalla: conteos enteros (los de pedidos son la cohorte de 1.14, §7.1), monto reembolsado y CSAT con 2 decimales sin separador de miles, y `Sin encuestas` cuando no hay CSAT.
- Nombre del archivo: `reporte-ventas-postventa_<desde>_<hasta>_<canal>.csv`.

## 9. Rendimiento y disponibilidad

- La consulta debe responder en menos de 2 segundos con un dataset reproducible de al menos 5,000 pedidos.
- La medición debe realizarse utilizando los agregados precalculados de ESP-15.
- Una caída temporal del consumidor de eventos no debe inutilizar el dashboard; se presenta la última consolidación válida mientras se procesa lo pendiente.
- La exportación no debe provocar un recálculo completo de ventas ni modificar los agregados.

## 10. Validaciones

1. Verificar que el token corresponde a un usuario administrador.
2. Verificar que `desde` y `hasta` estén presentes y tengan el formato esperado.
3. Verificar que `desde` no sea posterior a `hasta`.
4. Verificar que `canal`, cuando se informe, pertenezca al catálogo permitido.
5. Verificar que todas las métricas devueltas correspondan a los mismos filtros.
6. Verificar que el reporte exportado coincida exactamente con los indicadores visibles.
7. No exponer filtros de vendedor o producto mientras no estén definidos en `specs/api-contract.md`.
8. No implementar ni documentar una ruta de exportación hasta que forme parte del contrato de API.

## 11. Criterios de aceptación

### CA-01. Consulta por periodo

- **DADO** que existen agregados para varios periodos.
- **CUANDO** el administrador consulta `GET /api/v2/dashboard/metricas` con `desde` y `hasta` válidos.
- **ENTONCES** recibe `200 OK` con indicadores correspondientes únicamente al periodo solicitado.

### CA-02. Filtro por canal

- **DADO** que existen agregados para `MARKETPLACE`, `CHATBOT` y `RETAIL`.
- **CUANDO** el administrador incluye un canal válido.
- **ENTONCES** todos los indicadores corresponden únicamente a ese canal y al periodo solicitado.

### CA-03. Consulta sin canal

- **DADO** un periodo con actividad en varios canales.
- **CUANDO** el administrador omite el parámetro `canal`.
- **ENTONCES** el dashboard muestra la consolidación del periodo para todos los canales.

### CA-04. Validación de filtros

- **DADO** un intervalo donde `desde` es posterior a `hasta` o un canal no permitido.
- **CUANDO** se intenta consultar el dashboard.
- **ENTONCES** la solicitud se rechaza mediante el estándar de error del contrato y no se entregan métricas correspondientes a filtros distintos.

### CA-05. Exportación consistente

- **DADO** un conjunto de indicadores visible con filtros aplicados.
- **CUANDO** el administrador solicita exportarlo.
- **ENTONCES** el reporte contiene exactamente el periodo, canal y métricas mostrados en pantalla.

### CA-06. Rendimiento

- **DADO** un dataset reproducible con al menos 5,000 pedidos.
- **CUANDO** el administrador consulta el dashboard.
- **ENTONCES** la respuesta se obtiene desde agregados precalculados en menos de 2 segundos.

### CA-07. Última consolidación disponible

- **DADO** que existen eventos pendientes por una caída temporal del consumidor.
- **CUANDO** el administrador consulta el dashboard.
- **ENTONCES** se presenta la última consolidación válida sin error ni datos corruptos y los eventos pendientes se incorporan cuando el consumidor se recupera.

## 12. Criterio de completitud

ESP-16 se considera completa cuando el endpoint contractual filtra correctamente por periodo y canal, devuelve todas las métricas documentadas desde agregados, cumple el objetivo de rendimiento y la exportación reproduce exactamente los datos visibles. La implementación técnica de la exportación solo queda cerrada cuando su mecanismo y formato estén definidos en `specs/api-contract.md`.

# Funcionalidad 6: Reclamos, dashboard y reportes

**Responsable:** Fabrizio
**Estado:** En especificación
**Actor principal:** Cliente (registra reclamo) y Gestor (atiende/analiza)
**Microservicio:** M2 — Postventa
**Lineamiento del curso:** "Gestión de reclamos y envío de formato de reclamo" + "Dashboard y reportes de ventas por canal, vendedor, productos, etc." (Módulo D — Ventas y Postventa)

## 1. Contexto

F6 unifica dos responsabilidades relacionadas: (1) la gestión operativa del **Libro de Reclamaciones**, con control de SLA legal, y (2) la vista analítica del Gestor (dashboard y reportes), construida a partir de agregados que F6 mantiene actualizados escuchando eventos de M1 y M2 — nunca recalculando toda la base transaccional en cada consulta.

## 2. Propósito

Registrar y atender reclamos/quejas dentro del plazo legal, y proporcionar al Gestor una lectura consolidada y rápida de ventas/postventa mediante agregados precalculados.

## 3. Alcance

Incluye:
- Registro del reclamo con código único, motivo tipificado y cálculo automático del SLA.
- Atención del reclamo por el Gestor, con respuesta formal visible al cliente.
- Consulta pública del estado por el cliente.
- Mantenimiento de agregados a partir de eventos de M1/M2.
- Indicadores, filtros, gráficos/tablas y exportación de reportes.

**No incluye:** recalcular métricas recorriendo toda la base transaccional en cada consulta — el dashboard siempre se sirve desde agregados precalculados.

## 4. Libro de Reclamaciones (Requisito A10)

### 4.1. Ciclo de vida y máquina de estados del reclamo

`REGISTRADO → EN PROCESO → ATENDIDO` (rama alterna opcional: `DERIVADO`, si escala a mediación externa).

- **REGISTRADO:**
  - El consumidor o canal genera el reclamo/queja.
  - Se asigna un código único correlativo (`REC-YYYY-XXXX`).
  - Se vincula de forma opcional a un `pedidoId`.
  - Se calcula y fija automáticamente el plazo legal improrrogable: **15 días hábiles** (SLA normado por Indecopi), registrando la fecha límite en `fechaLimiteSLA`.
- **EN PROCESO:** el Gestor toma el expediente en su bandeja de atención para análisis y recopilación de evidencias.
- **ATENDIDO:** el Gestor emite la resolución formal. Es **obligatorio** completar el campo `respuestaVisibleCliente` para que el consumidor pueda consultarlo desde cualquier canal.

### 4.2. Catálogo de motivos tipificados (`motivo`)

Para estandarizar el registro y facilitar la agregación en el dashboard, se definen los siguientes motivos obligatorios:

1. `INCUMPLIMIENTO_PLAZO_ENTREGA`: pedido entregado fuera de la fecha/horario pactado.
2. `PRODUCTO_DEFECTUOSO_O_INCORRECTO`: averías de fábrica, producto equivocado o faltante.
3. `COBRO_INDEBIDO_O_NO_RECONOCIDO`: discrepancias en montos cobrados o cargos duplicados.
4. `ATENCION_INADECUADA`: trato deficiente por soporte, transportista o canal de atención.
5. `INCUMPLIMIENTO_GARANTIA`: desacuerdo o demora en la aplicación de garantías postventa.

### 4.3. Flujo de respuesta visible al cliente

1. **Consulta del cliente:** el consumidor puede consultar el estado de su reclamo en cualquier momento usando su código de seguimiento (`REC-YYYY-XXXX`) y número de documento.
2. **Cierre por Gestor:** al dictaminar la respuesta, el sistema valida que el campo `respuestaVisibleCliente` no sea nulo ni vacío.
3. **Auditoría de SLA:** el sistema registra la fecha y hora exacta de respuesta en UTC y calcula automáticamente si se cumplió o se excedió el SLA de 15 días hábiles, alimentando los indicadores del dashboard administrativo.

## 5. Precondiciones, dependencias y resultados

### 5.1. Precondiciones

- Para un reclamo: datos mínimos de contacto, detalle y motivo tipificado; el pedido asociado es opcional.
- Para reportes: los agregados deben estar disponibles y los filtros solicitados deben ser válidos.

### 5.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| M1 — Pedidos (F1) | Publica eventos (`pedido.pagado`, `pedido.anulado`, `pedido.entregado`) que F6 consume para sus agregados. |
| M2 — Postventa (F2 a F5) | Publican eventos relevantes (anulaciones, devoluciones, reembolsos, calificaciones) que también alimentan los agregados. |
| Seguridad (G) | Aporta datos de contacto y rol del cliente/Gestor. |
| Canales A/B/C | Punto de entrada para que el cliente registre un reclamo. |

### 5.3. Resultados

- Un reclamo válido queda registrado con código único, motivo tipificado y `fechaLimiteSLA`.
- El Gestor responde y actualiza el estado del reclamo hasta `ATENDIDO`, con `respuestaVisibleCliente` obligatorio.
- El cliente puede consultar el estado de su reclamo en cualquier momento con su código y documento.
- El dashboard se sirve desde agregados actualizados por periodo, canal, vendedor y producto.

## 6. Requisitos y criterios de aceptación automatizables

### RF-13. Registro del libro de reclamos

El sistema DEBE registrar un reclamo con código único, pedido opcional, motivo tipificado y SLA calculado automáticamente.

#### CA-01. Registro exitoso con código único
- **DADO** un cliente que envía un reclamo con datos de contacto, motivo tipificado y detalle válidos.
- **CUANDO** se registra.
- **ENTONCES** el sistema asigna un código único (`REC-YYYY-XXXX`), fija el estado `REGISTRADO` y calcula `fechaLimiteSLA` a 15 días hábiles.

#### CA-02. Registro sin pedido asociado
- **DADO** un reclamo que no está vinculado a ningún pedido.
- **CUANDO** contiene los datos mínimos requeridos.
- **ENTONCES** el sistema lo registra igualmente, sin exigir un `pedidoId`.

#### CA-03. Rechazo por motivo no tipificado
- **DADO** un reclamo cuyo `motivo` no pertenece al catálogo definido.
- **CUANDO** se intenta registrar.
- **ENTONCES** el sistema rechaza el registro y no genera código hasta que se use un motivo válido.

### RF-14. Formato y evidencia de atención

El sistema DEBE exigir una respuesta visible al cliente al atender el reclamo, y auditar el cumplimiento del SLA con fecha y hora exactas.

#### CA-04. Respuesta del Gestor dentro de plazo
- **DADO** un reclamo `EN PROCESO` con `respuestaVisibleCliente` completado antes de `fechaLimiteSLA`.
- **CUANDO** el Gestor cierra el reclamo.
- **ENTONCES** el sistema lo transiciona a `ATENDIDO`, registra la fecha/hora en UTC y marca el SLA como cumplido.

#### CA-05. Rechazo por respuesta vacía
- **DADO** un reclamo que el Gestor intenta cerrar sin completar `respuestaVisibleCliente`.
- **CUANDO** se intenta la transición a `ATENDIDO`.
- **ENTONCES** el sistema rechaza el cierre y exige el campo antes de continuar.

#### CA-06. Consulta pública del estado
- **DADO** un reclamo registrado con código `REC-YYYY-XXXX`.
- **CUANDO** el cliente consulta con ese código y su número de documento.
- **ENTONCES** el sistema retorna el estado actual y, si ya fue `ATENDIDO`, la respuesta visible.

#### CA-07. SLA excedido
- **DADO** un reclamo cuya respuesta se registra después de `fechaLimiteSLA`.
- **CUANDO** se calcula el cumplimiento.
- **ENTONCES** el sistema marca el SLA como excedido y este dato queda disponible para el dashboard.

### RF-15. Tablas agregadas y optimización

El sistema DEBE mantener agregados analíticos actualizados por evento, evitando escaneos pesados sobre la base transaccional.

#### CA-08. Actualización de agregados por evento
- **DADO** un evento `pedido.pagado` publicado por F1.
- **CUANDO** F6 lo consume.
- **ENTONCES** el sistema actualiza el agregado correspondiente (por ejemplo, ventas por canal/periodo) sin recorrer toda la base transaccional.

#### CA-09. Agregado temporalmente retrasado
- **DADO** que un evento llega con retraso o el consumidor estuvo temporalmente caído.
- **CUANDO** el Gestor consulta el dashboard durante ese lapso.
- **ENTONCES** el sistema muestra la última actualización disponible, y procesa el evento pendiente en cuanto el consumidor se recupera — sin mostrar un error ni datos corruptos.

### RF-16. Métricas y exportación del dashboard

El sistema DEBE permitir filtrar temporalmente/por canal y exportar reportes del dashboard, con un rendimiento garantizado.

#### CA-10. Filtro por periodo y canal
- **DADO** agregados disponibles para varios periodos y canales.
- **CUANDO** el Gestor filtra el dashboard por un periodo y canal específicos.
- **ENTONCES** el sistema muestra únicamente los indicadores correspondientes a ese filtro.

#### CA-11. Exportación de reporte
- **DADO** un conjunto de indicadores filtrados en el dashboard.
- **CUANDO** el Gestor solicita exportar el reporte.
- **ENTONCES** el sistema genera el archivo de reporte con exactamente los datos mostrados en pantalla.

#### CA-12. Rendimiento del dashboard
- **DADO** una base de prueba con al menos 5,000 pedidos.
- **CUANDO** el Gestor consulta el dashboard.
- **ENTONCES** el sistema responde en menos de 2 segundos.

## 7. Frontend

Superficie visible dentro del panel del Gestor (más el formulario de reclamo y la consulta pública que ve el cliente):

| Elemento | Responsabilidad |
|---|---|
| Formulario de reclamo (cliente) | Captura motivo tipificado, detalle, contacto y `pedidoId` opcional. |
| Consulta pública (cliente) | Verifica estado del reclamo con código `REC-YYYY-XXXX` + número de documento. |
| Bandeja de reclamos (Gestor) | Lista por estado y urgencia de SLA, con acceso al detalle y respuesta. |
| Formulario de cierre (Gestor) | Exige `respuestaVisibleCliente` antes de permitir la transición a `ATENDIDO`. |
| Dashboard | Indicadores, gráficos/tablas filtrables por periodo, canal, vendedor y producto. |
| Exportación de reportes | Botón de descarga del reporte según los filtros aplicados. |

## 8. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Registro de reclamos | Genera código único (`REC-YYYY-XXXX`), valida motivo tipificado y calcula `fechaLimiteSLA`. |
| Motor de SLA | Calcula y mantiene visible la fecha límite y su estado (a tiempo, próximo a vencer, vencido). |
| Servicio de atención | Gestiona la transición `REGISTRADO → EN PROCESO → ATENDIDO`/`DERIVADO`, exigiendo `respuestaVisibleCliente`. |
| Consumidor de eventos de M1/M2 | Escucha eventos relevantes de todas las funcionalidades del módulo para mantener los agregados. |
| Servicio de agregados | Mantiene tablas resumen por periodo/canal/vendedor/producto, consultadas por el dashboard. |
| Exportador de reportes | Genera el archivo de reporte según los filtros solicitados. |

## 9. Requisitos no funcionales

- **Performance (RNF-01):** el dashboard responde en menos de 2 segundos con al menos 5,000 pedidos de prueba.
- **Seguridad (RNF-02):** solo el consumidor identificado o un canal autenticado registra un reclamo en su nombre.
- **Trazabilidad (RNF-03):** el código único, `fechaLimiteSLA` y la fecha/hora de respuesta (UTC) quedan fijados de forma inmutable.
- **Usabilidad (RNF-04):** la consulta pública del cliente es simple (solo código + documento), sin cuenta ni autenticación compleja.
- **Uso de agregados precalculados:** el dashboard nunca recalcula recorriendo toda la base transaccional en cada consulta.
- **Disponibilidad (RNF-05):** el consumidor de eventos se recupera automáticamente ante una caída temporal, sin perder eventos.

## 10. Fuera de alcance

- **Resolución de la causa raíz del reclamo:** F6 gestiona registro, SLA y respuesta; no ejecuta acciones correctivas de otras funcionalidades (por ejemplo, iniciar una devolución se hace por separado en F3).
- **Cálculo en tiempo real sobre datos crudos:** el dashboard siempre se sirve desde agregados, nunca desde consultas directas sobre toda la base transaccional.
- **Mediación externa formal:** la rama `DERIVADO` solo marca la escalación; el proceso de mediación en sí no es parte de este sistema.

## 11. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 a CA-03 | Registrar reclamos válidos, sin pedido y con motivo no tipificado. | Unitaria e integración | Código `REC-YYYY-XXXX` generado con `fechaLimiteSLA` correcta, o rechazo según corresponda. |
| CA-04 a CA-07 | Simular respuesta del Gestor dentro y fuera de plazo, cierre sin respuesta y consulta pública. | Integración | Estado y SLA calculados correctamente; cierre bloqueado sin `respuestaVisibleCliente`. |
| CA-08 y CA-09 | Publicar eventos de M1/M2 y simular un consumidor temporalmente caído. | Integración | Agregados actualizados; última data disponible mostrada sin error durante el retraso. |
| CA-10 a CA-12 | Filtrar, exportar y cargar 5,000 pedidos de prueba para medir tiempo de respuesta. | Integración y performance | Filtros correctos, exportación coincidente, respuesta menor a 2 segundos. |

## 12. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-12` están implementados y verificados, incluyendo la prueba de performance con 5,000 pedidos.
- Reclamo y queja quedan siempre diferenciados y tipificados según el catálogo de 5 motivos.
- Todo reclamo `ATENDIDO` tiene una `respuestaVisibleCliente` no vacía y su SLA (cumplido/excedido) calculado en UTC.
- El cliente puede consultar el estado de su reclamo en cualquier momento con código + documento, sin exponer reclamos ajenos.
- El dashboard nunca depende de un recálculo completo sobre la base transaccional.
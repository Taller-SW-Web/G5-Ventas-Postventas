# Especificación F6: Reclamos, dashboard y reportes

**Responsable:** Fabrizio
**Estado:** En especificación
**Actor principal:** Cliente (registra reclamo) y Gestor (atiende/analiza)
**Microservicio:** M2 — Postventa
**Lineamiento del curso:** "Gestión de reclamos y envío de formato de reclamo" + "Dashboard y reportes de ventas por canal, vendedor, productos, etc." (Módulo D — Ventas y Postventa)

## 1. Contexto

F6 unifica dos responsabilidades relacionadas: (1) la gestión operativa de reclamos y quejas del cliente, con control de SLA, y (2) la vista analítica del Gestor (dashboard y reportes), construida a partir de agregados que F6 mantiene actualizados escuchando eventos de M1 y M2 — nunca recalculando toda la base transaccional en cada consulta.

## 2. Propósito

Unificar la operación de reclamos con la vista analítica del administrador, proporcionando control de SLA y una lectura consolidada de ventas/postventa mediante agregados.

## 3. Alcance

Incluye:
- Registro y atención de reclamo/queja, con código único, formato, respuesta y SLA.
- Indicadores, filtros, gráficos/tablas y exportación de reportes.

**No incluye:** recalcular métricas recorriendo toda la base transaccional en cada consulta — el dashboard siempre se sirve desde agregados precalculados.

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- Para un reclamo: datos mínimos de contacto y detalle; el pedido asociado es opcional.
- Para reportes: los agregados deben estar disponibles y los filtros solicitados deben ser válidos.

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| M1 — Pedidos (F1) | Publica eventos (pagado, anulado, entregado) que F6 consume para sus agregados. |
| M2 — Postventa (F2 a F5) | Publican eventos relevantes (anulaciones, devoluciones, reembolsos, calificaciones) que también alimentan los agregados. |
| Seguridad (G) | Aporta datos de contacto y rol del cliente/Gestor. |
| Canales A/B/C | Punto de entrada para que el cliente registre un reclamo. |

### 4.3. Resultados

- Un reclamo válido queda registrado con código único, tipificación (reclamo/queja) y fecha límite (SLA).
- El Gestor puede responder y actualizar el estado del reclamo, con trazabilidad.
- El dashboard se sirve desde agregados actualizados por periodo, canal, vendedor y producto.
- Los reportes pueden exportarse según el alcance definido por el equipo.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Registro de reclamo/queja

El sistema DEBE registrar reclamos y quejas de forma diferenciada, con código único y cálculo de SLA.

#### CA-01. Registro exitoso con código único

- **DADO** un cliente que envía un reclamo con datos de contacto y detalle válidos.
- **CUANDO** se registra.
- **ENTONCES** el sistema asigna un código único, tipifica el caso como reclamo o queja, y calcula la fecha límite de respuesta (SLA: 15 días hábiles, parametrizable, según referencia normativa de Indecopi).

#### CA-02. Registro sin pedido asociado

- **DADO** un reclamo que no está vinculado a ningún pedido.
- **CUANDO** contiene los datos mínimos requeridos.
- **ENTONCES** el sistema lo registra igualmente, sin exigir un pedido.

#### CA-03. Rechazo por datos incompletos

- **DADO** un reclamo sin los datos mínimos de contacto o detalle.
- **CUANDO** se intenta registrar.
- **ENTONCES** el sistema devuelve una validación y no genera un código definitivo hasta que la solicitud sea válida.

### RF-02. Atención y control de SLA

El sistema DEBE permitir que el Gestor responda y actualice el estado del reclamo, manteniendo visible el estado del SLA en todo momento.

#### CA-04. Respuesta del Gestor

- **DADO** un reclamo registrado con código válido.
- **CUANDO** el Gestor responde dentro del plazo.
- **ENTONCES** el sistema actualiza el estado del reclamo y registra la respuesta con trazabilidad.

#### CA-05. Visibilidad del SLA

- **DADO** un reclamo próximo a vencer su fecha límite.
- **CUANDO** el Gestor consulta su bandeja.
- **ENTONCES** el sistema muestra claramente el estado del SLA (a tiempo, próximo a vencer, o vencido).

### RF-03. Agregados y dashboard

El sistema DEBE mantener agregados actualizados a partir de eventos, y servir el dashboard desde ellos — nunca recalculando sobre la base transaccional completa en cada consulta.

#### CA-06. Actualización de agregados por evento

- **DADO** un evento `pedido pagado` publicado por F1.
- **CUANDO** F6 lo consume.
- **ENTONCES** el sistema actualiza el agregado correspondiente (por ejemplo, ventas por canal/periodo) sin recorrer toda la base transaccional.

#### CA-07. Agregado temporalmente retrasado

- **DADO** que un evento llega con retraso o el consumidor estuvo temporalmente caído.
- **CUANDO** el Gestor consulta el dashboard durante ese lapso.
- **ENTONCES** el sistema muestra la última actualización disponible, y procesa el evento pendiente en cuanto el consumidor se recupera — sin mostrar un error ni datos corruptos.

#### CA-08. Rendimiento del dashboard

- **DADO** una base de prueba con al menos 5,000 pedidos.
- **CUANDO** el Gestor consulta el dashboard.
- **ENTONCES** el sistema responde en menos de 2 segundos, según el requisito no funcional del proyecto.

## 6. Frontend

Superficie visible dentro del panel del Gestor (más el formulario de reclamo que ve el cliente):

| Elemento | Responsabilidad |
|---|---|
| Formulario de reclamo (cliente) | Captura tipo (reclamo/queja), detalle, contacto y pedido opcional. |
| Bandeja de reclamos (Gestor) | Lista por estado y urgencia de SLA, con acceso al detalle y respuesta. |
| Dashboard | Indicadores, gráficos/tablas filtrables por periodo, canal, vendedor y producto. |
| Exportación de reportes | Botón de descarga del reporte según los filtros aplicados. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Registro de reclamos | Genera código único, tipifica y calcula el SLA. |
| Motor de SLA | Calcula y mantiene visible la fecha límite y su estado. |
| Consumidor de eventos de M1/M2 | Escucha eventos relevantes de todas las funcionalidades del módulo para mantener los agregados. |
| Servicio de agregados | Mantiene tablas resumen por periodo/canal/vendedor/producto, consultadas por el dashboard. |
| Exportador de reportes | Genera el archivo de reporte según los filtros solicitados. |

## 8. Requisitos no funcionales

- **Performance del dashboard:** menos de 2 segundos de respuesta con al menos 5,000 pedidos de prueba.
- **Uso de agregados precalculados:** el dashboard nunca recalcula recorriendo toda la base transaccional en cada consulta.
- **Integridad histórica:** los datos descriptivos de la venta se conservan tal como estaban al momento de la transacción, sin verse afectados por modificaciones posteriores del catálogo.
- **Visibilidad de SLA:** el estado del plazo de respuesta debe ser siempre visible para el Gestor, parametrizado (por defecto 15 días hábiles) y verificado antes de una entrega real.

## 9. Fuera de alcance

- **Resolución de la causa raíz del reclamo:** F6 gestiona el registro, SLA y respuesta; no ejecuta acciones correctivas de otras funcionalidades (esas se inician por separado, por ejemplo iniciando una devolución en F3).
- **Cálculo en tiempo real sobre datos crudos:** el dashboard siempre se sirve desde agregados, nunca desde consultas directas sobre toda la base transaccional.

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 a CA-03 | Registrar reclamos válidos, sin pedido y con datos incompletos. | Unitaria e integración | Código generado correctamente o validación devuelta según corresponda. |
| CA-04 y CA-05 | Simular respuesta del Gestor y consulta de SLA próximo a vencer. | Integración | Estado actualizado con trazabilidad; SLA visible correctamente. |
| CA-06 y CA-07 | Publicar eventos de M1/M2 y simular un consumidor temporalmente caído. | Integración | Agregados actualizados; última data disponible mostrada sin error durante el retraso. |
| CA-08 | Cargar 5,000 pedidos de prueba y medir tiempo de respuesta del dashboard. | Performance | Respuesta menor a 2 segundos. |

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-08` están implementados y verificados, incluyendo la prueba de performance con 5,000 pedidos.
- Reclamo y queja quedan siempre diferenciados en el sistema.
- El SLA es visible y parametrizable, con su referencia normativa documentada.
- El dashboard nunca depende de un recálculo completo sobre la base transaccional.
- Los datos históricos de venta no se alteran por cambios posteriores del catálogo.
# RNF-06 — Mantenibilidad

**Funcionalidad:** F4 — Reembolsos y extornos  
**Microservicio:** M2 — Postventa  
**Responsable:** Luis Alejandro  
**Tipo:** Requisito no funcional

## 1. Propósito

Establecer las condiciones para que personal autorizado pueda comprender, revisar y dar seguimiento a solicitudes, intentos y fallos de F4 mediante la información funcional y de auditoría disponible.

## 2. Alcance

Este requisito cubre la trazabilidad y comprensión del ciclo de vida de un reembolso, sus dependencias y sus resultados. No prescribe una arquitectura de código, herramienta de observabilidad, almacenamiento físico ni tiempo numérico de diagnóstico.

## 3. Requisitos

### RNF-06-01 — Responsabilidades y límites

- F2 decide y aprueba las anulaciones; si corresponde un reembolso de un pedido pagado, origina la solicitud a F4 con `ANULACION`.
- F3 decide y aprueba las devoluciones con reembolso; origina la solicitud a F4 con `DEVOLUCION`.
- F4 valida la solicitud, controla el saldo, ejecuta el extorno y conserva su auditoría; no decide si la anulación o devolución procede.
- M1 es dueño de sus datos de pedidos y pagos. F4 conserva reembolsos y auditoría en M2 y no escribe directamente en la base de datos de M1.
- La trazabilidad de cada reembolso debe relacionar su identificador con origen, referencia del pago original, `X-Idempotency-Key`, actor/autorizador cuando corresponda, fecha UTC, intentos, estado y resultados.

### RNF-06-02 — Contratos documentados y versionados

Los contratos API/OpenAPI entre F2, F3, F4 y sus dependencias deben estar documentados y versionados por sus responsables. Todo cambio compatible o incompatible debe quedar documentado, incluida su compatibilidad y el impacto esperado para los consumidores. Esta especificación no prescribe una herramienta ni un esquema de versionado concreto.

### RNF-06-03 — Cambios de persistencia trazables

Cuando un cambio requiera modificar los registros de reembolso o auditoría, las migraciones de persistencia deben estar versionadas y documentadas junto con el cambio. Este requisito no define tablas, motores ni altera el modelo de datos del proyecto.

### RNF-06-04 — Documentación sincronizada

La documentación funcional y técnica afectada debe actualizarse junto con cada cambio. Debe mantenerse coherente la descripción de orígenes válidos, idempotencia, control de monto, estados, auditoría, autorización de consulta y recuperación.

### RNF-06-05 — Revisión antes de integración

Todo cambio de F4 debe revisarse mediante Pull Request antes de integrarse. La revisión verifica el alcance, los límites de responsabilidad entre F2/F3/F4/M1, la documentación asociada y los criterios de prueba aplicables.

### RNF-06-06 — Criterios de prueba documentados

Los cambios deben incluir criterios de prueba documentados, aplicables según el cambio, para:

- Idempotencia: repetir `X-Idempotency-Key` devuelve el resultado previamente registrado y no produce un segundo extorno.
- Monto: validar monto y moneda contra el pago original y rechazar excesos.
- Concurrencia: controlar o reservar montos pendientes para que solicitudes simultáneas no excedan el saldo reembolsable.
- Auditoría: verificar campos obligatorios, secuencia de intentos e inmutabilidad.
- Recuperación: comprobar estados, registro de errores/timeouts y reintentos seguros sin pérdida ni duplicación.

### RNF-06-07 — Consulta autorizada e historial

La consulta de estado e historial de reembolsos está restringida a usuarios autorizados. La información debe permitir reconstruir el estado vigente y la secuencia de intentos/resultados sin acceder directamente a la base de datos de M1; los registros conservan su inmutabilidad y se retienen según plazo legal aplicable, de acuerdo con ESP-10.

## 4. Criterios de aceptación

### RNF-06-CA-01 — Límites entendibles

**Dado** un revisor de un cambio de F4  
**Cuando** consulta esta especificación y los documentos relacionados  
**Entonces** puede identificar las responsabilidades de F2, F3, F4 y M1 sin atribuir a F4 decisiones de anulación o devolución ni escrituras en M1.

### RNF-06-CA-02 — Cambio contractual documentado

**Dado** un cambio compatible o incompatible en un contrato de API/OpenAPI  
**Cuando** el cambio se prepara para integración  
**Entonces** el contrato se encuentra documentado y versionado, y el cambio y su impacto de compatibilidad están descritos.

### RNF-06-CA-03 — Cambio de persistencia documentado

**Dado** un cambio que modifica registros de reembolso o auditoría  
**Cuando** se prepara para integración  
**Entonces** la migración aplicable está versionada y documentada junto con el cambio.

### RNF-06-CA-04 — Revisión y pruebas trazables

**Dado** un cambio de F4  
**Cuando** se solicita integrarlo  
**Entonces** existe revisión mediante Pull Request y criterios de prueba documentados para idempotencia, monto, concurrencia, auditoría y recuperación según corresponda.

### RNF-06-CA-05 — Consulta y diagnóstico

**Dado** un usuario autorizado y un identificador de reembolso  
**Cuando** consulta el estado y el historial  
**Entonces** puede relacionar origen, referencia, `X-Idempotency-Key`, estado, intentos y resultados; un usuario no autorizado no recibe esos datos.

### RNF-06-CA-06 — Recuperación trazable

**Dado** un reembolso fallido o con resultado incierto  
**Cuando** personal autorizado revisa su historial  
**Entonces** puede distinguir el resultado conocido, el estado pendiente y la evidencia de recuperación, y los intentos previos permanecen inmutables sin permitir un segundo extorno.

## 5. Umbrales

Este requisito no establece tiempos, SLA numéricos ni herramientas concretas no aprobadas. Cualquier objetivo cuantitativo o selección de herramienta requiere aprobación explícita antes de incorporarse.
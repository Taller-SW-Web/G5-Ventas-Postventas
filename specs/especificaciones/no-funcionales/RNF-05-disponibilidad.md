# RNF-05 — Disponibilidad

**Funcionalidad:** F4 — Reembolsos y extornos  
**Microservicio:** M2 — Postventa  
**Responsable:** Luis Alejandro  
**Tipo:** Requisito no funcional

## 1. Propósito

Establecer las condiciones de continuidad y recuperación documentalmente verificables para que fallos de la pasarela simulada o de dependencias de F4 no pierdan solicitudes ni produzcan extornos duplicados.

## 2. Alcance

Aplica a la recepción, registro, procesamiento, recuperación y notificación de solicitudes de reembolso de F4. La disponibilidad se expresa mediante resultados verificables ante fallos; no se fija porcentaje de disponibilidad, tiempo de respuesta, tiempo de recuperación ni otro SLA numérico no aprobado.

## 3. Requisitos

### RNF-05-01 — Persistencia de operaciones aceptadas

Una solicitud aceptada y cada intento deben quedar registrados antes de que una interrupción de dependencia pueda hacer perder su seguimiento. El resultado de cada intento, incluidos error y timeout, debe conservarse.

### RNF-05-02 — Recuperación sin pérdida ni duplicación

Después de una interrupción, F4 debe poder identificar las solicitudes pendientes o fallidas y continuar su recuperación dentro del mismo registro. La recuperación no debe crear una segunda solicitud de reembolso ni un segundo movimiento de dinero.

### RNF-05-03 — Reintentos seguros e idempotencia

Los reintentos seguros de una operación pendiente o fallida se recuperan dentro del mismo registro y conservan la `X-Idempotency-Key` original y el historial de intentos. Una repetición de la misma solicitud devuelve el resultado previamente registrado; el control de idempotencia impide ejecutar otro extorno.

### RNF-05-04 — Fallos visibles

Los fallos de pasarela o dependencias quedan registrados junto con el reembolso y el intento correspondiente. Un resultado externo incierto permanece identificable como `PENDIENTE` hasta su resolución; no se presenta como `EXITOSO` sin confirmación.

### RNF-05-05 — Control del saldo ante concurrencia

El control o reserva atómica de montos pendientes debe mantenerse durante errores y recuperación, de modo que extornos exitosos y montos pendientes o reservados no excedan el pago original.

### RNF-05-06 — Pruebas de caída y recuperación

La validación documental de disponibilidad debe incluir pruebas de caída y recuperación del simulador de pasarela y de cada dependencia externa definida para el flujo F4. Las pruebas verifican persistencia de las operaciones aceptadas, registro del fallo, recuperación segura y ausencia de pérdida o duplicación de extornos.

## 4. Criterios de aceptación

### RNF-05-CA-01 — Pasarela no disponible

**Dado** una solicitud aceptada y una interrupción del simulador  
**Cuando** F4 no puede confirmar el resultado  
**Entonces** la solicitud y el intento permanecen registrados, el estado refleja la incertidumbre y la recuperación no produce un segundo extorno.

### RNF-05-CA-02 — Dependencia interrumpida

**Dado** una dependencia necesaria del flujo de F4 que deja de responder  
**Cuando** se interrumpe el procesamiento o la notificación  
**Entonces** el fallo queda visible, los datos aceptados se conservan y la operación puede recuperarse sin pérdida ni duplicación.

### RNF-05-CA-03 — Reanudación concurrente

**Dado** varias solicitudes pendientes para un mismo pago original  
**Cuando** F4 recupera y procesa solicitudes concurrentes  
**Entonces** mantiene el control atómico del saldo y la suma de montos exitosos y pendientes/reservados no excede el pago original.

## 5. Umbrales

No se establece un porcentaje de disponibilidad ni SLA numérico. Cualquier umbral cuantitativo requerirá aprobación explícita antes de incorporarse a esta especificación.

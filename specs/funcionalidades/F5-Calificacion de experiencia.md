# Especificación F5: Calificación de experiencia

**Responsable:** Johan
**Estado:** En especificación
**Actor principal:** Cliente (responde) y Gestor (consulta resultados)
**Microservicio:** M2 — Postventa
**Lineamiento del curso:** "Calificación y valoración de la experiencia de compra (llamadas y mailing)" (Módulo D — Ventas y Postventa)

## 1. Contexto

F5 mide qué tan satisfecho quedó el cliente después de una entrega confirmada, convirtiendo esa percepción en información comparable por canal y periodo. Se activa automáticamente a partir del evento `pedido entregado` que publica F1 — F5 nunca decide por sí sola cuándo encuestar, solo reacciona al evento.

## 2. Propósito

Capturar la satisfacción del cliente después de una entrega confirmada y convertirla en información comparable por canal y periodo (CSAT).

## 3. Alcance

Incluye:
- Disparo automático de una encuesta breve tras la entrega confirmada.
- Registro de una puntuación de 1 a 5 y un comentario opcional.
- Actualización del agregado de CSAT usado por F6.

**No incluye:** sustituir un reclamo (eso es F6), ni modificar el estado del pedido (la calificación es completamente independiente del ciclo de vida del pedido).

## 4. Precondiciones, dependencias y resultados

### 4.1. Precondiciones

- El pedido debe estar `ENTREGADO`, confirmado por evento de F1.
- Debe existir una referencia válida al pedido.
- Debe existir un medio de contacto disponible cuando la encuesta se envía por correo (aportado por Seguridad — G).

### 4.2. Dependencias

| Dependencia | Responsabilidad |
|---|---|
| F1 — Ciclo de vida del pedido | Publica el evento `pedido entregado` que dispara la encuesta; F5 solo consume este evento. |
| Seguridad y Usuarios (G) | Aporta el dato de contacto del cliente para el envío de la encuesta. |
| F6 — Reclamos, dashboard y reportes | Consume el agregado de CSAT que F5 mantiene actualizado. |

### 4.3. Resultados

- Cada entrega confirmada dispara una encuesta vinculada al pedido.
- Una respuesta válida queda persistida con canal y fecha.
- El agregado de CSAT se actualiza tras cada respuesta válida.
- La calificación nunca modifica el estado del pedido.

## 5. Requisitos y criterios de aceptación automatizables

### RF-01. Disparo de la encuesta

El sistema DEBE generar y enviar la encuesta únicamente a partir del evento de entrega confirmada, y no antes.

#### CA-01. Disparo tras entrega confirmada

- **DADO** que F1 publica el evento `pedido entregado` para un pedido válido.
- **CUANDO** F5 consume el evento.
- **ENTONCES** el sistema genera y envía una encuesta breve vinculada a ese pedido.

#### CA-02. Sin contacto disponible

- **DADO** un pedido entregado cuyo cliente no tiene un medio de contacto registrado.
- **CUANDO** se intenta enviar la encuesta.
- **ENTONCES** el sistema registra el caso sin bloquear el cierre del pedido, y no genera un error que afecte a otros módulos.

### RF-02. Registro de la respuesta

El sistema DEBE validar y persistir la respuesta del cliente, respetando el rango permitido de puntuación.

#### CA-03. Respuesta válida

- **DADO** una encuesta enviada y pendiente de respuesta.
- **CUANDO** el cliente responde con puntuación 4 y un comentario opcional.
- **ENTONCES** el sistema persiste la respuesta con canal y fecha, y actualiza el agregado de CSAT.

#### CA-04. Puntuación fuera de rango

- **DADO** una respuesta con puntuación fuera de 1 a 5.
- **CUANDO** se envía.
- **ENTONCES** el sistema la rechaza y no la persiste ni actualiza el CSAT.

#### CA-05. Respuesta duplicada

- **DADO** que ya existe una respuesta registrada para un pedido, y la política es "una respuesta por pedido".
- **CUANDO** llega una segunda respuesta para el mismo pedido.
- **ENTONCES** el sistema la rechaza o retorna la respuesta existente, según la política acordada por el equipo — nunca la persiste como una segunda entrada.

### RF-03. Independencia del estado del pedido

El sistema DEBE garantizar que la calificación nunca modifique el estado del pedido.

#### CA-06. No afecta el estado del pedido

- **DADO** un pedido `ENTREGADO` que recibe una calificación de 1 (muy insatisfecho).
- **CUANDO** la respuesta se procesa.
- **ENTONCES** el estado del pedido permanece `ENTREGADO`, sin transición alguna.

## 6. Frontend

Superficie visible dentro del panel del Gestor (más el formulario de encuesta que ve el cliente):

| Elemento | Responsabilidad |
|---|---|
| Encuesta del cliente | Formulario breve: puntuación 1-5 (obligatoria) y comentario (opcional). |
| Listado de calificaciones (Gestor) | Consulta de respuestas por canal y periodo. |
| Indicador de CSAT | Muestra el agregado actualizado, segmentable por canal/periodo. |

## 7. Backend

| Componente lógico | Responsabilidad |
|---|---|
| Consumidor del evento `pedido entregado` | Escucha el evento de F1 y dispara la generación de la encuesta. |
| Servicio de envío de encuesta | Genera y envía la encuesta por el canal de contacto disponible. |
| Validador de respuesta | Verifica rango de puntuación y política de duplicados. |
| Actualizador de agregado CSAT | Recalcula el agregado consumido por F6 tras cada respuesta válida. |

## 8. Requisitos no funcionales

- **Reactividad basada en eventos:** la encuesta se dispara solo por el evento `pedido entregado`, nunca por consulta directa o temporizador arbitrario.
- **Resiliencia:** la ausencia de contacto no bloquea el cierre del pedido ni genera errores en cascada.
- **Independencia:** la calificación nunca cambia el estado del pedido, bajo ninguna circunstancia.
- **Consistencia del agregado:** el CSAT se actualiza de forma consistente con cada respuesta válida, sin duplicar conteos.

## 9. Fuera de alcance

- **Gestión de reclamos:** una calificación baja no genera automáticamente un reclamo; eso requeriría una acción separada del cliente hacia F6.
- **Modificación del estado del pedido:** la calificación es completamente independiente del ciclo de vida gestionado por F1.
- **Canales de encuesta distintos a correo/notificación básica:** llamadas telefónicas mencionadas en el enunciado del curso quedan fuera del alcance técnico automatizado de esta especificación, salvo que el equipo decida incorporarlas explícitamente.

## 10. Estrategia de verificación

| Criterios | Verificación automatizada | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 y CA-02 | Simular el evento `pedido entregado` con y sin contacto disponible. | Integración | Encuesta enviada en el primer caso; caso registrado sin bloqueo en el segundo. |
| CA-03 y CA-04 | Enviar una respuesta válida y una fuera de rango. | Unitaria e integración | Persistencia y actualización de CSAT correctas; rechazo sin persistir en la inválida. |
| CA-05 | Enviar dos respuestas para el mismo pedido. | Integración | Segunda respuesta rechazada o resuelta según política, sin duplicar. |
| CA-06 | Enviar una calificación baja y verificar el estado del pedido. | Integración | Estado del pedido sin cambios. |

## 11. Criterio de completitud

La funcionalidad se considera completa cuando:

- Los criterios `CA-01` a `CA-06` están implementados y cuentan con pruebas automatizadas exitosas.
- Se demuestra que la encuesta solo se dispara a partir del evento de entrega, nunca antes.
- Ninguna calificación, sin importar su valor, modifica el estado del pedido.
- El agregado de CSAT queda consistente y disponible para F6.
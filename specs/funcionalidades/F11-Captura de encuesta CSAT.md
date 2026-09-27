# ESP-11 — Captura de encuesta CSAT

**Módulo:** D — Ventas y Postventa  
**Funcionalidad relacionada:** F5 — Calificación de experiencia  
**Microservicio:** M2 — Postventa  
**Responsable funcional:** Johan Solano  
**Estado:** En especificación  
**Actor principal:** Cliente  
**Actores relacionados:** F1 — Ciclo de vida del pedido, Seguridad y Usuarios (G), F6 — Reclamos, dashboard y reportes

---

## 1. Objetivo

Definir el comportamiento esperado para la captura de una respuesta de satisfacción del cliente (CSAT) después de una entrega confirmada

La encuesta debe permitir registrar una puntuación de 1 a 5 y un comentario opcional, manteniendo la respuesta vinculada al pedido que originó la encuesta. La información registrada servirá posteriormente para actualizar el indicador de satisfacción utilizado por F6 en el dashboard y los reportes del Módulo D

La captura de la encuesta no modifica el estado del pedido ni reemplaza el flujo de reclamos

---

## 2. Contexto funcional

F5 se activa únicamente después de que F1 publica el evento de pedido entregado. A partir de ese evento se genera la encuesta asociada al pedido y cuando existe un medio de contacto disponible, se envía al cliente

El cliente responde desde la vista o canal habilitado para la encuesta. El Gestor no registra la calificación en nombre del cliente; su participación se limita a consultar posteriormente los resultados agregados y los comentarios disponibles

El flujo general es:

`Pedido ENTREGADO → generación de encuesta → respuesta del cliente → validación → persistencia → actualización de CSAT`

La respuesta registrada permanece independiente del ciclo de vida transaccional del pedido

---

## 3. Precondiciones

Para aceptar una respuesta CSAT se deben cumplir las siguientes condiciones:

- El pedido relacionado debe existir
- El pedido debe haber sido confirmado previamente como `ENTREGADO`
- Debe existir una encuesta generada o habilitada para ese pedido
- La puntuación debe encontrarse dentro del rango permitido de 1 a 5
- El comentario es opcional
- La respuesta debe estar asociada al pedido y al canal correspondiente
- Debe respetarse la política definida por el equipo para evitar respuestas duplicadas sobre un mismo pedido

Si alguna condición necesaria no se cumple, la respuesta no debe persistirse ni alterar el agregado CSAT

---

## 4. Datos de entrada

La captura de la encuesta debe manejar, como mínimo, la siguiente información funcional:

| Campo        | Obligatorio | Descripción                                                                            |
| ------------ | ----------: | -------------------------------------------------------------------------------------- |
| `idPedido`   |          Sí | Identificador del pedido sobre el cual se generó la encuesta                           |
| `puntaje`    |          Sí | Valor entero entre 1 y 5 que representa la satisfacción del cliente                    |
| `comentario` |          No | Texto libre opcional enviado por el cliente                                            |
| `canal`      |          Sí | Canal asociado a la experiencia de compra y utilizado posteriormente para segmentación |

Los nombres, estructura final del payload, endpoint y códigos de respuesta deben mantenerse alineados con `specs/api-contract.md`

---

## 5. Flujo principal

1. F1 confirma la entrega del pedido y publica el evento correspondiente
2. F5 genera una encuesta vinculada al pedido
3. El cliente accede a la encuesta desde el medio habilitado
4. El cliente selecciona una puntuación entre 1 y 5
5. Opcionalmente, registra un comentario
6. El sistema valida el pedido, el rango del puntaje y la política de duplicados
7. Si la respuesta es válida, se persiste con su canal y fecha
8. F5 actualiza el agregado de CSAT
9. F6 puede consumir el agregado actualizado para mostrarlo en dashboard y reportes
10. El estado del pedido permanece sin cambios

---

## 6. Reglas de negocio

### RN-01. Encuesta posterior a la entrega

La encuesta solo puede responderse cuando su origen corresponde a un pedido cuya entrega fue confirmada previamente

No debe habilitarse una captura de CSAT antes del evento de entrega

### RN-02. Rango de puntuación

El valor de `puntaje` debe encontrarse entre 1 y 5, inclusive

Cualquier valor fuera de este rango debe rechazarse y no debe afectar el indicador CSAT

### RN-03. Comentario opcional

El cliente puede registrar únicamente la puntuación sin escribir un comentario

La ausencia de comentario no invalida una respuesta que tenga un puntaje correcto

### RN-04. Control de duplicados

Debe respetarse la política definida para respuestas por pedido. Si ya existe una respuesta válida y la política vigente es una respuesta por pedido, una nueva captura no debe crear una segunda calificación

El comportamiento exacto ante el reintento debe conservar la respuesta existente o rechazar el segundo registro, según lo establecido en el contrato y la implementación acordada

### RN-05. Independencia del pedido

Una calificación, incluso si corresponde a un puntaje bajo, no debe modificar el estado del pedido ni disparar por sí sola una transición

Un puntaje bajo tampoco debe registrar automáticamente un reclamo. Si el cliente desea presentar uno, debe utilizar el flujo correspondiente a F6

### RN-06. Actualización de CSAT

Toda respuesta válida debe contribuir al agregado de CSAT utilizado por F6

Las respuestas rechazadas, inválidas o duplicadas no deben modificar el agregado

---

## 7. Escenarios y criterios de aceptación

### CA-01 — Captura válida de encuesta

**DADO** un pedido confirmado como `ENTREGADO` y una encuesta habilitada para dicho pedido  
**Y** el cliente selecciona un puntaje dentro del rango de 1 a 5  
**CUANDO** envía la encuesta  
**ENTONCES** el sistema registra la respuesta asociada al pedido, canal y fecha  
**Y** actualiza el agregado CSAT correspondiente.

---

### CA-02 — Captura válida sin comentario

**DADO** un pedido `ENTREGADO` con encuesta habilitada  
**Y** el cliente selecciona un puntaje válido sin ingresar comentario  
**CUANDO** envía la respuesta  
**ENTONCES** el sistema debe aceptarla  
**Y** persistir la calificación sin exigir texto adicional

---

### CA-03 — Rechazo de puntuación fuera de rango

**DADO** una encuesta asociada a un pedido válido  
**CUANDO** se intenta registrar una puntuación menor que 1 o mayor que 5  
**ENTONCES** el sistema rechaza la respuesta  
**Y** no persiste la calificación  
**Y** no actualiza el agregado CSAT

---

### CA-04 — Respuesta duplicada

**DADO** que ya existe una respuesta válida registrada para el pedido  
**Y** la política vigente establece una única respuesta por pedido  
**CUANDO** se intenta enviar una nueva respuesta para la misma encuesta  
**ENTONCES** el sistema no debe crear una segunda calificación  
**Y** debe resolver el intento según la política definida, sin duplicar el aporte al CSAT

---

### CA-05 — Independencia del estado del pedido

**DADO** un pedido `ENTREGADO`  
**CUANDO** el cliente registra una calificación, incluso con puntaje 1  
**ENTONCES** el pedido debe conservar su estado  
**Y** no debe ejecutarse ninguna transición en F1

---

### CA-06 — Calificación baja no genera reclamo automático

**DADO** una respuesta válida con puntuación baja  
**CUANDO** la respuesta se procesa correctamente  
**ENTONCES** el sistema registra la calificación y actualiza CSAT  
**PERO** no crea un reclamo automáticamente en F6

---

## 8. Comportamiento esperado en frontend

La vista de encuesta dirigida al cliente debe ser breve y clara. Como mínimo debe incluir:

- Identificación o referencia suficiente del pedido asociado
- Control de puntuación de 1 a 5
- Campo de comentario opcional
- Acción para enviar la respuesta
- Mensaje de confirmación cuando la respuesta sea registrada correctamente
- Mensaje comprensible cuando la respuesta sea inválida o ya exista una calificación registrada

Durante el envío, la acción debe mantenerse en estado de carga para reducir envíos repetidos desde la interfaz. Esta protección mejora la experiencia, pero la validación definitiva de duplicados corresponde al backend

La interfaz del Gestor no debe permitir modificar la respuesta del cliente; su función es consultar los resultados y agregados dentro de las vistas de calificaciones y reportes

---

## 9. Relaciones con otras funcionalidades

| Funcionalidad / módulo                  | Relación con ESP-11                                                                               |
| --------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **F1 — Ciclo de vida del pedido**       | Publica el evento de pedido entregado que habilita el proceso de encuesta                         |
| **Seguridad y Usuarios (G)**            | Proporciona el medio de contacto disponible cuando la encuesta se envía por correo o notificación |
| **F6 — Reclamos, dashboard y reportes** | Consume el agregado de CSAT para mostrar indicadores segmentados por canal y periodo              |
| **F6 — Reclamos**                       | Es un flujo independiente. Una calificación baja no crea un reclamo de forma automática           |

---

## 10. Casos de error relevantes

La implementación debe manejar de forma controlada, como mínimo, los siguientes casos:

- Pedido inexistente o referencia inválida
- Pedido que aún no se encuentra `ENTREGADO`
- Puntaje fuera del rango permitido
- Segundo intento de respuesta cuando la política no permite duplicados
- Error de red durante el envío
- Falla temporal al actualizar el agregado CSAT

Una falla posterior en la actualización del agregado no debe provocar una segunda respuesta del cliente ni duplicar la calificación ya persistida

---

## 11. Fuera de alcance

Este escenario no incluye:

- Modificar el estado del pedido
- Crear reclamos automáticamente a partir de una mala puntuación
- Gestionar reclamos o quejas
- Mostrar el dashboard administrativo completo
- Definir mecanismos de llamadas telefónicas no automatizadas
- Modificar respuestas ya registradas, salvo que el equipo defina posteriormente una política específica para ello

---

## 12. Evidencia de verificación

Para considerar ESP-11 correctamente implementado debe demostrarse, como mínimo:

- Registro exitoso de una puntuación válida
- Registro exitoso sin comentario
- Rechazo de puntuaciones fuera de 1 a 5
- Control de una segunda respuesta para el mismo pedido
- Actualización del agregado CSAT solo ante respuestas válidas
- Verificación de que la calificación no modifica el estado del pedido
- Verificación de que una puntuación baja no crea automáticamente un reclamo

---

## 13. Criterio de completitud

ESP-11 se considera completo cuando la captura de encuesta permite registrar de forma consistente una calificación válida posterior a la entrega, evita respuestas inválidas o duplicadas según la política del proyecto mantiene independencia total respecto al estado del pedido y deja disponible la información necesaria para que F6 actualice y consulte el indicador CSAT

# ESP-12 — Actualización de métricas CSAT

**Módulo:** D — Ventas y Postventa  
**Funcionalidad relacionada:** F5 — Calificación de experiencia  
**Microservicio:** M2 — Postventa  
**Responsable funcional:** Johan Solano  
**Estado:** En especificación  
**Actor principal:** Sistema (F5)  
**Actores relacionados:** Cliente, F6 — Reclamos, dashboard y reportes

---

## 1. Objetivo

Definir el comportamiento esperado para la actualización de las métricas de satisfacción del cliente (CSAT) a partir de las respuestas válidas registradas en F5

Cada respuesta aceptada debe reflejarse de manera consistente en el agregado de CSAT que posteriormente consume F6 para mostrar indicadores en el dashboard y en los reportes del Módulo D

La actualización de estas métricas no modifica el estado del pedido ni genera por sí sola un reclamo

---

## 2. Contexto funcional

F5 recibe las respuestas de las encuestas de satisfacción asociadas a pedidos previamente confirmados como `ENTREGADO`

Cuando una respuesta cumple las validaciones establecidas —principalmente una puntuación dentro del rango de 1 a 5 y el control de respuestas duplicadas— el sistema la persiste y actualiza el agregado de CSAT

F6 utiliza dicho agregado para presentar resultados de satisfacción segmentables por canal y periodo, evitando recalcular la información completa desde los datos transaccionales cada vez que el Gestor consulta el dashboard

El flujo general es:

`Respuesta válida → persistencia → actualización del agregado CSAT → consulta desde F6`

---

## 3. Precondiciones

Para actualizar las métricas CSAT se deben cumplir las siguientes condiciones:

- Debe existir una respuesta de encuesta válida y aceptada por F5
- La puntuación debe encontrarse dentro del rango de 1 a 5
- La respuesta debe estar vinculada a un pedido y a un canal
- La respuesta no debe haber sido descartada por la política de duplicados
- La actualización debe realizarse únicamente después de que la respuesta haya sido persistida correctamente

Una respuesta inválida, rechazada o duplicada no debe alterar las métricas existentes

---

## 4. Datos considerados para la actualización

| Dato         | Uso                                                                                      |
| ------------ | ---------------------------------------------------------------------------------------- |
| `idPedido`   | Mantiene la trazabilidad entre la calificación y el pedido                               |
| `puntaje`    | Valor de satisfacción registrado por el cliente                                          |
| `canal`      | Permite segmentar posteriormente las métricas                                            |
| `fecha`      | Permite consultar resultados por periodo                                                 |
| `comentario` | Se conserva como información cualitativa, pero no es obligatorio para actualizar el CSAT |

La estructura exacta de almacenamiento y los nombres definitivos de campos deben mantenerse alineados con `specs/api-contract.md` y con el modelo acordado por el equipo

---

## 5. Flujo principal

1. El cliente envía una respuesta de encuesta
2. F5 valida la puntuación y la política de duplicados
3. La respuesta válida se persiste con su canal y fecha
4. El sistema identifica el agregado CSAT correspondiente
5. Se actualiza el agregado utilizando la nueva respuesta válida
6. El resultado actualizado queda disponible para F6
7. El Gestor puede visualizar posteriormente el indicador segmentado por canal y periodo
8. El estado del pedido permanece sin cambios

---

## 6. Reglas de negocio

### RN-01. Actualización solo con respuestas válidas

El agregado CSAT debe modificarse únicamente cuando la respuesta haya sido aceptada y persistida correctamente

### RN-02. Puntuaciones fuera de rango

Una respuesta con puntuación menor que 1 o mayor que 5 debe rechazarse antes de afectar el agregado

### RN-03. Control de duplicados

Si una segunda respuesta para el mismo pedido no está permitida por la política vigente, esta no debe incrementar ni modificar por segunda vez el agregado de CSAT

### RN-04. Segmentación

El agregado debe conservar la información necesaria para que F6 pueda consultar resultados por canal y periodo

### RN-05. Consistencia

La actualización de CSAT debe corresponder con las respuestas válidas efectivamente registradas

### RN-06. Independencia del pedido

La actualización de una métrica de satisfacción no debe modificar el estado del pedido en F1, sin importar el valor del puntaje recibido

### RN-07. Independencia de reclamos

Una puntuación baja puede reflejar insatisfacción, pero no debe crear automáticamente un reclamo en F6

---

## 7. Escenarios y criterios de aceptación

### CA-01 — Actualización por respuesta válida

**DADO** una encuesta asociada a un pedido entregado  
**Y** una respuesta válida con puntaje dentro del rango de 1 a 5  
**CUANDO** F5 persiste la respuesta  
**ENTONCES** el sistema actualiza el agregado CSAT correspondiente  
**Y** deja el resultado disponible para F6

### CA-02 — Actualización segmentada por canal

**DADO** una respuesta válida asociada a un canal determinado  
**CUANDO** se actualiza el agregado CSAT  
**ENTONCES** la información debe quedar disponible para su consulta segmentada por dicho canal

### CA-03 — Actualización por periodo

**DADO** una respuesta válida registrada con su fecha correspondiente  
**CUANDO** F6 consulta resultados para un periodo específico  
**ENTONCES** la respuesta debe formar parte únicamente del agregado que corresponda a dicho periodo

### CA-04 — Respuesta fuera de rango no altera métricas

**DADO** una respuesta con puntuación menor que 1 o mayor que 5  
**CUANDO** F5 intenta procesarla  
**ENTONCES** la respuesta es rechazada  
**Y** el agregado CSAT permanece sin cambios

### CA-05 — Respuesta duplicada no incrementa el agregado

**DADO** que ya existe una respuesta válida para un pedido  
**Y** la política definida permite una sola respuesta por pedido  
**CUANDO** se intenta registrar una segunda respuesta  
**ENTONCES** el sistema no debe contabilizarla nuevamente  
**Y** el agregado CSAT conserva un único aporte asociado a ese pedido

### CA-06 — La actualización no modifica el pedido

**DADO** un pedido en estado `ENTREGADO`  
**Y** una respuesta válida con cualquier puntuación permitida  
**CUANDO** se actualiza el agregado CSAT  
**ENTONCES** el pedido continúa en estado `ENTREGADO`  
**Y** no se genera ninguna transición en F1

### CA-07 — Puntuación baja no genera reclamo

**DADO** una respuesta válida con una puntuación baja  
**CUANDO** se actualiza la métrica CSAT  
**ENTONCES** la respuesta se contabiliza normalmente  
**PERO** no se crea automáticamente un reclamo en F6

---

## 8. Relación con F6 — Dashboard y reportes

F6 consume el agregado actualizado por F5 para presentar la información de satisfacción al Gestor

Desde el punto de vista funcional, F6 debe poder:

- Consultar el indicador CSAT disponible
- Segmentar los resultados por canal
- Consultar resultados por periodo
- Mostrar la distribución o resumen correspondiente en las vistas analíticas
- Combinar estas métricas con los demás indicadores del dashboard y reportes

ESP-12 no define la presentación visual final del dashboard; únicamente garantiza que la información agregada de satisfacción esté actualizada y disponible para su consumo

---

## 9. Comportamiento esperado en frontend

La actualización del agregado ocurre como parte del procesamiento de la respuesta y no requiere una acción manual adicional del cliente

En la vista del Gestor:

- El indicador CSAT debe mostrarse a partir de la información entregada por F6
- Los filtros por canal y periodo deben consultar los agregados correspondientes
- La interfaz no debe recalcular manualmente las métricas a partir del listado completo de respuestas
- Si no existen datos para un filtro seleccionado, debe mostrarse un estado vacío comprensible

La visualización final se implementará de acuerdo con el sistema de diseño definido en Figma y los componentes acordados para el frontend

---

## 10. Manejo de inconsistencias y errores

La implementación debe contemplar:

- Respuesta inválida que no debe afectar el agregado
- Respuesta duplicada que no debe contabilizarse nuevamente
- Falla temporal al actualizar el agregado después de persistir una respuesta válida
- Consulta de un periodo o canal sin datos disponibles

Si ocurre una falla posterior a la persistencia de una respuesta válida, la respuesta no debe duplicarse ni solicitarse nuevamente al cliente

---

## 11. Fuera de alcance

ESP-12 no incluye:

- El envío o presentación de la encuesta al cliente
- La captura inicial de la respuesta, definida en ESP-11
- La modificación del estado del pedido
- La creación automática de reclamos
- La definición visual completa del dashboard
- La exportación de reportes de F6
- La definición de una fórmula distinta a la acordada por el equipo para el cálculo del indicador CSAT

---

## 12. Evidencia de verificación

Para considerar ESP-12 correctamente implementado debe demostrarse:

- Actualización del agregado después de una respuesta válida
- Disponibilidad de resultados segmentados por canal
- Disponibilidad de resultados por periodo
- Ausencia de actualización ante una puntuación inválida
- Ausencia de doble contabilización ante una respuesta duplicada
- Verificación de que el estado del pedido no cambia
- Verificación de que una puntuación baja no crea un reclamo automáticamente
- Consistencia entre respuestas válidas persistidas y respuestas contabilizadas en el agregado

---

## 13. Criterio de completitud

ESP-12 se considera completo cuando toda respuesta válida registrada por F5 actualiza de forma consistente el agregado CSAT, las respuestas inválidas o duplicadas no alteran las métricas y la información resultante queda disponible para que F6 la consulte por canal y periodo, sin modificar el estado del pedido ni generar reclamos de forma automática

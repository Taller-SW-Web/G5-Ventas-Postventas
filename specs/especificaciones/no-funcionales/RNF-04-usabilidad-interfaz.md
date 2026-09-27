# RNF-04 — Usabilidad e interfaz

## 1. Identificación

| Campo           | Detalle                      |
| --------------- | ---------------------------- |
| **Código**      | RNF-04                       |
| **Nombre**      | Usabilidad e interfaz        |
| **Módulos**     | M1 — Ventas / M2 — Postventa |
| **Responsable** | Joseph                       |
| **Tipo**        | Requisito no funcional       |

---

## 2. Propósito

Garantizar que las interfaces del sistema permitan realizar las operaciones de forma clara, consistente y comprensible, reduciendo errores durante la gestión de pedidos y procesos de postventa.

La interfaz debe proporcionar información clara sobre el estado de las operaciones y confirmar las acciones que puedan generar cambios importantes o irreversibles.

---

## 3. Requisito

La consola del Gestor y las interfaces asociadas a M1 y M2 deben ser **responsive**, mantener una estructura visual consistente y proporcionar retroalimentación clara ante las acciones realizadas.

Las acciones críticas deben solicitar confirmación cuando corresponda, mientras que los errores deben comunicarse mediante mensajes comprensibles para el usuario y sin exponer información técnica innecesaria.

---

## 4. Aspectos de usabilidad

La interfaz debe considerar como mínimo:

| Aspecto               | Requisito                                                                                       |
| --------------------- | ----------------------------------------------------------------------------------------------- |
| **Responsive**        | Adaptarse a los tamaños de pantalla contemplados por el proyecto.                               |
| **Navegación**        | Mantener una estructura clara y consistente entre las funcionalidades.                          |
| **Estados**           | Mostrar de forma diferenciada el estado actual de pedidos, devoluciones, reembolsos y reclamos. |
| **Errores**           | Mostrar mensajes claros indicando qué ocurrió y, cuando sea posible, cómo corregirlo.           |
| **Acciones críticas** | Solicitar confirmación antes de operaciones irreversibles o de impacto importante.              |
| **Retroalimentación** | Informar al usuario cuando una operación fue realizada, rechazada o requiere atención.          |
| **Formularios**       | Identificar campos obligatorios y validar los datos antes de enviar la operación.               |

---

## 5. Reglas

1. Los elementos de navegación y acciones equivalentes deben mantener una presentación consistente.
2. Los campos obligatorios deben identificarse claramente antes de enviar un formulario.
3. Los errores de validación deben mostrarse cerca del elemento correspondiente o mediante un mensaje claramente asociado.
4. Las operaciones irreversibles o de impacto importante deben solicitar confirmación antes de ejecutarse.
5. Los estados de las operaciones deben ser comprensibles y mantenerse actualizados después de una acción.
6. La interfaz no debe mostrar mensajes técnicos innecesarios, como trazas internas o detalles de implementación.
7. La interfaz debe mantener una presentación usable en los tamaños de pantalla definidos para el proyecto.

---

## 6. Criterios de aceptación

### CA-01 — Validación de formularios

**DADO** un formulario con campos obligatorios.

**CUANDO** el usuario intenta enviarlo con información incompleta o inválida.

**ENTONCES** el sistema identifica los campos que requieren corrección y muestra un mensaje comprensible.

### CA-02 — Confirmación de acciones críticas

**DADO** una operación que puede generar un cambio irreversible o importante.

**CUANDO** el usuario intenta ejecutarla.

**ENTONCES** el sistema solicita confirmación antes de completar la operación.

### CA-03 — Retroalimentación de operaciones

**DADO** una operación realizada desde la interfaz.

**CUANDO** el servidor responde.

**ENTONCES** la interfaz informa claramente si la operación fue exitosa, rechazada o requiere una acción adicional.

### CA-04 — Diseño responsive

**DADO** una interfaz del sistema.

**CUANDO** se visualiza en los tamaños de pantalla contemplados.

**ENTONCES** los elementos principales permanecen accesibles y utilizables sin pérdida de información esencial.

---

## 7. Verificación

El cumplimiento del requisito se verificará mediante:

* **Revisión de wireframes y UI:** comprobar navegación, jerarquía visual y consistencia de los elementos.
* **Pruebas de interacción:** ejecutar formularios y acciones críticas para verificar validaciones y confirmaciones.
* **Pruebas responsive:** revisar las interfaces en los tamaños de pantalla definidos para el proyecto.
* **Pruebas de errores:** provocar entradas inválidas y operaciones rechazadas para comprobar la claridad de los mensajes mostrados.

---

## 8. Trazabilidad del requisito

| Elemento                          | Referencia                   |
| --------------------------------- | ---------------------------- |
| **Funcionalidades relacionadas**  | F1, F2, F3, F4, F5 y F6      |
| **Wireframes**                    | `diseno/wireframes/`         |
| **Arquitectura**                  | M1 — Ventas / M2 — Postventa |
| **Especificaciones relacionadas** | ESP-01 a ESP-16              |
| **Contrato**                      | `api-contract.md`            |

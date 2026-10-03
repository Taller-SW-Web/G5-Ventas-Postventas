# Propuesta 03 — Diferenciación Cromática por Tipo de Origen en Reembolsos

- **Pantalla intervenida:** `W07 — Reembolsos`[cite: 11, 15]
- **Módulo responsable:** M2 — Postventa[cite: 4]
- **Perfil de usuario objetivo:** Gestor Financiero / Administrador de Reembolsos (`ADMIN_VENTAS`)

---

## 1. Contexto Operativo y Alcance
La gestión de reembolsos constituye una operación financiera crítica sujeta a estrictas reglas de negocio e idempotencia transaccional (RNF-08)[cite: 4]. De acuerdo con las especificaciones de arquitectura del sistema, el proceso de reembolso (F4) solo puede originarse a partir de dos fuentes exclusivas:
1. **Anulaciones preventivas (M1):** Pedidos cancelados de forma previa al despacho logístico por abandono de pago, error de sistema o solicitud directa del cliente[cite: 4, 15].
2. **Devoluciones físicas de producto (M2):** Retornos procesados con inspección física de evidencias fotográficas aprobadas por el operador de postventa[cite: 4, 15].

La pantalla `W07` concentra el registro de estas transacciones monetarias para su ejecución y conciliación ante pasarelas bancarias[cite: 11, 15].

---

## 2. Diagnóstico del Estado Actual (Problema Identificado)

### 2.1. Homogeneidad Tipográfica y Dificultad de Conciliación
En el diseño base de `W07 — Reembolsos`, la columna *"Origen"* mostraba los valores *"Anulación"* y *"Devolución"* utilizando texto plano en color gris neutro, idéntico al resto de datos secundarios de la fila (como fecha o ID de pedido)[cite: 11, 15].
Este diseño causaba las siguientes limitaciones:
* **Escaneo Visual Ineficiente:** El gestor no podía identificar de forma inmediata la naturaleza del desembolso, requiriendo lectura serial línea por línea durante el cuadre de caja diario[cite: 11, 15].
* **Riesgo en la Conciliación Contable:** Los reembolsos originados por Anulación restituyen fondos retenidos en pasarela antes del corte logístico, mientras que las Devoluciones implican un reintegro posterior a la entrega física que altera cuentas de merma o inventario reingresado[cite: 4, 15]. Mezclarlos visualmente aumentaba el riesgo de confusiones en la auditoría contable.
* **Infracción de Heurísticas de Usabilidad:**
  * *Relación entre el sistema y el mundo real (Heurística 2 de Nielsen):* El sistema no reflejaba visualmente la clara distinción operativa que existe en el negocio entre anular una orden no enviada y reembolsar una mercadería devuelta[cite: 4, 15].

---

## 3. Especificación Detallada de la Solución de Diseño

### 3.1. Identificadores Cromáticos (Badges Temáticos por Origen)
Se implementaron etiquetas redondeadas (*badges*) con contrastes cromáticos estandarizados según el origen de la transacción[cite: 15]:
* **Origen: Anulación (M1):**  
  * *Estilo Visual:* Badge con fondo naranja pálido y texto naranja oscuro (`#E67E22`)[cite: 15].  
  * *Semántica de Negocio:* Asocia visualmente la operación al módulo de Ventas (M1), denotando cancelaciones tempranas de checkout o preparation cancel[cite: 4, 15].
* **Origen: Devolución (M2):**  
  * *Estilo Visual:* Badge con fondo azul cielo suave y texto azul corporativo (`#2980B9`)[cite: 15].  
  * *Semántica de Negocio:* Asocia visualmente la transacción al flujo de Postventa (M2), indicando que el expediente cuenta con evidencia de producto validada[cite: 4, 15].

### 3.2. Facilidad de Escaneo en Bloque
La diferenciación cromática permite que el gestor, al realizar scroll vertical o aplicar filtros por fecha, identifique de un golpe de vista la proporción de egresos monetarios derivados de fallas de inventario/producto frente a cancelaciones transaccionales directas[cite: 4, 15].

---

## 4. Impacto Operativo y Métricas Esperadas
* **Velocidad de Conciliación Operativa:** Aumento estimado del 50% en la rapidez de verificación contable diaria de egresos financieros sin abrir el modal de detalle[cite: 15].
* **Prevención de Errores de Categorización:** Eliminación de discrepancias durante auditorías cruzadas entre los microservicios de Ventas y Postventa[cite: 4, 15].
* **Alineación con la Arquitectura de Microservicios:** Refuerza en la interfaz la regla de desacoplamiento formal donde cada reembolso rastrea de manera explícita su `tipoOrigen` y su `idOrigen`[cite: 4, 5, 15].

Referencia Figma:
https://www.figma.com/design/J2KeLP6nl8qlDunNNUAC52/Mockup-Hito-2?node-id=325-27498&t=KlUQl3JPqioO24em-1

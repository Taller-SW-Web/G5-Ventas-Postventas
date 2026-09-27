# Glosario de Términos — Módulo D: Ventas y Postventa

*Versión:* 1.0.0  
*Fecha:* Septiembre 2026  
*Propósito:* Definir el Lenguaje Ubicuo (Ubiquitous Language) formal para el Módulo D (M1: Ventas y M2: Postventa), asegurando consistencia conceptual y técnica entre las especificaciones, modelos de datos, contratos de API e integraciones entre equipos.

---

## 1. Entidades del Dominio

* *Pedido (Order):* Entidad transaccional central del microservicio M1 que representa la intención y compromiso formal de compra de uno o más productos por parte de un cliente a través de un canal autorizado.
* *Detalle de Pedido (Order Item):* Línea individual de producto asociada a un pedido. Mantiene una copia fija (snapshot) del SKU, descripción y precio unitario al momento exacto de la venta.
* *Solicitud de Anulación (Cancellation Request):* Expediente generado para cancelar un pedido cuando este se encuentra en una etapa que compromete recursos físicos (ej. EN_PREPARACION), requiriendo la evaluación y dictamen de un Gestor.
* *Devolución / Cambio (Return / Exchange):* Expediente postventa (F3 en M2) solicitado por un cliente tras la entrega efectiva de su compra, destinado a devolver físicamente un producto defectuoso o disconforme a cambio de un reemplazo o el extorno del dinero.
* *Evidencia Multimedia (Return Evidence):* Archivo digital (imagen PNG/JPG o documento PDF) adjunto a un expediente de devolución que sustenta de manera objetiva el defecto, falla o condición del producto entregado.
* *Reembolso / Extorno (Refund):* Transacción financiera ejecutada por el servicio F4 en M2 para restituir fondos al cliente hacia la pasarela de pagos o cuenta bancaria, originada exclusivamente por una anulación (F2), devolución aprobada (F3) o entrega fallida definitiva (Módulo E).
* *Encuesta CSAT (CSAT Survey):* Instrumento de medición de satisfacción del cliente post-entrega (F5), compuesto por una valoración cuantitativa (escala 1 a 5) y retroalimentación cualitativa opcional.
* *Reclamo (Claim):* Manifestación formal de disconformidad del consumidor relacionada directamente con los bienes adquiridos o la falta de cumplimiento en la entrega de estos.
* *Queja (Complaint):* Manifestación de malestar o disconformidad del consumidor referida a la atención al público, el trato recibido o aspectos del servicio general no ligados directamente al producto.

---

## 2. Estados del Ciclo de Vida

### 2.1. Estados del Pedido (Máquina de Estados M1)
* *CREADO:* Pedido registrado en el sistema a través de un canal; la pasarela de pago o el método de cobro aún no ha confirmado la transacción.
* *PAGADO:* El pago fue validado y conciliado exitosamente por la pasarela de pagos.
* *EN_PREPARACION:* El pedido fue recibido por el almacén o centro de distribución y se encuentra en etapa de picking/packing.
* *DESPACHADO:* La orden cuenta con guía de remisión y fue entregada a la empresa de transporte o courier en ruta hacia el destino.
* *ENTREGADO:* El paquete fue recibido físicamente por el cliente o destinatario final.
* *ANULADO:* El pedido fue cancelado de forma definitiva (sea por cancelación directa en CREADO/PAGADO, por autorización de Gestor en EN_PREPARACION, o por entrega fallida definitiva en Logística). No puede reactivarse.

### 2.2. Motivos de Transición Clave
* *PAGO_NO_COMPLETADO:* Motivo tipificado de anulación automática aplicado cuando expira el tiempo límite de espera de confirmación de la pasarela de pagos sin éxito en el cobro.
* *ENTREGA_FALLIDA_DEFINITIVA:* Evento reportado por Logística (Módulo E) cuando se agotan los intentos de entrega o la dirección es inubicable, derivando a la anulación del pedido y reembolso automático.

### 2.3. Estados de Expedientes Postventa (M2)
* *SOLICITADA:* Expediente de devolución registrado por el canal/cliente, en espera de revisión.
* *EN_EVALUACION:* El expediente y sus evidencias visuales están siendo inspeccionados por el Gestor de Postventa.
* *APROBADA:* Dictamen favorable emitido por el Gestor. Si el tipo es dinero, desencadena el proceso de reembolso en F4.
* *RECHAZADA:* Dictamen desestimado por el Gestor, el cual exige obligatoriamente un texto de fundamento legal o técnico.
* *COMPLETADA:* Ciclo postventa cerrado (mercadería de cambio entregada o dinero efectivamente acreditado).

---

## 3. Actores del Sistema

* *Cliente / Consumidor:* Persona natural o jurídica que adquiere productos a través de los canales digitales o presenciales y ejerce sus derechos de compra y postventa.
* *Canal (Channel):* Aplicación de frontend o interfaz de entrada que interactúa con el cliente (CHATBOT, MARKETPLACE, RETAIL).
* *Gestor de Ventas / Postventa:* Usuario administrativo interno con permisos y roles elevados (GESTOR, ADMIN) para autorizar anulaciones complejas, evaluar devoluciones y dictaminar resoluciones a reclamos.
* *Pasarela de Pagos (Payment Gateway):* Sistema externo encargado de la captura, autorización y liquidación de pagos electrónicos (tarjetas, transferencias).
* *Módulo de Despacho y Logística (Módulo E):* Servicio externo a Ventas responsable de la asignación de transportistas, rutas de entrega y notificación del estado del envío.
* *Módulo de Seguridad y Usuarios (Módulo G):* Servicio centralizado de autenticación, control de accesos (RBAC), emisión de tokens JWT y gestión del maestro de cuentas de usuario.

---

## 4. Conceptos Técnicos y Normativos

* *Idempotencia (Idempotency):* Propiedad de una operación de API por la cual múltiples peticiones idénticas producen el mismo resultado sin generar efectos secundarios no deseados. Se implementa en F4 mediante la cabecera X-Idempotency-Key para evitar cobros o devoluciones duplicadas (*RNF-08*).
* *Snapshot Histórico:* Patrón de persistencia en el cual se copia y congela el estado exacto de los datos en el momento de la transacción (como precios de catálogo, datos de contacto y documentos fiscales), evitando inconsistencias si el catálogo o el perfil del usuario cambian en el futuro.
* *SLA (Service Level Agreement):* Acuerdo de Nivel de Servicio que estipula el tiempo máximo legal o contractual para atender una solicitud. En el Libro de Reclamaciones (F6) corresponde a un plazo legal perentorio de *15 días hábiles* fijado por la normativa de Indecopi.
* *Respuesta Visible al Cliente:* Dictamen resolutivo emitido y redactado formalmente por el Gestor que se publica en el expediente del reclamo para consulta directa y transparente del consumidor.
* *Aislamiento de Microservicios:* Principio de diseño (*RNF-07*) que prohíbe el uso de bases de datos compartidas y llaves foráneas físicas cruzadas entre M1 (Ventas) y M2 (Postventa), obligando a que toda comunicación inter-módulo ocurra mediante APIs REST o eventos.

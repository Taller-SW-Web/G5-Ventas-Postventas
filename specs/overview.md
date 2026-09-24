# Visión General del Sistema (Overview) — Módulo D: Ventas y Postventa

**Módulo:** D — Ventas y Postventa
**Versión de Especificación:** 2.0.0
**Fecha:** Septiembre 2026

---

## 1. Propósito y Alcance

El **Módulo D (Ventas y Postventa)** constituye el núcleo transaccional y de atención post-compra de la plataforma. Su alcance cubre de extremo a extremo:

1. La captura, validación y control del ciclo de vida de las órdenes de compra emitidas desde los canales de atención (Web, Chatbot, POS/Retail).
2. La gestión de excepciones transaccionales tempranas (anulación de pedidos antes o durante el despacho).
3. El ciclo integral de postventa una vez efectuada la entrega física (devoluciones de productos, extornos económicos a través de pasarela, evaluación de experiencia CSAT y gestión normativa del Libro de Reclamaciones conforme a la regulación nacional de Indecopi).

El diseño del módulo prioriza la **alta disponibilidad en el checkout**, el **aislamiento de dominios**, la **inmutabilidad de registros fiscales** y la **idempotencia en transacciones financieras**.

---

## 2. Arquitectura de Microservicios

El dominio de Ventas y Postventa está desacoplado en dos microservicios independientes (**RNF-07**), aplicando el patrón **Database-per-Service** para evitar acoplamiento a nivel de persistencia:

```
                  ┌──────────────────────────────────────────────┐
                  │    Canales de Entrada (Web, Chatbot, POS)    │
                  └───────┬──────────────────────────────┬───────┘
                          │                              │
                          ▼ (HTTP / REST)                ▼ (HTTP / REST)
          ┌───────────────────────────────┐     ┌────────────────────────────────┐
          │     MICROSERVICIO M1          │     │        MICROSERVICIO M2        │
          │         (Ventas)              │     │          (Postventa)           │
          ├───────────────────────────────┤     ├────────────────────────────────┤
          │ • F1: Gestión de Pedidos      │     │ • F3: Devoluciones y Cambios   │
          │ • F2: Anulaciones             │──┐  │ • F4: Reembolsos y Extornos    │
          │                               │  │  │ • F5: Encuesta CSAT            │
          │                               │  │  │ • F6: Reclamos y Dashboard     │
          └──────────────┬────────────────┘  │  └───────────────┬────────────────┘
                         │                   │ (REST Interno)   │
                         │                   └─────────────────▶│ (Disparo de Reembolso)
                         ▼                                      ▼
                  ┌──────────────┐                       ┌──────────────┐
                  │ Base de Datos│                       │ Base de Datos│
                  │   M1_VENTAS  │                       │ M2_POSTVENTA │
                  └──────────────┘                       └──────────────┘
```

### 2.1. M1 — Microservicio de Ventas

* **Foco:** Operaciones transaccionales críticas de alta concurrencia (creación y consulta de pedidos).
* **Persistencia:** Base de datos relacional orientada a consistencia estricta (ACID) y conservación de snapshots históricos inmutables de compra.

### 2.2. M2 — Microservicio de Postventa

* **Foco:** Flujos orientados a procesos, auditoría, intervención humana (Gestores) y cumplimiento legal de plazos de atención.
* **Persistencia:** Base de datos independiente; las entidades de postventa referencian al pedido únicamente mediante identificadores lógicos (pedidoId), sin llaves foráneas físicas inter-base de datos.

---

## 3. Matriz de Funcionalidades (F1 - F6)

| Código | Funcionalidad | Servicio | Responsable | Descripción de Alcance |
|---|---|:---:|:---:|---|
| **F1** | **Gestión de Pedidos** | M1 | Michael | Máquina de estados del pedido (CREADO → ENTREGADO). Recepción de payloads de compra con snapshot inmutable de cliente y precios. |
| **F2** | **Anulación de Pedidos** | M1 | Luis Arroyo | Cancelación directa en estados tempranos (CREADO, PAGADO) o generación de expediente de anulación con aprobación de Gestor en EN_PREPARACION. |
| **F3** | **Devoluciones y Cambios** | M2 | Joseph | Endpoint de carga de evidencias visuales (multipart/form-data), registro de solicitudes post-entrega y dictamen técnico. |
| **F4** | **Reembolsos y Extornos** | M2 | Luis Alejandro | Orquestación de extornos monetarios hacia pasarela externa con validación obligatoria de idempotencia (X-Idempotency-Key). |
| **F5** | **Satisfacción (CSAT)** | M2 | Johan | Recolección de calificaciones (1 a 5) y comentarios post-entrega para evaluación continua de calidad del servicio. |
| **F6** | **Libro de Reclamaciones** | M2 | Fabrizio | Registro de quejas/reclamos con código único rastreable, SLA regulatorio de 15 días hábiles, respuesta pública al cliente y métricas ejecutivas. |

---

## 4. Integraciones y Límites de Dominio

1. **Canales de Atención (Frontends / Chatbot):**
   Interactúan mediante APIs REST documentadas bajo especificación OpenAPI/Swagger. Para archivos binarios (fotos de evidencias en F3), el canal consume el endpoint de upload de M2 antes de formalizar la solicitud JSON.
2. **Módulo G (Seguridad y Usuarios):**
   Emite los tokens JWT que validan la identidad del cliente y autorizan operaciones privilegiadas de los gestores (GESTOR, ADMIN). M1 y M2 validan la firma del token sin consultar síncronamente la base de datos de usuarios en el checkout crítico.
3. **Módulo E (Despacho y Logística):**
   Comunica a M1 los hitos de entrega (DESPACHADO, ENTREGADO) o reporta la condición de ENTREGA_FALLIDA_DEFINITIVA, evento que desencadena la anulación en M1 y el extorno automático en M2.
4. **Pasarela de Pagos Externa:**
   Provee confirmación transaccional de recaudación hacia M1 y procesa reversiones financieras invocadas por F4 en M2.

---

## 5. Requerimientos No Funcionales (RNF)

* **RNF-05 (Rendimiento y Autonomía en Checkout):** El registro de pedidos (POST /api/v1/pedidos) responde en T < 500 ms. No realiza bloqueos síncronos contra servicios externos periféricos.
* **RNF-07 (Aislamiento de Microservicios):** Prohibición absoluta de esquemas relacionales compartidos o triggers entre M1 y M2. Toda coordinación inter-módulo se gestiona a nivel de aplicación (API REST interna autenticada).
* **RNF-08 (Idempotencia Financiera):** Todas las solicitudes de reembolso en F4 requieren la cabecera X-Idempotency-Key generada por el emisor, garantizando que reintentos de red no originen transacciones duplicadas.
* **RNF-12 (Trazabilidad y No Repudio):** Cualquier dictamen humano (autorización de anulación en F2, rechazo de devolución en F3, respuesta a reclamo en F6) persiste el autorizadorId, marca de tiempo ISO-8601 y fundamento no editable para fines de auditoría.

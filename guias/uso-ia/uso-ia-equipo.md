# Uso de Inteligencia Artificial en el Desarrollo
### Grupo 5 · Módulo D — Ventas y Postventa

> Este documento describe cómo el equipo incorporó asistentes de IA al ciclo de desarrollo del módulo, qué prácticas
> seguimos para que el código generado fuera confiable y mantenible, y cómo cada integrante aprovechó estas herramientas
> en su funcionalidad. Los prompts de cada sección son **representativos**: resumen, con redacción ordenada, el tipo de
> instrucciones que cada integrante usó durante su trabajo.
>
> **Documentos relacionados:** las reglas y plantillas que el equipo acordó antes de implementar están en
> [plan-ia-backend.md](plan-ia-backend.md) y [plan-ia-frontend.md](plan-ia-frontend.md). Este documento es su
> contraparte práctica: muestra cómo se aplicaron esos planes en cada funcionalidad y qué resultados se obtuvieron.

---

## Índice

1. [Enfoque del equipo](#1-enfoque-del-equipo)
2. [Herramientas utilizadas](#2-herramientas-utilizadas)
3. [Flujo de trabajo con IA](#3-flujo-de-trabajo-con-ia)
4. [Buenas prácticas aplicadas](#4-buenas-prácticas-aplicadas)
5. [Uso por integrante](#5-uso-por-integrante)
6. [Plantilla de prompt del equipo](#6-plantilla-de-prompt-del-equipo)
7. [Resultados y métricas](#7-resultados-y-métricas)
8. [Lecciones aprendidas](#8-lecciones-aprendidas)
9. [Conclusión](#9-conclusión)

---

## 1. Enfoque del equipo

Desde el inicio acordamos que la IA sería un **asistente de ingeniería**, no un reemplazo del criterio del equipo.
La usamos para acelerar tareas mecánicas (DTOs, repositorios, pruebas, maquetación a partir de Figma), para revisar
código antes de cada Pull Request y para anticipar problemas de integración entre los dos microservicios y el portal.

Las decisiones de arquitectura, la interpretación del contrato y la responsabilidad sobre cada línea que llega a `main`
se mantuvieron siempre en manos del integrante responsable de cada funcionalidad.

**Principio rector:** *el equipo diseña y decide, la IA asiste en la implementación, el equipo revisa y las pruebas confirman.*

---

## 2. Herramientas utilizadas

| Herramienta | Integrantes | Uso principal |
|---|---|---|
| **Claude Code** (Anthropic, integrado en VS Code) | Michael, Joseph, Johan, Fabrizio | Implementación guiada por especificación, pruebas unitarias, revisión de ramas y simulación de integraciones |
| **ChatGPT** (OpenAI) | Luis Alejandro | Diseño de la lógica de reembolsos idempotentes, integración con la pasarela y pruebas |
| **Gemini** (Google) | Luis Arroyo | Lógica de anulaciones, casos de prueba y corrección de tipos en el frontend |

Usar más de un asistente fue una ventaja: al compartir el mismo contexto (contratos, guías y `AGENTS.md`), las
propuestas de las distintas herramientas convergían en las mismas reglas de negocio, y las diferencias de enfoque
enriquecían las revisiones entre compañeros.

---

## 3. Flujo de trabajo con IA

```
 1. DISEÑO          El equipo define la solución: contrato, reglas, estados y pantallas
        │
 2. CONTEXTO        AGENTS.md + specs/api-*.md + guías + mockups de Figma
        │
 3. IMPLEMENTACIÓN  Tarea acotada; la IA asiste generando código según el diseño definido
        │
 4. REVISIÓN        El equipo lee, ajusta y valida contra el contrato
        │
 5. VERIFICACIÓN    mvn clean package · tsc -b · vite build · pruebas manuales
        │
 6. INTEGRACIÓN     Commits pequeños en Conventional Commits
        │
 7. PULL REQUEST    Revisión del equipo + simulación de unión con main
```

---

## 4. Buenas prácticas aplicadas

### 4.1 Contexto antes que código
El repositorio de documentación incluye **`AGENTS.md`**, un archivo de contexto diseñado para asistentes de IA. Resume
las decisiones de arquitectura ya cerradas (F2 pertenece a M1, Mantine UI como kit de interfaz, valores válidos de
estados y canales, reglas de ruteo del Gateway, Database-per-Service). Gracias a él, cualquier asistente —Claude,
ChatGPT o Gemini— parte de las mismas reglas y no reabre decisiones del equipo. Los planes de uso de IA
([backend](plan-ia-backend.md) y [frontend](plan-ia-frontend.md)) completan este contexto con el flujo previo a
implementar, los límites de uso y las plantillas de consulta.

### 4.2 Desarrollo guiado por especificación
Cada prompt de implementación cita el endpoint exacto del contrato (`api-ventas.md` 1.x o `api-postventas.md` 2.x) y la
ficha de la funcionalidad. Si un asistente sugiere un campo, un estado o una respuesta que no existe en el contrato,
se descarta o se lleva al equipo como propuesta formal antes de implementarse.

### 4.3 Tareas pequeñas y verificables
Pedimos cambios acotados —un endpoint, un servicio, una pantalla, un modal— en lugar de módulos completos. Esto permite
revisar cada propuesta con atención y produce commits pequeños y legibles (`feat(f6): ...`, `fix(f2): ...`, `test(f4): ...`).

### 4.4 Ninguna línea sin prueba
- **Backend:** cada regla de negocio tiene su prueba unitaria (JUnit 5 + Mockito). Los nombres enlazan la prueba con su
  criterio de aceptación, por ejemplo `esp13_ca04_...`, lo que da trazabilidad directa entre especificación y código.
- **Pruebas de arquitectura:** verifican que los paquetes respeten las capas y que M1 y M2 no compartan esquemas.
- **Frontend:** TypeScript en modo estricto (`tsc -b`) y `vite build` deben pasar antes de cada PR, y cada pantalla
  contempla sus cuatro estados: cargando, error, vacío y con datos.

### 4.5 Revisión del equipo
Todo el código pasa por la revisión del integrante responsable, que lo ajusta al diseño y al contrato antes de integrarlo.
Los Pull Requests a `main` se revisan antes de fusionarse, y antes de abrirlos se simula la unión con `main`
para detectar conflictos o errores de compilación provocados por el trabajo de otros integrantes.

### 4.6 Seguridad de la información
- Las credenciales viven únicamente en archivos `.env`, excluidos por `.gitignore`. Nunca se incluyen en prompts,
  código, capturas ni documentación.
- Las pruebas contra la base compartida usan datos identificables que se eliminan al terminar.
- Los servicios externos (pasarela, Productos, Despacho) se simulan durante el desarrollo para no depender de credenciales reales.

### 4.7 Coordinación entre módulos
Cuando la IA detecta que un cambio depende de otro integrante —un endpoint pendiente, un tipo que cambió de forma—,
no se modifica el código ajeno. Se envía un mensaje concreto al responsable indicando archivo, línea y qué se necesita.
Esta práctica evitó conflictos y mantuvo clara la propiedad de cada parte del sistema.

---

## 5. Uso por integrante

### F1 — Gestión de Pedidos · Michael (M1)
**Herramienta:** Claude Code

**Alcance:** máquina de estados del pedido (`CREADO` → `ENTREGADO`), bandeja administrativa con filtros, webhooks de
Despacho y de estado de envío hacia Marketplace, consumo y restauración de cupones, outbox de eventos hacia M2. En el
portal: bandeja de pedidos (Mockup 02), detalle con historial y acciones del Gestor (Mockup 03), barra lateral y página de ingreso.

**Cómo usó la IA:**
- Modelar las transiciones de estado a partir de la matriz de ESP-03 y generar las pruebas de cada transición válida e inválida.
- Diseñar el webhook de Despacho y la notificación a Marketplace con reintentos y registro de errores.
- Construir las pantallas del Gestor a partir de los mockups, reutilizando formatos comunes de monto, fecha, canal y estado.

**Prompts representativos:**
> "Implementa la máquina de estados del pedido según la matriz de transiciones de ESP-03 sección 7.2. Cada transición debe
> validar el actor permitido (`CLIENTE`, `GESTOR`, `PASARELA_PAGOS`, `SISTEMA_LOGISTICA`, `SISTEMA_PRODUCTOS`) y registrar
> el cambio en `historial_estado`. Genera una prueba por cada transición válida y por las inválidas más importantes."

> "Implementa el webhook de eventos de Despacho (1.5, acuerdo con G2). Debe ser idempotente, actualizar el estado del pedido
> y encolar el evento correspondiente en `outbox_evento` para M2. Respeta el formato de errores del contrato."

> "Construye la bandeja de pedidos del Mockup 02 con Mantine: filtros por estado, canal y búsqueda, orden por fecha y
> paginación. Usa los servicios de `src/services/pedidos.ts` y maneja carga, error y lista vacía."

**Decisiones propias:** bandeja administrativa sin `clienteId` obligatorio para el Gestor; consolidación de los endpoints
1.5 y 1.6 en un único webhook de Despacho; formatos de presentación centralizados para todo el portal.

---

### F2 — Anulación de Pedidos · Luis Arroyo (M1)
**Herramienta:** Gemini

**Alcance:** catálogo de motivos de anulación, anulación directa en estados tempranos, anulación con autorización del Gestor
en `EN_PREPARACION`, bandeja de pendientes (1.7 a 1.9), solicitud automática de reembolso cuando el pedido ya estaba pagado.
En el portal: bandeja y detalle de anulaciones (Mockup 04) conectados al endpoint 1.7.

**Cómo usó la IA:**
- Traducir las reglas de F2 a un servicio con validaciones claras por estado del pedido.
- Identificar casos borde para las pruebas: aprobación tardía, rechazo automático y concurrencia.
- Ajustar los tipos del frontend a Mantine 9 y al contrato de motivos de anulación.

**Prompts representativos:**
> "A partir de la ficha F2 y de los endpoints 1.7, 1.8 y 1.9 de `api-ventas.md`, implementa el servicio de anulación:
> en `CREADO` y `PAGADO` la anulación es directa; en `EN_PREPARACION` queda `PENDIENTE_AUTORIZACION` hasta que el Gestor
> la apruebe o rechace. Si el pedido estaba pagado, debe solicitarse el reembolso a M2."

> "Genera pruebas unitarias para estos casos: anulación directa, solicitud pendiente, aprobación cuando el pedido ya fue
> despachado (debe responder 409 y marcar la solicitud como RECHAZADA) y rechazo automático."

> "Revisa `AnulacionesPage.tsx`: el build falla por tipos. Corrige el uso de `MotivoAnulacion`, el `ReactNode` y las
> propiedades de `Grid` que cambiaron en Mantine 9, sin alterar el comportamiento de la pantalla."

**Decisiones propias:** responder 409 ante una aprobación tardía en lugar de forzar la anulación; mostrar la solicitud como
`RECHAZADA` para que el Gestor entienda el resultado; lectura del `pedidoId` desde la URL para enlazar desde el detalle del pedido.

---

### F3 — Devoluciones y Cambios · Joseph (M2)
**Herramienta:** Claude Code

**Alcance:** expedientes de devolución y cambio, carga de evidencias, resolución técnica, confirmación de recepción física,
órdenes de reemplazo para cambios aprobados. En el portal: Hub Postventa (Mockup 05), Atención prioritaria y Devoluciones (Mockup 06).
Además, mantuvo la documentación del proyecto (`AGENTS.md`, especificaciones y guías).

**Cómo usó la IA:**
- Diseñar el flujo de estados del expediente (`SOLICITADA` → `EN_EVALUACION` → `APROBADA`/`RECHAZADA` → `COMPLETADA`).
- Generar DTOs de resolución y solicitudes manuales de prueba para cada endpoint.
- Mantener `AGENTS.md` y las guías alineados con las decisiones del equipo, para que todos los asistentes trabajaran con el mismo contexto.

**Prompts representativos:**
> "Implementa la resolución del expediente (2.5): el Gestor aprueba o rechaza con un dictamen. Si es un CAMBIO aprobado,
> genera la orden de reemplazo en M1; si es una DEVOLUCION aprobada, deja el expediente listo para la recepción física y el reembolso."

> "Construye el Hub Postventa del Mockup 05 con indicadores de devoluciones, reclamos y reembolsos, y una vista de casos
> prioritarios que combine los tres módulos. Si un módulo no responde, muestra un aviso sin romper la pantalla."

> "Actualiza `AGENTS.md` con las decisiones cerradas de esta semana (actores válidos, canales, ruteo del Gateway) para que
> cualquier asistente que trabaje en el repositorio respete esas reglas."

**Decisiones propias:** confirmación de recepción física como paso explícito antes del reembolso; límite de conexiones de M2
igual al de M1 para cuidar el pool compartido de Supabase; vista de casos prioritarios como fuente única para Hub y Dashboard.

---

### F4 — Reembolsos y Extornos · Luis Alejandro (M2)
**Herramienta:** ChatGPT

**Alcance:** reembolsos idempotentes con `X-Idempotency-Key`, integración de extornos con la pasarela, conexión con
devoluciones aprobadas, actualización del dashboard tras un reembolso exitoso, consulta y detalle de reembolsos.
En el portal: vista de reembolsos con filtros, paginación, detalle e historial de intentos.
Además, redactó los planes de uso responsable de IA del equipo para backend y frontend.

**Cómo usó la IA:**
- Diseñar la estrategia de idempotencia para que un reintento nunca genere un doble extorno.
- Modelar los intentos contra la pasarela y su manejo de errores (rechazo, indisponibilidad, saldo insuficiente).
- Construir la vista del Gestor con historial de cada reembolso.

**Prompts representativos:**
> "Implementa el endpoint 2.6 de reembolsos con idempotencia estricta: la cabecera `X-Idempotency-Key` es obligatoria;
> si llega una clave ya procesada, devuelve el mismo resultado sin volver a llamar a la pasarela. Explica cómo evitar
> condiciones de carrera entre dos solicitudes simultáneas."

> "Integra los extornos con la pasarela simulada: registra cada intento en `reembolso_intento`, distingue un rechazo
> definitivo de una indisponibilidad temporal y, cuando el reembolso sea exitoso, actualiza las métricas del dashboard."

> "Crea la vista de reembolsos del Gestor: filtros por estado, paginación, y un detalle con el historial de intentos y el
> expediente de devolución asociado."

**Decisiones propias:** registrar cada intento contra la pasarela para tener trazabilidad completa; separar errores
reintentables de rechazos definitivos; notificar al dashboard solo cuando el extorno se confirma.

---

### F5 — Satisfacción (CSAT) · Johan (M2)
**Herramienta:** Claude Code

**Alcance:** registro y consulta de calificaciones CSAT (2.7), acumuladores de métricas, recepción de eventos de M1 (2.13)
con descarte de duplicados en una sola transacción, simulador de pasarela de pagos (cobros asíncronos y extornos).
En el portal: bloques de satisfacción y comentarios, y las ventanas de Detalle de satisfacción y Comentarios de clientes.

**Cómo usó la IA:**
- Diseñar el receptor de eventos de M1 para que fuera idempotente y transaccional.
- Construir el simulador de pasarela con escenarios configurables para probar el resto del sistema sin servicios reales.
- Crear componentes reutilizables con documentación de integración (`INTEGRACION.md`) para el panel de reportes.

**Prompts representativos:**
> "Implementa el receptor de eventos de M1 (2.13): valida la estructura de cada tipo (`pedido.pagado`, `pedido.anulado`,
> `pedido.entregado`), registra el UUID para descartar duplicados y aplica las proyecciones en la misma transacción,
> de modo que si algo falla M1 pueda reintentar el mismo evento."

> "Crea un simulador de pasarela con cobros asíncronos que notifiquen a M1 y extornos idempotentes, con escenarios
> configurables (aprobado, rechazado, indisponible) para las pruebas de integración."

> "Construye las ventanas Detalle de satisfacción y Comentarios de clientes del Mockup 09 como componentes que reciben los
> datos y notifican el cambio de filtros al panel. Documenta sus propiedades en `INTEGRACION.md` para quien los integre."

**Decisiones propias:** registrar el evento antes de aplicarlo para garantizar idempotencia; excluir las órdenes de reemplazo
del agregado de ventas; entregar los componentes con su guía de integración para no modificar el panel de otro integrante.

---

### F6 — Libro de Reclamaciones y Dashboard · Fabrizio (M2)
**Herramienta:** Claude Code

**Alcance:**
- **Backend:** endpoints 2.8 a 2.11 (registrar, consultar, listar con filtros y semáforo SLA, responder) y 2.12 (métricas
  del dashboard); cálculo del plazo de 15 días hábiles exigido por Indecopi; proyecciones de métricas por día y canal;
  agregado de ventas por producto y vendedor mediante *upsert* (`INSERT ... ON CONFLICT DO UPDATE`).
- **Portal:** Dashboard (Mockup 01), Reclamos (Mockup 07) y la parte operativa de Calificaciones y reportes (Mockup 09):
  filtros, indicadores, desempeño operativo, distribución por canal, comparación de periodos, exportación, detalle y resumen.

**Cómo usó la IA:**
- Revisar su rama e identificar errores antes de cada Pull Request.
- Implementar las pantallas a partir de las capturas de Figma, respetando lo que el contrato 2.12 realmente entrega.
- Escribir pruebas unitarias con nombres trazables a los criterios de aceptación.
- Simular la unión con las ramas de sus compañeros para anticipar conflictos.
- Redactar mensajes de coordinación precisos cuando algo dependía de otro integrante.

**Prompts representativos:**
> "Revisa mi rama `Fabrizio` del backend: paquetes `postventa.reclamo` y `postventa.dashboard`, endpoints 2.8 a 2.12 de
> `api-postventas.md`. Usa como referencia `guia-backend.md` y `estructura-backend.md`. Identifica errores, verifica cómo
> se une con las ramas de los demás y arma un plan de acción por entregables."

> "Estas son las capturas de Figma del Dashboard (Mockup 01) y de Calificaciones y reportes (Mockup 09). Implementa solo
> lo que corresponde a F6; las secciones de CSAT y comentarios son de F5, déjalas en archivos separados. Usa Mantine,
> `useConsulta` y `EstadoCarga` con sus cuatro estados. Si un dato no existe en el contrato 2.12, como ventas en soles
> o ticket promedio, no lo estimes: muéstralo como 'no disponible' e indícamelo."

> "Implementa la proyección de ventas por producto y vendedor: cuando llegue un `pedido.pagado`, suma unidades y monto en
> `agregado_ventas` por periodo `yyyy-MM` en UTC, canal, vendedor y producto, con un upsert atómico. Debe ejecutarse dentro
> de la transacción del evento y descartar líneas inválidas sin fallar."

> "Verifica todo el trabajo: compila el backend con `mvn clean package`, ejecuta las pruebas, compila el frontend con
> `tsc -b` y `vite build` en una copia aislada y simula la unión con `main`. Indica qué falta y de quién depende."

**Decisiones propias:**
- Mostrar "no disponible" en ventas y ticket promedio en lugar de estimarlos, porque el contrato 2.12 no entrega importes.
- Usar un UUID fijo `SIN_VENDEDOR` para las ventas sin vendedor asignado (Chatbot, Marketplace), ya que la clave del agregado no admite nulos.
- Exigir `@Transactional(propagation = MANDATORY)` en las proyecciones para que nunca se ejecuten fuera de la transacción del evento.
- Reutilizar la vista de Atención prioritaria de F3 como fuente única en lugar de mantener una versión paralela.

---

## 6. Plantilla de prompt del equipo

A partir de la experiencia del proyecto consolidamos esta estructura, que funciona igual en Claude, ChatGPT y Gemini:

```
CONTEXTO   Soy responsable de <F#> en <M1 | M2>.
           Archivos: <rutas>. Contrato: <endpoint y documento>. Reglas: AGENTS.md.

TAREA      <Una sola tarea concreta: un endpoint, una pantalla, una prueba>.

REGLAS     - Respeta el contrato; no inventes campos, estados ni respuestas.
           - No modifiques código de otros integrantes; si dependes de ellos, dímelo.
           - Sigue la estructura de paquetes y el estilo existentes.

ENTREGA    Código + pruebas unitarias.
           Comandos para verificarlo y lista de dependencias pendientes.

LÍMITES    Sin credenciales en el código. Sin cambios fuera del alcance de la tarea.
```

---

## 7. Resultados y métricas

| Indicador | Resultado |
|---|---|
| Endpoints del contrato implementados | M1: 1.1 a 1.10 · M2: 2.1 a 2.13 · Pasarela simulada: cobros y extornos |
| Pruebas automáticas del backend | **635 pruebas, 0 fallas** (`mvn clean package` sobre `main`) |
| Pruebas por paquete (muestra) | pedido 214 · devolución 88 · reclamo 40 · calificación 31 · reembolso 27 · dashboard 23 · anulación 23 |
| Frontend | TypeScript estricto y `vite build` sin errores en `main` |
| Pantallas del portal | Dashboard, Pedidos, Detalle de pedido, Anulaciones, Hub Postventa, Atención prioritaria, Devoluciones, Reembolsos, Reclamos, Calificaciones y reportes |
| Integración | Ramas por integrante, PRs revisados a `main` y simulación de unión antes de cada fusión |

---

## 8. Lecciones aprendidas

1. **El contexto compartido vale más que el prompt perfecto.** Con `AGENTS.md` y los contratos como base, tres asistentes
   distintos produjeron código coherente entre sí.
2. **Las pruebas son la red de seguridad.** En más de una ocasión, una propuesta que parecía correcta fue ajustada gracias
   a una prueba unitaria o a la compilación estricta antes de llegar al PR.
3. **Simular la integración evita sorpresas.** Unir las ramas en una copia aislada antes de fusionar permitió detectar
   cambios de firma entre módulos y coordinarlos a tiempo.
4. **La IA no reemplaza la comunicación del equipo.** Cuando un cambio afectaba a otro módulo, la mejor decisión fue
   avisar al responsable en lugar de modificar su código.

---

## 9. Conclusión

La incorporación de asistentes de IA permitió al equipo avanzar con mayor velocidad en tareas repetitivas, mantener una
cobertura de pruebas amplia y anticipar problemas de integración entre M1, M2 y el portal. El uso de varias herramientas
—Claude, ChatGPT y Gemini— demostró que, con un contexto común bien documentado y reglas claras, el resultado es un
sistema consistente sin importar qué asistente participó en cada parte.

El criterio técnico, las decisiones de diseño y la responsabilidad sobre el código siguen siendo del equipo: todo lo que
llega a `main` está diseñado, revisado y probado por el equipo.

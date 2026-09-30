# RNF-01: Performance

**Responsable:** Luis Arroyo
**Categoría:** Requisito No Funcional — Rendimiento
**Estado:** En especificación
**Aplica a:** Todo el sistema (M1 — Pedidos y M2 — Postventa), con énfasis en los endpoints de F2 (Anulación)

## 1. Propósito

Garantizar tiempos de respuesta aceptables tanto en las operaciones transaccionales sobre pedidos como en la consulta del dashboard analítico, incluso con un volumen de datos representativo de producción.

## 2. Objetivos de rendimiento

| Operación | Umbral objetivo | Condición de medición |
|---|---|---|
| Operaciones transaccionales sobre un pedido (creación, consulta por ID, transición de estado, **solicitud de anulación**) | **< 500 ms** (percentil95) | Bajo carga concurrente simulada, dataset reproducible. |
| Consulta del dashboard analítico (F6) | **< 2 s** (percentil95) | Con un dataset de **≥ 5 000 pedidos** cargados. |

## 3. Alcance

Incluye:

- Medición del tiempo de respuesta de `POST /api/v1/pedidos/{pedidoId}/anulaciones` (F2 — ESP-05) y de la orquestación de efectos secundarios en ESP-06, bajo el umbral general de 500 ms para la porción síncrona expuesta al cliente.
- Medición del tiempo de carga del dashboard (F6) con dataset ≥ 5 000 pedidos.
- Uso de datasets reproducibles (semillas fijas) para que las pruebas de carga sean repetibles entre corridas y entre integrantes del equipo.

**No incluye:** la latencia de servicios externos simulados (pasarela de pago, logística) fuera del control del equipo; el tiempo de proceso asíncrono de notificaciones o eventos de dominio, que se rige por sus propios acuerdos de entrega.

## 4. Criterios de aceptación

#### CA-01. Latencia de anulación bajo umbral

- **DADO** un pedido en un estado anulable, con carga concurrente simulada.
- **CUANDO** se invoca `POST /api/v1/pedidos/{pedidoId}/anulaciones`.
- **ENTONCES** el tiempo de respuesta del percentil 95 es menor a 500 ms.

#### CA-02. Latencia del dashboard con dataset representativo

- **DADO** un dataset reproducible con al menos 5 000 pedidos y sus respectivos eventos de anulación/devolución/reembolso.
- **CUANDO** el Gestor consulta el dashboard de F6.
- **ENTONCES** el tiempo de respuesta del percentil 95 es menor a 2 s.

#### CA-03. Reproducibilidad del dataset de prueba

- **DADO** el script o fixture de carga de datos de prueba.
- **CUANDO** se ejecuta en distintos entornos o por distintos integrantes.
- **ENTONCES** genera el mismo volumen y distribución de datos, permitiendo comparar mediciones de rendimiento de forma consistente.

## 5. Estrategia de verificación

| Criterio | Verificación | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 | Prueba de carga sobre el endpoint de anulación con herramienta de benchmarking (p. ej. k6, JMeter o Artillery). | Integración / carga | Reporte con percentil 95 < 500 ms. |
| CA-02 | Carga del dataset reproducible (≥ 5 000 pedidos) y medición del tiempo de respuesta del endpoint del dashboard. | Integración / carga | Reporte con percentil 95 < 2 s. |
| CA-03 | Ejecutar el fixture de carga dos veces en entornos distintos y comparar volumen/distribución resultante. | Integración | Resultados idénticos o con variación despreciable. |

## 6. Fuera de alcance

- Optimización de la latencia de terceros externos simulados (pasarela de pago, módulo de logística).
- Rendimiento de procesos batch o de generación de reportes exportables (cubierto en RF-16 / F6, no como RNF de latencia interactiva).

## 7. Criterio de completitud

RNF-01 se considera completo cuando:

- Los criterios `CA-01` a `CA-03` están implementados y verificados con evidencia reproducible.
- Existe al menos un dataset de prueba versionado con ≥ 5 000 pedidos disponible para el equipo.
- Las pruebas de carga pueden ejecutarse de forma repetible en CI o localmente, con resultados documentados.

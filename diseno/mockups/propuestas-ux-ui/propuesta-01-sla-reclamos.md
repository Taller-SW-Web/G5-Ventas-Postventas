# Propuesta 01 — Desacoplamiento de Estado Administrativo y Semáforo de SLA en Reclamos

- **Pantalla intervenida:** `W06 — Reclamos`[cite: 16, 19]
- **Módulo responsable:** M2 — Postventa[cite: 4]
- **Perfil de usuario objetivo:** Gestor de Postventa / Administrador de Operaciones (`ADMIN_VENTAS`)

---

## 1. Contexto Operativo y Alcance
La gestión del Libro de Reclamaciones dentro de una plataforma transaccional no solo responde a criterios de servicio al cliente, sino a una obligación regulatoria vinculante bajo fiscalización del Indecopi (Ley N° 29571)[cite: 2]. El microservicio de Postventa (M2) registra cada reclamo y fija una fecha límite perentoria computada sobre una base de 15 días hábiles[cite: 2, 4]. En este entorno, la pantalla `W06` constituye la herramienta diaria del operador para priorizar expedientes, formular descargos y registrar la `respuestaVisibleCliente` antes de la expiración de los plazos legales[cite: 2, 19].

---

## 2. Diagnóstico del Estado Actual (Problema Identificado)

### 2.1. Ambigüedad de Estados y Sobrecarga Cognitiva
En la versión inicial del mockup (`W06 — Reclamos - Mockup Alta Fidelidad`), la tabla presentaba una sola columna rotulada como *"SLA"* con textos descriptivos genéricos como *"En plazo"*, *"Próximo"* o *"Cumplido"*[cite: 10, 16]. Asimismo, en la cabecera solo existía un filtro global por estado[cite: 16].
Esta estructura introducía fricciones críticas:
* **Cálculo mental continuo:** El gestor no podía determinar con exactitud si *"Próximo"* representaba 4 horas, 1 día o 3 días, viéndose forzado a abrir el detalle de cada fila o calcular manualmente la diferencia entre la fecha de creación y el calendario real[cite: 16].
* **Infracción de Heurísticas de Usabilidad:**
  * *Visibilidad del estado del sistema (Heurística 1 de Nielsen):* El sistema ocultaba la métrica temporal exacta de mayor relevancia jurídica.
  * *Reconocimiento antes que recuerdo (Heurística 6 de Nielsen):* El usuario debía recordar las fechas de corte en lugar de visualizarlas procesadas directamente.
* **Riesgo Regulatorio:** La incapacidad de filtrar y ordenar por umbral de vencimiento incrementaba la probabilidad de que expedientes críticos quedasen relegados tras un lote masivo de reclamos recientes, generando multas administrativas por vencimiento extemporáneo.

---

## 3. Especificación Detallada de la Solución de Diseño

### 3.1. Desacoplamiento Formal de Dimensiones en Cabecera
Se dividió el control de filtrado superior en dos componentes selectores independientes para evitar solapar el flujo de vida del reclamo con la urgencia temporal[cite: 19]:
1. **Filtro de Estado Administrativo:** Controla el ciclo de resolución (`Todos`, `REGISTRADO`, `EN PROCESO`, `ATENDIDO`)[cite: 19].
2. **Filtro de Urgencia Operativa (SLA):** Controla el semáforo temporal con opciones discretas (`Todos`, `Vencidos`, `Por vencer`, `En plazo`, `Atendidos`)[cite: 19].

### 3.2. Semáforo Cromático y Etiquetas de Cuenta Regresiva
En el cuerpo de la tabla, se reemplazó el texto estático por badges cromáticos dinámicos que combinan colorimetría de alerta y tiempo restante explícito[cite: 19]:
* **Verde (#2ECC71 / Fondo suave) — En plazo:** Rango de 6 a 15 días hábiles restantes (ejemplo: *"Quedan 15 días"*)[cite: 19]. Indica margen holgado de recopilación de antecedentes.
* **Amarillo (#F1C40F / Fondo suave) — Por vencer:** Rango de 3 a 5 días hábiles restantes (ejemplo: *"Quedan 5 días"*)[cite: 19]. Dispara advertencia preventiva para requerir descargo a áreas internas.
* **Rojo (#E74C3C / Fondo suave) — Crítico / Urgencia alta:** Rango de 1 a 2 días hábiles restantes (ejemplo: *"Quedan 2 días"*)[cite: 19]. Denota máxima prioridad operativa para emisión de respuesta legal.
* **Negro / Púrpura (#2C3E50) — Vencido:** Casos fuera de plazo reglamentario que indican el retraso acumulado (ejemplo: *"Vencido (+5 días)"*)[cite: 19]. Prioriza la mitigación inmediata de contingencias.
* **Gris neutro (#95A5A6) — Atendido:** Reclamos formalmente cerrados con descargo notificado al consumidor (`respuestaVisibleCliente`)[cite: 2, 19].

---

## 4. Impacto Operativo y Métricas Esperadas
* **Reducción del Tiempo de Clasificación (*Time to Triage*):** El operador identifica reclamos al borde del vencimiento en menos de 3 segundos desde la carga de la vista[cite: 19].
* **Mitigación de Riesgo de Sanciones:** Tasa de reclamos vencidos proyectada a 0% gracias a la segregación directa mediante el filtro de urgencia[cite: 19].
* **Cumplimiento de Auditoría A10:** Coherencia completa entre el modelo relacional (atributos `plazoDiasHabiles` y `fechaLimiteRespuesta`) y la representación visual en la capa de presentación[cite: 2, 19].

Referencia Figma:
https://www.figma.com/design/J2KeLP6nl8qlDunNNUAC52/Mockup-Hito-2?node-id=325-34&t=KlUQl3JPqioO24em-1
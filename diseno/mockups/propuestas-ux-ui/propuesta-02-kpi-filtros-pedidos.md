# Propuesta 02 — Filtro Rápido e Interactivo en Tarjetas KPI de Pedidos

- **Pantalla intervenida:** `W02 — Pedidos`[cite: 5, 14]
- **Módulo responsable:** M1 — Ventas[cite: 4]
- **Perfil de usuario objetivo:** Gestor Comercial / Administrador de Ventas (`ADMIN_VENTAS`)

---

## 1. Contexto Operativo y Alcance
El módulo de Ventas (M1) gobierna el ciclo de vida transaccional del pedido desde su creación hasta su despacho final[cite: 4]. En periodos de alta concurrencia o campañas promocionales (e.g., CyberDays), el volumen de órdenes diarias alcanza picos elevados, demandando un monitoreo ágil sobre pedidos bloqueados o en cola de preparación[cite: 5]. La pantalla `W02` es el tablero principal donde el gestor realiza el seguimiento del embudo de ventas y audita la progresión de estados[cite: 5, 14].

---

## 2. Diagnóstico del Estado Actual (Problema Identificado)

### 2.1. Fricción por Interacción Indirecta
En la propuesta original de `W02`, la cabecera incluía cinco tarjetas de resumen de métricas clave: *Total pedidos (2,880)*, *Pendientes (426)*, *Pagados (1,320)*, *Despachados (740)* y *Entregados (394)*[cite: 5].
A pesar de su prominencia visual, presentaban las siguientes deficiencias de interacción:
* **Componentes Pasivos Desaprovechados:** Las tarjetas funcionaban únicamente como texto estático informativo[cite: 5, 14]. Un gestor que detectaba una cifra anómala en *Pendientes* no podía interactuar con dicho elemento para profundizar en los datos[cite: 5, 14].
* **Pasos Redundantes:** Para aislar las órdenes asociadas a un indicador, el usuario debía desplazarse hacia la barra de filtros superior, abrir el menú desplegable *"Estado"*, buscar la opción deseada y presionar *"Aplicar filtros"*[cite: 5, 14]. Esto representaba un patrón de interacción de al menos 4 clics por consulta.
* **Infracción de Heurísticas de Usabilidad:**
  * *Flexibilidad y eficiencia de uso (Heurística 7 de Nielsen):* El sistema carecía de aceleradores para usuarios recurrentes que ejecutan tareas repetitivas de supervisión de colas.

---

## 3. Especificación Detallada de la Solución de Diseño

### 3.1. Transformación a Tarjetas de Filtrado Interactivo (Filter Chips / KPI Buttons)
Se redefinieron las tarjetas métricas superiores para dotarlas de comportamiento de botón selector de estado (*toggle state*)[cite: 14]:
* **Estado Predeterminado (Default):** Fondo blanco/crema con borde sutil, visualizando el conteo global y el icono representativo[cite: 5, 14].
* **Estado Activo / Seleccionado (Active):** Al hacer clic sobre una tarjeta (por ejemplo, *Pendientes: 426*), la tarjeta adquiere un borde perimetral destacado con el color primario de marca (`#FF5A00`), elevación visual sutil y realce tipográfico[cite: 14].
* **Respuesta Inmediata en Listado:** La acción ejecuta un filtrado reactivo instantáneo en la tabla inferior, mostrando exclusivamente los pedidos en estados compatibles (e.g., `EN PREPARACIÓN` o `CREADO`) sin requerir pulsar *"Aplicar filtros"*[cite: 14].
* **Comportamiento de Deselección:** Al hacer clic nuevamente sobre la tarjeta activa o presionar *"Limpiar"*, la vista se restablece automáticamente mostrando el universo total de pedidos[cite: 14].

---

## 4. Impacto Operativo y Métricas Esperadas
* **Optimización de Tasa de Clics:** Reducción del 75% en los pasos de interacción requeridos para auditar estados específicos (de 4 clics a 1 solo clic)[cite: 14].
* **Fluidez Operativa en Picos de Tráfico:** Permite al gestor auditar cuellos de botella en preparación o despachos mediante navegación reactiva e intuitiva[cite: 14].
* **Consistencia del Sistema de Diseño:** Se mantiene la integridad visual corporativa sin agregar elementos invasivos en la jerarquía del layout[cite: 14].

Referencia Figma:
https://www.figma.com/design/J2KeLP6nl8qlDunNNUAC52/Mockup-Hito-2?node-id=325-13635&t=KlUQl3JPqioO24em-1

# Guía para programar el frontend - Módulo D Ventas y Postventa

El esqueleto (Fase 0) del repositorio `G5-Ventas-Postventas-Frontend` ya está creado (2026-10-13), siguiendo esta guía — ver `guias/frontend/estructura-frontend.md` para la estructura real ya confirmada. Esta guía sigue siendo la referencia para programar cada pantalla, a diferencia de la guía de backend (que corrige código ya existente). Se usa junto con `guias/frontend/estructura-frontend.md`, `specs/stack-frontend.md`, `specs/api-contract.md` (o `specs/api/api-ventas.md` y `api-postventas.md`, más detallados) y los mockups de alta fidelidad (Figma, exportados como imágenes `M0N_...`, uno por pantalla y por cada modal/overlay que la compone — más detallados que los `.md` de `diseno/mockups/`).

> **Estado real (revisado 2026-10-17):** las 9 pantallas de las secciones 5 a 12 ya están construidas en el repo (Dashboard, Pedidos/Detalle, Anulaciones, Hub Postventa, Devoluciones, Reclamos, Reembolsos, Calificaciones/Reportes), además de Login y las páginas de error/acceso denegado. Varios campos que esta guía no menciona (`metodoPago`, `clienteNombre`/`clienteId`, `total` en Reembolsos; `historial`/`recepciones`/`requiereDevolucionFisica` en Devoluciones; `consumidor`/`atendidoPor`/`estadoSla`/`diasHabilesRestantes`/`slaCumplido` en Reclamos; `ultimaActualizacion` en Dashboard) ya están en `api-postventas.md` porque el backend ya los construyó — el frontend los consume igual. **Bug real encontrado en esta revisión:** la bandeja de Devoluciones (Mockup 06) llama a `GET /api/v2/devoluciones` sin `clienteId` y sin los filtros `buscar`/`desde`/`hasta`/`orden` que ya tiene programados — el backend real todavía exige `clienteId` y no tiene esos filtros, así que la pantalla no carga contra el backend tal como está hoy. Ver `AGENTS.md` sección 4 y `api-postventas.md` 2.4.

Si esta guía y un mockup/contrato no coinciden, manda el mockup o el contrato; avisa en el grupo para corregir la guía.

> **Los mockups todavía no son el diseño final.** Al 2026-10-12 faltan dos correcciones de UX/UI antes de darlos por cerrados:
> 1. **Paleta de colores del Dashboard** — hoy usa 5 colores distintos en las tarjetas de KPI (naranja, azul, rojo, verde, celeste) y en los gráficos; se va a corregir para reducir la saturación y que el **naranja sea el color predominante**. No hardcodear esos 5 colores como definitivos en el theme de Mantine.
> 2. **Páginas 1 a 9 actualizadas con las 3 propuestas de UX/UI aprobadas (páginas 11, 12 y 13 del archivo de diseño)**, y el flujo interactivo de la página 10 reflejando esos cambios — todavía no está aplicado a los mockups oficiales.
>
> Lo que hay ahora sirve para empezar a programar estructura, datos y lógica — no para dar por cerrado el detalle visual final. Revisen la versión más reciente antes de pulir estilos.

---

## Índice

1. Reparto y orden de trabajo
2. Preparar el entorno
3. Reglas comunes
4. Autenticación y permisos
5. W01/Mockup 01 — Dashboard (Fabrizio)
6. W02–W03/Mockup 02–03 — Pedidos y Detalle (Michael)
7. W04/Mockup 04 — Anulaciones (Luis Arroyo)
8. Mockup 05 — Hub Postventa (Joseph)
9. W05/Mockup 06 — Devoluciones y cambios (Joseph)
10. W06/Mockup 07 — Reclamos (Fabrizio)
11. W07/Mockup 08 — Reembolsos (Luis Alejandro)
12. W08/Mockup 09 — Calificaciones y reportes (Johan + Fabrizio)
13. Antes de abrir un PR

---

## 1. Reparto y orden de trabajo

### 1.1. Quién hace qué

Mismo reparto que el backend (README.md), una pantalla por persona:

| Persona | Pantalla(s) | Endpoints que consume |
|---|---|---|
| Michael | Pedidos (02), Detalle del pedido (03) | `api-ventas.md` 1.3, 1.4 |
| Luis Arroyo | Anulaciones (04) | `api-ventas.md` 1.7 a 1.9 |
| Joseph | Devoluciones y cambios (06), Hub Postventa (05) | `api-postventas.md` 2.1 a 2.5 |
| Luis Alejandro | Reembolsos (08) | `api-postventas.md` 2.6 |
| Johan | Calificaciones (parte de 09) | `api-postventas.md` 2.7 |
| Fabrizio | Dashboard (01), Reclamos (07), Reportes (parte de 09) | `api-postventas.md` 2.8 a 2.12 |

**Mockup 05 — Hub Postventa — asignado a Joseph (2026-10-12).** Es la pantalla que conecta Devoluciones, Reclamos y Reembolsos (ver `diseno/mockups/Mockup 05 - Hub Postventa.md`); no tiene endpoint propio, solo agrega indicadores de las otras tres. Las tres pantallas que agrupa son de personas distintas (Joseph, Fabrizio, Luis Alejandro); se asignó a Joseph por ser la pantalla "pegamento" entre las tres y no sumar más carga a quien ya tiene varios mockups (Fabrizio) ni a quien está más justo de tiempo (Luis Alejandro).

### 1.2. Qué se puede avanzar ya, sin esperar a nadie

El backend recién está llegando a sus endpoints reales (ver `guias/backend/guia-backend.md`, sección 5.9/6.6): hoy la mayoría de endpoints de M1 son stubs (501) y M2 está sin empezar. **Nadie tiene que esperar al backend para avanzar la interfaz:**

1. Arma la pantalla completa con datos de prueba fijos (un `mock` local, no un servicio — eso viene después).
2. Define el `type` TypeScript de la respuesta según el contrato (`api-ventas.md`/`api-postventas.md`), no según lo que el backend devuelva hoy (puede estar incompleto o ser un 501).
3. Deja el `service` de esa pantalla con la llamada real ya escrita, apuntando a la URL del contrato — cuando el endpoint deje de ser un stub, la pantalla funciona sin tocar nada más.

### 1.3. Fases

```text
Fase 0  Esqueleto del proyecto (Vite + Mantine + theme + routing + cliente HTTP) — ver sección 2
Fase 1  Cada uno, en paralelo, con datos de prueba fijos: UI Kit que falte + su(s) pantalla(s) completas
Fase 2  Conectar cada pantalla a su endpoint real, a medida que el backend los libera (ver guía de backend)
Fase 3  Hub Postventa, una vez que Devoluciones/Reclamos/Reembolsos tengan su indicador listo
```

---

## 2. Preparar el entorno

### 2.1. Primera vez

```bash
npm create vite@latest . -- --template react-ts
npm install @mantine/core @mantine/hooks @mantine/form @mantine/notifications @mantine/dates
npm install react-router-dom axios
```

`.env.example` (cada uno copia a `.env`, que nunca se sube):

```properties
VITE_API_VENTAS_URL=http://localhost:8081
VITE_API_POSTVENTA_URL=http://localhost:8082
VITE_GATEWAY_URL=http://localhost:8080
VITE_SEGURIDAD_LOGIN_URL=<lo da Seguridad, G7>
```

En desarrollo, las llamadas van directo a cada microservicio (`8081`/`8082`) o por el Gateway (`8080`) según lo que el equipo decida — el Gateway rutea por recurso, ver `AGENTS.md` sección 2 punto 6. Mientras no haya decisión, usar el Gateway: es lo más parecido a producción.

### 2.2. Cliente HTTP (`services/api.ts`)

Centralizado, no uno por pantalla (stack-frontend.md, sección 5.1):

- Agrega `Authorization: Bearer <token>` desde donde quede guardado el JWT tras el login (ver sección 4).
- Interpreta `400`/`401`/`403`/`404`/`409`/`501` y los traduce a un error con el mismo `codigo` que manda el backend (`ErrorResponse`, ver `guias/backend/guia-backend.md` sección 3.3) — así cada pantalla puede mostrar el mensaje sin volver a parsear nada.
- Un `501` (`NO_IMPLEMENTADO`) debe mostrarse como "todavía no disponible", no como un error genérico — hoy la mayoría de endpoints de M2 van a devolver esto.

---

## 3. Reglas comunes

- **Tipado estricto:** nunca `any`. Los `types/` se escriben contra el contrato (`api-ventas.md`/`api-postventas.md`), no contra lo que el backend devuelve hoy si todavía está incompleto.
- **Cuatro estados en toda pantalla con datos async:** `loading`, `success`, `error`, `vacío` (sin resultados) — ninguna pantalla se da por terminada si le falta alguno (stack-frontend.md, sección 8.2 y 12).
- **Confirmación obligatoria** antes de: anular un pedido, aprobar/rechazar una devolución, ejecutar un reembolso, marcar un reclamo como atendido (stack-frontend.md, sección 8.1). El modal debe decir explícitamente qué se va a hacer, no un "¿estás seguro?" genérico.
- **Nunca inventar un estado o enum como texto suelto** — usar siempre el valor exacto del contrato (`CREADO`, `EN_PREPARACION`, `ADMIN_VENTAS`, etc.), igual que la regla del backend.
- **Badges de estado:** un componente único por tipo de entidad (`EstadoBadge`), no un `<span>` con color hardcodeado en cada pantalla — la paleta la define Figma, no cada quien a su criterio.
- **Nada de acciones que el estado actual no permite:** si un pedido no está `PAGADO`, no se muestra "Pasar a preparación" ni deshabilitado ni oculto a medias — se oculta. El backend vuelve a validar esto igual, pero la interfaz no debe sugerir una acción imposible.
- **Git y commits:** mismo flujo que el backend — rama por persona, PR hacia `main`, Conventional Commits (`feat(f3): bandeja de devoluciones`). Ver `guias/backend/guia-backend.md` sección 3.8, aplica igual aquí.

---

## 4. Autenticación y permisos

**`specs/stack-frontend.md` sección 7 ya corregida (2026-10-13):** decía que el acceso administrativo era para rol `GESTOR` o `ADMIN` — eso era el nombre viejo. El catálogo cerrado de Seguridad (G7) solo tiene `ADMIN_VENTAS` para el Gestor (ver `AGENTS.md`, sección 2, punto 9). El portal valida contra `ADMIN_VENTAS`, no contra `GESTOR` ni `ADMIN` — ya implementado así en `src/services/auth.ts` (`ROL_GESTOR = 'ADMIN_VENTAS'`) y `src/components/RutaProtegida/`.

- El login lo resuelve Seguridad (G7, fuera de este repo) y entrega un JWT de usuario con el claim `roles`.
- El portal del Gestor (todas las pantallas de esta guía) exige el rol `ADMIN_VENTAS`. Si el token no lo tiene: pantalla de acceso denegado, nunca ocultar solo visualmente las rutas `/admin/*` (stack-frontend.md, sección 7).
- El rol `CLIENTE` **no** se usa en el portal del Gestor — es para las vistas de integración que menciona `stack-frontend.md` sección 1 (encuesta CSAT, consulta pública de reclamo), que son pantallas aparte, sin layout administrativo, y pueden vivir en rutas públicas (`/encuesta/:pedidoId`, `/reclamos/consultar`) fuera de `/admin/*`.
- Los **scopes** (`ventas:pedidos:crear`, `postventa:csat:escribir`, etc.) son para tokens de servicio de otros módulos (canales, Despacho) — el frontend del Gestor nunca los usa ni los ve, porque siempre manda un token de usuario. No hay que replicar la tabla de scopes de la guía de backend aquí.
- El backend vuelve a validar todo esto — la protección de rutas en el frontend es solo para UX, no es la medida de seguridad real (stack-frontend.md, sección 7).

---

## 5. Dashboard (Mockup 01, Fabrizio)

**Pantallas del mockup:** `Dashboard_Principal`, `Atencion_Prioritaria`, `Modal_Detalle_prioritario`.

- **Layout confirmado en el mockup:** barra lateral fija (`VENTAS / POSTVENTA`) con 4 accesos — Dashboard, Pedidos, Postventa, Reportes — más filtros de `Periodo` (rango de fechas) y `Canal` arriba, con botones `Aplicar filtros`/`Limpiar`.
- **Tarjetas de KPI:** Ingresos, Ticket promedio, Tasa de anulación, Tasa de devolución, Atención (reclamos abiertos) — cada una con variación vs. periodo anterior. **Hoy usan 5 colores distintos de acento; va a corregirse a una paleta dominada por naranja (ver advertencia al inicio de esta guía)** — no hardcodear esos 5 colores.
- Gráficos: tendencia de ventas (línea), ventas por canal (barras, `Marketplace`/`Chatbot`/`Retail`), distribución de pedidos por estado (dona).
- **Endpoint:** `GET /api/v2/dashboard/metricas` (2.12), rol `ADMIN_VENTAS`.
- Filtros `desde`, `hasta` (obligatorios), `canal` (opcional, `MARKETPLACE`/`CHATBOT`/`RETAIL` — nunca `WEB`, ver `AGENTS.md` sección 2 punto 4).
- Indicadores: pedidos totales/anulados/entregados, devoluciones aprobadas, monto reembolsado PEN, CSAT promedio, reclamos pendientes de SLA.
- "Atención prioritaria" (panel propio en el Dashboard, más una vista ampliada `Ver todas` con su propio modal de detalle) cruza datos de varias pantallas — no tiene endpoint propio documentado todavía; confirmar con Fabrizio cómo arma esa consulta (probablemente combinando 1.8 de anulaciones pendientes, reclamos vencidos de 2.9/2.10, y devoluciones `EN_EVALUACION`).

---

## 6. Pedidos y Detalle del pedido (Mockup 02–03, Michael)

**Pantallas del mockup:** `Bandeja_Pedidos_Principal` (02), `Detalle_Pedido_Principal` (03) — a diferencia de las demás, Michael no tiene modales/overlays adicionales listados en el mockup, solo las dos pantallas principales.

- **Bandeja (02):** `GET /api/v1/pedidos` (1.4, uso administrativo, rol `ADMIN_VENTAS`) — filtros `clienteId`, `estado`, `desde`, `hasta`, paginado.
- **Detalle (03):** `GET /api/v1/pedidos/{pedidoId}` (1.3) — items, pago, envío (o `tiendaId` si es `RETAIL`, ver `api-ventas.md` "Campos adicionales de Retail"), historial de estados completo.
- Acciones por estado (desde el mockup): "Pasar a preparación", "Marcar como despachado", "Marcar como entregado" — corresponden a 1.5 (`PATCH .../estado`), que **hoy es un stub en el backend** (ver `guias/backend/guia-backend.md` 5.9). Arma la UI igual, pero no esperes que responda todavía.
- Un pedido `RETAIL` nunca pasa por preparación/despacho — nace `PAGADO` y queda `ENTREGADO` en el mismo momento (acuerdo G4). El detalle debe reflejar eso: no mostrar botones de preparación/despacho para pedidos `RETAIL`.
- Desde el detalle, "Iniciar anulación" lleva a Mockup 04.

---

## 7. Anulaciones (Mockup 04, Luis Arroyo)

**Pantallas del mockup:** `Anulaciones_Principal`, `Modal_Confirmar_aprobacion`, `Modal_Confirmar_rechazo` — dos modales de confirmación separados, uno por decisión (no un solo modal genérico con un toggle).

- **Endpoint:** `POST /api/v1/pedidos/{pedidoId}/anulaciones` (1.7) para solicitar; `GET .../anulaciones/pendientes` (1.8) y `PATCH .../anulaciones/{anulacionId}` (1.9) para la bandeja del Gestor, ambos rol `ADMIN_VENTAS`.
- Catálogo de motivos cerrado — ver `guias/backend/guia-backend.md` sección 6.1. El formulario de anulación nunca debe aceptar texto libre como motivo, es un selector contra ese catálogo. **No incluir `STOCK_NO_DISPONIBLE` ni `CUPON_RECHAZADO` en el selector del Gestor** — esos dos los dispara Productos automáticamente, nunca una persona.
- `EN_PREPARACION` necesita el modal de autorización (aprobar/rechazar), con `comentario` obligatorio si se rechaza.
- `DESPACHADO`/`ENTREGADO` no se pueden anular — la interfaz no debe ni mostrar el botón, y debe indicar que corresponde una devolución (F3) en su lugar.

---

## 8. Hub Postventa (Mockup 05, Joseph)

**Pantallas del mockup:** `Hub_Postventa`, `Atencion_Prioritaria`, `Modal_Detalle_prioritario` — mismo patrón de "atención prioritaria" que el Dashboard (Mockup 01), pero acotado a postventa (reclamos + devoluciones).

Es una pantalla simple: 3 tarjetas de resumen (devoluciones pendientes, reclamos abiertos, reembolsos en proceso), 3 tarjetas de acceso a módulo con botón `Ir al módulo`, y el panel de atención prioritaria con `Ver casos prioritarios`. No tiene formularios ni tablas propias — es puramente navegación y conteos que ya expone cada pantalla individual (ver 1.1 — agrupa indicadores de Devoluciones, Reclamos y Reembolsos, sin endpoint propio). Construirla después de que esas tres pantallas tengan su resumen/listado funcionando, para poder reusar esos mismos `services`.

---

## 9. Devoluciones y cambios (Mockup 06, Joseph)

**Pantallas del mockup:** `Devoluciones_y_Cambios_Principal`, `Modal_Confirmar_aprobacion`, `Modal_Confirmar_rechazo`, `Modal_Confirmar_cambio`, `Modal_Derivar_reembolso`, `Modal_Comprobante_adjunto`, `Modal_Vista_previa_evidencia` — es la pantalla con más estados de las nueve (7 en total). Los tres modales de resolución (`aprobacion`/`rechazo`/`cambio`) son distintos entre sí, no un solo modal con un selector — y `Modal_Derivar_reembolso` es un paso aparte después de aprobar con `DEVOLUCION_DINERO`, antes de pasar a Reembolsos (Mockup 08).

- **Endpoints:** 2.1 (subir evidencia), 2.2 (registrar), 2.3 (consultar), 2.4 (listado administrativo), 2.5 (resolver) — todos `api-postventas.md`.
- El plazo es 7 días naturales desde la entrega — mostrarlo en el expediente, no solo validarlo al resolver.
- Evidencia: solo `image/jpeg`, `image/png`, `image/webp`, `application/pdf`, máximo 5 MB — validar en el cliente antes de subir, aunque el backend valide de nuevo.
- Resolución: `CAMBIO`, `REEMBOLSO` o `RECHAZO` son excluyentes — el formulario no debe permitir marcar más de una. Si es `REEMBOLSO`, deriva a Reembolsos (Mockup 08).

---

## 10. Reclamos (Mockup 07, Fabrizio)

**Pantallas del mockup:** `Reclamos_Principal`, `Modal_Responder_reclamo`, `Modal_Marcar_atendido`, `Overlay_PDF_reclamo` — responder y marcar como atendido son dos pasos/modales separados, no uno solo; el PDF se abre en un overlay dedicado, no una descarga directa.

- **Endpoints:** 2.8 (registrar, normalmente desde el canal, no desde el Gestor), 2.9 (consultar por código), 2.10/2.10b (listar), 2.11 (responder) — `api-postventas.md`.
- `respuestaVisibleCliente` es obligatorio para cerrar — el botón "Marcar como atendido" debe quedar deshabilitado hasta que el campo tenga contenido (stack-frontend.md, sección 5.4).
- Mostrar el SLA (plazo de 15 días hábiles) como algo **distinto** del estado de atención — un reclamo puede estar `EN_PROCESO` y tener el plazo vencido a la vez; no ocultar eso.

---

## 11. Reembolsos (Mockup 08, Luis Alejandro)

**Pantallas del mockup:** `Reembolsos_Principal` (filtros `Buscar`/`Estado`/`Origen`/`Fecha de creación`, tabla con Código/Fecha, Pedido, Cliente, Origen, Monto, Estado, Acción), `Modal_Autorizar_reembolso`, `Modal_Ejecutar_reembolso`, `Modal_Reintento_seguro`, `Overlay_Resultado_reembolso` — **autorizar y ejecutar son dos modales distintos y consecutivos**, no un solo botón "procesar": confirma exactamente el recorrido de `Contexto y Flujo - Mockup.md` sección 9 (`Autorizar cuando corresponde → Ejecutar → Consultar resultado`).

- **Endpoint:** `POST /api/v2/reembolsos` (2.6), requiere cabecera `X-Idempotency-Key` siempre (RNF-08) — generarla una vez por intento de envío (UUID), no una por cada click, para que un doble click no dispare dos reembolsos.
- Estados: `PENDIENTE`, `EXITOSO`, `FALLIDO`. Un `FALLIDO` o `PENDIENTE` sin confirmar habilita `Modal_Reintento_seguro` — reenviar con la **misma** clave de idempotencia guardada, no generar una nueva.
- El resultado final se muestra en `Overlay_Resultado_reembolso`, no en un simple cambio de badge en la tabla — es una pantalla propia de confirmación.
- Deshabilitar el botón de ejecutar mientras la operación está en curso (stack-frontend.md, sección 5.3) — es la única defensa de UX contra doble envío, la validación real la hace el backend.

---

## 12. Calificaciones y reportes (Mockup 09, Johan + Fabrizio)

**Pantallas del mockup:** `Calificaciones_y_Reportes_Principal`, `Modal_Comparar_reportes`, `Modal_Exportar_reporte`, `Overlay_Detalle_CSAT`, `Overlay_Detalle_Operacion`, `Overlay_Comentarios`, `Overlay_Resumen`, `Overlay_Distribucion_por_canal`, `Overlay_Exportacion_completada` — la pantalla con más estados de las nueve (9 en total), reflejo de que mezcla dos funcionalidades (F5 y F6). Conviene que Johan y Fabrizio se repartan los overlays según a qué dato pertenecen (`Detalle_CSAT`/`Comentarios` → Johan; `Detalle_Operacion`/`Distribucion_por_canal`/`Resumen` → Fabrizio) antes de empezar, para no pisarse el componente principal.

- **Calificaciones (Johan):** `POST /api/v2/csat` (2.7) no lo llama el Gestor — lo llama el canal tras la entrega. Esta pantalla es de **solo lectura** para el Gestor: consulta resultados, no registra encuestas. Si hace falta una vista de encuesta real (para que el cliente la responda), es una vista pública aparte (ver sección 4), no parte de este mockup.
- **Reportes (Fabrizio):** reusa 2.12 (mismo endpoint que el Dashboard), con filtros de periodo/canal y comparación contra el periodo anterior. "Exportar" **ya genera y descarga un CSV real** (actualizado 2026-10-21, `ModalExportar.tsx`) con los indicadores de la consulta aplicada — pero el CSV se arma entero en el navegador a partir de datos ya traídos, sin llamar a ningún endpoint nuevo: no hay endpoint de exportación en el contrato (ESP-16, fuera de alcance por ahora), y no lo necesita porque no se genera en el servidor.

---

## 13. Antes de abrir un PR

- [ ] `npm run build` pasa sin errores de TypeScript
- [ ] La pantalla maneja los 4 estados (`loading`, `success`, `error`, vacío)
- [ ] Las acciones irreversibles de la lista de la sección 3 piden confirmación
- [ ] Ningún estado o rol escrito como texto suelto: siempre el valor exacto del contrato
- [ ] El rol protegido es `ADMIN_VENTAS`, nunca `GESTOR` ni `ADMIN`
- [ ] Componentes del UI Kit reusados en vez de duplicados (revisar `components/` antes de crear uno nuevo)
- [ ] Si el endpoint todavía es un `501` en el backend, la pantalla lo muestra como "no disponible", no como error
- [ ] Probado a mano con datos de ejemplo del mockup correspondiente
- [ ] Descripción del PR: qué pantalla, qué mockup, qué endpoints consume, cómo probarlo

# Guion de demo — F1 Ciclo de vida del pedido (Hito 4)

Duración estimada: 8 a 10 minutos. Responsable: Michael.

## Antes de empezar

- [ ] Abrir el frontend: <https://g5-ventas-postventas-frontend.vercel.app> y entrar como Gestor (`/ingresar`).
- [ ] "Despertar" el backend de Render 2 minutos antes (el plan gratuito se duerme): abrir `https://g5-servicio-ventas.onrender.com/api/v1/pedidos/me` en el navegador y esperar la respuesta.
- [ ] Tener una terminal de PowerShell en esta carpeta para correr [`demo-f1.ps1`](demo-f1.ps1). El script avanza paso a paso con Enter, así se puede narrar cada uno.
- [ ] Tener abiertas las pestañas **Actions** de los repos de frontend y backend (para la parte de CI/CD).

> El script crea un pedido real en la base. Si la seguridad de M1 está activa en Render, hay que pasarle `-Token` con un token que tenga los scopes de cada paso; si no, los pasos que necesitan token van a responder 401/403.

## 1. Contexto (1 min)

- M1 es el único dueño del estado del pedido. Los estados son `CREADO → PAGADO → EN_PREPARACION → DESPACHADO → ENTREGADO`, con `ANULADO` como salida.
- Toda transición pasa por la máquina de estados (matriz de ESP-03 §7.2), queda en el historial con actor, motivo y fecha UTC, y publica su evento a M2 por el outbox.

## 2. Ciclo completo (5 min) — `demo-f1.ps1`

| Paso del script | Qué mostrar | Qué decir |
|---|---|---|
| 1.1 Crear pedido | Respuesta `201` con `PED-AAAA-NNNNN` en `CREADO` | El canal crea el pedido con su token de servicio; la `Idempotency-Key` es obligatoria |
| Idempotencia | Mismo `pedidoId`, sin pedido duplicado | Reintentar con la misma clave devuelve `200` con el mismo pedido (acuerdo H-02) |
| 1.2 Pago aprobado | `nuevoEstado: PAGADO` | Solo la pasarela puede pasar de `CREADO` a `PAGADO`; la misma `transaccionId` no se aplica dos veces |
| 1.12 Iniciar preparación | `EN_PREPARACION` | Botón del Gestor; mostrarlo también en el detalle del pedido del frontend |
| 1.13 Paquete sellado | Mensaje de despacho solicitado | Crea el despacho en Despacho (G2); el estado no cambia hasta que Despacho avise |
| 1.5 En camino | `Pedido DESPACHADO` | Webhook genérico de Despacho, idempotente por `idEvento` |
| Transición inválida | `409 TRANSICION_NO_PERMITIDA` | La máquina de estados rechaza saltos fuera de la matriz, incluso para el Gestor |
| 1.5 Entregado | `Pedido ENTREGADO` | Publica `pedido.entregado` a M2: desde aquí el cliente puede pedir devolución o calificar |
| 1.3 Consultar | Tabla del historial con actores | Trazabilidad completa (RNF-03): `CANAL_CHATBOT`, `PASARELA_PAGOS`, `SISTEMA_LOGISTICA` |

## 3. Frontend (2 min)

1. **Pedidos** (mockup 02): buscar el `pedidoId` recién creado; mostrar los filtros por estado y canal.
2. **Detalle del pedido** (mockup 03): historial de estados y acciones del Gestor.
3. **Dashboard** (mockup 01): ventas por canal.

## 4. Cierre: CI/CD (1 min)

- Pestaña **Actions** del frontend: build + 12 tests + deploy automático a Vercel en cada merge a `main`.
- Pestaña **Actions** del backend: 290 tests; Render solo despliega si pasan ("After CI Checks Pass").
- Ejemplo real de que el CI frena código roto: la corrida roja que detectó errores de TypeScript (frontend) y el test desactualizado (backend).

## Si algo falla en vivo

| Síntoma | Qué hacer |
|---|---|
| Timeout en el primer paso | Render estaba dormido: esperar 1 minuto y volver a correr el script |
| `401`/`403` | La seguridad está activa: correr con `-Token` o mostrar el flujo desde el frontend |
| `409` en Paquete sellado | Revisar que el pedido tenga `direccion` y `distrito` (los exige Despacho) |

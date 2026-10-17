# Acuerdo con G4 — Retail / POS

Confirmado con el equipo de Retail. Última actualización: 2026-10-12.

## Qué consumimos de ellos

Nada directamente — Retail es quien consume nuestra API (`POST /api/v1/pedidos` con `canal.tipo: RETAIL`) para registrar cada venta de mostrador.

## Qué consumen ellos de nosotros

`POST /api/v1/pedidos`, para reportar cada venta (en tiempo real o reconciliada al reconectar tras una venta sin conexión).

## Decisiones confirmadas

| # | Qué se acordó | Dónde quedó documentado |
|---|---|---|
| R1 | Identificador de pedido: formato `PED-YYYY-NNNNN`, igual para todos los canales. | `specs/api/api-ventas.md` 1.1 |
| R2 | `vendedorId` y `clienteId` son el UUID de Seguridad (`sub` del JWT), no un identificador propio de Retail. | `AGENTS.md` sección 2, punto 10 |
| R3 | **El pedido nace `PAGADO`:** el cobro ya ocurrió físicamente en el POS antes de la llamada. Datos del cobro en el bloque `pago`: `metodoPago` (`EFECTIVO`\|`TARJETA_POS`\|`MIXTO`), `referenciaOperacion` (obligatorio con tarjeta o mixto), `montoEfectivo`/`montoTarjeta` (obligatorio en mixto). No se guarda código de autorización ni últimos 4 dígitos — el arqueo queda del lado de Retail. | `ESP-01-creacion-pedido.md` regla 13; `F1-Ciclo de vida del pedido.md` CA-01c |
| R4 | **El pedido transiciona a `ENTREGADO` en la misma operación:** el cliente se lleva el producto en el momento de la venta. Historial `PAGADO → ENTREGADO` con actor `CLIENTE`, motivo `ENTREGA_INMEDIATA_EN_TIENDA`, sin que Despacho participe. Se publica `pedido entregado` igual que cualquier canal; el plazo de 7 días de F3 (devoluciones) corre desde ahí, y se activa la encuesta CSAT de F5. | `ESP-03-transiciones-historial.md` regla 8, CA-04b; `ESP-01` regla 13; `F1-Ciclo de vida del pedido.md` CA-01d |
| R5 | **`envio` es opcional para `RETAIL`:** en su lugar es obligatorio `envio.tiendaId` (código de tienda, ej. `TIENDA-MIRAFLORES`). Nunca hay entrega a domicilio desde una venta de mostrador — si el cliente la quiere, compra por Marketplace. | `ESP-01` regla 5, tabla de datos de entrada |
| R6 | **La venta, el comprobante fiscal (boleta/factura, serie, correlativo, IGV, QR) y las notas de crédito/vales son responsabilidad exclusiva de Retail.** No construimos `ordenes/presenciales`, `validar-cambio` ni `generar-nota-credito`; no guardamos ninguno de esos datos. Si el cliente pide devolver dinero de un pedido, usa nuestra devolución (F3). | Consulta, preguntas 4, 6 y 7 |
| R7 | **Una venta por llamada**, con `Idempotency-Key` (igual que el resto de la API). Ventas sin conexión se guardan localmente y se envían una por una al reconectar, con la misma clave — no se duplican. | `ESP-01` regla 11 (acuerdo H-02, ya vigente para todos los canales) |
| R8 | **`fechaVenta`** (opcional, solo ventas sin conexión): UTC, ISO-8601, fecha y hora completas, máximo 72 h de antigüedad. Se usa como `fechaHora` del historial `PAGADO → ENTREGADO`; no reemplaza el `fechaHora` del historial `null → PAGADO`, que siempre refleja el momento real de la llamada. | `ESP-01` regla 13, tabla de datos de entrada |
| R9 | **El stock es el inventario central de Productos (F), no uno propio de Retail.** El POS lo descuenta directo al registrar cada venta y Retail concilia las ventas offline con Productos — M1 **no** reserva ni confirma stock para pedidos `RETAIL`. | `ESP-01` paso 5; `F1-Ciclo de vida del pedido.md`, tabla de dependencias |
| R10 | `LISTO_PARA_RECOJO` no es un valor de `pedido.estado` — es un sub-estado de Despacho (confirmación todavía pendiente de G2 — no se incluyó en `integraciones/ACUERDO_G2_DESPACHO.md`, es un hilo aparte, falta mandar la pregunta formalmente). Retail corrige el ejemplo en su documento. | Consulta, pregunta 8 |

## Pendiente de confirmar / resolver

- **G2 (Despacho) ya confirmó** que `LISTO_PARA_RECOJO` no es un estado ni sub-estado suyo (2026-10-13, Kevin) — es que el cliente eligió recoger en tienda al comprar. Esto no es un sub-estado de Despacho: es el gap de `RECOJO_TIENDA` de abajo.
- **`RECOJO_TIENDA` (click & collect) sin especificar — nunca se envió la consulta a Retail.** `ESP-01` solo tiene `envio.tipoEntrega: RECOJO_TIENDA` como valor suelto de un enum (línea 171), sin ningún camino en la máquina de estados (`ESP-03`), sin que `tiendaId` sea obligatorio para ese caso, y sin acuerdo de quién marca "listo para recoger" ni quién marca `ENTREGADO`. Preguntas pendientes de mandar: (1) ¿`tiendaId` obligatorio con `RECOJO_TIENDA`, igual que en `RETAIL`? (2) ¿quién/qué marca "listo para recoger" y notifica al cliente? (3) ¿quién marca `ENTREGADO` cuando el cliente recoge — endpoint que llama Retail, o acción del Gestor? (4) ¿corre igual el plazo de 7 días de F3 desde ese `ENTREGADO`?
- **Verificar si Retail ya actualizó su `api-contracts.md`** (§1.1, §4.3, §5.5, decisión D-04) para quitar la responsabilidad de emisión de comprobante que seguía atribuyéndonos a nosotros (R6) — pedido el 2026-10-12, nunca confirmado.
- **Aclarar la tabla de "límites de responsabilidad" de Retail** (recibida vía G2 el 2026-10-13) que atribuye a "Ventas y Postventa (G5)" la propiedad de "comprobante fiscal" — contradice R6 si se lee literal. Sin confirmar si es un error de transcripción o una contradicción real; hay que pedirles la tabla con el formato intacto antes de asumir cualquiera de las dos.

## Historial

- 2026-10-10: Se envía la consulta inicial con 8 preguntas agrupadas por tipo de resultado esperado.
- 2026-10-12: Retail responde las 8 preguntas. Se detectan dos huecos reales en el diseño (no solo de nomenclatura): el pedido nace `PAGADO` no está contemplado en `ESP-01` (que hoy exige `CREADO` sin excepción), y el stock se descuenta directo con Productos sin pasar por nuestra reserva. Se corrige `ESP-01`, `F1-Ciclo de vida del pedido.md` y `AGENTS.md` para el caso de stock (R9); se mandan 4 preguntas de detalle para el caso `PAGADO` (R3, R5, R8).
- 2026-10-12: Retail responde las 4 preguntas de detalle y señala que su propio `api-contracts.md` seguía atribuyéndonos la emisión de comprobante — se les pide corregirlo (R6, R10). Al revisar su frase "el pedido queda entregado en el mismo momento de la venta" se detecta un tercer hueco: la máquina de estados no tiene ningún camino hacia `ENTREGADO` que no pase por Despacho, lo que bloquearía F3 y F5 para pedidos `RETAIL`. Se envía una pregunta de cierre.
- 2026-10-12: Retail confirma que sí debe llegar a `ENTREGADO` y propone el diseño completo de la transición directa (R4). Se corrige `ESP-03`, `ESP-01`, `F1-Ciclo de vida del pedido.md` y `AGENTS.md`. Acuerdo cerrado.

# RNF-02: Seguridad

**Responsable:** Luis Arroyo
**Categoría:** Requisito No Funcional — Seguridad
**Estado:** En especificación
**Aplica a:** Todo el sistema (M1 — Pedidos y M2 — Postventa), con énfasis en los endpoints de F2 (Anulación)

## 1. Propósito

Garantizar que todo endpoint que modifique o exponga datos de pedidos, anulaciones, reembolsos o reclamos valide identidad (token JWT) y autorización (rol y pertenencia del recurso) antes de ejecutar cualquier operación.

## 2. Reglas de seguridad

| Regla | Descripción |
|---|---|
| Validación de token | Toda solicitud a un endpoint protegido debe incluir un `Authorization: Bearer <token>` válido, emitido por el módulo de Seguridad (G). Un token ausente, expirado o inválido responde `401 Unauthorized`. |
| Validación de rol | Las acciones administrativas (aprobar/rechazar anulaciones `EN PREPARACIÓN`, resolver expedientes, consultar el dashboard) requieren rol `GESTOR`/`ADMIN`. Un rol insuficiente responde `403 Forbidden`. |
| Validación de pertenencia del recurso | Un Cliente solo puede consultar o anular **sus propios** pedidos. Intentar operar sobre un pedido de otro cliente responde `403 Forbidden`, aunque el token sea válido. |
| Validación de origen de servicio | Endpoints invocados por sistemas internos (Canal, Despacho, pasarela de pago) exigen un token de servicio específico, distinto del token de usuario final. |

## 3. Alcance

Incluye:

- Middleware/interceptor de validación de JWT en todos los endpoints de F2 (`POST /api/v1/pedidos/{pedidoId}/anulaciones` y los internos de coordinación con F/E/F4).
- Control de acceso basado en roles (RBAC) diferenciando `CLIENTE`, `GESTOR` y `SERVICIO` (canal, despacho, pasarela).
- Verificación de que el `pedidoId` solicitado pertenece al cliente autenticado, para las operaciones que el Cliente puede iniciar directamente.
- Pruebas explícitas de los códigos `401` y `403` ante tokens ausentes/inválidos y ante roles/recursos ajenos.

**No incluye:** el mecanismo de emisión y renovación de tokens en sí (responsabilidad del módulo de Seguridad, G); cifrado de datos en tránsito/reposo a nivel de infraestructura (fuera del alcance funcional de F2).

## 4. Criterios de aceptación

#### CA-01. Rechazo por token ausente o inválido

- **DADO** una solicitud a `POST /api/v1/pedidos/{pedidoId}/anulaciones` sin header `Authorization` o con un token expirado/malformado.
- **CUANDO** se envía la solicitud.
- **ENTONCES** el sistema responde `401 Unauthorized` y no procesa la anulación.

#### CA-02. Rechazo por rol insuficiente

- **DADO** un usuario autenticado con rol `CLIENTE` que intenta aprobar/rechazar una anulación `EN PREPARACIÓN` (acción reservada al Gestor).
- **CUANDO** se envía la solicitud.
- **ENTONCES** el sistema responde `403 Forbidden` y no ejecuta la acción.

#### CA-03. Rechazo por pedido ajeno

- **DADO** un Cliente autenticado que intenta anular un pedido perteneciente a otro cliente.
- **CUANDO** se envía la solicitud con un `pedidoId` que no le pertenece.
- **ENTONCES** el sistema responde `403 Forbidden`, incluso si el token es válido y el rol es correcto.

#### CA-04. Aceptación con token y rol válidos

- **DADO** un Gestor autenticado con rol `GESTOR` y token válido.
- **CUANDO** aprueba una anulación `EN PREPARACIÓN`.
- **ENTONCES** el sistema procesa la solicitud normalmente, sin bloqueos de seguridad.

## 5. Estrategia de verificación

| Criterio | Verificación | Nivel | Evidencia esperada |
|---|---|---|---|
| CA-01 | Enviar solicitudes sin token, con token expirado y con token malformado. | Integración | `401 Unauthorized` en los tres casos. |
| CA-02 | Enviar solicitud de aprobación de anulación con un token de rol `CLIENTE`. | Integración | `403 Forbidden`. |
| CA-03 | Enviar solicitud de anulación de un `pedidoId` que no pertenece al cliente autenticado. | Integración | `403 Forbidden`. |
| CA-04 | Enviar solicitud de aprobación con token de rol `GESTOR` válido. | Integración | `200 OK` / procesamiento exitoso. |

## 6. Fuera de alcance

- Emisión, renovación y revocación de tokens JWT (módulo de Seguridad, G).
- Cifrado de datos en tránsito/reposo a nivel de infraestructura.
- Protección contra ataques de red (DDoS, rate limiting global), cubiertos a nivel de infraestructura/gateway.

## 7. Criterio de completitud

RNF-02 se considera completo cuando:

- Los criterios `CA-01` a `CA-04` están implementados y cuentan con pruebas automatizadas exitosas.
- Ningún endpoint de F2 procesa una solicitud sin validar token, rol y pertenencia del recurso.
- Existe cobertura de prueba explícita para los códigos `401` y `403` en los endpoints críticos de anulación.

# ESP-02 — Consulta y listado de pedidos

## 1. Identificación

| Campo              | Detalle                          |
| ------------------ | --------------------------------- |
| **Código**          | ESP-02                            |
| **Nombre**          | Consulta y listado de pedidos     |
| **Funcionalidad**   | F1 — Ciclo de vida del pedido     |
| **Módulo**          | M1 — Pedidos                      |
| **Responsable**     | Michael                           |
| **Tipo**            | Especificación funcional          |

---

## 2. Propósito

Definir el comportamiento para consultar el detalle completo de un pedido por identificador, y para listar los pedidos de un cliente aplicando filtros.

Esta especificación es la única puerta de lectura hacia las tablas de M1 desde canales, el Gestor y otros módulos.

---

## 3. Alcance

Esta especificación comprende:

* Consulta de un pedido por identificador, incluyendo ítems, bloques (`canal`, `cupon`, `envio`, `contacto`, `pago`), estado actual e historial.
* Listado de pedidos de un cliente, con filtro por estado.
* Control de qué actor puede consultar qué pedidos.

La modificación del estado del pedido no forma parte de esta especificación (ver **ESP-03**).

---

## 4. Actores y responsabilidades

| Actor                          | Responsabilidad                                                      |
| ------------------------------- | ------------------------------------------------------------------------ |
| **Canal (Marketplace/Chatbot/Retail)** | Consulta pedidos del cliente al que representa.                    |
| **Gestor**                      | Consulta cualquier pedido desde el panel administrativo.                |
| **M1 — Pedidos**                 | Resuelve la consulta y aplica el control de acceso correspondiente.     |

---

## 5. Precondiciones

1. El solicitante (canal o Gestor) debe estar autenticado.
2. Si el solicitante es un canal, solo puede consultar pedidos del cliente al que representa.
3. El Gestor puede consultar cualquier pedido sin restricción de cliente.

---

## 6. Disparador

```text
Canal o Gestor
   │
   ▼
Solicita detalle por pedidoId, o listado por clienteId + filtro
   │
   ▼
M1 valida permisos de acceso
   │
   ▼
Devuelve detalle o listado
```

---

## 7. Flujo funcional

### 7.1 Flujo principal — consulta por identificador

1. El canal o el Gestor solicita el detalle de un pedido por `pedidoId`.
2. El sistema valida que el solicitante tenga permiso sobre ese pedido.
3. El sistema recupera el pedido, sus ítems, bloques (`canal`, `cupon`, `envio`, `contacto`, `pago`), estado actual e historial.
4. El sistema devuelve el detalle completo.

### 7.2 Flujo principal — listado por cliente

1. Un canal solicita el listado de pedidos de un cliente, con un filtro opcional de `estado`.
2. El sistema valida que el canal represente a ese cliente.
3. El sistema recupera los pedidos que cumplen el filtro.
4. El sistema devuelve el listado.

### 7.3 Flujos alternativos

<details>
<summary><strong>A. Pedido inexistente</strong></summary>

1. El sistema busca el pedido por `pedidoId`.
2. No lo encuentra.
3. Responde `404 Not Found`.

</details>

<details>
<summary><strong>B. Canal consulta un pedido que no le pertenece</strong></summary>

1. El sistema valida el permiso del canal sobre el pedido solicitado.
2. Detecta que el pedido pertenece a otro cliente.
3. Responde `403 Forbidden`, sin exponer datos del pedido ajeno.

</details>

</details>

---

## 8. Datos

### 8.1 Parámetros de entrada

| Endpoint            | Parámetro     | Tipo        | Obligatorio | Descripción                        |
| --------------------- | --------------- | ------------ | :---------: | ------------------------------------- |
| Consulta por id        | `pedidoId`       | UUID         |      Sí     | Identificador del pedido.             |
| Listado por cliente     | `clienteId`      | Texto        |      Sí     | Cliente cuyos pedidos se listan.      |
| Listado por cliente     | `estado`         | Enumeración  |      No     | Filtro por estado del pedido.         |

### 8.2 Datos de salida (detalle)

| Campo             | Descripción                                     |
| ------------------- | -------------------------------------------------- |
| `pedidoId`           | Identificador del pedido.                            |
| `estado`             | Estado actual.                                        |
| `items`              | Ítems con precio unitario (snapshot).                 |
| `canal`, `cupon`, `envio`, `contacto`, `pago` | Bloques registrados en la creación (ver ESP-01). |
| `historialEstados`   | Lista ordenada cronológicamente (ver ESP-03).        |

---

## 9. Reglas de negocio

1. Un canal solo puede leer pedidos del cliente al que representa.
2. El Gestor puede leer cualquier pedido, sin restricción de cliente.
3. La consulta es de solo lectura; ningún endpoint de esta especificación modifica el pedido.
4. El historial devuelto debe estar siempre ordenado cronológicamente.

---

## 10. Validaciones y errores

| Validación           | Condición                                  | Respuesta esperada  |
| ----------------------- | --------------------------------------------- | ----------------------- |
| Autenticación             | Solicitante no autenticado                     | `401 Unauthorized`      |
| Autorización              | Canal consulta pedido de otro cliente          | `403 Forbidden`         |
| Pedido inexistente        | `pedidoId` no encontrado                        | `404 Not Found`         |

---

## 11. Estado y trazabilidad

Esta especificación no modifica el estado del pedido ni genera historial — solo lee los datos persistidos por ESP-01 y actualizados por ESP-03.

---

## 12. Integraciones y API

```http
GET /api/pedidos/{pedidoId}
GET /api/pedidos?clienteId={id}&estado={estado}
```

> Las rutas y estructuras definitivas deben mantenerse alineadas con `specs/api-contract.md`.

---

## 13. Criterios de aceptación

### CA-01 — Consulta exitosa por identificador

**DADO** un pedido existente.

**CUANDO** un canal o el Gestor consulta por su identificador.

**ENTONCES** el sistema retorna `200 OK` con el detalle, el estado actual y el historial completo.

---

### CA-02 — Consulta de pedido inexistente

**DADO** un identificador que no corresponde a ningún pedido.

**CUANDO** se realiza la consulta.

**ENTONCES** el sistema responde `404 Not Found`.

---

### CA-03 — Listado filtrado por cliente y estado

**DADO** un cliente con varios pedidos en distintos estados.

**CUANDO** un canal solicita el listado filtrando por `estado=ENTREGADO`.

**ENTONCES** el sistema retorna solo los pedidos de ese cliente que están `ENTREGADO`.

---

### CA-04 — Rechazo por consulta de pedido ajeno

**DADO** un canal que representa a un cliente distinto al dueño del pedido.

**CUANDO** intenta consultar ese pedido por identificador.

**ENTONCES** el sistema responde `403 Forbidden` sin exponer el detalle del pedido.

---

## 14. Trazabilidad

| Elemento                       | Referencia                                                    |
| --------------------------------- | ----------------------------------------------------------------- |
| **Funcionalidad**                 | F1 — Ciclo de vida del pedido                                       |
| **Especificación**                | ESP-02 — Consulta y listado de pedidos                              |
| **RNF relacionados**              | RNF-01 — Performance; RNF-02 — Seguridad                            |
| **Contrato API**                  | [`api-contract.md`](../api-contract.md)                            |
| **Especificación relacionada**    | ESP-01 — Creación de pedido; ESP-03 — Transiciones e historial     |

### Relación con F1

```text
F1 — Ciclo de vida del pedido
│
├── ESP-01 — Creación de pedido
├── ESP-02 — Consulta y listado de pedidos
├── ESP-03 — Transiciones de estado e historial
└── ESP-04 — Publicación de eventos
```

# Casos de prueba API — F6 Reclamos y dashboard

**Responsable:** Fabrizio  
**Estado:** Preparado para la etapa de implementación  
**Contrato de referencia:** [specs/api-contract.md](../api-contract.md)  

## 1. Uso del documento

Estas solicitudes sirven como base para pruebas manuales o de integración cuando estén disponibles los endpoints de M2. Los valores `{{baseUrl}}`, `{{tokenCliente}}` y `{{tokenGestor}}` deben reemplazarse por la configuración del entorno de prueba. No deben utilizarse datos personales reales.

## 2. Registrar un reclamo válido

**Objetivo:** comprobar la creación del expediente y el cálculo del SLA.

```http
POST {{baseUrl}}/api/v2/reclamos
Authorization: Bearer {{tokenCliente}}
Content-Type: application/json

{
  "pedidoId": "PED-PRUEBA-001",
  "tipo": "RECLAMO",
  "canal": "WEB",
  "motivo": "INCUMPLIMIENTO_PLAZO_ENTREGA",
  "detalle": "Pedido de prueba no entregado en la fecha acordada.",
  "consumidor": {
    "nombreCompleto": "Consumidor de Prueba",
    "documento": "00000000",
    "email": "pruebas@example.test",
    "telefono": "999999999"
  }
}
```

**Resultado esperado:** `201 Created`, estado `REGISTRADO`, código de seguimiento con formato `REC-YYYY-XXXX` y `fechaLimiteSLA` en UTC.

## 3. Rechazar un motivo no tipificado

**Objetivo:** comprobar que un valor fuera del catálogo no crea un expediente.

```http
POST {{baseUrl}}/api/v2/reclamos
Authorization: Bearer {{tokenCliente}}
Content-Type: application/json

{
  "tipo": "RECLAMO",
  "canal": "WEB",
  "motivo": "MOTIVO_NO_VALIDO",
  "detalle": "Caso de validación.",
  "consumidor": {
    "nombreCompleto": "Consumidor de Prueba",
    "documento": "00000000",
    "email": "pruebas@example.test",
    "telefono": "999999999"
  }
}
```

**Resultado esperado:** `400 Bad Request` y ausencia de código de seguimiento generado.

## 4. Atender un reclamo con respuesta visible

**Precondición:** reemplazar `{{reclamoId}}` por un expediente válido en atención.

```http
PATCH {{baseUrl}}/api/v2/reclamos/{{reclamoId}}/respuesta
Authorization: Bearer {{tokenGestor}}
Content-Type: application/json

{
  "nuevoEstado": "ATENDIDO",
  "respuestaVisibleCliente": "Se registró la atención de su solicitud de prueba.",
  "atendidoPor": "GESTOR-PRUEBA"
}
```

**Resultado esperado:** `200 OK`, estado `ATENDIDO`, timestamp `fechaRespuesta` en UTC y respuesta disponible para consulta.

## 5. Rechazar una atención sin respuesta

**Precondición:** reemplazar `{{reclamoId}}` por un expediente válido.

```http
PATCH {{baseUrl}}/api/v2/reclamos/{{reclamoId}}/respuesta
Authorization: Bearer {{tokenGestor}}
Content-Type: application/json

{
  "nuevoEstado": "ATENDIDO",
  "respuestaVisibleCliente": "",
  "atendidoPor": "GESTOR-PRUEBA"
}
```

**Resultado esperado:** `400 Bad Request`; el expediente no debe cambiar a `ATENDIDO`.

## 6. Consultar métricas filtradas

```http
GET {{baseUrl}}/api/v2/dashboard/metricas?desde=2026-09-01&hasta=2026-09-30&canal=MARKETPLACE
Authorization: Bearer {{tokenGestor}}
```

**Resultado esperado:** `200 OK` con métricas del periodo y canal solicitados, obtenidas desde agregados precalculados.

## 7. Evidencia a registrar

Por cada ejecución se debe guardar el identificador del caso, los valores de prueba, el código HTTP, la respuesta obtenida y la conclusión. Los tokens y datos sensibles nunca deben incluirse en capturas o repositorios.

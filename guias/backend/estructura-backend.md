# Estructura del backend - Módulo D Ventas y Postventa

Java 21, Spring Boot 3.5, Maven multimódulo. Cuatro aplicaciones que se despliegan por separado.

| Aplicación | Puerto local | Qué hace | Esquema |
|---|---|---|---|
| `api-gateway` | 8080 | Única entrada pública. Valida el JWT y reparte por recurso | — |
| `servicio-ventas` (M1) | 8081 | F1 Pedidos y F2 Anulaciones | `ventas` |
| `servicio-postventa` (M2) | 8082 | F3 Devoluciones, F4 Reembolsos, F5 CSAT, F6 Reclamos y dashboard | `postventa` |
| `simulador-pasarela` | 8083 | Simula la pasarela de pagos: cobros (avisa a M1) y extornos (los pide M2). Sin base de datos | — |

Cada funcionalidad tiene su subcarpeta `dto/` (no se muestra en el árbol). Paquetes Java cortos: `gateway`, `ventas`, `postventa` y `pasarela` (por ejemplo `package ventas.pedido;`). El `groupId` de Maven sigue siendo `pe.unmsm.ventaspostventa`.

```text
G5-Ventas-Postventas-Backend/              repositorio del backend
├── pom.xml
├── .env.example                            plantilla; cada uno crea su .env (no se sube)
├── .gitignore
├── README.md
│
├── api-gateway/
│   ├── pom.xml
│   └── src/main/
│       ├── java/gateway/
│       │   ├── ApiGatewayApplication.java
│       │   └── SecurityConfig.java
│       └── resources/application.yml
│
├── servicio-ventas/                         M1 (Michael, Luis Arroyo)
│   ├── pom.xml
│   ├── peticiones/pedidos.http              pruebas manuales de F1
│   └── src/
│       ├── main/
│       │   ├── java/ventas/
│       │   │   ├── VentasApplication.java
│       │   │   ├── compartido/
│       │   │   ├── pedido/                  F1 Michael
│       │   │   ├── anulacion/               F2 Luis Arroyo
│       │   │   └── integracion/
│       │   │       └── eventos/
│       │   └── resources/application.yml
│       └── test/java/ventas/
│           ├── ArquitecturaTest.java
│           ├── compartido/
│           ├── pedido/
│           └── anulacion/                   pruebas de F2
│
├── servicio-postventa/                      M2 (Joseph, Luis Alejandro, Johan, Fabrizio)
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── java/postventa/
│       │   │   ├── PostventaApplication.java
│       │   │   ├── compartido/
│       │   │   ├── devolucion/              F3 Joseph
│       │   │   ├── reembolso/               F4 Luis Alejandro
│       │   │   ├── calificacion/            F5 Johan
│       │   │   ├── reclamo/                 F6 Fabrizio
│       │   │   ├── dashboard/               F6 Fabrizio
│       │   │   └── integracion/             PasarelaClient (Luis Alejandro) y demás clientes
│       │   │       └── eventos/             receptor de eventos (Johan)
│       │   └── resources/application.yml
│       └── test/java/postventa/
│           ├── ArquitecturaTest.java
│           ├── compartido/
│           └── devolucion/ reembolso/ calificacion/ reclamo/
│
└── simulador-pasarela/                      Johan (sistema externo: solo HTTP, sin base de datos)
    ├── pom.xml
    └── src/
        ├── main/
        │   ├── java/pasarela/
        │   │   ├── PasarelaApplication.java
        │   │   ├── compartido/              error y transacciones en memoria
        │   │   ├── cobro/                   POST /pasarela/v1/cobros → avisa a M1 (1.2)
        │   │   │   └── dto/
        │   │   └── extorno/                 POST /pasarela/v1/extornos ← lo llama M2
        │   │       └── dto/
        │   └── resources/application.yml
        └── test/java/pasarela/
            ├── ArquitecturaTest.java
            ├── cobro/
            └── extorno/
```

## Dentro de cada funcionalidad

Todas siguen el mismo orden, de afuera hacia adentro:

```text
Controller   recibe la petición, valida el formato del DTO y llama al Service. Sin reglas de negocio.
   │
Service      reglas de negocio y transacción (@Transactional). Llama a repositorios y clientes.
   │
Repository   acceso a la tabla (Spring Data JPA).          Client   llamada a otro sistema (integracion/).
```

- Un controller nunca llama a un repository directamente.
- Un service de una funcionalidad puede llamar al service de otra del mismo microservicio (por ejemplo, `AnulacionService` llama a `MaquinaEstados`), pero nunca a sus repositorios.
- M1 y M2 nunca se importan entre sí. Se comunican por HTTP (clientes de `integracion/`) o por eventos.
- El simulador de pasarela tampoco importa M1 ni M2: avisa a M1 por la 1.2 y M2 lo llama con `PasarelaClient`.

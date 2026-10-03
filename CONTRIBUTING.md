# Guía de Contribución — Módulo D: Ventas y Postventa (G5)

Gracias por contribuir al desarrollo del **Módulo D (Ventas y Postventa)**. Para mantener la calidad, consistencia y trazabilidad de la documentación y el código, todo el equipo debe seguir los lineamientos de este documento.

---

## Tabla de contenidos

1. [Principios de desarrollo](#1-principios-de-desarrollo)
2. [Estrategia de ramas](#2-estrategia-de-ramas)
3. [Convención de mensajes de commit](#3-convención-de-mensajes-de-commit)
4. [Flujo de trabajo y Pull Requests](#4-flujo-de-trabajo-y-pull-requests)
5. [Normas para desarrollo frontend](#5-normas-para-desarrollo-frontend)
6. [Normas para desarrollo backend y APIs](#6-normas-para-desarrollo-backend-y-apis)
7. [Matriz de responsables](#7-matriz-de-responsables)

---

## 1. Principios de desarrollo

Toda contribución debe respetar las reglas de arquitectura y dominio definidas en `specs/`:

1. **Aislamiento de microservicios (RNF-07):** prohibido hacer `JOIN`s, triggers o consultas directas entre las bases de datos de M1 (`M1_VENTAS`) y M2 (`M2_POSTVENTA`). Las referencias entre ambas se manejan únicamente por `idPedido` y se comunican a través de los endpoints de [specs/api-contract.md](specs/api-contract.md), nunca por acceso directo a datos.
2. **Idempotencia financiera (RNF-08):** toda solicitud de reembolso (F4) debe enviar obligatoriamente el header `X-Idempotency-Key`.
3. **Auditoría y trazabilidad (RNF-03):** toda acción administrativa o dictamen (aprobar/rechazar devolución, anular pedido en preparación, cerrar reclamo) debe registrar actor/autorizador, motivo y marca de tiempo UTC en formato ISO-8601.
4. **Fidelidad al diseño:** el frontend debe reflejar los wireframes (`diseno/wireframes/`) y, cuando exista, el sistema de diseño en Figma, usando los componentes de **Mantine UI** (ver [specs/stack-frontend.md](specs/stack-frontend.md)).

---

## 2. Estrategia de ramas

El repositorio usa **ramas personales por integrante**, no un flujo Gitflow con `develop`:

- `main`: rama estable. Contiene solo trabajo ya revisado por el equipo.
- Cada integrante trabaja en su propia rama, nombrada con su nombre: `Michael`, `Luis-Arroyo`, `Joseph`, `Luis-Alejandro`, `Johan`, `Fabrizio`.
- **Nunca se hace commit directo a `main`.** Todo cambio llega mediante un Pull Request desde la rama personal correspondiente.
- Antes de empezar a trabajar, actualiza tu rama con lo último de `main`:

```bash
git checkout <tu-rama>
git fetch origin
git merge origin/main
```

Esto evita que tu Pull Request llegue con conflictos grandes al final.

---

## 3. Convención de mensajes de commit

Mensajes cortos, en modo imperativo, describiendo qué hace el commit:

```
<tipo>(<alcance opcional>): <descripción breve>
```

| Tipo | Uso |
|---|---|
| `feat` | Nueva funcionalidad o contenido nuevo (ej. `feat(F2): agregar criterio de anulación automática`) |
| `fix` | Corrección de un error |
| `docs` | Cambios exclusivamente de documentación/specs (ej. `docs: agregar diagrama ER`) |
| `style` | Cambios de formato sin alterar lógica ni contenido |
| `refactor` | Reorganización de código o documentos sin cambiar su comportamiento/significado |
| `test` | Adición o corrección de pruebas |
| `rename` | Renombrar un archivo |
| `delete` | Eliminar un archivo |

El alcance entre paréntesis es opcional y suele indicar la funcionalidad afectada (`F1`...`F6`) o el documento (`api-contract`, `diseno`).

---

## 4. Flujo de trabajo y Pull Requests

1. **Actualiza tu rama** con lo último de `main` (ver sección 2) antes de empezar a trabajar.
2. **Desarrolla y verifica** que tu contenido cumple los criterios de aceptación (CA) de la especificación correspondiente.
3. **Haz commit** siguiendo la convención de la sección 3.
4. **Sube tu rama:**
   ```bash
   git push origin <tu-rama>
   ```
5. **Abre un Pull Request** en GitHub hacia `main`, describiendo brevemente qué agrega o cambia.
6. **Espera revisión** de al menos un integrante del equipo antes de mergear, salvo cambios ya acordados en reunión (como specs propias ya validadas).
7. Si hay conflictos, resuélvelos en tu propia rama — nunca directamente en `main`.

---

## 5. Normas para desarrollo frontend

El frontend del portal del Gestor se construirá con **React + TypeScript + Vite + Mantine UI** (ver [specs/stack-frontend.md](specs/stack-frontend.md)). Estas normas aplican desde que arranque la implementación:

- **Tipado estricto:** no usar `any`. Definir interfaces de TypeScript para las respuestas de API, basadas en [specs/api-contract.md](specs/api-contract.md).
- **Estados de interfaz:** todo componente que haga peticiones asíncronas debe contemplar visualmente `loading`, `success`, `error` y `empty` (sin datos).
- **Confirmación de acciones irreversibles:** anular un pedido, rechazar una devolución o ejecutar un reembolso requieren un modal de confirmación previo (ver [RNF-04](specs/especificaciones/no-funcionales/RNF-04-usabilidad-interfaz.md)).
- **Estructura de directorios prevista** (se creará al iniciar la implementación, todavía no existe en el repo):
  ```text
  src/
  ├── components/    # Componentes UI reutilizables
  ├── pages/          # Pantallas completas (W01 a W08)
  ├── services/       # Llamadas a API (Axios/Fetch)
  ├── types/          # Interfaces y tipos TypeScript
  ├── hooks/          # Custom hooks de React
  └── theme/          # Tema personalizado de Mantine
  ```

---

## 6. Normas para desarrollo backend y APIs

Estas normas aplican desde que arranque la implementación del backend:

- **El contrato es la fuente de verdad:** endpoints, payloads y códigos de respuesta HTTP (`200`, `201`, `400`, `401`, `403`, `404`, `409`) deben respetar estrictamente [specs/api-contract.md](specs/api-contract.md). Cualquier cambio al contrato se discute con el equipo antes de implementarlo.
- **Validación de documentos de identidad** (según lo definido en las specs de F1/F2):
  - DNI: 8 dígitos numéricos.
  - RUC: 11 dígitos, iniciando en 10, 15, 17 o 20.
  - CE / Pasaporte: alfanumérico, sin caracteres especiales.
- **Formato estándar de error**, consistente en todos los endpoints:
  ```json
  {
    "codigo": "DOCUMENTO_INVALIDO",
    "mensaje": "Descripción del error",
    "timestamp": "2026-10-02T19:35:00Z",
    "detalles": []
  }
  ```

---

## 7. Matriz de responsables

Para dudas sobre reglas de negocio o revisión de PRs de una funcionalidad específica, contactar a:

| Funcionalidad | Responsable | Rama |
|---|---|---|
| F1 — Ciclo de vida del pedido | Michael | `Michael` |
| F2 — Anulación de pedidos | Luis Arroyo | `Luis-Arroyo` |
| F3 — Devoluciones y cambios | Joseph | `Joseph` |
| F4 — Reembolsos y extornos | Luis Alejandro | `Luis-Alejandro` |
| F5 — Calificación CSAT | Johan | `Johan` |
| F6 — Libro de Reclamaciones y Dashboard | Fabrizio | `Fabrizio` |

Si tu cambio afecta documentos compartidos por todo el módulo (`specs/api-contract.md`, `specs/modelo-datos.md`, `specs/overview.md`), avisa al equipo antes de fusionarlo a `main`.
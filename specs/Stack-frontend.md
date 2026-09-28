# Especificación de Stack Frontend — Módulo D: Ventas y Postventa

**Módulo:** D — Ventas y Postventa  
**Aplicación:** Portal del Gestor (Backoffice) y vistas de integración

---

## 1. Alcance y propósito

Este documento define el stack tecnológico, los criterios de diseño y las reglas generales de implementación del frontend del Módulo D — Ventas y Postventa.

El frontend principal corresponde a una consola interna para el Gestor o Administrador de ventas. El Cliente y el Vendedor no ingresan directamente a este panel administrativo; sus acciones se originan desde los canales Marketplace, Chatbot o Retail, según corresponda

El frontend debe permitir al Gestor:

- Consultar pedidos, estados, historial y detalle de venta (F1)
- Revisar solicitudes de anulación y autorizar únicamente los casos que lo requieran (F2)
- Evaluar devoluciones o cambios, revisar evidencia y registrar su resolución (F3)
- Consultar y ejecutar las acciones habilitadas sobre reembolsos, respetando la idempotencia (F4)
- Consultar calificaciones, comentarios e indicadores de satisfacción CSAT (F5)
- Atender reclamos, controlar su SLA, registrar la respuesta formal y consultar dashboard/reportes (F6)

Además del backoffice, algunas funcionalidades contemplan vistas de integración para el cliente, como formularios de encuesta o consulta pública de reclamos. Estas vistas no forman parte del panel administrativo y deben mantenerse separadas de las rutas `/admin/*`

---

## 2. Tecnologías principales

La implementación del frontend se realizará con el siguiente stack:

| Componente                    | Tecnología     | Uso dentro del proyecto                                                                                |
| ----------------------------- | -------------- | ------------------------------------------------------------------------------------------------------ |
| **Librería base**             | **React**      | Construcción de las vistas y componentes del módulo.                                                   |
| **Lenguaje**                  | **TypeScript** | Tipado de datos, props, respuestas de API y estructuras definidas en los contratos.                    |
| **Herramienta de desarrollo** | **Vite**       | Entorno de desarrollo y compilación del frontend.                                                      |
| **Librería de componentes**   | **Mantine**    | Base para botones, formularios, tablas, modales, alertas, badges, loaders y componentes reutilizables. |
| **Guía visual**               | **Figma**      | Fuente de referencia para identidad, paleta, tipografía, espaciado, componentes y estados visuales.    |

### 2.1. Criterio para estilos y diseño

Se utilizará **Mantine** como biblioteca principal de componentes UI. La intención no es utilizar su apariencia por defecto como diseño final, sino adaptar sus componentes al sistema visual definido por el equipo UX/UI en figma

La relación será:

`Figma / Design System → Theme de Mantine → Componentes reutilizables → Pantallas del módulo`

Por lo tanto:

- Los colores del proyecto se definirán en Figma y luego se reflejarán en el theme de Mantine
- Los tamaños de fuente, radios de borde, espaciados y jerarquías visuales seguirán la guía aprobada por UX/UI
- No se crearán estilos diferentes para cada pantalla si ya existe un componente reutilizable
- Se priorizará el uso de componentes Mantine antes de desarrollar componentes equivalentes desde cero
- El CSS adicional se utilizará solo cuando sea necesario para ajustes específicos que no se resuelvan correctamente mediante props, theme o estilos del componente

---

## 3. Sistema de diseño y componentes reutilizables

Para mantener consistencia entre las pantallas W01–W08, se trabajará con una biblioteca común de componentes

### 3.1. Elementos base

Como mínimo, el UI Kit debe contemplar:

- Botones primarios, secundarios y de acciones críticas
- Inputs de texto y búsqueda
- Selectores y filtros
- Textareas para respuestas, motivos y observaciones
- Checkboxes cuando sean necesarios
- Badges o etiquetas para estados
- Tablas con paginación
- Modales de confirmación
- Alertas y notificaciones
- Skeletons o indicadores de carga
- Estados vacíos
- Mensajes de error
- Tooltips cuando una acción necesite explicación adicional

### 3.2. Estados visuales

Los componentes reutilizables deben contemplar, como mínimo:

- `default`
- `hover`
- `focus`
- `disabled`
- `loading`
- `error`

Los componentes asociados a reglas de negocio deben representar también el estado funcional correspondiente. Por ejemplo una acción que no está permitida para el estado actual del pedido debe mostrarse deshabilitada o no presentarse como ejecutable

### 3.3. Estados de negocio

Los badges y etiquetas deben mantener una convención visual uniforme para estados como:

- Pedidos: `CREADO`, `PAGADO`, `EN PREPARACIÓN`, `DESPACHADO`, `ENTREGADO`, `ANULADO`.
- Devoluciones: `SOLICITADA`, `EN EVALUACIÓN`, `APROBADA`, `RECHAZADA`, `COMPLETADA`.
- Reclamos: `REGISTRADO`, `EN PROCESO`, `ATENDIDO` y `DERIVADO` cuando corresponda.
- Reembolsos: `PENDIENTE`, `EXITOSO` y `FALLIDO`.

La definición final de colores para cada estado se realizará en Figma y será aplicada mediante el theme del frontend

---

## 4. Estructura funcional de pantallas

El frontend del Gestor se organiza en cuatro zonas principales de navegación:

- **Dashboard**
- **Pedidos**
- **Postventa**
- **Reportes**

Estas zonas agrupan las pantallas definidas previamente en los wireframes:

- **W01:** Dashboard general
- **W02:** Bandeja de pedidos
- **W03:** Detalle del pedido
- **W04:** Anulaciones
- **W05:** Devoluciones y cambios
- **W06:** Reclamos
- **W07:** Reembolsos
- **W08:** Calificaciones y reportes

La navegación debe mantener el contexto del proceso. Por ejemplo:

- W02 permite acceder a W03
- W03 puede derivar a W04 o a procesos de postventa
- W05 puede derivar a W07 cuando corresponde devolución de dinero
- W06 puede volver al pedido cuando existe `pedidoId`
- W08 funciona como vista analítica y no modifica información transaccional

---

## 5. Conexión con APIs y contratos

La implementación del frontend debe respetar lo definido en `specs/api-contract.md`

### 5.1. Cliente HTTP

Se utilizará **Fetch o Axios**, según la decisión final de implementación del equipo, manteniendo una configuración centralizada para evitar llamadas dispersas con lógica duplicada

La capa de acceso a API debe encargarse de:

- Agregar el token de autenticación
- Interpretar códigos HTTP
- Manejar errores de red
- Mantener una estructura común de respuestas y errores
- Evitar que cada pantalla repita la misma lógica de integración

### 5.2. Seguridad

Las solicitudes protegidas deben enviar:

`Authorization: Bearer <token_jwt>`

El token y los permisos dependen del Módulo G — Seguridad y Usuarios

### 5.3. Reembolsos e idempotencia

Las operaciones de reembolso deben respetar el control idempotente definido para F4

Cuando el contrato lo requiera, se enviará la cabecera:

`X-Idempotency-Key`

El frontend debe impedir acciones repetidas mientras una operación monetaria se encuentra en proceso, pero la validación definitiva de idempotencia siempre corresponde al backend

### 5.4. Reclamos

Para F6, el frontend debe respetar los contratos definidos para:

- Registro de reclamo
- Consulta de estado
- Atención del Gestor
- Respuesta formal visible al cliente

En particular, el cierre de un reclamo no debe habilitarse si `respuestaVisibleCliente` está vacío

---

## 6. Validaciones en interfaz

Las validaciones de frontend tienen como objetivo mejorar la experiencia de uso y evitar envíos evidentemente inválidos. No sustituyen la validación del backend

Entre las principales validaciones se consideran:

- Campos obligatorios antes de enviar formularios
- Formato de documento según el tipo admitido por el contrato
- Motivo obligatorio al rechazar una devolución o registrar una anulación
- `respuestaVisibleCliente` obligatoria al cerrar un reclamo
- Puntaje de satisfacción limitado al rango de 1 a 5
- Archivos de evidencia conforme al tamaño y formatos definidos en `api-contract.md`
- Prevención de doble envío mientras una operación se encuentra en estado `loading`

Cuando una validación falle, el mensaje debe indicar de forma breve qué campo debe corregirse y evitar mensajes técnicos innecesarios para el usuario

---

## 7. Control de acceso y roles

Las rutas administrativas, bajo `/admin/*`, deben estar protegidas

El frontend debe:

- Validar la existencia del token antes de mostrar contenido administrativo
- Respetar el rol recibido desde Seguridad (G)
- Permitir acceso a funciones administrativas solo a `GESTOR` o `ADMIN`, según el contrato
- Mostrar una vista de acceso denegado cuando el usuario no tenga permisos
- No depender únicamente del frontend para proteger operaciones sensibles; el backend debe volver a validar rol y autorización

Un usuario sin permisos administrativos no debe poder acceder a las vistas del Gestor aunque conozca la URL

---

## 8. Patrones de interacción

### 8.1. Acciones irreversibles

Las operaciones con impacto relevante deben solicitar confirmación antes de enviarse, por ejemplo:

- Anular un pedido
- Aprobar o rechazar una devolución
- Ejecutar un reembolso
- Marcar un reclamo como atendido

La confirmación debe indicar claramente qué acción se realizará

### 8.2. Carga, éxito y error

Toda operación asíncrona debe contemplar:

- Estado de carga
- Confirmación visual de éxito
- Error comprensible
- Posibilidad de reintento cuando el flujo lo permita

No se debe presentar una operación como exitosa si una dependencia externa reportó error o si la respuesta del backend no lo confirma

### 8.3. Tablas y bandejas

Las bandejas administrativas deben mantener un patrón consistente:

- Filtros visibles
- Búsqueda cuando corresponda
- Estados mediante badges
- Acción principal clara
- Paginación
- Acceso al detalle en lugar de concentrar operaciones complejas dentro de la tabla

---

## 9. Responsive y usabilidad

La consola debe ser responsive y mantener una experiencia usable en resoluciones distintas

Como criterio general:

- En escritorio se prioriza la visualización completa de tablas, filtros y paneles de detalle
- En resoluciones menores, los componentes pueden reorganizarse en columnas o bloques verticales
- Los controles principales deben continuar siendo accesibles sin pérdida de funcionalidad
- Los mensajes de error y confirmación deben mantenerse visibles y comprensibles

La implementación final debe seguir los breakpoints y reglas de layout definidos por UX/UI en Figma y adaptados al sistema de layout de Mantine

---

## 10. Organización del código frontend

Para mantener el proyecto legible y facilitar el trabajo en equipo, se recomienda separar:

- **pages/**: pantallas completas del módulo
- **components/**: componentes reutilizables
- **services/**: integración con endpoints
- **types/**: interfaces y tipos TypeScript asociados a contratos
- **hooks/**: lógica reutilizable de interfaz cuando corresponda
- **theme/**: configuración visual de Mantine y tokens derivados de Figma

La estructura definitiva del repositorio puede ajustarse según lo acordado por el equipo, pero se debe evitar mezclar lógica de API, componentes visuales y tipos en un mismo archivo sin necesidad

---

## 11. Fuente de verdad y mantenimiento

Para evitar inconsistencias entre diseño, documentación e implementación:

- `specs/api-contract.md` será la referencia para endpoints, payloads y respuestas
- Los archivos de `specs/funcionalidades/` serán la referencia para reglas de negocio y criterios de aceptación
- Figma será la referencia visual para estilos, componentes y comportamiento gráfico
- Mantine será la base técnica para implementar los componentes del Design System
- Cualquier cambio que afecte contratos, estados o campos debe reflejarse en la documentación correspondiente antes de consolidarse en frontend

---

## 12. Criterio de completitud del frontend

Una pantalla se considera lista para integración cuando:

- Respeta el diseño aprobado en figma
- Utiliza los componentes reutilizables definidos por el proyecto
- Maneja estados de carga, éxito, error y vacío
- Valida los campos básicos antes de enviar
- Consume el endpoint definido en `api-contract.md`
- Respeta permisos y roles
- No expone acciones prohibidas por el estado actual
- Presenta errores comprensibles al Gestor
- Mantiene consistencia visual con el resto del Módulo D

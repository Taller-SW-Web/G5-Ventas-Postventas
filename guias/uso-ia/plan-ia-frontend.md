# Plan de uso de IA para el desarrollo frontend

## 1. Propósito

Este documento define cómo se planifica el uso responsable de IA generativa durante el desarrollo del Portal del Gestor. La IA se considera una herramienta de apoyo para convertir requisitos y mockups en tareas verificables, resolver dudas técnicas y revisar implementaciones; el equipo conserva la responsabilidad por las decisiones de producto, accesibilidad, seguridad, código y pruebas.

Las fuentes de verdad son los mockups aprobados, `specs/stack-frontend.md`, `guias/frontend/`, los contratos de API y los acuerdos del proyecto. La IA no puede reemplazar esos documentos ni crear comportamientos que no estén definidos por el equipo.

## 2. Alcance y límites

La IA puede apoyar en:

- leer una pantalla y dividirla en componentes, estados y eventos de usuario;
- proponer la estructura de tipos TypeScript a partir de un contrato confirmado;
- identificar estados de carga, vacío, error y éxito de una consulta asíncrona;
- explicar React, Mantine, Axios, Vite, accesibilidad o manejo de estado;
- preparar una lista de casos de prueba manual y de revisión visual;
- revisar un error de compilación o una respuesta HTTP sin exponer información sensible.

No se utilizará para:

- copiar una imagen de Figma como implementación o ignorar componentes existentes;
- cambiar colores, flujos, endpoints o textos de negocio sin aprobación;
- enviar tokens JWT, archivos `.env`, datos personales, URL privadas o credenciales;
- generar una pantalla completa sin revisión de la persona responsable;
- sustituir la prueba visual en navegador, `npx tsc -b`, el build ni el Pull Request.

## 3. Flujo previo a implementar una pantalla

### Paso 1. Analizar el material entregado

Antes de consultar a la IA, el responsable identifica:

1. pantalla, funcionalidad y responsable asignado;
2. mockup, variantes, modales y estados visuales;
3. endpoint, parámetros, respuesta y errores esperados;
4. componentes compartidos que deben reutilizarse;
5. interacciones: filtros, paginación, botones, navegación y confirmaciones;
6. criterios de aceptación visual y funcional.

### Paso 2. Dividir la pantalla en unidades pequeñas

La tarea se divide antes de pedir ayuda. Por ejemplo: modelo TypeScript, servicio HTTP, encabezado, filtros, tabla, detalle, modal de confirmación, estado de carga/error/vacío y prueba de integración. Esto evita consultas imprecisas y permite revisar cada cambio.

### Paso 3. Construir un prompt con contexto suficiente

El prompt debe indicar el stack y las restricciones del repositorio:

- React + TypeScript + Vite;
- Mantine UI como biblioteca base;
- cliente HTTP centralizado y tipos separados;
- mockup y contrato como fuentes de verdad;
- sin credenciales ni datos del `.env`;
- resultado solicitado: plan, pseudocódigo, tipos, casos de prueba o revisión puntual.

### Paso 4. Revisar y adaptar la propuesta

La persona responsable verifica que la propuesta:

- reutilice los componentes y servicios existentes;
- respete nombres de parámetros, DTOs, códigos de error y paginación del contrato;
- implemente carga, éxito, vacío y error;
- mantenga accesibilidad básica: etiquetas, nombres de botones y estados comprensibles;
- preserve el diseño aprobado sin añadir elementos no solicitados.

### Paso 5. Implementar, probar y registrar

El código se adapta al proyecto, se ejecuta `npx tsc -b` y se prueba en navegador contra mocks o backend local. La revisión incluye filtros combinados, paginación, errores de red, datos vacíos y variantes de estado. Finalmente se revisa el diff, se hace commit y se abre Pull Request.

## 4. Plantilla de prompt para frontend

```text
Actúa como asistente de planificación y revisión, no como fuente de verdad.
Estoy implementando una pantalla del Portal del Gestor.

Stack: React, TypeScript, Vite, Mantine UI y Axios.
Pantalla/funcionalidad: [nombre].
Mockup y comportamiento esperado: [describir o adjuntar la parte relevante].
Contrato confirmado: [endpoint, parámetros y respuesta resumida].
Componentes/servicios existentes: [rutas o nombres].
Restricciones: reutilizar el cliente HTTP y tipos existentes; no incluir secretos;
mantener estados loading/success/empty/error; no inventar endpoints.

Necesito: [descomposición / propuesta de tipos / casos de prueba / diagnóstico].
Devuelve pasos pequeños, riesgos o datos faltantes y criterios de verificación.
Si falta una decisión, indícala en vez de asumirla.
```

## 5. Ejemplo de planificación: F4 Reembolsos

### Contexto entregado a la IA

```text
Pantalla: bandeja de reembolsos del Gestor.
Contrato: GET paginado con filtros de estado, origen, búsqueda, fecha y orden;
GET de detalle al pulsar "Ver"; POST idempotente para ejecutar o reintentar.
Diseño: tabla, filtros, panel lateral de detalle, historial y modales de
autorización/ejecución.
Reglas: cliente muestra — en la lista; cliente/canal/método de pago solo se
consultan en el detalle; la autorización es visual y el reintento conserva la
misma clave idempotente.
Necesito una lista de unidades de implementación y pruebas manuales.
```

### Resultado esperado de la consulta

Una respuesta útil debe proponer, como mínimo:

1. definir tipos de listado, detalle, intentos y filtros;
2. crear o extender el servicio HTTP centralizado;
3. obtener el listado paginado y manejar carga, error, vacío y éxito;
4. cargar el detalle solo al seleccionar una fila;
5. separar confirmación visual de autorización y envío real del reintento;
6. refrescar listado/detalle luego de una operación;
7. probar filtros, paginación, detalle, respuesta vacía y error del servidor.

La persona responsable compara esta lista con el mockup y los contratos antes de escribir código. La IA no decide el diseño ni el significado de los estados.

## 6. Ejemplo de consulta de diagnóstico

```text
Contexto: React + Axios consume un endpoint local de Postventa.
La UI muestra "No se pudo cargar la información" y la respuesta HTTP es 500.
El backend reporta "permiso denegado al esquema postventa".
¿Cómo distinguir si el problema está en CORS, la URL, el backend o permisos de
base de datos? Propón un orden de verificación seguro sin pedir credenciales ni
desactivar seguridad.
```

El equipo verifica la respuesta con el log del backend y la configuración local autorizada. No se considera correcto ocultar el error en la interfaz ni cambiar datos sensibles para que la pantalla parezca funcionar.

## 7. Lista de verificación antes del Pull Request

- [ ] La implementación se basa en un mockup y contrato identificables.
- [ ] Los componentes y el cliente HTTP compartidos se reutilizan cuando corresponde.
- [ ] No se suben `.env`, tokens, contraseñas ni datos personales.
- [ ] La pantalla maneja carga, éxito, vacío y error.
- [ ] Se validó TypeScript y se realizó una prueba manual proporcional al cambio.
- [ ] El PR describe la funcionalidad, pruebas y limitaciones conocidas.

## 8. Trazabilidad

Las consultas de IA sirven como apoyo de análisis. La evidencia técnica del proyecto se mantiene en las specs, acuerdos, commits, pruebas y Pull Requests. Así el equipo puede explicar qué decidió, por qué lo decidió y cómo lo verificó, sin depender de una respuesta no revisada de una herramienta.

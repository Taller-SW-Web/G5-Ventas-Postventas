# Plan de uso de IA para el desarrollo backend

## 1. Propósito

Este documento define el uso planificado de herramientas de IA generativa como apoyo al desarrollo del backend del Módulo D — Ventas y Postventa. Su objetivo es que el equipo trabaje con un criterio común antes de escribir código: la IA puede ayudar a analizar, proponer alternativas, explicar errores y revisar una solución, pero no sustituye las decisiones del equipo ni la validación técnica.

La fuente de verdad es la documentación del proyecto: contratos en `specs/api/`, reglas de negocio en `specs/especificaciones/funcionales/`, modelo de datos, acuerdos de integración y `guias/backend/`. Si una respuesta de IA contradice esas fuentes, se descarta o se corrige; nunca se cambia una regla del dominio solo porque la IA la sugiera.

## 2. Alcance y límites

La IA se planifica como apoyo para:

- descomponer una funcionalidad en tareas pequeñas y verificables;
- identificar DTOs, validaciones, entidades, dependencias y pruebas necesarias;
- explicar conceptos de Spring Boot, JPA, transacciones, HTTP, JWT o pruebas;
- proponer borradores de pseudocódigo, casos de prueba y listas de revisión;
- diagnosticar errores a partir de mensajes de compilación, pruebas o logs ya revisados por una persona.

No se usará para:

- inventar endpoints, estados, permisos, tablas o integraciones que no estén acordados;
- subir secretos, tokens, contraseñas, datos personales o accesos a servicios externos;
- aceptar código generado sin leerlo, adaptarlo al proyecto y probarlo;
- reemplazar la revisión de pares, las pruebas automatizadas ni las decisiones del responsable de la funcionalidad.

## 3. Flujo previo a implementar una funcionalidad

### Paso 1. Delimitar la funcionalidad

Antes de consultar a la IA, el responsable revisa y anota:

1. la funcionalidad asignada y sus criterios de aceptación;
2. las reglas de negocio y estados permitidos;
3. los endpoints, DTOs y errores contractuales relacionados;
4. las entidades/tablas que pertenecen al microservicio;
5. las integraciones externas, scopes y eventos involucrados;
6. las pruebas que demostrarán que el cambio está terminado.

El resultado es una lista de tareas pequeñas. Por ejemplo: "validar solicitud", "persistir operación", "llamar adaptador externo", "registrar auditoría", "manejar idempotencia" y "probar éxito, fallo y reintento".

### Paso 2. Preparar el contexto mínimo

La consulta incluye únicamente el contexto necesario y verificable: extractos del contrato, nombres de clases existentes, la regla concreta y la pregunta técnica. No se pega todo el repositorio ni archivos `.env`.

Antes de preguntar, se indica explícitamente:

- lenguaje y stack: Java, Spring Boot, JPA, PostgreSQL, Maven y JUnit/Mockito;
- módulo y límite de datos: M1 (`ventas`) o M2 (`postventa`), sin joins cruzados;
- qué regla o contrato no puede modificarse;
- formato esperado de respuesta: explicación, pseudocódigo, casos de prueba o revisión, según corresponda.

### Paso 3. Consultar por una decisión acotada

Una consulta se limita a una necesidad. Se prefieren preguntas que pidan razonamiento y alternativas antes que "genera toda la funcionalidad". Ejemplos válidos: cómo asegurar idempotencia, qué pruebas cubren una transición de estado, o cómo evitar una carga perezosa fuera de transacción.

### Paso 4. Revisar la propuesta

El responsable contrasta la respuesta contra las fuentes de verdad y revisa:

- que respete nombres, estados, códigos de error y contratos existentes;
- que no agregue tablas, endpoints o permisos no aprobados;
- que mantenga la separación M1/M2 y los adaptadores de `integracion/`;
- que gestione errores, transacciones y concurrencia de acuerdo con la guía;
- que incluya pruebas relevantes y no solo el camino exitoso.

Si una propuesta no cumple, se descarta, se reduce el alcance de la pregunta o se consulta al equipo.

### Paso 5. Implementar y verificar

La persona responsable adapta la solución al código real. Luego ejecuta las verificaciones acordadas, como `mvn clean package`, pruebas unitarias y, si aplica, pruebas de integración con PostgreSQL o los simuladores locales. El código se revisa mediante diff y Pull Request antes de fusionarse.

## 4. Plantilla de prompt para backend

```text
Actúa como asistente técnico, no como fuente de verdad. Estoy planificando una tarea
del backend del Módulo D de ventas y postventa.

Stack: Java, Spring Boot, JPA, PostgreSQL, Maven y JUnit/Mockito.
Servicio: [M1 Ventas / M2 Postventa].
Contrato o regla vigente: [pegar extracto corto y verificable].
Código existente relevante: [clase/interfaz y comportamiento actual].
Restricciones: [por ejemplo, no modificar el contrato, no crear tablas nuevas,
no hacer joins entre esquemas, mantener idempotencia].

Necesito: [análisis / pseudocódigo / casos de prueba / revisión de error].
Devuelve:
1. pasos propuestos;
2. riesgos o supuestos que debo confirmar;
3. pruebas de éxito, error y borde.
No inventes requisitos; marca explícitamente cualquier dato faltante.
```

## 5. Ejemplo de planificación: F4 Reembolsos

### Contexto entregado a la IA

```text
Servicio: M2 Postventa.
Regla: cada solicitud de reembolso usa X-Idempotency-Key; la misma clave debe
devolver la operación existente y una clave reutilizada con datos distintos debe
producir conflicto. El reembolso solo actualiza el dashboard cuando es EXITOSO.
La pasarela se consume por un cliente de integración; no se accede a su base.
Necesito una lista de pruebas unitarias para procesar, repetir y reintentar un
reembolso sin cambiar estas reglas.
```

### Resultado esperado de la consulta

La IA puede proponer escenarios, no decidir el contrato:

1. creación exitosa con registro de intento y actualización de proyección;
2. repetición de una clave exitosa sin una nueva llamada a pasarela;
3. misma clave con monto u origen distintos y respuesta de conflicto;
4. resultado `PENDIENTE` o `FALLIDO` sin actualización de proyección;
5. reintento con la misma clave y conservación del expediente.

### Validación humana previa al código

El responsable comprueba que estos escenarios coincidan con `api-postventas.md`, la guía de backend y la entidad `Reembolso`. Después implementa las pruebas y valida el resultado con Maven. La respuesta de la IA es solo una lista inicial; los nombres finales, códigos de error y la transacción se toman del proyecto.

## 6. Criterio para prompts de diagnóstico

Cuando una prueba o servicio falla, primero se reproduce el error y se comparte únicamente información no sensible:

```text
Contexto: Spring Boot + JPA. El endpoint de listado devuelve 500.
Error raíz: "permiso denegado al esquema postventa".
Configuración sensible omitida.
¿Qué hipótesis se deben comprobar y qué permisos mínimos necesita el usuario de
desarrollo para leer/escribir las tablas y secuencias del esquema?
No propongas desactivar validaciones ni usar credenciales de producción.
```

La respuesta se trata como hipótesis. Los cambios de base de datos se confirman en la documentación y se prueban solo en el entorno local autorizado.

## 7. Evidencia de calidad y trazabilidad

Para cada tarea se conserva, cuando corresponda:

- enlace a la spec, contrato o acuerdo que originó la tarea;
- decisiones tomadas por el equipo y supuestos confirmados;
- pruebas ejecutadas y resultado;
- diff, commit y Pull Request de la implementación.

Esto permite explicar el razonamiento del equipo sin atribuir decisiones técnicas a una herramienta ni ocultar su uso como apoyo.
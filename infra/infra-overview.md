# Infraestructura y Despliegue — Módulo D

Esta carpeta centralizará la documentación técnica, guías de aprovisionamiento y configuraciones de entorno para la ejecución del módulo en local y producción.

## Documentos incluidos

- **`base-de-datos-supabase.md`**: Aprovisionamiento de las bases de datos en la nube (PostgreSQL en Supabase), esquemas aislados para M1 y M2, credenciales y políticas de acceso.
- **`backend-microservicios.md`**: Despliegue de los servicios backend (M1 Ventas y M2 Postventa), variables de entorno, puertos y empaquetado en contenedores Docker.
- **`frontend-portal.md`**: Despliegue de la aplicación web del Gestor (Backoffice), configuración de build y conexión con los endpoints de los microservicios.
- **`variables-entorno.md`**: Plantilla de variables (`.env.example`), secrets compartidos y configuración de tokens JWT/OAuth2 para comunicación entre módulos.
- **`redes-y-seguridad.md`**: Mapeo de puertos, configuración de CORS, reglas de firewall y políticas de red para la integración con los demás módulos (Despacho, Pagos y Canales).

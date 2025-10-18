# Changelog

Todas las modificaciones importantes de este proyecto serán documentadas aquí.

## [1.0.0] - 2025-10-01

### Agregado

- Sistema completo de correo multi-dominio con Docker Compose
- 2 servidores MTA independientes (docker-mailserver)
- 2 clientes webmail (Roundcube)
- Servidor VPN WireGuard integrado
- Enrutamiento automático entre dominios
- Scripts de despliegue automatizado (Linux/Windows)
- Documentación completa en README.md

### Corregido

- **Error "queue file write error"**: Resuelto usando volúmenes Docker nombrados en lugar de bind mounts
- **Problemas de autenticación SSL**: Configuración TLS corregida (`ssl://` → `tls://`)
- **Correos no llegan entre dominios**: Sistema de transporte y relay configurado
- **Problemas de permisos en Windows**: Volúmenes Docker manejados internamente

### Configuración

- Servicios no esenciales deshabilitados (OpenDKIM, OpenDMARC, Amavis, etc.)
- Configuración de redes de confianza para relay interno
- Puertos externos específicos para cada MTA
- Variables de entorno optimizadas para estabilidad

### Seguridad

- Contraseñas por defecto para demo (se recomienda cambiar en producción)
- Configuración SSL/TLS para comunicaciones seguras
- Restricciones de relay configuradas correctamente

### Rendimiento

- Timeouts de cola optimizados
- Gestión mejorada de memoria y archivos temporales
- Configuración simplificada para reducir overhead

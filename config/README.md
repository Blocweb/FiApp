# Configuración

Archivos de configuración compartidos entre el frontend (Flutter) y el backend (ASP.NET Core).

| Archivo | Descripción |
|---------|-------------|
| `.env.example` | Plantilla de variables de entorno (URL API, timeouts, flags) |

## Buenas prácticas

- No subas archivos `.env` con secretos reales.
- Mantén valores por defecto seguros para desarrollo local.
- En producción, usa variables del sistema o un gestor de secretos.

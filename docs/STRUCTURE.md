# Estructura del monorepo FiApp

## Organización general

| Ruta | Responsabilidad |
|------|-----------------|
| `frontend/` | App Flutter: UI, estado, cliente HTTP |
| `frontend/lib/core/config/` | Configuración de la app |
| `frontend/lib/core/network/` | Cliente API (Dio) |
| `frontend/lib/features/*/presentation/` | Parte visual (pantallas, widgets) |
| `frontend/lib/features/*/data/` | Modelos y repositorios (capa hacia API) |
| `frontend/assets/images/` | Imágenes y logo |
| `frontend/assets/fonts/` | Fuentes |
| `frontend/test/` | Pruebas unitarias y de widgets |
| `backend/` | API ASP.NET Core (scaffold) |
| `config/` | Plantillas de entorno compartidas |
| `docs/` | Documentación técnica |
| `.github/workflows/` | CI (analyze + test) |

## Capas por feature (frontend)

```
features/<modulo>/
├── data/
│   ├── models/          # DTOs fromJson/toJson
│   ├── datasources/     # Remotos futuros
│   └── repositories/    # Mock hoy / remoto mañana
├── domain/
│   ├── entities/
│   └── repositories/    # Contratos
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/
```

## Buenas prácticas

- Separación frontend / backend / config en carpetas de primer nivel
- Clean Architecture en Flutter
- Sin secretos en el repositorio (usar `config/.env.example`)
- Ramas `main` + `develop` + convenciones feature/fix
- CI en cada push/PR a `main` y `develop`

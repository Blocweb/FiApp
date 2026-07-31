# FiApp — Fiados bajo control

Monorepo profesional para gestionar fiados y abonos de tienda.

| Capa | Ubicación | Tecnología |
|------|-----------|------------|
| **Frontend** (UI móvil) | [`frontend/`](frontend/) | Flutter 3 / Dart 3 |
| **Backend** (APIs) | [`backend/`](backend/) | ASP.NET Core (scaffold) |
| **Configuración** | [`config/`](config/) | Variables de entorno |
| **Imágenes / fuentes** | [`frontend/assets/`](frontend/assets/) | PNG, TTF |
| **Documentación** | [`docs/`](docs/) | Guías técnicas |
| **CI** | [`.github/workflows/`](.github/workflows/) | GitHub Actions |

## Estructura del repositorio

```
FiApp/
├── frontend/                 # App Flutter (parte visual + cliente API)
│   ├── lib/
│   │   ├── core/             # config, network, theme, widgets, router
│   │   └── features/         # auth, home, clients, fiados, abonos, …
│   ├── assets/images/        # Logo e imágenes
│   ├── assets/fonts/         # Tipografías
│   └── test/                 # Pruebas unitarias y de widgets
├── backend/                  # API REST ASP.NET Core (en preparación)
│   ├── src/FiApp.Api/
│   └── tests/
├── config/                   # Plantillas de entorno (.env.example)
├── docs/                     # Documentación
└── .github/workflows/        # Integración continua
```

## Inicio rápido (frontend)

```bash
cd frontend
flutter pub get
flutter test
flutter run
```

## Ramas

| Rama | Uso |
|------|-----|
| `main` | Estable / listo para release |
| `develop` | Integración continua de features |
| `feature/*` | Nuevas funcionalidades |
| `fix/*` | Correcciones |
| `release/*` | Preparación de versiones |

Ver [`docs/BRANCHING.md`](docs/BRANCHING.md).

## Arquitectura frontend

Clean Architecture por módulo (`presentation` / `domain` / `data`).
Hoy los repositorios son **mock**; al conectar el backend solo se cambian
las implementaciones en `data/` y los providers.

## Licencia / equipo

Proyecto **Blocweb** — [github.com/Blocweb/FiApp](https://github.com/Blocweb/FiApp)

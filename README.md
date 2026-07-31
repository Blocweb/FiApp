# FiApp — Fiados bajo control

Apk para llevar control sobre deudas/fiados en tu negocio.

Monorepo profesional para gestionar fiados y abonos de tienda.

| Capa | Ubicación | Tecnología |
|------|-----------|------------|
| **Frontend** (UI móvil) | [`frontend/`](frontend/) | Flutter 3 / Dart 3 |
| **Backend** (APIs) | [`backend/`](backend/) | FastApi (Python/Pydactic) |
| **Configuración** | [`config/`](config/) | Variables de entorno |
| **Imágenes / fuentes** | [`frontend/assets/`](frontend/assets/) | PNG, TTF |
| **Documentación** | [`docs/`](docs/) | Guías técnicas |
| **CI** | [`.github/workflows/`](.github/workflows/) | GitHub Actions |

## Estructura del repositorio

```text
FiApp/
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   └── features/
│   ├── assets/images/
│   ├── assets/fonts/
│   └── test/
├── backend/
│   ├── src/FiApp.Api/
│   └── tests/
├── config/
├── docs/
└── .github/workflows/
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
| `develop` | Integración continua |
| `feature/*` | Nuevas funcionalidades |
| `fix/*` | Correcciones |
| `release/*` | Versiones |

Ver `docs/BRANCHING.md`.

## Arquitectura

Clean Architecture por módulos.

## Licencia

Proyecto Blocweb.

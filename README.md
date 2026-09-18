# FiApp — Fiados bajo control

Apk para llevar control sobre deudas/fiados en tu negocio.

Monorepo profesional para gestionar fiados y abonos de tienda.

| Capa | Ubicación | Tecnología |
|------|-----------|------------|
| **Frontend** (UI móvil) | [`frontend/`](frontend/) | Flutter 3 / Dart 3 |
| **Backend** (APIs) | [`backend/`](backend/) | FastAPI + SQLAlchemy async |
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
│   ├── src/app/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
├── config/
├── docs/
└── .github/workflows/
```

## Inicio rápido

```bash
cd frontend
flutter pub get
flutter test
flutter run -d emulator-5554
```

El backend debe estar disponible en `http://10.0.2.2:8000` desde el emulador.

```bash
cd backend
python -m uvicorn main:app --reload
```

Para levantar el backend en Docker, copia `backend/.env.example` a
`backend/.env`, completa sus valores fuera de Git y ejecuta:

```bash
docker compose up --build
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

Flutter usa Clean Architecture parcial por feature: UI/providers, entidades y
repositories, con Dio como cliente HTTP y Supabase para autenticación. FastAPI
se organiza como Router -> Service -> SQLAlchemy async -> Supabase PostgreSQL.

## Licencia

Proyecto Blocweb.
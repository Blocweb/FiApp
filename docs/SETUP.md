# Configuración y setup

## Requisitos

- Flutter SDK 3.24+ (probado con 3.35)
- Dart SDK 3.6+
- Android Studio / VS Code con extensión Flutter
- Python 3.12+
- Docker Desktop (opcional, para ejecutar el backend en contenedor)

## Frontend

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run
```

### Variables de entorno (dart-define)

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=API_URL=http://10.0.2.2:8000 \
  --dart-define=APP_ENV=development
```

En Android Emulator, `10.0.2.2` representa el `localhost` del equipo host.
Las plantillas son [`frontend/.env.example`](../frontend/.env.example) y
[`backend/.env.example`](../backend/.env.example).

## Backend

```bash
cd backend
python -m pip install -r requirements-dev.txt
python -m uvicorn main:app --reload
python -m pytest -q
```

Swagger: `http://127.0.0.1:8000/docs`.

## Docker

Supabase sigue siendo la base de datos externa; Compose solo ejecuta FastAPI.

```bash
docker compose up --build
```

## CI

GitHub Actions ejecuta analyze/tests de Flutter y compile/tests de FastAPI en ramas
`main` y `develop`.

# Configuración y setup

## Requisitos

- Flutter SDK 3.24+ (probado con 3.35)
- Dart SDK 3.6+
- Android Studio / VS Code con extensión Flutter
- (Opcional) .NET 8 SDK cuando se implemente el backend

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
  --dart-define=API_BASE_URL=https://localhost:5001/api \
  --dart-define=APP_ENV=development \
  --dart-define=USE_MOCK_REPOSITORIES=true
```

Plantilla completa: [`config/.env.example`](../config/.env.example).

## Backend (cuando exista)

```bash
cd backend
dotnet restore
dotnet build
dotnet test
dotnet run --project src/FiApp.Api
```

## CI

GitHub Actions ejecuta analyze + test del frontend en ramas `main` y `develop`.

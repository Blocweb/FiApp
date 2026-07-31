# Backend y APIs

Scaffold en [`backend/`](../backend/). Cliente HTTP en
[`frontend/lib/core/network/`](../frontend/lib/core/network/).

## Objetivo

- API REST en ASP.NET Core
- Contratos JSON alineados con modelos Dart (`camelCase`)
- Sustituir mocks por repositorios remotos sin tocar la UI

## Capas previstas

```
backend/src/FiApp.Api/
├── Controllers/
├── Models/
├── Services/
└── Data/
```

## Integración con Flutter

1. Definir `API_BASE_URL` (`config/.env.example` / `--dart-define`)
2. Implementar `XxxRepositoryRemoteImpl` con `ApiClient.instance.dio`
3. Cambiar el provider en `repository_providers.dart`
4. Poner `USE_MOCK_REPOSITORIES=false`

## Próximos pasos

1. Crear solución `dotnet new webapi`
2. Auth JWT + endpoints de clientes / fiados / abonos
3. Pruebas en `backend/tests/FiApp.Api.Tests`
4. Documentar OpenAPI/Swagger

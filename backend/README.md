# Backend — FiApp API (ASP.NET Core)

API REST futura en **C# / ASP.NET Core** consumida por la app Flutter (`frontend/`).

## Estado actual

Scaffold profesional listo. Aún no hay proyecto `.csproj` compilable; la estructura
define dónde vivirá cada capa cuando se cree la solución.

## Estructura prevista

```
backend/
├── src/
│   └── FiApp.Api/
│       ├── Controllers/     # Endpoints REST
│       ├── Models/          # DTOs / request-response
│       ├── Services/        # Lógica de negocio
│       └── Data/            # DbContext, repositorios EF Core
└── tests/
    └── FiApp.Api.Tests/     # Pruebas de API e integración
```

## Endpoints previstos (alineados al frontend)

| Recurso | Métodos | Descripción |
|---------|---------|-------------|
| `/api/auth` | POST login, register, forgot-password | Autenticación JWT |
| `/api/clients` | GET, POST, PUT, DELETE | Clientes |
| `/api/fiados` | GET, POST | Registro de fiados |
| `/api/abonos` | GET, POST | Registro de abonos |
| `/api/transactions` | GET | Historial de movimientos |

## Contrato JSON

Los modelos Dart en `frontend/lib/features/*/data/models/` ya usan **camelCase**
y tipos primitivos compatibles con System.Text.Json de ASP.NET Core.

## Próximos pasos

1. `dotnet new webapi -n FiApp.Api -o src/FiApp.Api`
2. Añadir autenticación JWT y EF Core
3. Implementar controladores según la tabla anterior
4. Actualizar `API_BASE_URL` en `config/.env`
5. Sustituir repositorios mock del Flutter por implementaciones remotas

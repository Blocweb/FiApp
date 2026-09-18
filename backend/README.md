# Backend — FiApp API (FastAPI)

API REST de FiApp consumida por Flutter y conectada a Supabase PostgreSQL mediante
SQLAlchemy async.

## Estructura

```
backend/
├── src/app/
│   ├── routers/             # Endpoints REST
│   ├── schemas/             # DTOs Pydantic
│   ├── services/            # Lógica de negocio
│   ├── models/              # Modelos SQLAlchemy
│   └── database/            # Conexión y esquema SQL
├── tests/                   # Tests Pytest
├── Dockerfile
└── requirements.txt
```

## Endpoints principales

| Recurso | Métodos | Descripción |
|---------|---------|-------------|
| `/clientes/` | GET, POST, GET/PUT por id | Clientes |
| `/transacciones/` | GET, POST fiado, POST abono | Movimientos |
| `/perfil/` | GET, PUT | Perfil del negocio |
| `/reportes/*` | GET | Resúmenes |
| `/health` | GET | Estado de base de datos |

## Ejecución local

```bash
python -m pip install -r requirements-dev.txt
python -m uvicorn main:app --reload
python -m pytest -q
```

La documentación OpenAPI queda disponible en `/docs`. Las variables sensibles se
inyectan mediante `backend/.env`; usa `backend/.env.example` como plantilla.

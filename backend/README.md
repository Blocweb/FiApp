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
│   ├── dependencies/        # Dependencias FastAPI (resolución de tenant)
│   ├── core/                # Configuración y contexto (tenant_context)
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
| `/tenants/` | GET | Negocios del usuario (membresías activas) |
| `/tenants/current` | GET | Contexto del tenant seleccionado |
| `/health` | GET | Estado de base de datos |

## Multi-tenant: resolución centralizada del tenant (Tarea 3.1)

La resolución del tenant activo es única y reutilizable, no una implementación
por router:

```
Supabase Auth -> JWT validado -> profile -> tenant solicitado (X-Tenant-ID)
              -> membresía activa en tenant_usuarios -> rol
```

- **`X-Tenant-ID: <uuid>`** es obligatorio en los endpoints que requieren
  contexto de tenant (por ejemplo `/tenants/current`). Es **solo un selector**:
  nunca se acepta como prueba de autorización.
- El backend comprueba la **membresía real en la base de datos**. No hay fallback
  al primer tenant del usuario, no se autoriza con un `tenant_id` del cuerpo y
  no se guarda el tenant activo en estado global del servidor.
- El rol efectivo proviene **exclusivamente de `tenant_usuarios.rol`**.
  `profiles.rol` es un campo heredado y **no** se usa para autorizar tenants.
- En esta fase **solo `estado = 'activo'`** permite operar. `suspendido`, `mora`
  y `cancelado` se rechazan con 403.

Dependencia reutilizable: `get_current_tenant_context()` en
`src/app/dependencies/tenant.py`, que devuelve un `TenantContext` tipado
(`src/app/core/tenant_context.py`) con usuario, profile, tenant, membresía y rol.

### Contrato de errores
| Caso | Código |
|------|--------|
| Bearer ausente o inválido | `401` |
| Perfil inexistente | `401` |
| `X-Tenant-ID` ausente | `400` (`code: "tenant_required"`) |
| `X-Tenant-ID` no es UUID | `422` |
| Tenant inexistente, ajeno, no operativo o con membresía inactiva | `403` (misma respuesta genérica) |

La respuesta 403 es idéntica para tenant ajeno e inexistente, de modo que no se
puede deducir la existencia de tenants de otros usuarios.

### Alcance de esta fase
`/tenants/` y `/tenants/current` exponen la resolución del tenant. Los routers
financieros (`clientes`, `transacciones`, `reportes`) **aún no están migrados** a
`tenant_id` ni RLS: eso pertenece a tareas posteriores. `get_current_profile()`
conserva su firma y los routers existentes siguen funcionando sin cambios.

## Ejecución local

```bash
python -m pip install -r requirements-dev.txt
python -m uvicorn main:app --reload
python -m pytest -q
```

La documentación OpenAPI queda disponible en `/docs`. Las variables sensibles se
inyectan mediante `backend/.env`; usa `backend/.env.example` como plantilla.

## Ejecutar en Windows (entorno `.venv312`)

```powershell
.\.venv312\Scripts\Activate.ps1
python --version
# 0.0.0.0 permite que el emulador Android llegue a la API en http://10.0.2.2:8000
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

# Backend y APIs

API REST en [`backend/`](../backend/) con **FastAPI + SQLAlchemy async** sobre
**PostgreSQL en Supabase**. La app Flutter la consume con Dio desde
[`frontend/lib/core/network/`](../frontend/lib/core/network/).

## Capas

```
backend/src/app/
├── routers/        # Endpoints REST (validan rol y llaman servicios)
├── services/       # Lógica de negocio y consultas SQLAlchemy
├── schemas/        # Contratos Pydantic (alias camelCase para Flutter)
├── models/         # Tablas SQLAlchemy
├── dependencies/   # Resolución del negocio (tenant) por petición
├── core/           # Configuración, permisos por rol, contexto RLS
└── database/       # Conexión, esquema base y migraciones SQL
```

## Autenticación, negocio y roles

1. La app inicia sesión con **Supabase Auth** y envía el token como `Bearer`.
2. La API valida el token con Supabase y carga el `profile`.
3. `get_current_tenant_context` resuelve el negocio (`X-Tenant-ID` opcional
   si el usuario tiene un solo negocio) y la membresía activa en
   `tenant_usuarios`. Un usuario recién registrado sin membresías recibe su
   negocio propio como `propietario`; una membresía **inactiva** responde 403.
4. `core/permissions.py` aplica el control por rol (HU01 · T05). El backend
   se conecta con un rol que ignora RLS, por eso las reglas viven en la API.

| Rol en la base | Rol en el backlog | Puede |
|---|---|---|
| `propietario` | Administrador | Todo; único que crea o modifica administradores |
| `administrador` | Administrador | Todo; crea y desactiva trabajadores |
| `supervisor` | — | Consultar todo el negocio y reportes |
| `cobrador` | Trabajador | Registrar clientes y movimientos; solo ve sus propios movimientos en el historial |

## Endpoints

| Método | Ruta | Uso | Rol |
|---|---|---|---|
| GET | `/tenants/`, `/tenants/current` | Negocios del usuario y rol actual | Todos |
| GET / POST | `/usuarios/` | Listar / crear cuenta de trabajador (Supabase Admin API) | Propietario, administrador |
| PATCH | `/usuarios/{id}` | Activar, desactivar o cambiar rol | Propietario, administrador |
| GET | `/clientes/?q=` | Listar y buscar por nombre o identificación | Todos |
| POST / PUT | `/clientes/`, `/clientes/{id}` | Crear / editar; 409 `cliente_duplicado` si la identificación ya existe | Todos |
| DELETE | `/clientes/{id}` | Borrado lógico (sin saldo pendiente) | Propietario, administrador |
| GET | `/transacciones/` | Historial (el trabajador solo ve lo suyo) | Todos |
| GET | `/transacciones/cliente/{id}` | Historial completo de un cliente | Todos |
| POST | `/transacciones/fiado` | Venta a crédito con fecha, productos y quién vendió | Todos |
| POST | `/transacciones/abono` | Abono | Todos |
| GET | `/reportes/resumen`, `/reportes/evolucion` | Reportes del negocio | Propietario, administrador, supervisor |
| GET / PUT | `/perfil/` | Perfil propio (incluye `nombre`) | Todos |

El saldo del cliente y `saldo_posterior` los calculan los triggers de
PostgreSQL (`fn_calcular_saldo_posterior`, `fn_actualizar_cliente_tras_transaccion`).

## Migraciones

Los scripts de [`database/migrations/`](../backend/src/app/database/migrations/)
se aplican en orden sobre el esquema base `fiapp_supabase_schema.sql`.
`006_sprint1_usuarios_clientes.sql` agrega `profiles.nombre` y, en `clientes`,
`identificacion`, `autoriza_datos` y `autoriza_datos_en` (Ley 1581 de 2012),
con índice único por negocio e identificación.

## Variables de entorno

Ver [`backend/.env.example`](../backend/.env.example). `SUPABASE_SERVICE_ROLE_KEY`
es obligatoria para crear cuentas de trabajadores y **nunca** se pone en la app.

## Pruebas

```bash
cd backend
python -m pytest -q          # unitarias + HTTP con SQLite en memoria
python -m ruff check src main.py tests
```

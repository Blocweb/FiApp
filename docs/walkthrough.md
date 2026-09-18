# Walkthrough - Fase 1: Estabilización

Este documento resume las tareas implementadas, refactorizaciones y verificaciones ejecutadas para completar la **Fase 1: Estabilización** de FiApp.

---

## 1. Auditoría Inicial y Eliminación de Mocks/Fakes
- **Mocks eliminados**:
  - `frontend/lib/core/mock/mock_data.dart` (eliminado).
  - `frontend/lib/features/clients/data/repositories/client_repository_mock_impl.dart` (eliminado).
  - `frontend/lib/features/history/data/repositories/transaction_repository_mock_impl.dart` (eliminado).
  - `backend/src/app/routers/api/profile.py` (eliminado en favor del router unificado `/perfil/`).
- **Inyección de dependencias limpiada**: Los providers de Flutter (`clientRepositoryProvider`, `transactionRepositoryProvider`, `profileRepositoryProvider`) ahora usan exclusivamente implementaciones remotas (`*RepositoryRemoteImpl`) conectadas al backend FastAPI y a Supabase Auth.

---

## 2. Contrato API ↔ Flutter (`lastMovement` / `ultimo_movimiento_en`)
- **Backend**:
  - Esquema `ClienteResponse` configurado con alias bidireccionales (`lastMovement` / `ultimo_movimiento_en`, `balance` / `saldo`, `createdAt`, `updatedAt`).
  - Serialización correcta de campos `datetime` ISO-8601 o `null`.
- **Flutter**:
  - `ClientModel` parsea `lastMovement` como `DateTime?` desde ISO-8601 string o `null`.
  - Entidad de dominio `Client` utiliza `DateTime? lastMovement`.
  - Las pantallas de interfaz (`ClientsScreen`, `ClientDetailScreen`) formatean la fecha adecuadamente con `Formatters.relativeDate` o `Formatters.date`.

---

## 3. Refactor del Saldo (`adjustBalance`)
- **Eliminación**: `adjustBalance` fue completamente removido de la interfaz `ClientRepository`, del `ClientRepositoryRemoteImpl` y de los providers de Riverpod.
- **Flujo transaccional real**: El saldo del cliente ya no se muta de forma artificial en memoria o con llamadas fakes. Tras registrar un **Fiado** o un **Abono**, los datos se refrescan llamando a `refreshClients()` y `fetchTransactions()`, reflejando el saldo calculado de manera determinística por la base de datos y la API.

---

## 4. Borrado Lógico de Clientes (Soft Delete)
- **Backend**:
  - Creado y asegurado el endpoint `DELETE /clientes/{id}` en `backend/src/app/routers/clientes.py`.
  - Validación estricta de pertenencia: `owner_id = str(profile.id)` para evitar accesos cruzados.
  - Implementado `delete_cliente` en `cliente_service.py` que establece `deleted_at = func.now()`.
  - Consultas `get_clientes` y `get_cliente_by_id` actualizadas con filtro `Cliente.deleted_at.is_(None)`.
- **Flutter**:
  - Implementado `deleteClient(String id)` en `ClientApiService`, `ClientRepository`, `ClientRepositoryRemoteImpl` y `ClientsNotifier`.
  - Conectado en la interfaz de confirmación de eliminación en `ClientDetailScreen`.

---

## 5. Consolidación de Perfil
- **Backend**:
  - Eliminado el endpoint duplicado `/api/profile` en `main.py` y archivos residuales.
  - Unificado bajo el router `/perfil/` (`GET /perfil/`, `PUT /perfil/`).
- **Flutter**:
  - Repositorio y provider de perfil (`profile_provider.dart`, `profile_repository_remote_impl.dart`) apuntando al endpoint `/perfil/`.
  - `updateProfile` realiza llamada HTTP `PUT` real al backend, actualizando el perfil autenticado en la base de datos sin simulaciones.

---

## 6. Reportes
- **Backend**:
  - Endpoints activos y validados: `GET /reportes/resumen` y `GET /reportes/evolucion`, filtrando por el `owner_id` del token JWT.
- **Flutter**:
  - Creada capa completa en arquitectura limpia:
    - Entidades `ResumenNegocio` y `EvolucionMensual`.
    - `ReporteModel` para deserialización de respuestas.
    - `ReporteApiService` y `ReporteRepositoryRemoteImpl`.
    - `ReportesNotifier` y `reportesProvider` (Riverpod).
  - `ReportesScreen` actualizado para consumir datos en tiempo real mediante el provider, removiendo variables estáticas y hardcodeadas.

---

## 7. Exportaciones (UI "Próximamente")
- `ExportInfoScreen` actualizado para eliminar mensajes de éxito simulados o descargas ficticias.
- Muestra una pantalla clara de **"Próximamente"** informando sobre el soporte futuro para Excel (.xlsx) y PDF.

---

## 8. Flujo de Recuperación de Contraseña
- **Integración Supabase Auth**:
  - `ForgotPasswordScreen`: envía correo de restablecimiento con `Supabase.instance.client.auth.resetPasswordForEmail(email)` y navega pasando el correo como parámetro hacia la pantalla de verificación.
  - `VerifyCodeScreen`: pantalla rediseñada que permite ingresar el código de verificación de 6 dígitos mediante `Supabase.instance.client.auth.verifyOTP(email: ..., token: code, type: OtpType.recovery)` o reenviar el código.
  - `main.dart`: listener global `auth.onAuthStateChange` configurado para capturar deep links con `AuthChangeEvent.passwordRecovery` y redirigir automáticamente a `/new-password`.
  - `NewPasswordScreen`: actualiza la clave del usuario autenticado con `Supabase.instance.client.auth.updateUser(UserAttributes(password: password))`.

---

## 9. Seguridad y Políticas RLS
- **Derivación de `owner_id`**:
  - Todos los endpoints del backend obtienen el perfil del usuario autenticado a través de la dependencia `get_current_profile` basada en el JWT de Supabase (`token.sub`).
  - No se permite que el frontend inyecte o manipule `owner_id`.
- **Esquema SQL (`backend/src/app/database/fiapp_supabase_schema.sql`)**:
  - Se completaron las políticas de Row Level Security faltantes para operaciones de modificación y eliminación:
    - `clientes_delete_own`: `FOR DELETE USING (owner_id = auth.uid())`.
    - `productos_delete_own`: `FOR DELETE USING (owner_id = auth.uid())`.
    - `transacciones_update_own`: `FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid())`.
    - `transacciones_delete_own`: `FOR DELETE USING (owner_id = auth.uid())`.
    - `fiado_items_update_own`: `FOR UPDATE USING (...) WITH CHECK (...)`.
    - `fiado_items_delete_own`: `FOR DELETE USING (...)`.

---

## 10. Verificación y Resultados de Pruebas
1. **Backend (Python / pytest)**:
   - Comando: `$env:PYTHONPATH = "backend"; python -m pytest backend/tests`
   - Resultado: **6 passed in 0.87s** (esquemas Pydantic, alias, validación de montos e items, derivación de `owner_id` por JWT, soft delete).
2. **Frontend (Flutter Analyze)**:
   - Comando: `flutter analyze`
   - Resultado: **No issues found! (ran in 2.7s)**. Cero errores y cero advertencias.
3. **Frontend (Flutter Test)**:
   - Comando: `flutter test`
   - Resultado: **All tests passed! (10 unit y widget tests passed)**.

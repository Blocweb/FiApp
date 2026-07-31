# Frontend y experiencia de usuario

Código en [`frontend/`](../frontend/).

## Objetivo

- UI modular y escalable por dominio (auth, clients, fiados, …)
- Separar pantallas, widgets y providers
- Preparar el cliente HTTP para la API ASP.NET Core

## Stack

- Flutter + Material 3
- GoRouter (navegación)
- Riverpod (estado)
- Dio (red)

## Parte visual

`lib/features/*/presentation/` y `lib/core/widgets/` / `lib/core/theme/`.

## Assets

- Imágenes: `frontend/assets/images/`
- Fuentes: `frontend/assets/fonts/`

## Pruebas

```bash
cd frontend
flutter test
```

- `test/unit/` — formatters, entidades, config
- `test/widget/` — humo de la app

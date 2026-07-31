# Frontend — FiApp (Flutter)

Aplicación móvil Flutter: UI, navegación, estado y cliente HTTP hacia la API.

## Cómo ejecutar

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run
```

## Capas (Clean Architecture)

```
lib/
├── main.dart
├── core/                 # Compartido
│   ├── config/           # Configuración de la app / API
│   ├── network/          # Cliente Dio
│   ├── theme/            # Colores, tipografía, animaciones
│   ├── widgets/          # UI reutilizable
│   ├── router/           # GoRouter
│   ├── providers/        # Inyección de repositorios
│   ├── utils/            # Formatters
│   └── mock/             # Datos de ejemplo
└── features/<módulo>/
    ├── presentation/     # Pantallas, widgets, providers (parte visual)
    ├── domain/           # Entidades e interfaces
    └── data/             # Modelos JSON y repositorios (mock / remoto)
```

## Assets

- `assets/images/` — logo e imágenes
- `assets/fonts/` — tipografías (opcional: Inter)

## Pruebas

- `test/widget/` — pruebas de widgets
- `test/unit/` — pruebas unitarias

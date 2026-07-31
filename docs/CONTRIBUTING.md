# Guía de contribución

1. Crea una rama desde `develop` (`feature/*` o `fix/*`).
2. Mantén frontend y backend en sus carpetas (`frontend/`, `backend/`).
3. No subas secretos (`.env`, keys, connection strings).
4. Añade o actualiza pruebas en `frontend/test/` (o `backend/tests/`).
5. Ejecuta antes del PR:

```bash
cd frontend
flutter analyze
flutter test
```

6. Abre PR hacia `develop` con descripción clara y plan de prueba.
7. Tras validar en `develop`, se promueve a `main` para release.

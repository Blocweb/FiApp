# Estrategia de ramas (Git Flow simplificado)

```
main          ← producción / releases estables
 │
 └── develop  ← integración diaria
       │
       ├── feature/nombre-funcionalidad
       ├── fix/descripcion-bug
       └── release/x.y.z
```

## Reglas

| Rama | Quién mergea | Protección recomendada |
|------|--------------|------------------------|
| `main` | Solo desde `develop` o `release/*` vía PR | CI verde + review |
| `develop` | Features y fixes vía PR | CI verde |
| `feature/*` | Desde `develop` | Borrar tras merge |
| `fix/*` | Hotfix a `develop` (y cherry-pick a `main` si urge) | — |

## Convención de commits

- `feat:` nueva funcionalidad
- `fix:` corrección
- `docs:` documentación
- `test:` pruebas
- `chore:` mantenimiento / CI / estructura
- `refactor:` cambio interno sin alterar comportamiento

## Flujo típico

```bash
git checkout develop
git pull
git checkout -b feature/registro-abonos
# … trabajo …
git push -u origin feature/registro-abonos
# Abrir PR → develop
```

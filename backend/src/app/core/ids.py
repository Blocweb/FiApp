"""Conversión segura de identificadores recibidos como texto."""

from uuid import UUID


def as_uuid(value) -> UUID | None:
    """Devuelve el UUID o ``None`` si el valor no es un UUID válido.

    Los ids llegan como texto desde la ruta o el cuerpo de la petición. Un id
    mal formado se trata como "no encontrado" en lugar de provocar un error 500.
    """
    if value is None or isinstance(value, UUID):
        return value
    try:
        return UUID(str(value))
    except ValueError:
        return None

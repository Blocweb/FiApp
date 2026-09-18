"""Tests de autenticación: validación de identidad con Supabase.

No se llama a Supabase real: se sustituye `httpx.AsyncClient` por dobles de
prueba para verificar el comportamiento ante tokens válidos, inválidos y
respuestas anómalas.
"""

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import HTTPException

from src.app.services.auth_service import (
    get_current_user,
    validate_supabase_token,
)
from src.app.schemas.auth import TokenData


def _mock_httpx_response(status_code: int, payload: dict | None = None):
    response = MagicMock()
    response.status_code = status_code
    if payload is None:
        response.json.side_effect = ValueError("cuerpo no JSON")
    else:
        response.json.return_value = payload
    return response


class _AsyncClientFactory:
    """Doble de `httpx.AsyncClient` que devuelve una respuesta prefijada."""

    def __init__(self, response):
        self._response = response

    def __call__(self, *args, **kwargs):
        client = AsyncMock()
        client.__aenter__.return_value = client
        client.__aexit__.return_value = False
        client.get.return_value = self._response
        return client


@pytest.mark.anyio
async def test_validate_supabase_token_valido():
    """Un token aceptado por Supabase produce identidad tipada."""
    user_id = uuid.uuid4()
    response = _mock_httpx_response(
        200, {"id": str(user_id), "email": "dueno@fiapp.test"}
    )

    with patch("httpx.AsyncClient", new=_AsyncClientFactory(response)):
        token_data = await validate_supabase_token("token-valido")

    assert isinstance(token_data, TokenData)
    assert token_data.sub == user_id
    assert token_data.email == "dueno@fiapp.test"


@pytest.mark.anyio
async def test_validate_supabase_token_acepta_sub_como_uuid():
    """`sub` también puede venir en el payload y se normaliza a UUID."""
    user_id = uuid.uuid4()
    response = _mock_httpx_response(200, {"sub": str(user_id), "email": None})

    with patch("httpx.AsyncClient", new=_AsyncClientFactory(response)):
        token_data = await validate_supabase_token("token-valido")

    assert token_data.sub == user_id


@pytest.mark.anyio
async def test_validate_supabase_token_rechazado():
    """Una respuesta no 200 de Supabase produce 401."""
    response = _mock_httpx_response(401, {"error": "invalid token"})

    with patch("httpx.AsyncClient", new=_AsyncClientFactory(response)):
        with pytest.raises(HTTPException) as exc_info:
            await validate_supabase_token("token-invalido")

    assert exc_info.value.status_code == 401


@pytest.mark.anyio
async def test_validate_supabase_token_sin_identidad():
    """Una respuesta 200 sin id/sub se rechaza como no autorizada."""
    response = _mock_httpx_response(200, {"email": "sin-id@fiapp.test"})

    with patch("httpx.AsyncClient", new=_AsyncClientFactory(response)):
        with pytest.raises(HTTPException) as exc_info:
            await validate_supabase_token("token-raro")

    assert exc_info.value.status_code == 401


@pytest.mark.anyio
async def test_validate_supabase_token_identidad_no_uuid():
    """Una identidad que no es UUID se rechaza de forma controlada."""
    response = _mock_httpx_response(200, {"id": "no-es-un-uuid"})

    with patch("httpx.AsyncClient", new=_AsyncClientFactory(response)):
        with pytest.raises(HTTPException) as exc_info:
            await validate_supabase_token("token-raro")

    assert exc_info.value.status_code == 401


@pytest.mark.anyio
async def test_validate_supabase_token_cuerpo_no_json():
    """Un cuerpo no parseable se traduce en 401, no en error 500."""
    response = _mock_httpx_response(200, None)

    with patch("httpx.AsyncClient", new=_AsyncClientFactory(response)):
        with pytest.raises(HTTPException) as exc_info:
            await validate_supabase_token("token-ilegible")

    assert exc_info.value.status_code == 401


@pytest.mark.anyio
async def test_validate_supabase_token_error_de_red():
    """Un fallo de transporte con Supabase produce 401, no una excepción cruda."""
    import httpx

    class _FailingClient:
        def __call__(self, *args, **kwargs):
            client = AsyncMock()
            client.__aenter__.return_value = client
            client.__aexit__.return_value = False
            client.get.side_effect = httpx.ConnectError("sin conexión")
            return client

    with patch("httpx.AsyncClient", new=_FailingClient()):
        with pytest.raises(HTTPException) as exc_info:
            await validate_supabase_token("token-x")

    assert exc_info.value.status_code == 401


@pytest.mark.anyio
async def test_get_current_user_devuelve_identidad():
    """`get_current_user()` envuelve el TokenData en la identidad del contexto."""
    user_id = uuid.uuid4()

    with patch(
        "src.app.services.auth_service.validate_supabase_token",
        new=AsyncMock(return_value=TokenData(sub=user_id, email="a@fiapp.test")),
    ):
        usuario = await get_current_user(token="token-valido")

    assert usuario.id == user_id
    assert usuario.email == "a@fiapp.test"

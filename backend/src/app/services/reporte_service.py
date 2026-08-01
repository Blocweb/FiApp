from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.encoders import jsonable_encoder


async def get_resumen_negocio(db: AsyncSession, owner_id: str) -> list[dict]:
    query = text("SELECT * FROM v_resumen_negocio WHERE owner_id = :owner_id")
    result = await db.execute(query, {"owner_id": owner_id})
    rows = [dict(row._mapping) for row in result]
    return jsonable_encoder(rows)


async def get_evolucion_mensual(db: AsyncSession, owner_id: str) -> list[dict]:
    query = text("SELECT * FROM v_evolucion_mensual WHERE owner_id = :owner_id ORDER BY 1")
    result = await db.execute(query, {"owner_id": owner_id})
    rows = [dict(row._mapping) for row in result]
    return jsonable_encoder(rows)

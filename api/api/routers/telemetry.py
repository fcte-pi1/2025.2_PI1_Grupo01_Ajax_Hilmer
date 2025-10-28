from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.database import get_session
from api.models import Telemetry
from api.schemas import (
    FilterPage,
    Message,
    TelemetryPublic,
    TelemetryPublicList,
    TelemetrySchema,
)

router = APIRouter(prefix='/telemetries', tags=['telemetries'])


Filter = Annotated[FilterPage, Query()]
Session = Annotated[AsyncSession, Depends(get_session)]


@router.get(
    '/',
    status_code=HTTPStatus.OK,
    response_model=TelemetryPublicList,
    response_class=JSONResponse,
)
async def read_telemetries(session: Session, filter: Filter):
    telemetries = await session.scalars(
        select(Telemetry).limit(filter.limit).offset(filter.offset)
    )

    return {'telemetries': telemetries}


@router.get(
    '/{telemetry_id}',
    status_code=HTTPStatus.OK,
    response_model=TelemetryPublic,
    response_class=JSONResponse,
)
async def read_telemetry(telemetry_id: int, session: Session):
    db_telemetry = await session.scalar(
        select(Telemetry).where(Telemetry.id == telemetry_id)
    )

    if db_telemetry:
        return db_telemetry

    raise HTTPException(
        status_code=HTTPStatus.NOT_FOUND, detail='Telemetry not found'
    )


@router.post(
    '/{route_id}',
    status_code=HTTPStatus.CREATED,
    response_model=TelemetryPublic,
    response_class=JSONResponse,
)
async def create_telemetry(
    telemetry: TelemetrySchema, session: Session, route_id: int
):
    new_telemetry = Telemetry(
        average_speed=telemetry.average_current,
        distance_traveled=telemetry.distance_traveled,
        energy_consumed=telemetry.energy_consumed,
        average_current=telemetry.average_current,
        status=telemetry.status,
        route_id=route_id,
    )

    session.add(new_telemetry)
    await session.commit()
    await session.refresh(new_telemetry)

    return new_telemetry


@router.delete(
    '/{telemetry_id}',
    status_code=HTTPStatus.OK,
    response_model=Message,
    response_class=JSONResponse,
)
async def delete_telemetry(telemetry_id: int, session: Session):
    db_telemetry = await session.scalar(
        select(Telemetry).where(Telemetry.id == telemetry_id)
    )

    if db_telemetry:
        await session.delete(db_telemetry)
        await session.commit()
        return {'message': 'Telemetry deleted'}

    raise HTTPException(
        status_code=HTTPStatus.NOT_FOUND, detail='Telemetry not found'
    )

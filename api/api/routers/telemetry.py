from http import HTTPStatus

from fastapi import APIRouter
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient
from api.schemas import (
    Message,
    TelemetryPublic,
    TelemetryPublicList,
    TelemetrySchema,
)

router = APIRouter(prefix='telemetries', tags=['telemetries'])


@router.get(
    '/',
    status_code=HTTPStatus.OK,
    response_model=TelemetryPublic,
    response_class=JSONResponse,
)
async def read_telemetries():
    pass


@router.get(
    '/{telemetry_id}',
    status_code=HTTPStatus.OK,
    response_model=TelemetryPublicList,
    response_class=JSONResponse,
)
async def read_telemetry(telemetry_id: int):
    pass


@router.post(
    '/',
    status_code=HTTPStatus.CREATED,
    response_model=TelemetryPublic,
    response_class=JSONResponse,
)
async def create_telemetry(telemetry: TelemetrySchema):
    pass


@router.put(
    '/{telemetry_id}',
    status_code=HTTPStatus.OK,
    response_model=TelemetryPublic,
    response_class=JSONResponse,
)
async def update_telemetry(telemetry_id: int, telemetry: TelemetrySchema):
    pass


@router.delete(
    '/{telemetry_id}',
    status_code=HTTPStatus.OK,
    response_model=Message,
    response_class=JSONResponse,
)
async def delete_telemetry(telemetry_id: int):
    pass

from http import HTTPStatus

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from api.schemas import Message, RoutePublic, RoutePublicList, RouteSchema

router = APIRouter(prefix='routes', tags=['routes'])


@router.get(
    '/',
    status_code=HTTPStatus.OK,
    response_model=RoutePublic,
    response_class=JSONResponse,
)
async def read_routes():
    pass


@router.get(
    '/{route_id}',
    status_code=HTTPStatus.OK,
    response_model=RoutePublicList,
    response_class=JSONResponse,
)
async def read_route(route_id: int):
    pass


@router.post(
    '/',
    status_code=HTTPStatus.CREATED,
    response_model=RoutePublic,
    response_class=JSONResponse,
)
async def create_route(route: RouteSchema):
    pass


@router.put(
    '/{route_id}',
    status_code=HTTPStatus.OK,
    response_model=RoutePublic,
    response_class=JSONResponse,
)
async def update_route(route_id: int, route: RouteSchema):
    pass


@router.delete(
    '/{route_id}',
    status_code=HTTPStatus.OK,
    response_model=Message,
    response_class=JSONResponse,
)
async def delete_route(route_id: int):
    pass

from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from api.database import get_session
from api.models import Route
from api.schemas import (
    FilterPage,
    Message,
    RoutePublic,
    RoutePublicList,
    RouteSchema,
)

router = APIRouter(prefix='/routes', tags=['routes'])

Filter = Annotated[FilterPage, Query()]
Session = Annotated[AsyncSession, Depends(get_session)]


@router.get(
    '/',
    status_code=HTTPStatus.OK,
    response_model=RoutePublicList,
    response_class=JSONResponse,
)
async def read_routes(session: Session, filter: Filter):
    routes = await session.scalars(
        select(Route).limit(filter.limit).offset(filter.offset)
    )

    return {'routes': routes}


@router.get(
    '/{route_id}',
    status_code=HTTPStatus.OK,
    response_model=RoutePublic,
    response_class=JSONResponse,
)
async def read_route(route_id: int, session: Session):
    db_route = await session.scalar(select(Route).where(Route.id == route_id))

    if db_route:
        return db_route

    raise HTTPException(
        status_code=HTTPStatus.NOT_FOUND, detail='Route not found'
    )


@router.post(
    '/',
    status_code=HTTPStatus.CREATED,
    response_model=RoutePublic,
    response_class=JSONResponse,
)
async def create_route(route: RouteSchema, session: Session):
    db_route = await session.scalar(
        select(Route).where(Route.commands == route.commands)
    )

    if db_route:
        raise HTTPException(
            status_code=HTTPStatus.CONFLICT, detail='Route already exists'
        )

    new_route = Route(commands=route.commands)

    session.add(new_route)
    await session.commit()
    await session.refresh(new_route)

    return new_route


@router.put(
    '/{route_id}',
    status_code=HTTPStatus.OK,
    response_model=RoutePublic,
    response_class=JSONResponse,
)
async def update_route(route_id: int, route: RouteSchema, session: Session):
    db_route = await session.scalar(select(Route).where(Route.id == route_id))

    if db_route:
        try:
            db_route.commands = route.commands

            await session.commit()
            await session.refresh(db_route)

            return db_route

        except IntegrityError:
            raise HTTPException(
                status_code=HTTPStatus.CONFLICT, detail='Route already exists'
            )

    raise HTTPException(
        status_code=HTTPStatus.NOT_FOUND, detail='Route not found'
    )


@router.delete(
    '/{route_id}',
    status_code=HTTPStatus.OK,
    response_model=Message,
    response_class=JSONResponse,
)
async def delete_route(route_id: int, session: Session):
    db_route = await session.scalar(select(Route).where(Route.id == route_id))

    if db_route:
        await session.delete(db_route)
        await session.commit()
        return {'message': 'Route deleted'}

    raise HTTPException(
        status_code=HTTPStatus.NOT_FOUND, detail='Route not found'
    )

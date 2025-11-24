from datetime import datetime
from http import HTTPStatus

import pytest

from api.models import Route
from api.schemas import RoutePublic

EXPECTED_ROUTES_COUNT_THREE = 3
EXPECTED_ROUTES_COUNT_TWO = 2


def test_create_route(client):
    commands = (
        'ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 20 CM,'
        'GIRAR 90 GRAUS DIREITA, ANDAR 35 CM, GIRAR 45 GRAUS ESQUERDA,'
        'ANDAR 20 CM, ENTREGAR'
    )

    response = client.post(
        '/routes/',
        json={'commands': commands},
    )

    assert response.status_code == HTTPStatus.CREATED
    assert response.json() == {
        'id': 1,
        'commands': commands,
    }


def test_read_routes(client, route):
    route_public = RoutePublic.model_validate(route).model_dump()
    response = client.get('/routes/')
    assert response.status_code == HTTPStatus.OK
    assert response.json() == {'routes': [route_public]}


def test_read_route(client, route):
    route_public = RoutePublic.model_validate(route).model_dump()
    response = client.get(f'/routes/{route.id}')
    assert response.status_code == HTTPStatus.OK
    assert response.json() == route_public


def test_read_route_incorrect_id(client):
    response = client.get('/routes/2')
    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Route not found'}


def test_create_route_conflict(client, route):
    commands = route.commands

    response = client.post(
        '/routes/',
        json={'commands': commands},
    )

    assert response.status_code == HTTPStatus.CONFLICT
    assert response.json() == {'detail': 'Route already exists'}


def test_update_route(client, route):
    commands = (
        'ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 20 CM,'
        'GIRAR 90 GRAUS DIREITA, ANDAR 35 CM, GIRAR 45 GRAUS ESQUERDA,'
        'ANDAR 20 CM, GIRAR 90 GRAUS DIREITA, ENTREGAR'
    )

    response = client.put(
        f'/routes/{route.id}',
        json={'commands': commands},
    )
    route_public = RoutePublic.model_validate(route).model_dump()
    assert response.status_code == HTTPStatus.OK
    assert response.json() == route_public


def test_update_route_conflict(client, route):
    commands = (
        'ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 20 CM,'
        'GIRAR 90 GRAUS DIREITA, ANDAR 35 CM, GIRAR 45 GRAUS ESQUERDA,'
        'ANDAR 20 CM, GIRAR 90 GRAUS DIREITA, ENTREGAR'
    )
    response = client.post(
        '/routes/',
        json={'commands': commands},
    )
    response = client.put(
        '/routes/2',
        json={'commands': route.commands},
    )
    assert response.status_code == HTTPStatus.CONFLICT
    assert response.json() == {'detail': 'Route already exists'}


def test_update_route_exception(client, route):
    commands = (
        'ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 20 CM,'
        'GIRAR 90 GRAUS DIREITA, ANDAR 35 CM, GIRAR 45 GRAUS ESQUERDA,'
        'ANDAR 20 CM, GIRAR 90 GRAUS DIREITA, ENTREGAR'
    )
    response = client.put(
        '/routes/2',
        json={'commands': commands},
    )
    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Route not found'}


def test_delete_route_incorrect(client):
    response = client.delete('/routes/10')
    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Route not found'}


def test_delete_route_correct(client, route):
    response = client.delete(f'/routes/{route.id}')
    assert response.status_code == HTTPStatus.OK
    assert response.json() == {'message': 'Route deleted'}


@pytest.mark.asyncio
async def test_read_routes_order_by_desc(client, session, mock_db_time):
    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 10, 0, 0)):
        route1 = Route(commands='ANDAR 10 CM, ENTREGAR')
        session.add(route1)
        await session.commit()
        await session.refresh(route1)

    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 12, 0, 0)):
        route2 = Route(commands='ANDAR 20 CM, ENTREGAR')
        session.add(route2)
        await session.commit()
        await session.refresh(route2)

    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 14, 0, 0)):
        route3 = Route(commands='ANDAR 30 CM, ENTREGAR')
        session.add(route3)
        await session.commit()
        await session.refresh(route3)

    response = client.get('/routes/?order_by=desc')
    assert response.status_code == HTTPStatus.OK
    routes = response.json()['routes']
    assert len(routes) == EXPECTED_ROUTES_COUNT_THREE
    assert routes[0]['commands'] == 'ANDAR 30 CM, ENTREGAR'
    assert routes[1]['commands'] == 'ANDAR 20 CM, ENTREGAR'
    assert routes[2]['commands'] == 'ANDAR 10 CM, ENTREGAR'


@pytest.mark.asyncio
async def test_read_routes_order_by_asc(client, session, mock_db_time):
    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 10, 0, 0)):
        route1 = Route(commands='ANDAR 10 CM, ENTREGAR')
        session.add(route1)
        await session.commit()
        await session.refresh(route1)

    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 12, 0, 0)):
        route2 = Route(commands='ANDAR 20 CM, ENTREGAR')
        session.add(route2)
        await session.commit()
        await session.refresh(route2)

    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 14, 0, 0)):
        route3 = Route(commands='ANDAR 30 CM, ENTREGAR')
        session.add(route3)
        await session.commit()
        await session.refresh(route3)

    response = client.get('/routes/?order_by=asc')
    assert response.status_code == HTTPStatus.OK
    routes = response.json()['routes']
    assert len(routes) == EXPECTED_ROUTES_COUNT_THREE
    assert routes[0]['commands'] == 'ANDAR 10 CM, ENTREGAR'
    assert routes[1]['commands'] == 'ANDAR 20 CM, ENTREGAR'
    assert routes[2]['commands'] == 'ANDAR 30 CM, ENTREGAR'


@pytest.mark.asyncio
async def test_read_routes_default_order_is_desc(
    client, session, mock_db_time
):
    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 10, 0, 0)):
        route1 = Route(commands='ANDAR 10 CM, ENTREGAR')
        session.add(route1)
        await session.commit()
        await session.refresh(route1)

    with mock_db_time(model=Route, time=datetime(2025, 1, 1, 12, 0, 0)):
        route2 = Route(commands='ANDAR 20 CM, ENTREGAR')
        session.add(route2)
        await session.commit()
        await session.refresh(route2)

    response = client.get('/routes/')
    assert response.status_code == HTTPStatus.OK
    routes = response.json()['routes']
    assert len(routes) == EXPECTED_ROUTES_COUNT_TWO
    assert routes[0]['commands'] == 'ANDAR 20 CM, ENTREGAR'
    assert routes[1]['commands'] == 'ANDAR 10 CM, ENTREGAR'

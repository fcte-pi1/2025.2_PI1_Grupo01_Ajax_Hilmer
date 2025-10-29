from http import HTTPStatus

from api.schemas import RoutePublic


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
    assert response.json() == {'id': 1, 'commands': commands}


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

from http import HTTPStatus


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

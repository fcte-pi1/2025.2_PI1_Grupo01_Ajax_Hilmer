from http import HTTPStatus

from api.schemas import TelemetryPublic


def test_create_telemetry(client, route):
    average_speed = 10
    distance_traveled = 200
    energy_consumed = 100
    average_current = 100
    status = 'success'
    route_id = 1

    response = client.post(
        '/telemetries/1',
        json={
            'average_speed': average_speed,
            'distance_traveled': distance_traveled,
            'energy_consumed': energy_consumed,
            'average_current': average_current,
            'status': status,
            'route_id': route_id,
        },
    )

    assert response.status_code == HTTPStatus.CREATED
    assert response.json() == {
        'id': 1,
        'average_speed': 10,
        'distance_traveled': 200,
        'energy_consumed': 100,
        'average_current': 100,
        'status': 'success',
    }


def test_create_telemetry_incorrect_route_id(client, route):
    average_speed = 10
    distance_traveled = 200
    energy_consumed = 100
    average_current = 100
    status = 'success'
    route_id = 1

    response = client.post(
        '/telemetries/2',
        json={
            'average_speed': average_speed,
            'distance_traveled': distance_traveled,
            'energy_consumed': energy_consumed,
            'average_current': average_current,
            'status': status,
            'route_id': route_id,
        },
    )

    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Route not found'}


def test_delete_telemetry_incorrect(client):
    response = client.delete('/telemetries/10')
    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Telemetry not found'}


def test_delete_telemetry_correct(client, telemetry):
    response = client.delete(f'/telemetries/{telemetry.id}')
    assert response.status_code == HTTPStatus.OK
    assert response.json() == {'message': 'Telemetry deleted'}


def test_read_telemetries(client, telemetry):
    telemetry_public = TelemetryPublic.model_validate(telemetry).model_dump()
    response = client.get('/telemetries/')
    assert response.status_code == HTTPStatus.OK
    assert response.json() == {'telemetries': [telemetry_public]}


def test_read_telemetry(client, telemetry):
    telemetry_public = TelemetryPublic.model_validate(telemetry).model_dump()
    response = client.get(f'/telemetries/{telemetry.id}')
    assert response.status_code == HTTPStatus.OK
    assert response.json() == telemetry_public


def test_read_telemetry_incorrect_id(client, telemetry):
    response = client.get(f'/telemetries/{telemetry.id + 1}')
    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Telemetry not found'}

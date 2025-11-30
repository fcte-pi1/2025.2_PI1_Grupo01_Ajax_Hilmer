from http import HTTPStatus


def test_create_telemetry(client, route):
    average_speed = 10
    distance_traveled = 200
    energy_consumed = 100
    average_current = 100
    status = 'success'
    route_id = route.id

    response = client.post(
        f'/telemetries/{route.id}',
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
    response_data = response.json()
    assert response_data['id'] == 1
    assert response_data['average_speed'] == average_speed
    assert response_data['distance_traveled'] == distance_traveled
    assert response_data['energy_consumed'] == energy_consumed
    assert response_data['average_current'] == average_current
    assert response_data['status'] == status
    assert response_data['route_id'] == route.id
    assert 'route' in response_data
    assert response_data['route']['id'] == route.id
    assert 'created_at' in response_data


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
    response = client.get('/telemetries/')
    assert response.status_code == HTTPStatus.OK

    response_data = response.json()
    assert 'telemetries' in response_data
    assert len(response_data['telemetries']) == 1

    telemetry_data = response_data['telemetries'][0]
    assert telemetry_data['id'] == telemetry.id
    assert telemetry_data['average_speed'] == telemetry.average_speed
    assert telemetry_data['distance_traveled'] == telemetry.distance_traveled
    assert telemetry_data['route_id'] == telemetry.route_id
    assert 'route' in telemetry_data
    assert 'created_at' in telemetry_data


def test_read_telemetry(client, telemetry):
    response = client.get(f'/telemetries/{telemetry.id}')
    assert response.status_code == HTTPStatus.OK

    response_data = response.json()
    assert response_data['id'] == telemetry.id
    assert response_data['average_speed'] == telemetry.average_speed
    assert response_data['distance_traveled'] == telemetry.distance_traveled
    assert response_data['route_id'] == telemetry.route_id
    assert 'route' in response_data
    assert response_data['route']['id'] == telemetry.route_id
    assert 'created_at' in response_data


def test_read_telemetry_incorrect_id(client, telemetry):
    response = client.get(f'/telemetries/{telemetry.id + 1}')
    assert response.status_code == HTTPStatus.NOT_FOUND
    assert response.json() == {'detail': 'Telemetry not found'}

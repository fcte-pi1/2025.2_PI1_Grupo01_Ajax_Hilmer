from dataclasses import asdict

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.models import Route, Telemetry


@pytest.mark.asyncio
async def test_create_route_db(session: AsyncSession, mock_db_time):
    with mock_db_time(model=Route) as time:
        commands = (
            'ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 20 CM,'
            'GIRAR 90 GRAUS DIREITA, ANDAR 35 CM, GIRAR 45 GRAUS ESQUERDA,'
            'ANDAR 20 CM, ENTREGAR'
        )

        new_route = Route(commands=commands)
        session.add(new_route)
        await session.commit()

        route = await session.scalar(
            select(Route).where(Route.commands == commands)
        )

        assert asdict(route) == {
            'id': 1,
            'commands': commands,
            'created_at': time,
            'updated_at': time,
            'telemetries': [],
        }


@pytest.mark.asyncio
async def test_create_telemetry_db(session: AsyncSession, mock_db_time, route):
    with mock_db_time(model=Telemetry) as time:
        average_speed = 10
        distance_traveled = 200
        energy_consumed = 100
        average_current = 100
        status = 'success'

        new_telemetry = Telemetry(
            average_speed=average_speed,
            distance_traveled=distance_traveled,
            energy_consumed=energy_consumed,
            average_current=average_current,
            status=status,
            route_id=route.id,
        )

        session.add(new_telemetry)
        await session.commit()

        telemetry = await session.scalar(
            select(Telemetry).where(Telemetry.id == 1)
        )

        telemetry_dict = asdict(telemetry)

        # Verifica campos principais
        assert telemetry_dict['id'] == 1
        assert telemetry_dict['average_speed'] == average_speed
        assert telemetry_dict['distance_traveled'] == distance_traveled
        assert telemetry_dict['energy_consumed'] == energy_consumed
        assert telemetry_dict['average_current'] == average_current
        assert telemetry_dict['status'] == status
        assert telemetry_dict['route_id'] == 1
        assert telemetry_dict['created_at'] == time

        # Verifica que o campo 'route' está presente
        assert 'route' in telemetry_dict
        assert telemetry_dict['route']['id'] == route.id
        assert telemetry_dict['route']['commands'] == route.commands

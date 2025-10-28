from dataclasses import asdict

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.models import Route


@pytest.mark.asyncio
async def test_create_route(session: AsyncSession, mock_db_time):
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
        }

from contextlib import contextmanager
from datetime import datetime

import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from testcontainers.postgres import PostgresContainer

from api.app import app
from api.database import get_session
from api.models import Route, Telemetry, table_registry


@pytest.fixture
def client(session: AsyncSession):
    def get_session_override():
        return session

    with TestClient(app) as client:
        app.dependency_overrides[get_session] = get_session_override
        yield client

    app.dependency_overrides.clear()


@pytest.fixture(scope='session')
def engine():
    with PostgresContainer('postgres:18', driver='psycopg') as postgres:
        yield create_async_engine(postgres.get_connection_url())


@pytest_asyncio.fixture
async def session(engine):
    async with engine.begin() as conn:
        await conn.run_sync(table_registry.metadata.create_all)

    async with AsyncSession(engine, expire_on_commit=False) as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(table_registry.metadata.drop_all)


@pytest_asyncio.fixture
async def telemetry(session: AsyncSession, route: Route):
    telemetry = Telemetry(
        average_speed=10,
        distance_traveled=200,
        energy_consumed=100,
        average_current=100,
        status='success',
        route_id=route.id,
    )
    session.add(telemetry)
    await session.commit()
    await session.refresh(telemetry)

    return telemetry


# seguir o mesmo exemplo para telemetry
@pytest_asyncio.fixture
async def route(session: AsyncSession):
    route = Route(
        commands='ANDAR 50 CM, GIRAR 90 GRAUS DIREITA, ANDAR 20 CM,'
        'GIRAR 90 GRAUS DIREITA, ANDAR 35 CM, GIRAR 45 GRAUS ESQUERDA,'
        'ENTREGAR'
    )

    session.add(route)
    await session.commit()
    await session.refresh(route)

    return route


@contextmanager
def _mock_db_time(*, model, time=datetime(2025, 1, 1)):
    def fake_time_hook(mapper, connection, target):
        if hasattr(target, 'created_at'):
            target.created_at = time
        if hasattr(target, 'updated_at'):
            target.updated_at = time

    event.listen(model, 'before_insert', fake_time_hook)

    yield time

    event.remove(model, 'before_insert', fake_time_hook)


@pytest.fixture
def mock_db_time():
    return _mock_db_time

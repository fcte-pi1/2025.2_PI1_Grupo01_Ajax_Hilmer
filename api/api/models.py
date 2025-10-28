from datetime import datetime
from enum import Enum

from sqlalchemy import ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, registry

table_registry = registry()


class StatusState(str, Enum):
    success = 'success'
    failed = 'failed'


@table_registry.mapped_as_dataclass
class Route:
    __tablename__ = 'routes'

    id: Mapped[int] = mapped_column(init=False, primary_key=True)
    commands: Mapped[str] = mapped_column(unique=True)
    created_at: Mapped[datetime] = mapped_column(
        init=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        init=False, server_default=func.now(), onupdate=func.now()
    )


@table_registry.mapped_as_dataclass
class Telemetry:
    __tablename__ = 'telemetries'

    id: Mapped[int] = mapped_column(init=False, primary_key=True)
    average_speed: Mapped[float]
    distance_traveled: Mapped[float]
    energy_consumed: Mapped[float]
    average_current: Mapped[float]
    status: Mapped[StatusState]
    created_at: Mapped[datetime] = mapped_column(
        init=False, server_default=func.now()
    )
    route_id: Mapped[int] = mapped_column(ForeignKey('routes.id'))

from datetime import datetime

from pydantic import BaseModel


class RouteSchema(BaseModel):
    commands: str


class RoutePublic(RouteSchema):
    id: int


class RoutePublicList(RoutePublic):
    routes: list[RoutePublic]


class TelemetrySchema(BaseModel):
    average_speed: float
    distance_traveled: float
    energy_consumed: float
    average_current: float
    status: str


class TelemetryPublic(TelemetrySchema):
    id: int
    created_at: datetime


class TelemetryPublicList(TelemetryPublic):
    telemetries: list[TelemetryPublic]


class Message(BaseModel):
    message: str

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class RouteSchema(BaseModel):
    commands: str


class RoutePublic(RouteSchema):
    id: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)


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
    model_config = ConfigDict(from_attributes=True)


class TelemetryPublicList(TelemetryPublic):
    telemetries: list[TelemetryPublic]


class Message(BaseModel):
    message: str


class FilterPage(BaseModel):
    offset: int = Field(ge=0, default=0)
    limit: int = Field(ge=0, default=10)

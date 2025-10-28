from pydantic import BaseModel, ConfigDict, Field

from api.models import StatusState


class RouteSchema(BaseModel):
    commands: str


class RoutePublic(RouteSchema):
    id: int
    model_config = ConfigDict(from_attributes=True)


class RoutePublicList(RoutePublic):
    routes: list[RoutePublic]


class TelemetrySchema(BaseModel):
    average_speed: float
    distance_traveled: float
    energy_consumed: float
    average_current: float
    status: StatusState


class TelemetryPublic(TelemetrySchema):
    id: int
    model_config = ConfigDict(from_attributes=True)


class TelemetryPublicList(TelemetryPublic):
    telemetries: list[TelemetryPublic]


class Message(BaseModel):
    message: str


class FilterPage(BaseModel):
    offset: int = Field(ge=0, default=0)
    limit: int = Field(ge=0, default=10)

from pydantic import BaseModel
from datetime import datetime


class RotaSchema(BaseModel):
    comandos: str


class TelemetriaSchema(BaseModel):
    data_criacao: datetime
    velocidade_media: float
    distancia_percorrida: float
    energia_consumida: float
    corrente_media: float
    status: str
    id_rota: int
    
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from http import HTTPStatus
from schemas import (
    RotaSchema, RotaSchemaDB, ListRotaSchema, 
    TelemetriaSchema, TelemetriaSchemaDB, ListTelemetriaSchema
)

# para rodar o server (precisa estar dentro da pasta backend): fastapi dev server.py


app = FastAPI(title='Backend - Projeto Integrador I 2025.2 (Carrinho entregador)')

@app.post(
    '/rota/', 
    status_code=HTTPStatus.CREATED,
    response_class=JSONResponse,
    response_model=RotaSchemaDB
)
async def cadastrar_rota(rota: RotaSchema):
    """
    Cadastra uma nova rota.
    
    Args:
        rota: Schema contendo os comandos da rota (separados por ';')
        
    Returns:
        RotaSchemaDB: A rota cadastrada
    """
    pass


@app.post(
    '/telemetria/',
    status_code=HTTPStatus.CREATED,
    response_class=JSONResponse,
    response_model=TelemetriaSchemaDB
)
async def cadastrar_telemetria(telemetria: TelemetriaSchema):
    """
    Cadastra uma nova telemetria relacionada a uma rota.
    
    Args:
        data_criacao: datetime
        velocidade_media: float
        distancia_percorrida: float
        energia_consumida: float
        corrente_media: float
        status: str
        id_rota: int
    
    Returns:
        TelemetriaSchemaDB: A telemetria cadastrada
    """
    pass


@app.get(
    '/rotas/{rota_id}',
    status_code=HTTPStatus.OK,
    response_class=JSONResponse,
    response_model=RotaSchemaDB
)
async def ver_rota(rota_id: int):
    """
    Visualiza uma rota específica passando o id
    
    Args:
        rota_id: int
    
    Returns:
        RotaSchemaDB: A rota com o id passado

    Raises:
        HTTPException se o id passado não pertence a uma rota cadastrada
    """
    pass


@app.get(
    '/telemetrias/{telemetria_id}',
    status_code=HTTPStatus.OK,
    response_class=JSONResponse,
    response_model=TelemetriaSchemaDB
)
async def ver_telemetria(telemetria_id: int):
    """
    Visualiza uma telemetria específica passando o id
    
    Args:
        telemetria_id: int
    
    Returns:
        TelemetriaSchemaDB: A telemetria com o id passado

    Raises:
        HTTPException se o id passado não pertence a uma telemetria cadastrada
    """
    pass


@app.get(
    '/rotas/',
    status_code=HTTPStatus.OK,
    response_class=JSONResponse,
    response_model=ListRotaSchema
)
async def ver_rotas():
    """
    Visualiza todas as rotas cadastradas
    
    Args:
        None
    
    Returns:
        ListRotaSchema: lista de rotas cadastradas
    """
    pass


@app.get(
    '/telemetrias/',
    status_code=HTTPStatus.OK,
    response_class=JSONResponse,
    response_model=ListTelemetriaSchema
)
async def ver_telemetrias():
    """
    Visualiza todas as telemetrias cadastradas
    
    Args:
        None
    
    Returns:
        ListTelemetriaSchema: lista de telemetrias cadastradas
    """
    pass
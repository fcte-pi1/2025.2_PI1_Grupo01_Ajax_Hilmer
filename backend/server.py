from fastapi import FastAPI, HTTPException
from http import HTTPStatus
from schemas import RotaSchema


app = FastAPI()

@app.post(
    '/rota', 
    status_code=HTTPStatus.CREATED, 
    response_model=RotaSchema
    )
async def cadastrar_rota(rota: RotaSchema):
    """
    Cadastra uma nova rota e envia os comandos via Bluetooth para o dispositivo.
    
    Args:
        rota: Schema contendo os comandos da rota (separados por ';')
        
    Returns:
        RotaSchema: A rota cadastrada
        
    Raises:
        HTTPException: Se houver erro ao enviar comandos via Bluetooth
    """
    
# para rodar comando: fastapi dev nome_arquivo.py
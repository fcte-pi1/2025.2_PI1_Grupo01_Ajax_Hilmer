from fastapi import FastAPI

from api.routers import route, telemetry

app = FastAPI(title='API Projeto Integrador de Engenharia I')

app.include_router(route.router)
app.include_router(telemetry.router)

#!/bin/sh

# Executar migrações
poetry run alembic upgrade head

# Iniciar aplicação
poetry run uvicorn --host 0.0.0.0 --port 8000 api.app:app
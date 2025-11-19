FROM python:3.12-slim
ENV POETRY_VIRTUALENVS_CREATE=false

WORKDIR /app

COPY api/pyproject.toml api/poetry.lock api/README.md ./
COPY api/api/ ./api/
COPY api/migrations/ ./migrations/
COPY api/entrypoint.sh api/alembic.ini ./

RUN pip install poetry
RUN poetry config installer.max-workers 10
RUN poetry install --no-interaction --no-ansi --without dev
RUN chmod +x entrypoint.sh

EXPOSE 8000

CMD ["./entrypoint.sh"]

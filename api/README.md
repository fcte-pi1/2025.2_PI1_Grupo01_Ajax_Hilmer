# Backend do Projeto

## Como configurar o ambiente de desenvolvimento

### Instalação

> O ambiente foi configurado para Linux, para demais sistemas operacionais, pesquisar como baixar os seguintes pacotes

#### pipx

```bash
sudo apt install pipx
```

#### poetry

```bash
pipx install poetry 
pipx inject poetry poetry-plugin-shell
```

#### Para instalar as demais dependências, entre na mesma pasta do `pyproject.toml` e rode os seguintes comandos

```bash
poetry install
```

## Como Rodar o Projeto

> Algumas dependências de desenvolvimento foram utilizadas: `ruff` e `taskipy`

- **Antes de rodar qualquer parte do código, sempre utilize o seguinte comando para formatar o código de acordo com os padrões estabelecidos**

```bash
task format
```

**Para rodar os testes, utilize o seguinte comando:**

```bash
task test
```

**Para rodar o backend, utilize o seguinte comando:**

```bash
task run
```

Para acessar a API só abrir o seguinte link depois que rodar o servidor:

[http://127.0.0.1:8000](http://127.0.0.1:8000)

Para acessar a documentação (Swagger) da aplicação:

[http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

## Organização do Projeto

O backend do projeto está organizado da seguinte forma:

```bash
├── alembic.ini
├── api
│   ├── app.py
│   ├── database.py
│   ├── models.py
│   ├── routers
│   │   ├── route.py
│   │   └── telemetry.py
│   ├── schemas.py
│   └── settings.py
├── database.db
├── htmlcov
├── migrations
│   ├── env.py
│   ├── script.py.mako
│   └── versions
├── poetry.lock
├── pyproject.toml
├── README.md
└── tests
    ├── conftest.py
    ├── __init__.py
    ├── test_db.py
    └── test_routes.py
    └── test_telemetries.py
```

> Para gerar a estrutura do projeto, basta rodar o seguinte comando: `tree -I '__pycache__|.git|*.pyc'`

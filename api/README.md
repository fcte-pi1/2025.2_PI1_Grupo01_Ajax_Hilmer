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

#### Para instalar as demais dependências, esteja no mesmo `*path*` do `pyproject.toml` e rode os seguintes comandos

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

> Cobertura de testes atualmente em 100%

```bash
Name                       Stmts   Miss  Cover
----------------------------------------------
api/__init__.py                0      0   100%
api/app.py                     5      0   100%
api/database.py                3      0   100%
api/models.py                 28      0   100%
api/routers/route.py          53      0   100%
api/routers/telemetry.py      40      0   100%
api/schemas.py                25      0   100%
api/settings.py                4      0   100%
----------------------------------------------
TOTAL                        158      0   100%
```

**Para subir o backend:**

```bash
docker compose up --build
```

Para acessar a API só abrir o seguinte link depois que rodar o servidor:

[http://0.0.0.0:8000/](http://0.0.0.0:8000/)

Para acessar a documentação (Swagger) da aplicação:

[http://0.0.0.0:8000/docs](http://0.0.0.0:8000/docs)


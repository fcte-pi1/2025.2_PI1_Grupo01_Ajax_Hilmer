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

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

**Antes de rodar qualquer parte do código, sempre utilize o seguinte comando para formatar o código de acordo com os padrões estabelecidos**

```bash
task format
```

**Para rodar o backend, utilize o seguinte comando:**

```bash
task run
```

**Para rodar os testes, utilize o seguinte comando:**

```bash
task test
```


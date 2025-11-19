
## Guia rápido para rodar o aplicativo mobile.

## O que você precisa ter instalado

* **Flutter SDK:** Versão 3.30 ou superior (Stable channel).
* **VS Code:** Com as extensões oficiais do **Flutter** e **Dart**.
* **Dispositivo:**
    * Celular Android físico (conectado via USB) -> **Obrigatório para testar Bluetooth**.
    * Emulador Android -> Serve apenas para ver telas e testar API.

## Configuração do .env

O projeto usa variáveis de ambiente para saber onde está a API.

1.  Crie um arquivo chamado **`.env`** na raiz desta pasta (`app/`).
2.  Cole o seguinte conteúdo dentro dele:
``API_BASE_URL=http://localhost:8000``

## Como rodar

1. Com o backend rodando, abra o terminal na pasta `app/`
2. Baixe as dependências:

``flutter pub get``

3. Conecte seu celular (com Depuração USB ativa) ou abra o emulador via android studio.

4. Inicie o app com o comando:

``flutter run``
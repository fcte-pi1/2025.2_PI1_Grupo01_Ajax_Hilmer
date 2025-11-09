# Hardware aqui


## Comunicação Bluetooth Low Energy (BLE)

O controle do carrinho é baseado em **Bluetooth Low Energy (BLE)** utilizado na arquitetura **GATT (Generic Attribute Profile)**.

Para funcionar, o ESP32 atua como o **Servidor** (GATT Server) e hospeda os canais de comunicação enquanto o Computador (Interface Gráfica) atua como o **Cliente** (GATT Client) ao enviar comandos e receber a telemetria.

### Canais de Comunicação

Foram definidos dois canais principais, cada um com uma finalidade e fluxo de dados específicos:

| Característica | Fluxo de Dados | Tipo GATT | Função Essencial |
| :--- | :--- | :--- | :--- |
| **Comando (CMD)** | Cliente $\rightarrow$ Servidor | `WRITE` (Escrita) | **RECEBER COMANDOS** de movimento e servo (ex: `FRENTE`, `SERVO_A:90`). |
| **Dados (DATA)** | Servidor $\rightarrow$ Cliente | `NOTIFY` (Notificação) | **ENVIAR TELEMETRIA** (status de sensores e bateria) em tempo real. |

### Funcionamento 

1.  **Comandos:** O Cliente escreve no canal **CMD** e o ESP32 recebe a interrupção (`_IRQ_GATTS_WRITE`), decodifica o comando e o insere em uma **fila** para execução segura no *loop* principal.
2.  **Telemetria:** O *loop* principal periodicamente coleta os dados dos sensores e os envia proativamente (push) para o Cliente através da **Notificação (`NOTIFY`)** no canal **DATA**.

A lógica de conexão, anúncio e tratamento de interrupções é gerenciada integralmente pela classe **`lib/ble_manager.py`**.

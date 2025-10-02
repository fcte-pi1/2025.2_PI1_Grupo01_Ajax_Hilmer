# Diagramas

## Diagrama BPMN

![Diagrama BPMN](diagramas/diagrama_bpmn.svg)

## Casos de Uso

## Diagrama Entidade-Relacionamento (DER)

![DER](diagramas/der_pi1.png)

## Análise de Dados

Com base nos requisitos definidos e na modelagem do banco de dados, a análise será realizada sobre as variáveis de telemetria coletadas durante a execução das rotas. As variáveis consideradas são:

- **Velocidade média**: avalia o desempenho do veículo em diferentes rotas.  
- **Corrente média**: permite estimar o consumo elétrico do sistema.  
- **Tensão de operação**: monitora as condições de alimentação do veículo.  
- **Energia consumida (J)**: calculada a partir da relação entre tensão, corrente e tempo de uso.  
- **Distância percorrida**: associada diretamente ao desempenho físico do veículo.  
- **Tempo de execução**: obtido a partir do intervalo entre início e fim de cada rota.  
- **Status de execução**: indica se a operação foi concluída corretamente ou se ocorreram falhas.  

A análise numérica será conduzida por meio de tabelas contendo valores coletados, possibilitando o cálculo de médias, máximos, mínimos e comparações entre diferentes execuções.  

Complementarmente, a análise gráfica será realizada por meio de representações visuais, como gráficos de barras, linhas e dispersão, permitindo identificar tendências, padrões e correlações entre variáveis — por exemplo, entre *velocidade média* e *energia consumida*.  

O tempo total de cada execução será calculado a partir dos campos `hora_inicio` e `hora_fim` registrados na entidade **Rota**, conforme a equação: *tempo_rota = hora_fim - hora_inicio*


Esse indicador possibilita avaliar a eficiência global da rota e identificar possíveis gargalos no percurso.  

Adicionalmente, será gerada uma representação gráfica da trajetória percorrida pelo carrinho, construída a partir das instruções armazenadas na entidade **Instrução**. Cada comando de *giro* ajusta a orientação do veículo, enquanto os comandos de *deslocamento* determinam a progressão em coordenadas `(x,y)`. Os pontos sucessivos serão conectados em um gráfico bidimensional, fornecendo uma visualização intuitiva da rota executada.  

Com essa abordagem, o sistema permite não apenas a avaliação quantitativa das variáveis de desempenho, mas também a interpretação visual do comportamento do veículo em diferentes rotas.

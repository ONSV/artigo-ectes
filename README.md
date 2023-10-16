# Artigo ECTES

## Objetivo

Este projeto consiste de um modelo classificador baseado em dados de vítimas fatais de sinistros de trânsito, com o objetivo de detectar vítimas ocupantes de motocicleta. Os resultados serão incluídos em um resumo de congresso, elaborado pelo Observatório Nacional de Segurança Viária (ONSV), que será submetido ao 23º *European Congress of Trauma and Emergency Surgery* (ECTES).

## Método

Os dados brutos foram coletados do servidor do DATASUS com auxílio do pacote [`microdatasus`](https://github.com/rfsaldanha/microdatasus), e armazenados em `data/`. O script `R/main.R` controla a execução do projeto. Para o ajuste do modelo classificador, foi utilizada uma Regressão Logística, com a seguinte relação de funções criada e disponível em `R/script.R`:

|Função|Argumentos|Retorno|
|:---|:---|:---|
|`data_prep()`|`x`: dados a serem preparados para o modelo|Dados processados|
|`get_best_cvfold()`|`x`: dados para Cross Validation|Subconjunto de melhor ajuste|
|`train_test_split()`|`x`: dados preparados para separação de teste e treino|Lista com conjuntos de teste e treino|
|`log_modeller()`|`x`: dados para ajuste do modelo (subconjunto da Cross Validation), `test`: conjunto de teste|Modelo ajustado, predições, métricas e coeficientes|

## Estrutura dos Arquivos

-   `report/` contém relatórios sobre o processo de criação do modelo
-   `data-raw/` possui dados brutos e scripts de extração desses dados
-   `data/` possui os dados tratados utilizados no modelo
-   `R/` inclui os scripts com o modelo final

# Artigo ECTES

- [Objetivo](#objetivo)
- [Método](#método)
- [Estrutura dos Arquivos](#estrutura-dos-arquivos)

## Objetivo 

Este projeto pretende criar um modelo classificador a partir de dados de acidentes fatais em trânsito para detectar vítimas que são motociclistas motociclistas, confeccionado com o intuito de gerar um abstrato científico do Observatório Nacional de Segurança Viária (ONSV) que será submetido ao 23º *European Congress of Trauma and Emergency Surgery* (ECTES).

## Método 

Os dados brutos foram coletados a partir da API [`microdatasus`](https://github.com/rfsaldanha/microdatasus), e armazenados em `data/`. O script `R/main.R` retorna todos os valores e estruturas gerados pelas funções criadas durante o presente projeto. Para o ajuste do modelo classificador, foi utilizada uma Regressão Logística, com a seguinte relação de funções criada e disponível em `R/`:

+----------------------+--------------------------------------------------------------------+-----------------------------------------------------+
| Função               | Argumentos                                                         | Retorno                                             |
+:====================:+:==================================================================:+=====================================================+
| `data_prep()`        | `x`: dados a serem preparados para o modelo                        | Dados processados                                   |
+----------------------+--------------------------------------------------------------------+-----------------------------------------------------+
| `get_best_cvfold()`  | `x`: dados para Cross Validation                                   | Subconjunto de melhor ajuste                        |
+----------------------+--------------------------------------------------------------------+-----------------------------------------------------+
| `train_test_split()` | `x`: dados preparados para separação de teste e treino             | Lista com conjuntos de teste e treino               |
+----------------------+--------------------------------------------------------------------+-----------------------------------------------------+
| `log_modeller()`     | `x`: dados para ajuste do modelo (subconjunto da Cross Validation) | Modelo ajustado, predições, métricas e coeficientes |
|                      |                                                                    |                                                     |
|                      | `test`: conjunto de teste                                          |                                                     |
+----------------------+--------------------------------------------------------------------+-----------------------------------------------------+

## Estrutura dos Arquivos
- `report/` contém relatórios sobre o processo de criação do modelo
- `data-raw/` possui dados brutos e scripts de extração deles
- `data/` possui os dados tratados utilizados no modelo
- `R/` possui o modelo e as funções criadas para previsão
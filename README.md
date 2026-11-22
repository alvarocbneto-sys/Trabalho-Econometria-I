# Trabalho Final de Econometria I – FGV EESP (2026.2)

Autores: Álvaro Cardoso Bastos Neto e Eduardo Simis

## Pergunta
A desigualdade de renda, a desocupação e a educação influenciam a taxa de homicídios nos municípios brasileiros com 60 mil habitantes ou mais?

## Dados (cross-section, 498 municípios, Censo 2010)
| Variável | Fonte |
|---|---|
| Óbitos por agressões (CID-10 X85–Y09), por residência, 2011–2013 | SIM/DataSUS (Ministério da Saúde) |
| Gini, desocupação, escolaridade esperada, renda per capita | Atlas do Desenvolvimento Humano (PNUD/IPEA/FJP) |
| População total e urbana | IBGE/SIDRA, tabela 202 |
| Homens de 15 a 29 anos | IBGE/SIDRA, tabela 1552 |
| Área territorial | IBGE/SIDRA, tabela 1301 |
| Óbitos de intenção indeterminada (CID-10 Y10–Y34), por residência, 2011–2013 (checagem do SIM) | SIM/DataSUS (Ministério da Saúde) |

Variável dependente: `taxa_homicidio` = óbitos de 2011–2013 / (população 2010 × 3) × 100.000. Nas regressões usa-se ln(taxa).

## Estrutura
- `dados/brutos/`: arquivos originais baixados das fontes
- `dados/final/base_final.csv`: base usada na análise (498 municípios, 28 variáveis)
- `dados/final/base_todos_municipios_2010.csv`: base com todos os 5.565 municípios
- `codigo/01_monta_base.R`: construção da base
- `codigo/02_importa_checa.R`: importação e checagem da base
- `codigo/03_descritiva.R`: estatísticas descritivas e gráficos exploratórios
- `codigo/04_regressao.R`: modelos M1 e M2, erros-padrão, diagnósticos
- `codigo/05_robustez.R`: tabela de robustez
- `codigo/06_figuras.R`: figuras do artigo
- `codigo/07_tabelas.R`: tabelas do artigo (regressões, ajuste, descritivas e teste F das dummies de região)
- `codigo/08_checagem_sim.R`: checagem do SIM com óbitos de intenção indeterminada (taxa ampla e municípios marcados)
- `tabelas/`: saídas dos scripts 05 e 07 (robustez, regressão, ajuste, descritivas e teste das dummies)
- `figuras/`: figuras do artigo (PNG)

## Método
Regressão linear múltipla (MQO) com ln(taxa de homicídios) como variável dependente. Erros-padrão robustos HC3 nas especificações principais. Na robustez: HC1, erros-padrão clusterizados por UF (estatística t com 26 graus de liberdade), exclusão de Luís Eduardo Magalhães, MQO ponderado pela população, dummies de UF (sem RR e DF, que têm um único município) e taxa ampla, que soma aos óbitos por agressão os de intenção indeterminada.

## Reprodução
1. Instalar os pacotes: `install.packages(c("readxl", "zoo", "sandwich", "lmtest", "ggplot2"))`.
2. Com a raiz do repositório como diretório de trabalho, rodar os scripts de `codigo/` em ordem numérica, de 01 a 08.
3. O script 01 gera `dados/final/base_final.csv`; o 05 gera `tabelas/robustez.csv`; o 06 gera as figuras em `figuras/`; o 07 gera as tabelas do artigo; o 08 imprime a checagem do SIM.

## Notas
- A base foi construída primeiro em Python e depois portada para R; a saída em R foi comparada com a original por `all.equal` e é idêntica.
- O VIF é calculado por `diag(solve(cor(model.matrix(m2)[, -1])))`, porque o pacote `car` não pôde ser instalado.

## Uso de IA
Os links públicos das conversas com IA estão no artigo.

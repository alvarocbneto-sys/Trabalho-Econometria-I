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

Variável dependente: `taxa_homicidio` = óbitos de 2011–2013 / (população 2010 × 3) × 100.000.

## Estrutura
- `dados/brutos/`: arquivos originais baixados das fontes
- `dados/final/base_final.csv`: base usada na análise (498 municípios, 28 variáveis)
- `codigo/01_monta_base.py`: construção da base (Python)
- `codigo/02_*.R` em diante: análise (R)

## Método
Regressão linear múltipla (MQO) com erros-padrão robustos.

## Reprodução
1. Rodar `codigo/01_monta_base.py` (pandas, numpy, openpyxl).
2. Rodar os scripts em R na ordem numérica.

## Uso de IA
Os links públicos das conversas com IA estão no artigo.


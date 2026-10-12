import numpy as np
import pandas as pd
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BRUTOS = RAIZ / "dados" / "brutos"
FINAL = RAIZ / "dados" / "final"
FINAL.mkdir(parents=True, exist_ok=True)

# 1) Atlas do Desenvolvimento Humano: indicadores do Censo 2010 por município
atlas = pd.read_excel(BRUTOS / "atlas_censo_total_1991_2010.xlsx", sheet_name="MUN 91-00-10")
atlas = atlas[atlas["ANO"] == 2010].copy()
atlas["cod7"] = atlas["Codmun7"].astype(int).astype(str)
atlas["cod6"] = atlas["Codmun6"].astype(int)
atlas = atlas.rename(columns={
    "Município": "municipio", "GINI": "gini", "T_DES18M": "desocupacao",
    "T_ANALF18M": "analfabetismo", "E_ANOSESTUDO": "anos_estudo_esperados",
    "RDPC": "renda_pc", "T_NESTUDA_NTRAB_MMEIO": "nem_nem_vulneravel",
})
atlas = atlas[["cod7", "cod6", "municipio", "gini", "desocupacao", "analfabetismo",
               "anos_estudo_esperados", "renda_pc", "nem_nem_vulneravel"]]

# 2) SIDRA 202: população total e urbana (o código só aparece na 1ª linha, por isso o ffill)
p202 = pd.read_excel(BRUTOS / "sidra_202_populacao_2010.xlsx", sheet_name=0, header=None, skiprows=5, dtype=str)
p202 = p202.iloc[:, :4]
p202.columns = ["cod7", "nome", "situacao", "pop"]
p202["cod7"] = p202["cod7"].ffill()
p202["nome"] = p202["nome"].ffill()
p202 = p202[p202["cod7"].str.fullmatch(r"\d{7}", na=False)]
p202["pop"] = pd.to_numeric(p202["pop"], errors="coerce")
pop = p202.pivot_table(index="cod7", columns="situacao", values="pop", aggfunc="first")
pop = pop.rename(columns={"Total": "pop_total", "Urbana": "pop_urbana"})[["pop_total", "pop_urbana"]].reset_index()
pop["pct_urbano"] = 100 * pop["pop_urbana"] / pop["pop_total"]

# 3) SIDRA 1552: homens de 15 a 19, 20 a 24 e 25 a 29 anos (somados)
p1552 = pd.read_excel(BRUTOS / "sidra_1552_homens_idade_2010.xlsx", sheet_name=0, header=None, skiprows=6, dtype=str)
p1552 = p1552.iloc[:, :5]
p1552.columns = ["cod7", "nome", "forma", "idade", "homens"]
p1552["cod7"] = p1552["cod7"].ffill()
p1552 = p1552[p1552["cod7"].str.fullmatch(r"\d{7}", na=False)]
p1552["homens"] = pd.to_numeric(p1552["homens"], errors="coerce")
jovens = p1552.groupby("cod7")["homens"].sum(min_count=3).rename("homens_15_29").reset_index()

# 4) SIDRA 1301: área do município em km²
p1301 = pd.read_excel(BRUTOS / "sidra_1301_area_densidade_2010.xlsx", sheet_name=0, header=None, skiprows=4, dtype=str)
p1301 = p1301.iloc[:, :3]
p1301.columns = ["cod7", "nome", "area_km2"]
p1301 = p1301[p1301["cod7"].str.fullmatch(r"\d{7}", na=False)]
p1301["area_km2"] = pd.to_numeric(p1301["area_km2"], errors="coerce")
area = p1301[["cod7", "area_km2"]]

# 5) DataSUS/SIM: óbitos por agressões (X85-Y09), por residência, 2011-2013; "-" significa zero
sim = pd.read_csv(BRUTOS / "datasus_agressoes_2011_2013.csv", sep=";", encoding="latin1", skiprows=5)
sim.columns = [c.strip() for c in sim.columns]
sim = sim.rename(columns={sim.columns[0]: "mun"})
sim = sim[sim["mun"].str[:6].str.fullmatch(r"\d{6}", na=False)].copy()
sim["cod6"] = sim["mun"].str[:6].astype(int)
for ano in ["2011", "2012", "2013"]:
    sim["obitos_" + ano] = pd.to_numeric(sim[ano].replace("-", "0"), errors="coerce").fillna(0)
sim = sim[["cod6", "obitos_2011", "obitos_2012", "obitos_2013"]]

# 6) Junta tudo pelo código do município
df = (atlas.merge(pop, on="cod7", how="left")
           .merge(jovens, on="cod7", how="left")
           .merge(area, on="cod7", how="left")
           .merge(sim, on="cod6", how="left"))
for ano in ["2011", "2012", "2013"]:
    df["obitos_" + ano] = df["obitos_" + ano].fillna(0)

# 7) Variáveis construídas
df["obitos_3anos"] = df[["obitos_2011", "obitos_2012", "obitos_2013"]].sum(axis=1)
df["taxa_homicidio"] = df["obitos_3anos"] / (df["pop_total"] * 3) * 100000
df["pct_jovens_homens"] = 100 * df["homens_15_29"] / df["pop_total"]
df["densidade"] = df["pop_total"] / df["area_km2"]
df["ln_renda_pc"] = np.log(df["renda_pc"])
df["ln_pop"] = np.log(df["pop_total"])

# 8) Grande região (1º dígito do código IBGE) e dummies; Sudeste é a categoria-base
nomes_regiao = {"1": "Norte", "2": "Nordeste", "3": "Sudeste", "4": "Sul", "5": "Centro-Oeste"}
df["regiao"] = df["cod7"].str[0].map(nomes_regiao)
for r in ["Norte", "Nordeste", "Sul", "Centro-Oeste"]:
    df["d_" + r.lower().replace("-", "_")] = (df["regiao"] == r).astype(int)

# 9) Salva a base completa e a amostra (60 mil habitantes ou mais)
df.to_csv(FINAL / "base_todos_municipios_2010.csv", index=False, encoding="utf-8-sig")
amostra = df[df["pop_total"] >= 60000].copy()
amostra.to_csv(FINAL / "base_final.csv", index=False, encoding="utf-8-sig")
amostra.to_excel(FINAL / "base_final.xlsx", index=False)

print("municípios no Atlas:", len(df))
print("óbitos casados:", int(df["obitos_3anos"].sum()))
print("amostra >= 60 mil:", len(amostra), "| colunas:", amostra.shape[1])
print("valores faltantes na amostra:", int(amostra.isna().sum().sum()))
print(amostra["regiao"].value_counts())
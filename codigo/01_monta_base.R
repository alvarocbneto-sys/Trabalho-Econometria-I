library(readxl)
library(zoo)
brutos <- "dados/brutos/"
le <- function(arq, pular, n) as.data.frame(read_excel(paste0(brutos, arq), sheet = 1, col_names = FALSE, skip = pular, col_types = "text"))[, 1:n]
atlas <- read_excel(paste0(brutos, "atlas_censo_total_1991_2010.xlsx"), sheet = "MUN 91-00-10", guess_max = 1e5)
atlas <- atlas[atlas$ANO == 2010, ]
df <- data.frame(cod7 = as.character(as.integer(atlas$Codmun7)), cod6 = as.integer(atlas$Codmun6), municipio = atlas[["Município"]], gini = atlas$GINI, desocupacao = atlas$T_DES18M, analfabetismo = atlas$T_ANALF18M, anos_estudo_esperados = atlas$E_ANOSESTUDO, renda_pc = atlas$RDPC, nem_nem_vulneravel = atlas$T_NESTUDA_NTRAB_MMEIO)
p202 <- le("sidra_202_populacao_2010.xlsx", 5, 4)
names(p202) <- c("cod7", "nome", "situacao", "pop")
p202$cod7 <- na.locf(p202$cod7, na.rm = FALSE)
p202 <- p202[grepl("^[0-9]{7}$", p202$cod7), ]
p202$pop <- suppressWarnings(as.numeric(p202$pop))
tot <- p202[p202$situacao == "Total", ]
urb <- p202[p202$situacao == "Urbana", ]
p1552 <- le("sidra_1552_homens_idade_2010.xlsx", 6, 5)
names(p1552) <- c("cod7", "nome", "forma", "idade", "homens")
p1552$cod7 <- na.locf(p1552$cod7, na.rm = FALSE)
p1552 <- p1552[grepl("^[0-9]{7}$", p1552$cod7), ]
p1552$homens <- suppressWarnings(as.numeric(p1552$homens))
soma <- tapply(p1552$homens, p1552$cod7, function(x) if (sum(!is.na(x)) >= 3) sum(x, na.rm = TRUE) else NA)
p1301 <- le("sidra_1301_area_densidade_2010.xlsx", 4, 3)
names(p1301) <- c("cod7", "nome", "area_km2")
p1301 <- p1301[grepl("^[0-9]{7}$", p1301$cod7), ]
p1301$area_km2 <- suppressWarnings(as.numeric(p1301$area_km2))
sim <- read.csv(paste0(brutos, "datasus_agressoes_2011_2013.csv"), sep = ";", skip = 5, fileEncoding = "latin1", check.names = FALSE, colClasses = "character", strip.white = TRUE)
names(sim) <- trimws(names(sim))
names(sim)[1] <- "mun"
sim <- sim[grepl("^[0-9]{6}$", substr(sim$mun, 1, 6)), ]
sim$cod6 <- as.integer(substr(sim$mun, 1, 6))
df$pop_total <- tot$pop[match(df$cod7, tot$cod7)]
df$pop_urbana <- urb$pop[match(df$cod7, urb$cod7)]
df$pct_urbano <- 100 * df$pop_urbana / df$pop_total
df$homens_15_29 <- as.numeric(soma[df$cod7])
df$area_km2 <- p1301$area_km2[match(df$cod7, p1301$cod7)]
for (a in c("2011", "2012", "2013")) {
  v <- suppressWarnings(as.numeric(ifelse(sim[[a]] == "-", "0", sim[[a]])))
  v[is.na(v)] <- 0
  w <- v[match(df$cod6, sim$cod6)]
  df[[paste0("obitos_", a)]] <- ifelse(is.na(w), 0, w)
}
df$obitos_3anos <- df$obitos_2011 + df$obitos_2012 + df$obitos_2013
df$taxa_homicidio <- df$obitos_3anos / (df$pop_total * 3) * 1e5
df$pct_jovens_homens <- 100 * df$homens_15_29 / df$pop_total
df$densidade <- df$pop_total / df$area_km2
df$ln_renda_pc <- log(df$renda_pc)
df$ln_pop <- log(df$pop_total)
df$regiao <- unname(c("1" = "Norte", "2" = "Nordeste", "3" = "Sudeste", "4" = "Sul", "5" = "Centro-Oeste")[substr(df$cod7, 1, 1)])
df$d_norte <- as.integer(df$regiao == "Norte")
df$d_nordeste <- as.integer(df$regiao == "Nordeste")
df$d_sul <- as.integer(df$regiao == "Sul")
df$d_centro_oeste <- as.integer(df$regiao == "Centro-Oeste")
dir.create("dados/final", showWarnings = FALSE, recursive = TRUE)
write.csv(df, "dados/final/base_todos_municipios_2010.csv", row.names = FALSE, fileEncoding = "UTF-8")
amostra <- df[df$pop_total >= 60000, ]
write.csv(amostra, "dados/final/base_final.csv", row.names = FALSE, fileEncoding = "UTF-8")
nrow(df)
nrow(amostra)
sum(is.na(amostra))
library(sandwich)
library(lmtest)
d <- read.csv("dados/final/base_final.csv", fileEncoding = "UTF-8-BOM")
d$ln_taxa <- log(d$taxa_homicidio)
d$ln_dens <- log(d$densidade)
d$uf <- substr(as.character(d$cod7), 1, 2)
f1 <- ln_taxa ~ gini + desocupacao + anos_estudo_esperados + ln_renda_pc + pct_jovens_homens + pct_urbano + ln_pop + ln_dens
f2 <- update(f1, . ~ . + d_norte + d_nordeste + d_sul + d_centro_oeste)
m1 <- lm(f1, d)
m2 <- lm(f2, d)
m3 <- lm(f2, d, weights = pop_total)
m4 <- lm(f2, d, subset = cod7 != 2919553)
m5 <- lm(update(f1, . ~ . + factor(uf)), d, subset = !uf %in% c("14", "53"))
ext <- function(nome, m, V, df = NULL) {
  ct <- coeftest(m, vcov = V, df = df)
  v <- c("gini", "desocupacao", "anos_estudo_esperados")
  data.frame(modelo = nome, var = v, beta = ct[v, 1], ep = ct[v, 2], p = ct[v, 4], row.names = NULL)
}
tab <- rbind(
  ext("M1 HC3", m1, vcovHC(m1, "HC3")),
  ext("M2 HC3", m2, vcovHC(m2, "HC3")),
  ext("M2 HC1", m2, vcovHC(m2, "HC1")),
  ext("M2 cluster UF", m2, vcovCL(m2, cluster = d$uf), 26),
  ext("M2 sem LEM HC3", m4, vcovHC(m4, "HC3")),
  ext("M2 WLS pop HC3", m3, vcovHC(m3, "HC3")),
  ext("UF dummies HC3 sem RR e DF", m5, vcovHC(m5, "HC3"))
)
tab[, 3:5] <- round(tab[, 3:5], 4)
tab
dir.create("tabelas", showWarnings = FALSE)
write.csv(tab, "tabelas/robustez.csv", row.names = FALSE)
g <- c("gini", "desocupacao", "anos_estudo_esperados", "ln_renda_pc")
for (k in 1:4) { m <- lm(reformulate(g[1:k], "ln_taxa"), d); print(coeftest(m, vcov = vcovHC(m, "HC3"))["gini", ]) }
b <- coef(m2)["gini"]
ic_hc3 <- b + c(-1, 1) * qt(0.975, df.residual(m2)) * sqrt(vcovHC(m2, "HC3")["gini", "gini"])
ic_cl <- b + c(-1, 1) * qt(0.975, 26) * sqrt(vcovCL(m2, cluster = d$uf)["gini", "gini"])
exp(sd(d$gini) * ic_hc3) - 1
exp(sd(d$gini) * ic_cl) - 1
v <- c("gini", "desocupacao", "anos_estudo_esperados")
q <- sapply(d[v], function(x) diff(quantile(x, c(0.25, 0.75))))
round(100 * (exp(cbind(coef(m2)[v], coefci(m2, vcov = vcovHC(m2, "HC3"))[v, ]) * q) - 1), 1)
mean(d$gini) * c(b, ic_hc3)

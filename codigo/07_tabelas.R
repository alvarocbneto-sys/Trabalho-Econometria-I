library(sandwich)
library(lmtest)
d <- read.csv("dados/final/base_final.csv", fileEncoding = "UTF-8-BOM")
d$ln_taxa <- log(d$taxa_homicidio)
d$ln_dens <- log(d$densidade)
f1 <- ln_taxa ~ gini + desocupacao + anos_estudo_esperados + ln_renda_pc + pct_jovens_homens + pct_urbano + ln_pop + ln_dens
f2 <- update(f1, . ~ . + d_norte + d_nordeste + d_sul + d_centro_oeste)
m1 <- lm(f1, d)
m2 <- lm(f2, d)
tab <- function(m) {
  ct <- coeftest(m, vcov = vcovHC(m, "HC3"))
  data.frame(variavel = rownames(ct), coef = ct[, 1], ep = ct[, 2], p = ct[, 4])
}
reg <- merge(tab(m1), tab(m2), by = "variavel", all = TRUE, suffixes = c("_m1", "_m2"))
reg <- reg[match(names(coef(m2)), reg$variavel), ]
ajuste <- data.frame(modelo = c("M1", "M2"), n = c(nobs(m1), nobs(m2)), r2 = c(summary(m1)$r.squared, summary(m2)$r.squared), r2_aj = c(summary(m1)$adj.r.squared, summary(m2)$adj.r.squared))
v <- c("taxa_homicidio", "gini", "desocupacao", "anos_estudo_esperados", "renda_pc", "pct_jovens_homens", "pct_urbano", "pop_total", "densidade")
q <- function(p) sapply(d[v], quantile, p, names = FALSE)
desc <- data.frame(variavel = v, media = sapply(d[v], mean), dp = sapply(d[v], sd), minimo = sapply(d[v], min), p25 = q(0.25), mediana = sapply(d[v], median), p75 = q(0.75), maximo = sapply(d[v], max))
w <- waldtest(m1, m2, vcov = function(x) vcovHC(x, "HC3"), test = "F")
dummies <- data.frame(teste = "dummies de regiao = 0 (HC3)", F = w$F[2], gl1 = abs(w$Df[2]), gl2 = w$Res.Df[2], p = w$`Pr(>F)`[2])
dir.create("tabelas", showWarnings = FALSE)
write.csv(reg, "tabelas/regressao.csv", row.names = FALSE)
write.csv(ajuste, "tabelas/ajuste.csv", row.names = FALSE)
write.csv(desc, "tabelas/descritivas.csv", row.names = FALSE)
write.csv(dummies, "tabelas/teste_dummies.csv", row.names = FALSE)


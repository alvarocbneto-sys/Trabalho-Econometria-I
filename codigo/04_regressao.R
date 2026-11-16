library(sandwich)
library(lmtest)
d <- read.csv("dados/final/base_final.csv", fileEncoding = "UTF-8-BOM")
d$ln_taxa <- log(d$taxa_homicidio)
d$ln_dens <- log(d$densidade)
d$uf <- substr(as.character(d$cod7), 1, 2)
f <- ln_taxa ~ gini + desocupacao + anos_estudo_esperados + ln_renda_pc + pct_jovens_homens + pct_urbano + ln_pop + ln_dens
m1 <- lm(f, d)
m2 <- update(m1, . ~ . + d_norte + d_nordeste + d_sul + d_centro_oeste)
coeftest(m1, vcov = vcovHC(m1, type = "HC3"))
coeftest(m2, vcov = vcovHC(m2, type = "HC3"))
coeftest(m2, vcov = vcovHC(m2, type = "HC1"))
coeftest(m2, vcov = vcovCL(m2, cluster = d$uf))
bptest(m2)
bptest(m2, ~ ln_pop, data = d)
cd <- cooks.distance(m2)
d[order(cd, decreasing = TRUE)[1:6], c("municipio", "regiao", "pop_total", "obitos_3anos", "taxa_homicidio")]
plot(d$ln_pop, resid(m2))
exp(0.01 * coef(m2)["gini"]) - 1
summary(m1)$r.squared
summary(m2)$r.squared
d$res <- resid(m2)
bptest(m2, ~ log(obitos_3anos), data = d)
tapply(d$res, d$uf, mean)
sd(d$gini)
quantile(d$gini, c(0.25, 0.75))
sum(cd > 4 / nrow(d))
d$esp <- d$pop_total * 3 * exp(fitted(m2)) / 1e5
bptest(m2, ~ log(esp), data = d)
coeftest(m2, vcov = vcovCL(m2, cluster = d$uf), df = 26)
diag(solve(cor(model.matrix(m2)[, -1])))
table(d$uf)

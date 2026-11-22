library(sandwich)
library(lmtest)
d <- read.csv("dados/final/base_final.csv", fileEncoding = "UTF-8-BOM")
ind <- read.csv("dados/brutos/datasus_indeterminadas_2011_2013.csv", sep = ";", skip = 5, fileEncoding = "latin1", check.names = FALSE, na.strings = "-")
ind$cod6 <- suppressWarnings(as.integer(substr(ind[[1]], 1, 6)))
ind$indet <- rowSums(ind[c("2011", "2012", "2013")], na.rm = TRUE)
d$indet <- ind$indet[match(d$cod6, ind$cod6)]
d$indet[is.na(d$indet)] <- 0
d$taxa_indet <- d$indet / (d$pop_total * 3) * 1e5
d$ln_ampla <- log((d$obitos_3anos + d$indet) / (d$pop_total * 3) * 1e5)
m <- lm(ln_ampla ~ gini + desocupacao + anos_estudo_esperados + ln_renda_pc + pct_jovens_homens + pct_urbano + ln_pop + log(densidade) + d_norte + d_nordeste + d_sul + d_centro_oeste, d)
coeftest(m, vcov = vcovHC(m, "HC3"))[2:4, ]
d[d$cod6 %in% c(291955, 290320), c("municipio", "obitos_3anos", "indet", "taxa_indet")]
summary(d$taxa_indet)
marca <- function(a, b) d$municipio[d$taxa_homicidio <= quantile(d$taxa_homicidio, a) & d$taxa_indet > quantile(d$taxa_indet, b)]
marca(0.1, 0.9)
marca(0.05, 0.95)
marca(0.15, 0.85)
table(d$regiao, d$taxa_indet > quantile(d$taxa_indet, 0.9))
r10 <- ave(d$taxa_homicidio, d$regiao, FUN = function(x) quantile(x, 0.1))
r90 <- ave(d$taxa_indet, d$regiao, FUN = function(x) quantile(x, 0.9))
d$municipio[d$taxa_homicidio <= r10 & d$taxa_indet > r90]

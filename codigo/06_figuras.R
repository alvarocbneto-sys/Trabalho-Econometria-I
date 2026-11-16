library(ggplot2)
d <- read.csv("dados/final/base_final.csv", fileEncoding = "UTF-8-BOM")
d$ln_taxa <- log(d$taxa_homicidio)
d$ln_dens <- log(d$densidade)
f2 <- ln_taxa ~ gini + desocupacao + anos_estudo_esperados + ln_renda_pc + pct_jovens_homens + pct_urbano + ln_pop + ln_dens + d_norte + d_nordeste + d_sul + d_centro_oeste
m2 <- lm(f2, d)
r <- read.csv("tabelas/robustez.csv")
r <- r[r$var == "gini", ]
dir.create("figuras", showWarnings = FALSE)
vc <- scales::label_number(decimal.mark = ",", big.mark = ".")
tema <- theme_classic(base_size = 11, base_family = "serif") + theme(axis.text = element_text(color = "black"), strip.background = element_blank(), strip.text = element_text(size = 11), legend.position = "bottom")
h <- rbind(data.frame(v = "Taxa de homicídios (por 100 mil)", x = d$taxa_homicidio), data.frame(v = "ln(taxa de homicídios)", x = d$ln_taxa))
h$v <- factor(h$v, levels = unique(h$v))
g1 <- ggplot(h, aes(x)) + geom_histogram(bins = 30, fill = "grey40", color = "white") + facet_wrap(~v, scales = "free_x") + scale_x_continuous(labels = vc) + labs(x = NULL, y = "Municípios") + tema
cores <- c("Centro-Oeste" = "#E69F00", "Nordeste" = "#D55E00", "Norte" = "#009E73", "Sudeste" = "#0072B2", "Sul" = "#CC79A7")
g3 <- ggplot(d, aes(gini, ln_taxa, color = regiao, shape = regiao)) + geom_point(alpha = 0.6, size = 1.6) + geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) + geom_smooth(aes(group = 1), method = "lm", se = FALSE, color = "black", linetype = "dashed", linewidth = 0.8) + scale_color_manual(values = cores) + scale_shape_manual(values = c(16, 17, 15, 18, 4)) + scale_x_continuous(labels = vc) + scale_y_continuous(labels = vc) + labs(x = "Índice de Gini", y = "ln(taxa de homicídios)", color = NULL, shape = NULL) + tema
g4 <- ggplot(data.frame(ln_pop = d$ln_pop, res = resid(m2)), aes(ln_pop, res)) + geom_point(color = "grey30", size = 1.3, alpha = 0.7) + geom_hline(yintercept = 0, linewidth = 0.4) + annotate("text", x = 11.1, y = -3.3, label = "Luís Eduardo Magalhães", hjust = 0, size = 3, family = "serif") + annotate("text", x = 11.95, y = -2.75, label = "Barreiras", hjust = 0, size = 3, family = "serif") + scale_x_continuous(labels = vc) + scale_y_continuous(labels = vc) + labs(x = "ln(população em 2010)", y = "Resíduo do modelo 2") + tema
lab <- c("M1 (HC3)", "M2 (HC3), principal", "M2 (HC1)", "M2 (cluster por UF)", "M2 sem Luís Eduardo Magalhães", "M2 ponderado por população", "Dummies de UF, sem RR e DF")
k <- ifelse(r$modelo == "M2 cluster UF", qt(0.975, 26), 1.96)
r$lo <- r$beta - k * r$ep
r$hi <- r$beta + k * r$ep
r$modelo <- factor(r$modelo, levels = rev(unique(r$modelo)), labels = rev(lab))
g5 <- ggplot(r, aes(beta, modelo)) + geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.4) + geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.5) + geom_point(size = 2) + scale_x_continuous(labels = vc) + labs(x = "Coeficiente do Gini (IC de 95%)", y = NULL) + tema
ggsave("figuras/distribuicao_taxa.png", g1, width = 6.3, height = 3, dpi = 300, bg = "white")
ggsave("figuras/gini_regiao.png", g3, width = 6.3, height = 4.2, dpi = 300, bg = "white")
ggsave("figuras/residuos_ln_pop.png", g4, width = 6.3, height = 3.5, dpi = 300, bg = "white")
ggsave("figuras/robustez_gini.png", g5, width = 6.3, height = 3.5, dpi = 300, bg = "white")
library(sandwich)
f3 <- function(x) format(round(x, 3), nsmall = 3, decimal.mark = ",")
vars <- c("gini", "desocupacao", "anos_estudo_esperados")
nomes <- c("Índice de Gini", "Taxa de desocupação (%)", "Anos esperados de estudo")
V <- vcovHC(m2, "HC3")
av <- do.call(rbind, lapply(1:3, function(i) {
  y <- resid(lm(update(f2, as.formula(paste(". ~ . -", vars[i]))), d))
  x <- resid(lm(update(f2, as.formula(paste(vars[i], "~ . -", vars[i]))), d))
  data.frame(v = paste0(nomes[i], "\nInclinação = ", f3(coef(m2)[vars[i]]), "\nEP (HC3) = ", f3(sqrt(V[vars[i], vars[i]]))), x = x, y = y)
}))
av$v <- factor(av$v, levels = unique(av$v))
g6 <- ggplot(av, aes(x, y)) + geom_point(color = "grey40", size = 1.2, alpha = 0.7) + geom_smooth(method = "lm", se = FALSE, color = "black", linewidth = 0.8) + facet_wrap(~v, scales = "free_x") + scale_x_continuous(labels = vc) + scale_y_continuous(labels = vc) + labs(x = "Resíduo da variável explicativa", y = "Resíduo de ln(taxa)") + tema + theme(strip.text = element_text(size = 9))
ggsave("figuras/regressao_parcial.png", g6, width = 6.3, height = 3.4, dpi = 300, bg = "white")
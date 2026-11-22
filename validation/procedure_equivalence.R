# -----------------------------------------------------------------------------
# EGAnetLab
# A jamovi module for Exploratory Graph Analysis and evidence-based
# methodological decision support on dimensional structure.
#
# Copyright (C) 2026 Arquímedes De León Chacón Chacón
#
# This file is part of EGAnetLab.
#
# EGAnetLab is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# EGAnetLab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EGAnetLab.
# If not, see https://www.gnu.org/licenses/.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Numerical equivalence of the optional procedures: EGAnetLab::ega() and
# EGAnetLab::dynega() vs. direct calls to EGAnet, NetworkComparisonTest and
# bootnet with the same options and seeds.
# ES: Equivalencia numérica de los procedimientos opcionales: EGAnetLab::ega()
# y EGAnetLab::dynega() frente a llamadas directas a EGAnet,
# NetworkComparisonTest y bootnet con las mismas opciones y semillas.
#
# It covers the 20 quantities of Table A1 of the EGAnetLab tutorial: the
# bootstrap, UVA, network loadings, riEGA, hierEGA, metric invariance, the
# NCT, the bootnet CS coefficient and dynamic EGA. The number of samples and
# permutations is reduced to keep the run short; equality does not depend on
# it, because both sides use the same seed and the same installed packages.
# ES: Cubre las 20 cantidades de la Tabla A1 del tutorial de EGAnetLab: el
# bootstrap, UVA, las cargas de red, riEGA, hierEGA, la invarianza métrica,
# la NCT, el coeficiente CS de bootnet y el EGA dinámico. El número de
# muestras y permutaciones se reduce para acortar la ejecución; la igualdad
# no depende de él, porque ambos lados usan la misma semilla y los mismos
# paquetes instalados.
#
# Run from the repository root: Rscript validation/procedure_equivalence.R
# -----------------------------------------------------------------------------

suppressMessages({
    library(EGAnet); library(NetworkComparisonTest); library(bootnet)
})

B <- 100      # bootstrap samples, permutations and bootnet samples
SEED <- 2026

est <- list(corr = "auto", na.data = "pairwise", model = "glasso",
            algorithm = "walktrap", uni.method = "louvain")
ega_args <- c(est, list(plot.EGA = FALSE, verbose = FALSE))
cell <- function(table, col, row_col = NULL, row = NULL) {
    df <- table$asDF
    if (!is.null(row_col)) df <- df[as.character(df[[row_col]]) == row, , drop = FALSE]
    df[[col]][1]
}
summary_value <- function(res, element) {
    s <- res$summary$asDF
    as.numeric(s$value[s$element == element][1])
}
quiet <- function(expr) suppressWarnings(suppressMessages(expr))

# Example 1: Big Five items (bfi) ---------------------------------------------
bfi <- utils::read.csv(file.path("data", "eganetlab_bfi.csv"))
items <- paste0(rep(c("A", "C", "E", "N", "O"), each = 5), 1:5)
neg <- c("A1", "C4", "C5", "E1", "E2", "O2", "O5")
x <- bfi[, items]
x_rev <- x
x_rev[neg] <- 7 - x_rev[neg]     # observed minimum + maximum - score
g <- as.character(bfi$gender)

# EGAnetLab, analysis 1: items as they are; bootstrap, UVA, bootnet.
lab1 <- quiet(do.call(EGAnetLab::ega, list(
    data = bfi, vars = items, runBoot = TRUE, iter = B, seed = SEED,
    runUVA = TRUE, runCentrality = TRUE, runBootnet = TRUE, bnIter = B,
    bnCaseIter = B, bnSeed = SEED, showNetworkPlot = FALSE)))
# EGAnetLab, analysis 2: negatively worded items declared as answered, so
# EGAnetLab reverses them for every procedure except riEGA.
# ES: análisis 2: ítems negativos declarados tal como se respondieron, así
# que EGAnetLab los invierte en todos los procedimientos salvo riEGA.
lab2 <- quiet(do.call(EGAnetLab::ega, list(
    data = bfi, vars = items, negItems = neg, negCoding = "raw",
    runHier = TRUE, runRI = TRUE, group = "gender", runInvariance = TRUE,
    invIter = B, runNCT = TRUE, nctIter = B, groupSeed = SEED,
    showNetworkPlot = FALSE)))

# Direct calls.
ega1 <- quiet(do.call(EGA, c(list(data = x), ega_args)))
set.seed(SEED)
boot1 <- quiet(do.call(bootEGA, c(list(data = x, iter = B, type = "parametric",
    ncores = 1, seed = SEED, plot.itemStability = FALSE, verbose = FALSE), est)))
stab1 <- quiet(dimensionStability(boot1, IS.plot = FALSE))
uva1 <- quiet(do.call(UVA, c(list(data = x, cut.off = 0.25, reduce = TRUE,
    reduce.method = "remove", verbose = FALSE), est)))
set.seed(SEED)
ri1 <- quiet(do.call(riEGA, c(list(data = x), ega_args)))
set.seed(SEED)
hier1 <- quiet(hierEGA(x_rev, corr = "auto", na.data = "pairwise", model = "glasso",
    uni.method = "louvain", plot.EGA = FALSE, verbose = FALSE))
ega1r <- quiet(do.call(EGA, c(list(data = x_rev), ega_args)))
set.seed(SEED)
inv1 <- quiet(do.call(invariance, c(list(data = x_rev, groups = g,
    structure = ega1r$wc, iter = B, configural.threshold = 0.70,
    configural.type = "parametric", ncores = 1, seed = SEED, verbose = FALSE), est)))
cc <- stats::complete.cases(x_rev)
set.seed(SEED)
nct1 <- quiet(NCT(x_rev[cc & g == "Male", ], x_rev[cc & g == "Female", ], it = B,
    test.centrality = TRUE, centrality = c("strength", "expectedInfluence"),
    p.adjust.methods = "holm", progressbar = FALSE, verbose = FALSE))
estimator <- function(d, ...) {
    net <- as.matrix(network.estimation(d, corr = "auto", na.data = "pairwise",
                                        model = "glasso", verbose = FALSE))
    dimnames(net) <- list(colnames(d), colnames(d)); net
}
set.seed(SEED)
net1 <- quiet(estimateNetwork(x, default = "none", fun = estimator,
                              labels = colnames(x), verbose = FALSE))
set.seed(SEED)
quiet(bootnet(net1, nBoots = B, type = "nonparametric", nCores = 1,
              statistics = "edge", verbose = FALSE))
set.seed(SEED)
case1 <- quiet(bootnet(net1, nBoots = B, type = "case", nCores = 1,
                       statistics = c("strength", "expectedInfluence"), verbose = FALSE))
cs1 <- quiet(corStability(case1, cor = 0.7,
                          statistics = c("strength", "expectedInfluence"), verbose = FALSE))
inv_p <- function(r, item) {
    r <- r$results
    if (!is.data.frame(r)) r <- r[[1]]
    r$p[rownames(r) == item]
}
freq <- function(b, k) b$frequency$Frequency[b$frequency$`# of Factors` == k]

# Example 2: dynamic EGA -------------------------------------------------------
dyn <- utils::read.csv(file.path("data", "eganetlab_dynamic_sim.csv"))
lab_dyn <- quiet(do.call(EGAnetLab::dynega, list(
    data = dyn, vars = paste0("V", 1:24), id = "ID", time = "Time",
    group = "Group", levelGroup = TRUE, levelIndividual = TRUE, seed = SEED,
    showNetworkPlot = FALSE, showIndPlot = FALSE)))
dyn_data <- data.frame(dyn[, paste0("V", 1:24)], ID = dyn$ID, Group = dyn$Group)
set.seed(SEED)
dyn1 <- quiet(dynEGA(dyn_data, id = "ID", group = "Group", n.embed = 5, tau = 1,
    delta = 1, use.derivatives = 1, level = c("population", "group", "individual"),
    corr = "auto", model = "glasso", algorithm = "walktrap",
    uni.method = "louvain", ncores = 1, verbose = FALSE))
ari <- function(a, b) {
    tab <- table(a, b); c2 <- function(v) v * (v - 1) / 2
    e <- sum(c2(rowSums(tab))) * sum(c2(colSums(tab))) / c2(length(a))
    m <- (sum(c2(rowSums(tab))) + sum(c2(colSums(tab)))) / 2
    (sum(c2(tab)) - e) / (m - e)
}

# Example 3: WMT-2 -------------------------------------------------------------
wmt <- utils::read.csv(file.path("data", "eganetlab_wmt2.csv"))
w_items <- paste0("wmt", 1:18)
lab3 <- quiet(do.call(EGAnetLab::ega, list(
    data = wmt, vars = w_items, runBoot = TRUE, iter = B, seed = SEED,
    showNetworkPlot = FALSE)))
ega3 <- quiet(do.call(EGA, c(list(data = wmt[, w_items]), ega_args)))
set.seed(SEED)
boot3 <- quiet(do.call(bootEGA, c(list(data = wmt[, w_items], iter = B,
    type = "parametric", ncores = 1, seed = SEED, plot.itemStability = FALSE,
    verbose = FALSE), est)))
stab3 <- quiet(dimensionStability(boot3, IS.plot = FALSE))

# Comparison ---------------------------------------------------------------------
lab_cs <- lab1$bnCS$asDF
rows <- list(
    c("1", "Number of dimensions", lab1$solution$asDF$dims[1], ega1$n.dim),
    c("1", "TEFI", lab1$solution$asDF$tefi[1], ega1$TEFI),
    c("1", "Network loading of A2", cell(lab1$loadings, "d1", "item", "A2"),
      net.loads(ega1)$std["A2", "1"]),
    c("1", "Bootstrap: proportion with 5 dimensions",
      cell(lab1$bootFrequency, "proportion", "dims", "5"), freq(boot1, 5)),
    c("1", "Structural consistency, dimension 3",
      cell(lab1$bootDimStability, "consistency", "dimension", "3"),
      stab1$dimension.stability$structural.consistency[["3"]]),
    c("1", "Lowest item stability", min(lab1$bootItemStability$asDF$stability),
      min(stab1$item.stability$item.stability$empirical.dimensions)),
    c("1", "UVA removes N1 (1 = yes)",
      as.numeric(any(grepl("\\bN1\\b", lab1$uvaSets$asDF$remove))),
      as.numeric(any(uva1$keep_remove$remove == "N1"))),
    c("1", "Dimensions after riEGA",
      cell(lab2$riSummary, "dims", "structure", "riEGA (after wording control)"),
      ri1$EGA$n.dim),
    c("1", "hierEGA lower-order dimensions",
      cell(lab2$hierSummary, "dims", "level", "Lower order"), hier1$lower_order$n.dim),
    c("1", "hierEGA higher-order dimensions",
      cell(lab2$hierSummary, "dims", "level", "Higher order"), hier1$higher_order$n.dim),
    c("1", "Invariance p, O1", cell(lab2$invTable, "p", "item", "O1"), inv_p(inv1, "O1")),
    c("1", "NCT M", lab2$nctGlobal$asDF$stat[1], nct1$nwinv.real),
    c("1", "NCT p (M)", lab2$nctGlobal$asDF$p[1], nct1$nwinv.pval),
    c("1", "CS coefficient, strength", lab_cs$cs[lab_cs$measure == "Strength"],
      cs1[["strength"]]),
    c("2", "Population dimensions", summary_value(lab_dyn, "Dimensions (population)"),
      dyn1$dynEGA$population$n.dim),
    c("2", "Median ARI with the population",
      cell(lab_dyn$indAgree, "median", "comparison", "The population"),
      stats::median(sapply(dyn1$dynEGA$individual,
                           function(p) ari(p$wc, dyn1$dynEGA$population$wc)))),
    c("3", "Number of dimensions", lab3$solution$asDF$dims[1], ega3$n.dim),
    c("3", "TEFI", lab3$solution$asDF$tefi[1], ega3$TEFI),
    c("3", "Bootstrap: proportion with 2 dimensions",
      cell(lab3$bootFrequency, "proportion", "dims", "2"), freq(boot3, 2)),
    c("3", "Item stability, wmt10", cell(lab3$bootItemStability, "stability", "item", "wmt10"),
      stab3$item.stability$item.stability$empirical.dimensions[["wmt10"]]))

num <- function(v) suppressWarnings(as.numeric(v))
results <- data.frame(
    example = vapply(rows, `[`, "", 1),
    quantity = vapply(rows, `[`, "", 2),
    EGAnetLab = round(num(vapply(rows, `[`, "", 3)), 4),
    direct = round(num(vapply(rows, `[`, "", 4)), 4))
tol <- 1e-8
results$agree <- !is.na(results$EGAnetLab) & !is.na(results$direct) &
    abs(results$EGAnetLab - results$direct) <= tol

print(results, row.names = FALSE)
cat("\n", R.version.string, "\n", sep = "")
for (p in c("EGAnet", "igraph", "NetworkComparisonTest", "bootnet"))
    cat(p, as.character(utils::packageVersion(p)), "\n")
utils::write.csv(results, file.path("validation", "procedure_equivalence_results.csv"),
                 row.names = FALSE)

if (!all(results$agree))
    stop("EGAnetLab and the direct calls disagree in at least one quantity.")

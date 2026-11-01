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
# Centrality and network stability helpers (phase 6).
# ES: Funciones auxiliares de centralidad y estabilidad de la red (fase 6).
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_centrality()
#
# Input: network - the EGA network (symmetric matrix of partial correlations,
#   items as dimnames); closbetw - also closeness and betweenness;
#   standardize - z values across items.
# Output: data frame item, strength, ei, closeness, betweenness (the last two
#   NA unless closbetw), plus attribute "raw" with the unstandardized values.
#   Strength is the sum of absolute weights and expected influence the signed
#   sum (Robinaugh et al., 2016), both from qgraph::centrality(), so they match
#   bootnet's definitions.
# ES: Entrada: network - la red de EGA; closbetw - también cercanía e
#   intermediación; standardize - valores z entre ítems. Salida: data frame
#   con item, strength, ei, closeness, betweenness (las dos últimas NA salvo
#   closbetw) y el atributo "raw" con los valores sin estandarizar. La fuerza
#   es la suma de pesos absolutos y la influencia esperada la suma con signo,
#   ambas de qgraph::centrality(), igual que en bootnet.
# -----------------------------------------------------------------------------
.el_centrality <- function(network, closbetw = FALSE, standardize = TRUE) {
    network <- as.matrix(network)
    diag(network) <- 0
    items <- colnames(network)
    if (is.null(items))
        items <- paste0("V", seq_len(ncol(network)))

    cen <- qgraph::centrality(network, weighted = TRUE, signed = TRUE,
                              all.shortest.paths = FALSE)
    raw <- data.frame(
        item = items,
        strength = as.numeric(cen$OutDegree),
        ei = as.numeric(cen$OutExpectedInfluence),
        closeness = if (closbetw) as.numeric(cen$Closeness) else NA_real_,
        betweenness = if (closbetw) as.numeric(cen$Betweenness) else NA_real_,
        stringsAsFactors = FALSE
    )
    # Closeness is not defined for items without a path to the rest.
    # ES: La cercanía no está definida para ítems sin camino al resto.
    raw$closeness[!is.finite(raw$closeness)] <- NA_real_

    out <- raw
    if (standardize) {
        z <- function(x) {
            s <- stats::sd(x, na.rm = TRUE)
            if (all(is.na(x)) || is.na(s) || s == 0) return(rep(NA_real_, length(x)))
            (x - mean(x, na.rm = TRUE)) / s
        }
        for (col in c("strength", "ei", "closeness", "betweenness"))
            out[[col]] <- z(raw[[col]])
    }
    attr(out, "raw") <- raw
    out
}

# -----------------------------------------------------------------------------
# .el_bootnet()
#
# Input: data - item data (reversed items already applied); corr, na_data,
#   model - the EGA estimation options; iter, case_iter - bootstrap samples;
#   seed; closbetw - include closeness and betweenness in the case-dropping
#   bootstrap; checkpoint - function called between the two procedures.
# Output: list with network (the bootnet estimate, identical to EGA's),
#   edges (data frame a, b, weight, low, high, nonzero for the non-zero edges
#   of the network), cases (data frame measure, drop, mean, low, high), cs
#   (named CS coefficients), iter, case_iter, seed.
#   Each bootstrap sample re-estimates the network with
#   EGAnet::network.estimation(), so the network checked is exactly the one
#   EGA used (Epskamp et al., 2018, procedures).
# ES: Entrada: data - datos de los ítems (con los invertidos ya aplicados);
#   corr, na_data, model - las opciones de estimación de EGA; iter,
#   case_iter - muestras bootstrap; seed; closbetw - incluir cercanía e
#   intermediación en el bootstrap de eliminación de casos; checkpoint -
#   función que se llama entre los dos procedimientos. Salida: lista con
#   network, edges, cases, cs, iter, case_iter y seed. Cada muestra reestima
#   la red con EGAnet::network.estimation(), así que la red evaluada es
#   exactamente la que usó EGA.
# -----------------------------------------------------------------------------
.el_bootnet <- function(data, corr, na_data, model, iter, case_iter, seed,
                        closbetw = FALSE, checkpoint = function() NULL) {

    data <- as.data.frame(data)
    estimator <- function(x, ...) {
        net <- EGAnet::network.estimation(
            data = x, corr = corr, na.data = na_data, model = model,
            verbose = FALSE)
        net <- as.matrix(net)
        dimnames(net) <- list(colnames(x), colnames(x))
        net
    }

    set.seed(seed)
    net <- bootnet::estimateNetwork(data, default = "none", fun = estimator,
                                    labels = colnames(data), verbose = FALSE)

    checkpoint()
    set.seed(seed)
    b_edges <- bootnet::bootnet(net, nBoots = iter, type = "nonparametric",
                                statistics = c("edge"), nCores = 1,
                                verbose = FALSE)

    checkpoint()
    measures <- c("strength", "expectedInfluence")
    if (closbetw)
        measures <- c(measures, "closeness", "betweenness")
    set.seed(seed)
    b_case <- bootnet::bootnet(net, nBoots = case_iter, type = "case",
                               statistics = measures, nCores = 1,
                               verbose = FALSE)

    # Edges: the non-zero edges of the estimated network, with percentile
    # intervals and the share of samples in which the edge was not zero.
    # ES: Aristas: las distintas de cero de la red estimada, con intervalos
    # percentiles y la proporción de muestras en que la arista no fue cero.
    graph <- as.matrix(net$graph)
    boot_tab <- b_edges$bootTable
    boot_tab <- boot_tab[boot_tab$type == "edge", , drop = FALSE]
    idx <- which(upper.tri(graph) & graph != 0, arr.ind = TRUE)
    labels <- colnames(graph)
    edges <- data.frame(a = labels[idx[, 1]], b = labels[idx[, 2]],
                        weight = graph[idx], stringsAsFactors = FALSE)
    if (nrow(edges) > 0) {
        stats <- t(vapply(seq_len(nrow(edges)), function(i) {
            v <- boot_tab$value[(boot_tab$node1 == edges$a[i] & boot_tab$node2 == edges$b[i]) |
                                (boot_tab$node1 == edges$b[i] & boot_tab$node2 == edges$a[i])]
            if (length(v) == 0) return(c(NA_real_, NA_real_, NA_real_))
            c(stats::quantile(v, c(0.025, 0.975), names = FALSE, na.rm = TRUE),
              mean(v != 0, na.rm = TRUE))
        }, numeric(3)))
        edges$low <- stats[, 1]
        edges$high <- stats[, 2]
        edges$nonzero <- stats[, 3]
        edges <- edges[order(-abs(edges$weight)), , drop = FALSE]
        rownames(edges) <- NULL
    } else {
        edges$low <- edges$high <- edges$nonzero <- numeric(0)
    }

    # Case dropping: correlation of each subsample's centrality with the
    # original, summarized by proportion of cases dropped.
    # ES: Eliminación de casos: correlación entre la centralidad de cada
    # submuestra y la original, resumida por proporción de casos eliminados.
    case_sum <- as.data.frame(summary(b_case, statistics = measures))
    cases <- data.frame(
        measure = as.character(case_sum$type),
        drop = 1 - case_sum$nPerson / nrow(data),
        mean = case_sum$mean,
        low = case_sum$q2.5,
        high = case_sum$q97.5,
        stringsAsFactors = FALSE
    )
    cases <- cases[order(match(cases$measure, measures), cases$drop), , drop = FALSE]

    cs <- bootnet::corStability(b_case, cor = 0.7, statistics = measures,
                                verbose = FALSE)

    list(network = graph, edges = edges, cases = cases, cs = cs[measures],
         iter = iter, case_iter = case_iter, seed = seed)
}

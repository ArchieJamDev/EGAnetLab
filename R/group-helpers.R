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
# Group comparison helpers (metric invariance and Network Comparison Test).
# ES: Funciones auxiliares de la comparación entre grupos (invarianza métrica
# y Network Comparison Test).
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_group_vector()
#
# Input: data - the analysis data (self$data); rows - row names of the items
#   used (rownames(prep$data)); var - the grouping variable name.
# Output: a character vector aligned to rows, NA where the group is missing.
# ES: Salida: un vector de caracteres alineado con rows, NA donde falta el
#   grupo.
# -----------------------------------------------------------------------------
.el_group_vector <- function(data, rows, var) {

    index <- match(rows, rownames(data))
    g <- data[[var]][index]
    out <- as.character(g)
    out[is.na(g)] <- NA_character_
    out
}

# -----------------------------------------------------------------------------
# .el_nct()
#
# Input: d1, d2 - item data frames of the two groups (same columns); paired -
#   TRUE when the rows of d1 and d2 are the same people; iter - permutations;
#   edges, centrality - whether to test every edge and node strength /
#   expected influence; adjust - p-value correction; ordinal - TRUE to use
#   polychoric correlations (qgraph::cor_auto) as EGA does with automatic
#   correlations; seed - integer.
# Output: .el_capture() list whose value is a small summary: global strength
#   of each network, the global strength difference (S) and the maximum
#   edge difference (M) with their p values, the two networks, and the edge
#   and centrality tests when asked.
# NCT estimates each network with EBICglasso (gamma = 0.5), the default of
#   EGA's glasso model, and draws its permutations from R's generator, so
#   the seed makes it reproducible.
# ES: NCT estima cada red con EBICglasso (gamma = 0.5), el valor por defecto
#   del modelo glasso de EGA, y sus permutaciones usan el generador de R, así
#   que la semilla las hace reproducibles.
# -----------------------------------------------------------------------------
.el_nct <- function(d1, d2, paired = FALSE, iter = 1000, edges = FALSE, centrality = FALSE,
                    adjust = "holm", ordinal = FALSE, seed = 2026) {

    # NCT() is called directly, not through do.call(): it inspects its own
    # call, which fails when the data frames are spliced into it.
    # ES: NCT() se llama directamente, no con do.call(): revisa su propia
    # llamada, que falla cuando los data frames van insertados en ella.
    data1 <- as.data.frame(d1)
    data2 <- as.data.frame(d2)
    estimator_args <- if (ordinal) list(corMethod = "cor_auto") else list()

    fit <- .el_capture(suppressMessages(.el_with_seed(seed,
        NetworkComparisonTest::NCT(
            data1, data2, it = as.integer(iter), paired = paired,
            test.edges = edges, edges = "all",
            test.centrality = centrality, centrality = c("strength", "expectedInfluence"),
            p.adjust.methods = adjust, progressbar = FALSE, verbose = FALSE,
            estimatorArgs = estimator_args))))
    if (is.null(fit$value))
        return(fit)

    r <- fit$value
    out <- list(
        strength = as.numeric(r$glstrinv.sep),
        S = as.numeric(r$glstrinv.real), S_p = as.numeric(r$glstrinv.pval),
        M = as.numeric(r$nwinv.real), M_p = as.numeric(r$nwinv.pval),
        nw1 = as.matrix(r$nw1), nw2 = as.matrix(r$nw2),
        edges = NULL, centrality = NULL)
    items <- colnames(d1)
    dimnames(out$nw1) <- dimnames(out$nw2) <- list(items, items)

    if (edges && !is.null(r$einv.pvals)) {
        e <- as.data.frame(r$einv.pvals)
        out$edges <- data.frame(
            a = as.character(e[[1]]), b = as.character(e[[2]]),
            p = as.numeric(e[[3]]), stringsAsFactors = FALSE)
        out$edges$w1 <- out$nw1[cbind(out$edges$a, out$edges$b)]
        out$edges$w2 <- out$nw2[cbind(out$edges$a, out$edges$b)]
    }
    if (centrality && !is.null(r$diffcen.real)) {
        real <- as.matrix(r$diffcen.real)
        pval <- as.matrix(r$diffcen.pval)
        rows <- list()
        for (m in colnames(real))
            rows[[m]] <- data.frame(item = rownames(real), measure = m,
                                    diff = as.numeric(real[, m]), p = as.numeric(pval[, m]),
                                    stringsAsFactors = FALSE)
        out$centrality <- do.call(rbind, rows)
        rownames(out$centrality) <- NULL
    }

    fit$value <- out
    fit
}

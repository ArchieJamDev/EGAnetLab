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
# Hierarchical EGA helpers for the EGA analysis.
# ES: Funciones auxiliares del EGA jerárquico para el análisis EGA.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_hier_plot_state()
#
# Input: items - item names; lower - raw hierEGA lower-order label of each
#   item; aligned - the same labels aligned to the EGA solution (as shown in
#   the membership table); higher - higher-order label of each item (NA when
#   there is no higher level); lower_loadings - hierEGA network loadings of
#   the items (items x lower dimensions) or NULL; higher_loadings - network
#   loadings of the lower-order scores on the higher-order dimensions or
#   NULL; labels - axis and group labels in the report language.
# Output: list(nodes, edges, labels), small and plain, for the plot state.
#   Items are ordered by higher-order and then lower-order dimension, so
#   edges do not cross; isolated items go last, without edges.
# ES: Salida: list(nodes, edges, labels), pequeña y simple, para el estado
#   del gráfico. Los ítems se ordenan por dimensión de orden superior y luego
#   inferior, para que las aristas no se crucen; los ítems aislados van al
#   final, sin aristas.
# -----------------------------------------------------------------------------
.el_hier_plot_state <- function(items, lower, aligned, higher, lower_loadings = NULL,
                                higher_loadings = NULL, labels) {

    lower <- as.character(lower[items]); names(lower) <- items
    aligned <- as.character(aligned[items]); names(aligned) <- items
    higher <- as.character(higher[items]); names(higher) <- items

    weight <- function(m, r, k) {
        if (is.null(m)) return(NA_real_)
        m <- as.matrix(m)
        if (is.null(rownames(m)) || is.null(colnames(m))) return(NA_real_)
        if (!(r %in% rownames(m)) || !(k %in% colnames(m))) return(NA_real_)
        abs(as.numeric(m[r, k]))
    }

    ord <- order(is.na(lower), higher, aligned, seq_along(items))
    it <- items[ord]
    x_item <- stats::setNames(seq_along(it), it)

    nodes <- data.frame(id = it, label = it, level = 0, x = as.numeric(x_item),
                        group = ifelse(is.na(aligned[it]), labels$isolated, aligned[it]),
                        stringsAsFactors = FALSE)
    edges <- data.frame(x = numeric(0), y = numeric(0), xend = numeric(0), yend = numeric(0),
                        weight = numeric(0))

    dims <- unique(stats::na.omit(lower[it]))
    x_dim <- numeric(0)
    for (d in dims) {
        members <- it[!is.na(lower[it]) & lower[it] == d]
        xd <- mean(x_item[members])
        x_dim[d] <- xd
        shown <- aligned[members[1]]
        nodes <- rbind(nodes, data.frame(id = paste0("L", d), label = shown, level = 1, x = xd,
                                         group = shown, stringsAsFactors = FALSE))
        for (m in members)
            edges <- rbind(edges, data.frame(x = x_item[[m]], y = 0, xend = xd, yend = 1,
                                             weight = weight(lower_loadings, m, d)))
    }

    if (any(!is.na(higher[it]))) {
        for (g in unique(stats::na.omit(higher[it]))) {
            under <- unique(lower[it][!is.na(higher[it]) & higher[it] == g & !is.na(lower[it])])
            if (length(under) == 0) next
            xg <- mean(x_dim[under])
            nodes <- rbind(nodes, data.frame(id = paste0("H", g), label = g, level = 2, x = xg,
                                             group = "higher", stringsAsFactors = FALSE))
            for (d in under)
                edges <- rbind(edges, data.frame(x = x_dim[[d]], y = 1, xend = xg, yend = 2,
                                                 weight = weight(higher_loadings, d, g)))
        }
    }

    rownames(nodes) <- NULL
    rownames(edges) <- NULL
    list(nodes = nodes, edges = edges, labels = labels)
}

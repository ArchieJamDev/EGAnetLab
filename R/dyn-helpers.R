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
# Dynamic EGA helpers (phase 7).
# ES: Funciones auxiliares del EGA dinámico (fase 7).
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_dyn_prepare()
#
# Input: data - jamovi data; vars - items; id, time, group - variable names
#   (time and group may be NULL); min_points - fewest rows a person needs.
# Output: list(ok, reason, data = data frame with the items, ID and (if any)
#   Group, rows ordered by person and time; points = rows per kept person;
#   dropped = persons left out; constant = constant items; group_varies =
#   number of persons whose group changes).
# ES: Entrada: data - datos de jamovi; vars - ítems; id, time, group -
#   nombres de variables (time y group pueden ser NULL); min_points - mínimo
#   de filas por persona. Salida: list(ok, reason, data con los ítems, ID y
#   Group, ordenada por persona y momento; points; dropped; constant;
#   group_varies).
# -----------------------------------------------------------------------------
.el_dyn_prepare <- function(data, vars, id, time = NULL, group = NULL, min_points = 7) {

    out <- list(ok = FALSE, reason = NULL, dropped = character(0), constant = character(0),
                group_varies = 0L)
    ids <- data[[id]]
    keep <- !is.na(ids) & nzchar(trimws(as.character(ids)))
    items <- as.data.frame(lapply(vars, function(v) jmvcore::toNumeric(data[[v]][keep])))
    names(items) <- vars
    ids <- as.character(ids[keep])

    constant <- vars[vapply(items, function(x) {
        x <- x[!is.na(x)]
        length(unique(x)) < 2
    }, logical(1))]
    if (length(constant) > 0) {
        out$reason <- "constant_item"
        out$constant <- constant
        return(out)
    }

    # Persons keep their order of first appearance; rows within a person
    # follow the time variable, or the data order without one.
    # ES: Las personas conservan su orden de primera aparición; las filas de
    # cada persona siguen la variable de tiempo, o el orden de los datos sin
    # ella.
    person_order <- match(ids, unique(ids))
    time_key <- if (!is.null(time)) jmvcore::toNumeric(data[[time]][keep]) else seq_along(ids)
    ord <- order(person_order, time_key, seq_along(ids))
    items <- items[ord, , drop = FALSE]
    ids <- ids[ord]

    df <- items
    df$ID <- ids
    if (!is.null(group)) {
        g <- as.character(data[[group]][keep])[ord]
        first <- tapply(g, factor(ids, levels = unique(ids)), function(x) x[!is.na(x)][1])
        varies <- tapply(g, factor(ids, levels = unique(ids)),
                         function(x) length(unique(x[!is.na(x)])) > 1)
        out$group_varies <- sum(varies, na.rm = TRUE)
        df$Group <- unname(first[ids])
        df <- df[!is.na(df$Group), , drop = FALSE]
    }

    points <- table(factor(df$ID, levels = unique(df$ID)))
    short <- names(points)[points < min_points]
    if (length(short) > 0) {
        out$dropped <- short
        df <- df[!df$ID %in% short, , drop = FALSE]
        points <- points[!names(points) %in% short]
    }
    if (length(points) < 2) {
        out$reason <- "too_few_persons"
        return(out)
    }

    rownames(df) <- NULL
    out$ok <- TRUE
    out$data <- df
    out$points <- stats::setNames(as.integer(points), names(points))
    out
}

# -----------------------------------------------------------------------------
# .el_ari()
#
# Adjusted Rand index between two memberships of the same items (Hubert &
# Arabie, 1985). Items without a dimension (NA) count as their own group.
# ES: Índice de Rand ajustado entre dos pertenencias de los mismos ítems.
# Los ítems sin dimensión (NA) cuentan como un grupo propio.
# -----------------------------------------------------------------------------
.el_ari <- function(a, b) {
    a <- as.character(a)
    b <- as.character(b)
    a[is.na(a)] <- paste0("na_", which(is.na(a)))
    b[is.na(b)] <- paste0("na_", which(is.na(b)))
    tab <- table(a, b)
    choose2 <- function(x) x * (x - 1) / 2
    n <- length(a)
    sum_ij <- sum(choose2(tab))
    sum_a <- sum(choose2(rowSums(tab)))
    sum_b <- sum(choose2(colSums(tab)))
    expected <- sum_a * sum_b / choose2(n)
    maximum <- (sum_a + sum_b) / 2
    if (maximum == expected)
        return(if (identical(unname(a), unname(b)) || sum_ij == maximum) 1 else 0)
    (sum_ij - expected) / (maximum - expected)
}

# -----------------------------------------------------------------------------
# .el_dyn_summary()
#
# Input: fit - an EGAnet::dynEGA() result; items - item names; points - time
#   points per person; groups - named vector person -> group (or NULL).
# Output: a small list for the cache: population (wc, n_dim, network), groups
#   (one entry per group: wc, n_dim, persons) and individual (data frame id,
#   points, dims, ari) plus the persons whose structure failed.
# ES: Salida: una lista pequeña para la caché: population, groups e
#   individual (data frame id, points, dims, ari) más las personas cuya
#   estructura falló.
# -----------------------------------------------------------------------------
.el_dyn_summary <- function(fit, items, points, groups = NULL) {

    clean_wc <- function(wc) {
        wc <- unlist(wc)
        names(wc) <- sub("\\.DerivOrd[0-9]+$", "", names(wc))
        out <- stats::setNames(rep(NA_real_, length(items)), items)
        common <- intersect(items, names(wc))
        out[common] <- as.numeric(wc[common])
        out
    }

    pop <- fit$dynEGA$population
    network <- as.matrix(pop$network)
    dimnames(network) <- list(items, items)
    population <- list(wc = clean_wc(pop$wc), n_dim = .el_clean_num(pop$n.dim), network = network)

    group_list <- list()
    if (!is.null(fit$dynEGA$group)) {
        for (g in names(fit$dynEGA$group)) {
            entry <- fit$dynEGA$group[[g]]
            group_list[[g]] <- list(wc = clean_wc(entry$wc), n_dim = .el_clean_num(entry$n.dim),
                                    persons = if (is.null(groups)) NA_integer_ else sum(groups == g))
        }
    }

    individual <- NULL
    failed <- character(0)
    if (!is.null(fit$dynEGA$individual)) {
        ind <- fit$dynEGA$individual
        rows <- lapply(names(points), function(id) {
            entry <- ind[[id]]
            if (is.null(entry) || is.null(entry$wc) || all(is.na(unlist(entry$wc)))) {
                failed <<- c(failed, id)
                return(data.frame(id = id, points = points[[id]], dims = NA_real_, ari = NA_real_))
            }
            wc <- clean_wc(entry$wc)
            data.frame(id = id, points = points[[id]], dims = .el_clean_num(entry$n.dim),
                       ari = .el_ari(wc, population$wc))
        })
        individual <- do.call(rbind, rows)
        individual$id <- as.character(individual$id)
    }

    list(population = population, groups = group_list, individual = individual, failed = failed)
}

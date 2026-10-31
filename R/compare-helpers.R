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
# Structure comparison (TEFI) helpers for the EGA analysis.
# ES: Funciones auxiliares de la comparación de estructuras (TEFI) para el
# análisis EGA.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_factors_structure()
#
# Input: factors - the "Theoretical structure" option: a list of factors,
#   each list(label, vars), as jamovi's own CFA builds it; items - the item
#   names of the analysis.
# Output: list(empty, wc, unknown, duplicated, duplicated_dims, unassigned,
#   single): wc is a character vector named by item with the factor name of
#   each item (NA when the item is in no factor). A factor without a name is
#   called "Factor k".
# ES: Salida: wc es un vector de caracteres con nombre de ítem y el nombre
#   del factor de cada ítem (NA si el ítem no está en ningún factor). Un
#   factor sin nombre se llama "Factor k".
# -----------------------------------------------------------------------------
.el_factors_structure <- function(factors, items) {

    out <- list(empty = TRUE, wc = NULL, unknown = character(0), duplicated = character(0),
                duplicated_dims = character(0), unassigned = character(0), single = FALSE)

    wc <- stats::setNames(rep(NA_character_, length(items)), items)
    labels <- character(0)

    for (k in seq_along(factors)) {
        f <- factors[[k]]
        vars <- unique(as.character(unlist(f$vars)))
        vars <- vars[!is.na(vars) & nzchar(vars)]
        if (length(vars) == 0)
            next
        label <- trimws(paste(as.character(unlist(f$label)), collapse = " "))
        if (length(label) == 0 || is.na(label) || !nzchar(label))
            label <- paste("Factor", k)
        labels <- c(labels, label)
        for (v in vars) {
            if (!(v %in% items))
                out$unknown <- c(out$unknown, v)
            else if (!is.na(wc[[v]]) && wc[[v]] != label)
                out$duplicated <- c(out$duplicated, v)
            else
                wc[[v]] <- label
        }
    }

    out$empty <- length(labels) == 0
    out$unknown <- unique(out$unknown)
    out$duplicated <- unique(out$duplicated)
    out$duplicated_dims <- unique(labels[duplicated(labels)])
    out$unassigned <- names(wc)[is.na(wc)]
    out$wc <- wc
    out$single <- length(unique(stats::na.omit(wc))) == 1
    out
}

# -----------------------------------------------------------------------------
# .el_tefi()
#
# Input: ega - the EGA object of the analysis; wc - memberships named by
#   item (any labels; NA = not in any dimension).
# Output: the TEFI of that structure on the EGA's own correlation matrix, or
#   NA. Items with NA are left out of the computation, as EGAnet does.
# ES: Salida: el TEFI de esa estructura sobre la misma matriz de
#   correlaciones del EGA, o NA. Los ítems con NA quedan fuera del cálculo,
#   como hace EGAnet.
# -----------------------------------------------------------------------------
.el_tefi <- function(ega, wc) {
    structure <- as.character(wc[names(ega$wc)])
    value <- tryCatch(
        suppressWarnings(EGAnet::tefi(ega, structure = structure, verbose = FALSE)),
        error = function(e) NULL)
    if (is.null(value))
        return(NA_real_)
    .el_clean_num(value[["VN.Entropy.Fit"]])
}

# -----------------------------------------------------------------------------
# .el_agreement()
#
# Input: wc - memberships of one structure; ref - EGA memberships (both
#   named by item).
# Output: list(same, total, moved): items placed in the same dimension as in
#   EGA after aligning labels by largest overlap, out of the items assigned
#   in both, and the names of the items that moved.
# ES: Salida: ítems ubicados en la misma dimensión que en EGA tras alinear
#   las etiquetas por mayor solapamiento, sobre los ítems asignados en
#   ambas, y los nombres de los que cambiaron.
# -----------------------------------------------------------------------------
.el_agreement <- function(wc, ref) {
    aligned <- .el_align_wc(wc, ref)
    ref <- as.character(ref)
    names(ref) <- names(aligned)
    both <- !is.na(aligned) & !is.na(ref)
    same <- both & aligned == ref
    list(same = sum(same), total = sum(both), moved = names(aligned)[both & !same],
         aligned = aligned)
}

# -----------------------------------------------------------------------------
# .el_with_seed()
#
# Input: seed - integer; expr - code to evaluate.
# Output: the value of expr, evaluated with set.seed(seed). The global random
#   stream is restored afterwards, so other results do not change. Louvain
#   and Leiden draw on R's generator, so the seed makes them reproducible.
# ES: Salida: el valor de expr, evaluado con set.seed(seed). El flujo
#   aleatorio global se restaura después. Louvain y Leiden usan el generador
#   de R, así que la semilla los hace reproducibles.
# -----------------------------------------------------------------------------
.el_with_seed <- function(seed, expr) {
    had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
    if (had_seed)
        old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
    on.exit({
        if (had_seed) assign(".Random.seed", old_seed, envir = globalenv())
        else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
            rm(".Random.seed", envir = globalenv())
    })
    set.seed(as.integer(seed))
    expr
}

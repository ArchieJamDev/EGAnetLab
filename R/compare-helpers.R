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
# .el_parse_structure()
#
# Input: text - the theoretical structure as the user typed it; items - the
#   item names of the analysis.
# Output: list(empty, ok, wc, unknown, duplicated, unassigned, single):
#   wc is a character vector named by item with the dimension name of each
#   item (NA when the item was not assigned).
# Syntax: one dimension per part, parts separated by ";" or new lines. Each
#   part is "Name = item, item, ..."; lavaan's "=~" and "+" also work, and
#   "*" matches any characters ("PA*" is every item whose name starts with
#   PA). Item names are matched exactly, then ignoring case.
# ES: Sintaxis: una dimensión por parte, separadas por ";" o saltos de línea.
#   Cada parte es "Nombre = ítem, ítem, ..."; también funcionan "=~" y "+"
#   de lavaan, y "*" equivale a cualquier secuencia de caracteres ("PA*" son
#   todos los ítems cuyo nombre empieza por PA). Los nombres se comparan
#   exactos y, si no, sin distinguir mayúsculas.
# -----------------------------------------------------------------------------
.el_parse_structure <- function(text, items) {

    out <- list(empty = TRUE, ok = FALSE, wc = NULL, unknown = character(0),
                duplicated = character(0), unassigned = character(0), single = FALSE)

    text <- trimws(paste(as.character(text), collapse = "\n"))
    if (length(text) == 0 || is.na(text) || !nzchar(text))
        return(out)
    out$empty <- FALSE

    wc <- stats::setNames(rep(NA_character_, length(items)), items)
    parts <- trimws(unlist(strsplit(text, "[;\n\r]+")))
    parts <- parts[nzchar(parts)]
    dims <- character(0)

    for (k in seq_along(parts)) {
        part <- parts[k]
        if (grepl("=~|=|:", part)) {
            name <- trimws(sub("\\s*(=~|=|:).*$", "", part))
            rhs <- sub("^[^=:]*(=~|=|:)", "", part)
        } else {
            name <- ""
            rhs <- part
        }
        if (!nzchar(name))
            name <- paste0("D", k)
        dims <- c(dims, name)

        # Commas and "+" separate items; spaces too, unless the whole chunk
        # is an item name that contains spaces.
        # ES: Comas y "+" separan ítems; los espacios también, salvo que el
        # trozo completo sea un nombre de ítem con espacios.
        chunks <- trimws(unlist(strsplit(rhs, "[,+]+")))
        chunks <- chunks[nzchar(chunks)]
        tokens <- unlist(lapply(chunks, function(chunk) {
            if (chunk %in% items || tolower(chunk) %in% tolower(items)) chunk
            else unlist(strsplit(chunk, "[[:space:]]+"))
        }))
        tokens <- tokens[nzchar(tokens)]
        for (token in tokens) {
            if (grepl("*", token, fixed = TRUE)) {
                hits <- items[grepl(utils::glob2rx(token), items)]
                if (length(hits) == 0)
                    hits <- items[grepl(utils::glob2rx(tolower(token)), tolower(items))]
            } else {
                hits <- items[items == token]
                if (length(hits) == 0)
                    hits <- items[tolower(items) == tolower(token)]
            }
            if (length(hits) == 0) {
                out$unknown <- c(out$unknown, token)
                next
            }
            for (item in hits) {
                if (!is.na(wc[[item]]) && wc[[item]] != name)
                    out$duplicated <- c(out$duplicated, item)
                else
                    wc[[item]] <- name
            }
        }
    }

    out$unknown <- unique(out$unknown)
    out$duplicated <- unique(out$duplicated)
    out$unassigned <- names(wc)[is.na(wc)]
    out$wc <- wc
    out$single <- length(unique(stats::na.omit(wc))) == 1
    out$ok <- length(out$unknown) == 0 && length(out$duplicated) == 0 &&
              any(!is.na(wc)) && length(unique(dims)) == length(dims)
    if (length(unique(dims)) != length(dims))
        out$duplicated_dims <- unique(dims[duplicated(dims)])
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

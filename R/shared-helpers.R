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
# Shared, purely structural helpers used across module .b.R files.
# ES: Helpers compartidos y puramente estructurales, usados por los archivos
# .b.R de los módulos.
#
# Same contract as AssumptionsLab's shared-helpers.R: this file holds only
# plumbing (translation, HTML assembly, row adding, number cleaning, palette
# lookup, item preparation, error capture). Narrative and interpretation text
# lives in texts.R; statistical decisions live in each module's .b.R. Every
# helper uses the `.el_` prefix (EGAnetLab) so that this module can be loaded
# next to AssumptionsLab (`.al_`) in the same R session without name clashes.
#
# ES: Mismo contrato que el shared-helpers.R de AssumptionsLab: este archivo
# contiene solo plomería (traducción, ensamblado HTML, filas, limpieza de
# números, paletas, preparación de ítems, captura de errores). El texto
# narrativo e interpretativo vive en texts.R; las decisiones estadísticas
# viven en el .b.R de cada módulo. Cada helper usa el prefijo `.el_`
# (EGAnetLab) para que este módulo pueda cargarse junto a AssumptionsLab
# (`.al_`) en la misma sesión de R sin choques de nombres.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_tr()
#
# Input: lang - normalized language code ("es" or "en", see
#   .el_normalize_lang() in texts.R); en - English text; es - Spanish text
#   (optional; defaults to `en`).
# Output: `es` when lang is "es", otherwise `en`.
#
# Report text that varies at runtime goes through this function, never
# through jmvcore's `.()`: `.()` caches its translator once per R process,
# so dynamic text routed through it freezes at the language active when
# jamovi started (the FiabilityLab regression documented in AssumptionsLab's
# ARCHITECTURE.md §12).
#
# ES: El texto del informe que varía en tiempo de ejecución pasa por esta
# función, nunca por `.()` de jmvcore: `.()` guarda su traductor una sola vez
# por proceso de R, así que el texto dinámico que pasa por ahí se congela en
# el idioma activo cuando jamovi arrancó (la regresión de FiabilityLab
# documentada en ARCHITECTURE.md §12 de AssumptionsLab).
# -----------------------------------------------------------------------------
.el_tr <- function(lang, en, es = NULL) {
    if (is.null(es))
        es <- en
    if (identical(lang, "es")) es else en
}

# -----------------------------------------------------------------------------
# .el_html_escape() / .el_html_block() / .el_html_list()
#
# HTML assembly for every `Html` result. Identical in behavior to
# AssumptionsLab's .al_html_* family (justified paragraphs, 7.25in maximum
# width, real <ul>/<ol> lists instead of hyphen-prefixed prose).
#
# ES: Ensamblado HTML para cada resultado `Html`. Mismo comportamiento que la
# familia .al_html_* de AssumptionsLab (párrafos justificados, ancho máximo
# de 7.25in, listas <ul>/<ol> reales en vez de prosa con guiones).
# -----------------------------------------------------------------------------
.el_html_escape <- function(x) {
    x <- as.character(x)
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    x <- gsub(">", "&gt;", x, fixed = TRUE)
    x <- gsub("\"", "&quot;", x, fixed = TRUE)
    x
}

.el_html_block <- function(title = NULL, text, paragraphs = TRUE, escape = TRUE, raw = FALSE) {

    if (isTRUE(raw)) {
        body <- paste(text, collapse = "\n")
    } else {
        parts <- .el_clean_text(text)

        if (length(parts) == 0)
            return("")

        p_style <- "margin: 0.15em 0 0.65em 0; line-height: 1.40;"
        maybe_escape <- if (isTRUE(escape)) .el_html_escape else identity

        if (isTRUE(paragraphs)) {
            body <- paste0("<p style=\"", p_style, "\">", maybe_escape(parts), "</p>", collapse = "\n")
        } else {
            body <- paste0("<p style=\"", p_style, "\">", maybe_escape(paste(parts, collapse = " ")), "</p>")
        }
    }

    if (!nzchar(body))
        return("")

    h_style <- "margin: 0.55em 0 0.50em 0; line-height: 1.25;"
    div_style <- "max-width: 7.25in; width: 100%; box-sizing: border-box; text-align: justify;"

    if (!is.null(title) && nzchar(title))
        body <- paste0("<h3 style=\"", h_style, "\">", .el_html_escape(title), "</h3>\n", body)

    paste0("<div style=\"", div_style, "\">\n", body, "\n</div>")
}

.el_html_list <- function(items, ordered = FALSE, escape = TRUE) {
    parts <- .el_clean_text(items)

    if (length(parts) == 0)
        return("")

    maybe_escape <- if (isTRUE(escape)) .el_html_escape else identity
    tag <- if (isTRUE(ordered)) "ol" else "ul"
    li_style <- "margin: 0 0 0.30em 0; line-height: 1.40; text-align: justify;"
    list_style <- "margin: 0.15em 0 0.65em 0; padding-left: 1.35em;"

    items_html <- paste0("<li style=\"", li_style, "\">", maybe_escape(parts), "</li>", collapse = "\n")

    paste0("<", tag, " style=\"", list_style, "\">\n", items_html, "\n</", tag, ">")
}

# -----------------------------------------------------------------------------
# .el_add_row() / .el_clean_num() / .el_fmt_num()
#
# Row adding and number cleaning. .el_clean_num() turns NULL, NA, NaN and
# Inf into NA_real_, so that a Category B failure (a statistic that came
# back non-finite without an error) is never displayed as a real number.
#
# ES: Agregar filas y limpiar números. .el_clean_num() convierte NULL, NA,
# NaN e Inf en NA_real_, para que un fallo de Categoría B (un estadístico que
# volvió no finito sin lanzar error) nunca se muestre como número real.
# -----------------------------------------------------------------------------
.el_add_row <- function(table, key, values) {
    table$addRow(rowKey = key, values = values)
}

.el_clean_num <- function(x) {
    if (length(x) == 0)
        return(NA_real_)

    x <- suppressWarnings(as.numeric(x[1]))

    if (is.na(x) || is.nan(x) || is.infinite(x))
        return(NA_real_)

    x
}

.el_fmt_num <- function(x, digits = 3, missing = "") {
    x <- .el_clean_num(x)
    if (is.na(x))
        return(missing)
    formatC(x, format = "f", digits = digits)
}

# -----------------------------------------------------------------------------
# .el_plot_series_palette()
#
# Input: choice - the analysis' plotPalette option ("jamovi", "colorblind"
#   or "viridis").
# Output: NULL for "jamovi" (let jamovi's own ggtheme scale handle colors),
#   otherwise a character vector of colors.
#
# Same policy as AssumptionsLab: the default follows jamovi's global theme;
# only the two palettes jamovi does not ship are added. Viridis stops are
# hard-coded so the result never depends on whether viridisLite is
# installed.
#
# ES: Misma política que AssumptionsLab: por defecto se sigue el tema global
# de jamovi; solo se agregan las dos paletas que jamovi no trae. Los puntos
# de viridis están fijos para que el resultado nunca dependa de si
# viridisLite está instalado.
# -----------------------------------------------------------------------------
.el_plot_series_palette <- function(choice) {
    if (is.null(choice) || length(choice) == 0 || identical(choice, "jamovi"))
        return(NULL)

    if (identical(choice, "viridis"))
        return(c("#440154", "#414487", "#2A788E", "#22A884", "#7AD151", "#FDE725"))

    if (identical(choice, "colorblind"))
        return(c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7"))

    NULL
}

# -----------------------------------------------------------------------------
# .el_prepare_items()
#
# Input: data - self$data; vars - the item names selected by the user;
#   na_data - "pairwise" or "listwise"; min_items - minimum number of usable
#   items (EGA needs at least 3 to form a network with communities).
# Output: list(ok =, reason =, data =, n_total =, n_complete =,
#   dropped_constant =, ordinal_like =).
#   `ok = FALSE` carries a `reason` code that the caller turns into a
#   Category A jmvcore::reject() message.
#
# Never removes observations silently (CODE_STYLE §21): listwise deletion
# only happens when the user chose it, and the counts are returned so the
# report can state how many cases were used. Zero-variance items are
# returned by name rather than dropped, because the decision to drop them
# is reported to the user as a Category A block, not taken quietly.
#
# ES: Nunca elimina observaciones en silencio (CODE_STYLE §21): la
# eliminación por lista solo ocurre cuando el usuario la eligió, y se
# devuelven los conteos para que el informe diga cuántos casos se usaron.
# Los ítems de varianza cero se devuelven por nombre en lugar de eliminarse,
# porque la decisión de quitarlos se informa al usuario como bloqueo de
# Categoría A, no se toma calladamente.
# -----------------------------------------------------------------------------
.el_prepare_items <- function(data, vars, na_data = "pairwise", min_items = 3) {

    out <- list(ok = FALSE, reason = NULL, data = NULL, n_total = 0L,
                n_complete = 0L, constant = character(0), ordinal_like = FALSE)

    if (is.null(data) || nrow(data) == 0) {
        out$reason <- "no_data"
        return(out)
    }

    vars <- vars[!is.na(vars) & nzchar(vars)]

    if (length(vars) < min_items) {
        out$reason <- "too_few_items"
        return(out)
    }

    items <- as.data.frame(
        lapply(vars, function(v) jmvcore::toNumeric(data[[v]])),
        stringsAsFactors = FALSE
    )
    names(items) <- vars
    # Keep jamovi's row numbers (they skip filtered rows) so scores saved
    # back to the dataset land on the right rows.
    # ES: Se conservan los números de fila de jamovi (omiten las filas
    # filtradas) para que las puntuaciones guardadas en el conjunto de datos
    # caigan en las filas correctas.
    rownames(items) <- rownames(data)

    out$n_total <- nrow(items)
    complete <- stats::complete.cases(items)
    out$n_complete <- sum(complete)

    if (identical(na_data, "listwise"))
        items <- items[complete, , drop = FALSE]

    observed <- vapply(items, function(x) sum(!is.na(x)), numeric(1))
    if (any(observed < 2)) {
        out$reason <- "empty_item"
        out$constant <- names(observed)[observed < 2]
        return(out)
    }

    spread <- vapply(items, function(x) stats::sd(x, na.rm = TRUE), numeric(1))
    constant <- names(spread)[!is.finite(spread) | spread == 0]
    if (length(constant) > 0) {
        out$reason <- "constant_item"
        out$constant <- constant
        return(out)
    }

    # Items with 7 or fewer distinct values are what EGAnet's "auto"
    # correlation treats as ordinal (polychoric/tetrachoric); the report says
    # so explicitly instead of leaving the choice implicit.
    # ES: Los ítems con 7 o menos valores distintos son los que la correlación
    # "auto" de EGAnet trata como ordinales (policórica/tetracórica); el
    # informe lo dice explícitamente en lugar de dejar la elección implícita.
    categories <- vapply(items, function(x) length(unique(x[!is.na(x)])), numeric(1))
    out$ordinal_like <- any(categories <= 7)

    if (nrow(items) < 2) {
        out$reason <- "too_few_cases"
        return(out)
    }

    out$ok <- TRUE
    out$data <- items
    out
}

# -----------------------------------------------------------------------------
# .el_capture()
#
# Input: expr - an expression (usually an EGAnet call).
# Output: list(value =, error =, warnings =). `value` is NULL on error;
#   `warnings` keeps every warning message so the report can surface it
#   instead of suppressing it (CODE_STYLE §21: never suppress warnings
#   without justification).
#
# ES: Entrada: expr - una expresión (normalmente una llamada a EGAnet).
# Salida: list(value =, error =, warnings =). `value` es NULL si hubo error;
# `warnings` conserva cada advertencia para que el informe la muestre en vez
# de suprimirla (CODE_STYLE §21: nunca suprimir advertencias sin
# justificación).
# -----------------------------------------------------------------------------
.el_capture <- function(expr) {
    warnings <- character(0)
    value <- withCallingHandlers(
        tryCatch(expr, error = function(e) structure(list(message = conditionMessage(e)), class = "el_error")),
        warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
        }
    )

    if (inherits(value, "el_error"))
        return(list(value = NULL, error = value$message, warnings = unique(warnings)))

    list(value = value, error = NULL, warnings = unique(warnings))
}

# -----------------------------------------------------------------------------
# .el_estimation_choice_labels() / .el_choices_guide()
#
# Input: tr - the analysis' translator (en, es); lang - report language;
#   options - self$options; labels - named list option -> (value -> label),
#   usually .el_estimation_choice_labels(tr) plus analysis-specific entries;
#   extra - further plain paragraphs appended at the end.
# Output: the HTML of the "About your choices" block: an introduction, then
#   one paragraph per option in `labels`, headed "Decision: selected value."
#   and explained by texts.R section "choices", key "<option>_<value>".
#
# Shared by every analysis that estimates an EGA network, so the five
# estimation decisions are explained with the same words everywhere.
# ES: Compartido por todo análisis que estima una red EGA, para que las cinco
# decisiones de estimación se expliquen con las mismas palabras en todos.
# -----------------------------------------------------------------------------
.el_estimation_choice_labels <- function(tr) {
    list(
        corr = list(
            auto = tr("Automatic", "Automática"), pearson = "Pearson",
            spearman = "Spearman", cosine = tr("Cosine", "Coseno")),
        naData = list(
            pairwise = tr("Pairwise", "Por pares"), listwise = tr("Listwise", "Por lista")),
        model = list(glasso = "GLASSO (EBIC)", TMFG = "TMFG", BGGM = "BGGM"),
        algorithm = list(walktrap = "Walktrap", louvain = "Louvain", leiden = "Leiden"),
        uniMethod = list(
            louvain = "Louvain", expand = tr("Expand", "Expandir"),
            LE = tr("Leading eigenvalue", "Autovalor principal"))
    )
}

.el_choices_guide <- function(lang, options, labels, extra = character(0)) {

    p_style <- "margin: 0.15em 0 0.65em 0; line-height: 1.40;"
    parts <- paste0("<p style=\"", p_style, "\">",
                    .el_html_escape(.el_text(lang, "choices", "intro")), "</p>")

    for (option in names(labels)) {
        value <- as.character(options[[option]])
        label <- labels[[option]][[value]]
        if (length(value) == 0 || is.null(label))
            next
        heading <- paste0(.el_text(lang, "choices", paste0("h_", option)), ": ", label, ".")
        body <- .el_text(lang, "choices", paste0(option, "_", value))
        parts <- c(parts, paste0(
            "<p style=\"", p_style, "\"><strong>", .el_html_escape(heading), "</strong> ",
            .el_html_escape(body), "</p>"))
    }

    for (paragraph in extra)
        parts <- c(parts, paste0("<p style=\"", p_style, "\">", .el_html_escape(paragraph), "</p>"))

    .el_html_block(NULL, parts, raw = TRUE)
}

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
# CFA and random-split helpers for the EGA analysis.
# ES: Funciones auxiliares de CFA y división aleatoria para el análisis EGA.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# .el_split_index()
#
# Input: n - number of cases; prop - share for part A; seed - integer seed.
# Output: sorted row positions of part A. The global random stream is left
#   exactly as it was, so the split never changes other results.
# ES: Salida: posiciones ordenadas de la parte A. El flujo aleatorio global
#   queda igual que antes, para que la división no cambie otros resultados.
# -----------------------------------------------------------------------------
.el_split_index <- function(n, prop, seed) {

    had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
    if (had_seed)
        old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
    on.exit({
        if (had_seed) assign(".Random.seed", old_seed, envir = globalenv())
        else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
            rm(".Random.seed", envir = globalenv())
    })

    set.seed(as.integer(seed))
    n_a <- max(1L, min(n - 1L, as.integer(round(n * prop))))
    sort(sample.int(n, n_a))
}

# -----------------------------------------------------------------------------
# .el_align_wc()
#
# Input: wc - memberships found in one sample (named by item); ref - the
#   reference memberships (total sample).
# Output: wc relabelled so each community takes the label of the reference
#   community it shares most items with (greedy, largest overlap first).
#   Communities with no match get the label "new1", "new2", ...
# Community numbers are arbitrary in every EGA run, so this is needed before
# comparing memberships across samples.
# ES: Los números de comunidad son arbitrarios en cada EGA, así que esto es
# necesario antes de comparar pertenencias entre muestras.
# -----------------------------------------------------------------------------
.el_align_wc <- function(wc, ref) {

    wc <- as.character(wc[names(ref)])
    names(wc) <- names(ref)
    ref <- as.character(ref)
    names(ref) <- names(wc)

    own <- unique(stats::na.omit(wc))
    targets <- unique(stats::na.omit(ref))
    if (length(own) == 0)
        return(wc)

    pairs <- expand.grid(own = own, target = targets, stringsAsFactors = FALSE)
    pairs$overlap <- mapply(function(o, g) sum(wc == o & ref == g, na.rm = TRUE), pairs$own, pairs$target)
    pairs <- pairs[order(-pairs$overlap), , drop = FALSE]

    mapping <- character(0)
    for (i in seq_len(nrow(pairs))) {
        o <- pairs$own[i]; g <- pairs$target[i]
        if (pairs$overlap[i] == 0 || o %in% names(mapping) || g %in% mapping)
            next
        mapping[o] <- g
    }
    k <- 0
    for (o in own) if (!(o %in% names(mapping))) { k <- k + 1; mapping[o] <- paste0("new", k) }

    out <- unname(mapping[wc])
    names(out) <- names(ref)
    out
}

# -----------------------------------------------------------------------------
# .el_cfa_fit()
#
# Input: data - item data frame; wc - memberships (named by item);
#   estimator - "auto", "ML", "MLR" or "WLSMV".
# Output: list(ok, error, warnings, estimator, ordinal, n, dropped, fit
#   (named numbers), loadings (data frame item, factor, loading, se)).
# "auto" follows EGAnet's CFA(): WLSMV with ordered items when any item has
# fewer than 6 categories, otherwise MLR with FIML. Dimensions with a single
# item cannot form a factor and are dropped (reported). Items are renamed to
# syntactic names for lavaan and mapped back.
# ES: "auto" sigue a CFA() de EGAnet: WLSMV con ítems ordinales si algún ítem
# tiene menos de 6 categorías, si no MLR con FIML. Las dimensiones de un solo
# ítem no pueden formar un factor y se descartan (se informa). Los ítems se
# renombran a nombres sintácticos para lavaan y se devuelven a su nombre.
# -----------------------------------------------------------------------------
.el_cfa_fit <- function(data, wc, estimator = "auto") {

    out <- list(ok = FALSE, error = NULL, warnings = character(0), estimator = estimator,
                ordinal = FALSE, n = nrow(data), dropped = character(0), fit = NULL, loadings = NULL)

    wc <- wc[!is.na(wc)]
    sizes <- table(as.character(wc))
    out$dropped <- names(sizes)[sizes < 2]
    keep_dims <- names(sizes)[sizes >= 2]
    if (length(keep_dims) == 0) {
        out$error <- "no dimension has two or more items"
        return(out)
    }

    items <- names(wc)[as.character(wc) %in% keep_dims]
    safe <- paste0("v", seq_along(items))
    d <- data[, items, drop = FALSE]
    names(d) <- safe
    item_of <- stats::setNames(items, safe)

    categories <- vapply(d, function(x) length(unique(stats::na.omit(x))), integer(1))
    ordinal <- any(categories < 6)
    if (identical(estimator, "auto"))
        estimator <- if (ordinal) "WLSMV" else "MLR"
    out$estimator <- estimator
    out$ordinal <- identical(estimator, "WLSMV")

    factor_names <- paste0("F", keep_dims)
    model <- paste(vapply(seq_along(keep_dims), function(j) {
        paste0(factor_names[j], " =~ ", paste(safe[as.character(wc[items]) == keep_dims[j]], collapse = " + "))
    }, character(1)), collapse = "\n")

    args <- list(model = model, data = d, std.lv = TRUE, estimator = estimator)
    if (out$ordinal) {
        args$ordered <- safe
        args$missing <- "pairwise"
    } else if (estimator %in% c("ML", "MLR")) {
        args$missing <- "fiml"
    }

    # lavaan reads its own call name, so the function is passed by name.
    # ES: lavaan lee el nombre de su propia llamada, así que la función se
    # pasa por nombre.
    fit <- .el_capture(do.call("cfa", args, envir = asNamespace("lavaan")))
    out$warnings <- fit$warnings
    if (is.null(fit$value)) {
        out$error <- fit$error
        return(out)
    }
    model_fit <- fit$value

    fm <- tryCatch(lavaan::fitMeasures(model_fit), error = function(e) NULL)
    pick <- function(candidates) {
        for (nm in candidates)
            if (!is.null(fm) && nm %in% names(fm) && is.finite(fm[[nm]]))
                return(as.numeric(fm[[nm]]))
        NA_real_
    }
    robust <- estimator %in% c("MLR", "WLSMV")
    out$fit <- c(
        chisq = if (robust) pick(c("chisq.scaled", "chisq")) else pick("chisq"),
        df = if (robust) pick(c("df.scaled", "df")) else pick("df"),
        pvalue = if (robust) pick(c("pvalue.scaled", "pvalue")) else pick("pvalue"),
        cfi = if (robust) pick(c("cfi.robust", "cfi.scaled", "cfi")) else pick("cfi"),
        tli = if (robust) pick(c("tli.robust", "tli.scaled", "tli")) else pick("tli"),
        rmsea = if (robust) pick(c("rmsea.robust", "rmsea.scaled", "rmsea")) else pick("rmsea"),
        rmsea_low = if (robust) pick(c("rmsea.ci.lower.robust", "rmsea.ci.lower.scaled", "rmsea.ci.lower")) else pick("rmsea.ci.lower"),
        rmsea_high = if (robust) pick(c("rmsea.ci.upper.robust", "rmsea.ci.upper.scaled", "rmsea.ci.upper")) else pick("rmsea.ci.upper"),
        srmr = pick(c("srmr", "srmr_bentler")),
        gfi = pick("gfi"),
        agfi = pick("agfi"),
        nfi = if (robust) pick(c("nfi.scaled", "nfi")) else pick("nfi"),
        ifi = if (robust) pick(c("ifi.scaled", "ifi")) else pick("ifi"),
        aic = pick("aic"),
        bic = pick("bic"),
        converged = as.numeric(isTRUE(tryCatch(lavaan::lavInspect(model_fit, "converged"), error = function(e) FALSE)))
    )
    out$n <- tryCatch(as.integer(lavaan::lavInspect(model_fit, "nobs")), error = function(e) nrow(d))

    std <- tryCatch(lavaan::standardizedSolution(model_fit), error = function(e) NULL)
    if (!is.null(std)) {
        std <- std[std$op == "=~", , drop = FALSE]
        out$loadings <- data.frame(
            item = unname(item_of[std$rhs]),
            factor = sub("^F", "", std$lhs),
            loading = as.numeric(std$est.std),
            se = as.numeric(std$se),
            stringsAsFactors = FALSE)
    }

    out$ok <- TRUE
    out
}

# -----------------------------------------------------------------------------
# .el_fit_label()
#
# Input: fit - named numbers from .el_cfa_fit().
# Output: "good", "acceptable" or "poor" by Hu and Bentler's (1999)
#   conventional guidelines (CFI/TLI .95/.90, RMSEA .06/.08, SRMR .08).
# -----------------------------------------------------------------------------
.el_fit_label <- function(fit) {
    if (is.null(fit) || any(is.na(fit[c("cfi", "tli", "rmsea")])))
        return(NA_character_)
    srmr_ok <- is.na(fit[["srmr"]]) || fit[["srmr"]] <= 0.08
    if (fit[["cfi"]] >= 0.95 && fit[["tli"]] >= 0.95 && fit[["rmsea"]] <= 0.06 && srmr_ok)
        return("good")
    if (fit[["cfi"]] >= 0.90 && fit[["tli"]] >= 0.90 && fit[["rmsea"]] <= 0.08)
        return("acceptable")
    "poor"
}

# -----------------------------------------------------------------------------
# .el_fmt_p()
#
# Input: p - a p value. Output: APA-style text ("< .001", ".034") or a dash.
# -----------------------------------------------------------------------------
.el_fmt_p <- function(p) {
    p <- .el_clean_num(p)
    if (is.na(p)) return("—")
    if (p < 0.001) return("p < .001")
    paste0("p = ", sub("^0", "", formatC(p, format = "f", digits = 3)))
}

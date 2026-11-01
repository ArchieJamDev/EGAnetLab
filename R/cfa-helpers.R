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
#   estimator - "auto", "ML", "MLR" or "WLSMV"; type - "correlated"
#   (default), "higher" (second-order factors, from `higher`: the
#   higher-order label of each item) or "bifactor" (general factor plus
#   uncorrelated specific factors).
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
.el_cfa_fit <- function(data, wc, estimator = "auto", type = "correlated", higher = NULL) {

    out <- list(ok = FALSE, error = NULL, warnings = character(0), estimator = estimator,
                ordinal = FALSE, n = nrow(data), n_items = 0L, dropped = character(0), fit = NULL,
                loadings = NULL)

    wc <- wc[!is.na(wc)]
    sizes <- table(as.character(wc))
    out$dropped <- names(sizes)[sizes < 2]
    keep_dims <- names(sizes)[sizes >= 2]
    if (length(keep_dims) == 0) {
        out$error <- "no dimension has two or more items"
        return(out)
    }

    items <- names(wc)[as.character(wc) %in% keep_dims]
    out$n_items <- length(items)
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
    lines <- vapply(seq_along(keep_dims), function(j) {
        paste0(factor_names[j], " =~ ", paste(safe[as.character(wc[items]) == keep_dims[j]], collapse = " + "))
    }, character(1))
    orthogonal <- FALSE

    # Hierarchical models. "higher": second-order factors over the
    # first-order ones, from `higher` (higher-order label of each item);
    # two first-order factors under one second-order factor get equal
    # loadings so the model is identified. "bifactor": one general factor on
    # every item plus the specific factors, all uncorrelated.
    # ES: Modelos jerárquicos. "higher": factores de segundo orden sobre los
    # de primer orden, según `higher` (etiqueta de orden superior de cada
    # ítem); dos factores de primer orden bajo un mismo factor de segundo
    # orden llevan cargas iguales para que el modelo esté identificado.
    # "bifactor": un factor general en todos los ítems más los factores
    # específicos, todos sin correlación.
    if (identical(type, "higher")) {
        higher <- as.character(higher[items])
        first <- as.character(wc[items])
        groups <- split(unique(first), vapply(unique(first), function(f) higher[match(f, first)], character(1)))
        second <- character(0)
        for (g in names(groups)) {
            members <- paste0("F", groups[[g]])
            if (length(members) == 2)
                second <- c(second, paste0("H", g, " =~ h", g, "*", members[1], " + h", g, "*", members[2]))
            else if (length(members) > 2)
                second <- c(second, paste0("H", g, " =~ ", paste(members, collapse = " + ")))
        }
        if (length(second) == 0) {
            out$error <- "no higher-order dimension groups two or more lower-order dimensions"
            return(out)
        }
        lines <- c(lines, second)
    } else if (identical(type, "bifactor")) {
        if (length(keep_dims) < 2) {
            out$error <- "a bifactor model needs two or more specific dimensions"
            return(out)
        }
        lines <- c(paste0("G =~ ", paste(safe, collapse = " + ")), lines)
        orthogonal <- TRUE
    }
    model <- paste(lines, collapse = "\n")

    args <- list(model = model, data = d, std.lv = TRUE, estimator = estimator)
    if (orthogonal)
        args$orthogonal <- TRUE
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

    # fitMeasures() can warn too (for example, a robust CFI that cannot be
    # computed); those warnings join the ones of the fit.
    # ES: fitMeasures() también puede advertir (por ejemplo, un CFI robusto
    # que no se puede calcular); esas advertencias se suman a las del ajuste.
    fm_capture <- .el_capture(lavaan::fitMeasures(model_fit))
    fm <- fm_capture$value
    out$warnings <- unique(c(out$warnings, fm_capture$warnings))
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

    std <- suppressWarnings(tryCatch(lavaan::standardizedSolution(model_fit), error = function(e) NULL))
    if (!is.null(std)) {
        std <- std[std$op == "=~" & std$rhs %in% safe, , drop = FALSE]
        out$loadings <- data.frame(
            item = unname(item_of[std$rhs]),
            factor = sub("^F", "", std$lhs),
            loading = as.numeric(std$est.std),
            se = as.numeric(std$se),
            stringsAsFactors = FALSE)
    }

    out$problems <- .el_cfa_problems(model_fit, item_of, out$warnings)

    out$ok <- TRUE
    out
}

# -----------------------------------------------------------------------------
# .el_cfa_problems()
#
# Input: model_fit - a fitted lavaan model; item_of - item name of each safe
#   variable name; warnings - lavaan warnings captured while fitting.
# Output: a named list of the problems that make the solution inadmissible
#   or doubtful (empty when there are none): neg_resid / neg_lv (items or
#   factors with a negative variance), std_load (standardized loadings above
#   1), lv_npd (factor covariance matrix not positive definite), theta_npd
#   (residual covariance matrix not positive definite) and vcov (covariance
#   matrix of the estimates not positive definite: possible identification
#   problem). Each element holds the names involved, or TRUE.
# ES: Salida: una lista con nombre de los problemas que hacen la solución
#   inadmisible o dudosa (vacía si no hay): varianzas negativas de ítems o
#   factores, cargas estandarizadas mayores que 1, matriz de covarianzas de
#   los factores o de los residuos no definida positiva y matriz de
#   covarianzas de las estimaciones no definida positiva (posible problema de
#   identificación).
# -----------------------------------------------------------------------------
.el_cfa_problems <- function(model_fit, item_of, warnings = character(0)) {

    problems <- list()
    name_of <- function(x) ifelse(x %in% names(item_of), item_of[x], x)

    pe <- suppressWarnings(tryCatch(lavaan::parameterEstimates(model_fit), error = function(e) NULL))
    if (!is.null(pe)) {
        var_rows <- pe$op == "~~" & pe$lhs == pe$rhs & is.finite(pe$est) & pe$est < 0
        ov <- unique(pe$lhs[var_rows & pe$lhs %in% names(item_of)])
        lv <- unique(pe$lhs[var_rows & !(pe$lhs %in% names(item_of))])
        if (length(ov) > 0) problems$neg_resid <- unname(name_of(ov))
        if (length(lv) > 0) problems$neg_lv <- lv
    }
    std <- suppressWarnings(tryCatch(lavaan::standardizedSolution(model_fit), error = function(e) NULL))
    if (!is.null(std)) {
        big <- std$op == "=~" & is.finite(std$est.std) & abs(std$est.std) > 1
        if (any(big)) problems$std_load <- unique(unname(name_of(std$rhs[big])))
    }
    cov_lv <- suppressWarnings(tryCatch(lavaan::lavInspect(model_fit, "cov.lv"), error = function(e) NULL))
    if (!is.null(cov_lv) && length(cov_lv) > 1) {
        ev <- tryCatch(eigen(as.matrix(cov_lv), symmetric = TRUE, only.values = TRUE)$values,
                       error = function(e) NULL)
        if (!is.null(ev) && min(ev) < -1e-8) problems$lv_npd <- TRUE
    }

    w <- tolower(paste(warnings, collapse = " "))
    if (grepl("covariance matrix of latent variables", w, fixed = TRUE) ||
        grepl("(psi) is not positive definite", w, fixed = TRUE))
        problems$lv_npd <- TRUE
    if (grepl("(theta) is not positive definite", w, fixed = TRUE))
        problems$theta_npd <- TRUE
    if ((grepl("vcov", w, fixed = TRUE) && grepl("positive definite", w, fixed = TRUE)) ||
        grepl("could not compute standard errors", w, fixed = TRUE))
        problems$vcov <- TRUE
    if (is.null(problems$neg_resid) && grepl("ov variances are negative", w, fixed = TRUE))
        problems$neg_resid <- TRUE
    if (is.null(problems$neg_lv) && grepl("lv variances are negative", w, fixed = TRUE))
        problems$neg_lv <- TRUE

    problems
}

# -----------------------------------------------------------------------------
# .el_factor_label()
#
# Input: f - lavaan factor names (F<n>, H<n>, G); lang. Output: readable
#   names ("factor 3", "higher-order factor 1", "general factor").
# -----------------------------------------------------------------------------
.el_factor_label <- function(f, lang) {
    es <- identical(.el_normalize_lang(lang), "es")
    vapply(f, function(x) {
        if (identical(x, "G")) return(if (es) "factor general" else "general factor")
        if (grepl("^H", x)) return(paste(if (es) "factor de orden superior" else "higher-order factor", sub("^H", "", x)))
        if (grepl("^F", x)) return(paste(if (es) "factor" else "factor", sub("^F", "", x)))
        x
    }, character(1), USE.NAMES = FALSE)
}

# -----------------------------------------------------------------------------
# .el_describe_problems() / .el_describe_warnings()
#
# Input: problems - from .el_cfa_problems(); warnings - lavaan warnings;
#   lang. Output: one plain sentence fragment naming each exact problem.
#   Warnings without a known meaning are quoted as lavaan wrote them.
# ES: Salida: un fragmento de oración que nombra cada problema exacto. Las
#   advertencias sin un significado conocido se citan como las escribió
#   lavaan.
# -----------------------------------------------------------------------------
.el_describe_problems <- function(problems, lang) {
    es <- identical(.el_normalize_lang(lang), "es")
    list_of <- function(x) if (isTRUE(x)) "" else paste0(" (", paste(x, collapse = ", "), ")")
    parts <- character(0)
    if (!is.null(problems$neg_resid))
        parts <- c(parts, paste0(if (es) "varianza residual negativa (caso Heywood)" else
            "negative residual variance (Heywood case)", list_of(problems$neg_resid)))
    if (!is.null(problems$neg_lv))
        parts <- c(parts, paste0(if (es) "varianza negativa de un factor" else "negative factor variance",
            if (isTRUE(problems$neg_lv)) "" else paste0(" (", paste(.el_factor_label(problems$neg_lv, lang), collapse = ", "), ")")))
    if (!is.null(problems$std_load))
        parts <- c(parts, paste0(if (es) "carga estandarizada mayor que 1" else "standardized loading above 1",
            list_of(ifelse(grepl("^(F|H)[0-9]+$|^G$", problems$std_load),
                           .el_factor_label(problems$std_load, lang), problems$std_load))))
    if (!is.null(problems$lv_npd))
        parts <- c(parts, if (es) "la matriz de covarianzas de los factores no es definida positiva" else
            "the factor covariance matrix is not positive definite")
    if (!is.null(problems$theta_npd))
        parts <- c(parts, if (es) "la matriz de covarianzas de los residuos de los ítems no es definida positiva" else
            "the residual covariance matrix of the items is not positive definite")
    if (!is.null(problems$vcov))
        parts <- c(parts, if (es) "la matriz de covarianzas de las estimaciones no es definida positiva, lo que puede indicar que el modelo no está identificado" else
            "the covariance matrix of the estimates is not positive definite, which may mean that the model is not identified")
    paste(parts, collapse = "; ")
}

.el_describe_warnings <- function(warnings, lang) {
    w <- unique(.el_clean_text(warnings))
    w <- trimws(sub("^lavaan (WARNING|warning):?", "", w))
    w <- gsub("\\s+", " ", w)
    paste0("\u201C", paste(w, collapse = "\u201D; \u201C"), "\u201D")
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

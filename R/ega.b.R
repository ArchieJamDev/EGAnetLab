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
# Exploratory Graph Analysis.
# ES: Análisis Exploratorio de Grafos.
#
# This file implements the complete analytical workflow for estimating the
# dimensional structure of a set of items with EGAnet::EGA(). It follows the
# AssumptionsLab lifecycle: validation, preparation, analysis, diagnostics,
# interpretation, recommendations, report.
#
# ES: Este archivo implementa el flujo completo para estimar la estructura
# dimensional de un conjunto de ítems con EGAnet::EGA(). Sigue el ciclo de
# vida de AssumptionsLab: validación, preparación, análisis, diagnóstico,
# interpretación, recomendaciones, informe.
#
# Error policy (CODE_STYLE.md §19.1):
#   Category A - fewer than three items, no data, empty or constant items,
#     EGA() failing to estimate the network -> jmvcore::reject().
#   Category B - network loadings failing for an otherwise valid structure ->
#     the loadings table still renders, with a "Not computable" row and a
#     footnote naming the reason. A failed bootstrap (Stability section)
#     leaves the EGA results intact and explains the failure there.
#
# ES: Política de errores (CODE_STYLE.md §19.1):
#   Categoría A - menos de tres ítems, sin datos, ítems vacíos o constantes,
#     o EGA() sin poder estimar la red -> jmvcore::reject().
#   Categoría B - cargas de red que fallan con una estructura por lo demás
#     válida -> la tabla de cargas se muestra igual, con una fila "No
#     computable" y una nota al pie con la razón. Un bootstrap fallido
#     (sección Estabilidad) deja intactos los resultados de EGA y explica el
#     fallo allí.
# -----------------------------------------------------------------------------

egaClass <- if (requireNamespace("jmvcore", quietly = TRUE)) R6::R6Class(
    "egaClass",
    inherit = egaBase,
    private = list(

        # Items below the stability cutoff in this run's bootstrap, read by
        # the redundancy interpretation.
        # ES: Ítems bajo el punto de corte de estabilidad en el bootstrap de
        # esta ejecución, leídos por la interpretación de redundancia.
        .bootUnstable = character(0),

        .run = function() {

            # -----------------------------------------------------------------
            # Initial setup.
            # ES: Configuración inicial.
            # -----------------------------------------------------------------
            lang <- .el_normalize_lang(self$options$reportLang)
            tr <- function(en, es) .el_tr(lang, en, es)
            txt <- function(section, key) .el_text(lang, section, key)

            private$.setTitles(tr)

            self$results$intro$setContent(
                .el_html_block(NULL, txt("ega", "intro"))
            )

            # Nothing selected yet: show the introduction only, without an
            # error, exactly as AssumptionsLab does on an empty analysis.
            # ES: Aún no hay nada seleccionado: se muestra solo la
            # introducción, sin error, igual que AssumptionsLab con un
            # análisis vacío.
            if (length(self$options$vars) == 0)
                return()

            # -----------------------------------------------------------------
            # About your choices: one explanatory paragraph per estimation
            # decision, for the option currently selected.
            # ES: Acerca de sus elecciones: un párrafo explicativo por
            # decisión de estimación, para la opción seleccionada.
            # -----------------------------------------------------------------
            if (isTRUE(self$options$showChoicesGuide)) {
                labels <- .el_estimation_choice_labels(tr)
                extra <- character(0)
                if (isTRUE(self$options$runBoot)) {
                    labels$bootType <- list(
                        parametric = tr("Parametric", "Paramétrico"),
                        resampling = tr("Resampling (cases)", "Remuestreo (casos)"))
                    extra <- sprintf(txt("choices", "iter_seed"),
                                     as.integer(self$options$iter), as.integer(self$options$seed))
                }
                if (isTRUE(self$options$runUVA))
                    extra <- c(extra, sprintf(txt("choices", "uva_cut"),
                                              .el_fmt_num(as.numeric(self$options$uvaCut), 2)))
                self$results$choicesGuide$setContent(
                    .el_choices_guide(lang, self$options, labels, extra = extra))
            }

            # -----------------------------------------------------------------
            # Validation and preparation (Category A).
            # ES: Validación y preparación (Categoría A).
            # -----------------------------------------------------------------
            prep <- .el_prepare_items(
                self$data, self$options$vars,
                na_data = self$options$naData, min_items = 3
            )

            if (!isTRUE(prep$ok)) {
                message <- txt("common", prep$reason)
                if (prep$reason %in% c("empty_item", "constant_item"))
                    message <- sprintf(message, paste(prep$constant, collapse = ", "))
                jmvcore::reject(message)
            }

            # -----------------------------------------------------------------
            # Analysis.
            # ES: Análisis.
            # -----------------------------------------------------------------
            fit <- .el_capture(EGAnet::EGA(
                data = prep$data,
                corr = self$options$corr,
                na.data = self$options$naData,
                model = self$options$model,
                algorithm = self$options$algorithm,
                uni.method = self$options$uniMethod,
                plot.EGA = FALSE,
                verbose = FALSE
            ))

            if (is.null(fit$value))
                jmvcore::reject(sprintf(txt("common", "estimation_failed"), fit$error))

            ega <- fit$value
            wc <- ega$wc
            items <- names(wc)
            n_dim <- .el_clean_num(ega$n.dim)
            tefi <- .el_clean_num(ega$TEFI)
            isolated <- items[is.na(wc)]

            # -----------------------------------------------------------------
            # Summary table.
            # ES: Tabla de resumen.
            # -----------------------------------------------------------------
            self$results$summaryGuide$setContent(
                .el_html_block(NULL, .el_html_list(txt("ega", "guide_summary")), raw = TRUE)
            )

            corr_label <- switch(self$options$corr,
                auto = tr("Automatic (Pearson / polychoric)", "Automática (Pearson / policórica)"),
                pearson = "Pearson", spearman = "Spearman", cosine = tr("Cosine", "Coseno"))
            if (identical(self$options$corr, "auto") && isTRUE(prep$ordinal_like))
                corr_label <- paste0(corr_label, tr(
                    "; items with 7 or fewer categories treated as ordinal",
                    "; ítems con 7 o menos categorías tratados como ordinales"))

            n_used <- if (identical(self$options$naData, "listwise")) prep$n_complete else prep$n_total

            summary_rows <- list(
                list(tr("Items", "Ítems"), as.character(length(items))),
                list(tr("Cases used", "Casos usados"), paste0(
                    n_used, " (", self$options$naData, "; ",
                    prep$n_complete, tr(" complete cases)", " casos completos)"))),
                list(tr("Correlation", "Correlación"), corr_label),
                list(tr("Network model", "Modelo de red"), self$options$model),
                list(tr("Community detection", "Detección de comunidades"), self$options$algorithm),
                list(tr("Unidimensionality check", "Verificación de unidimensionalidad"), self$options$uniMethod),
                list(tr("Number of dimensions", "Número de dimensiones"),
                     if (is.na(n_dim)) txt("common", "not_computable") else as.character(n_dim)),
                list("TEFI", .el_fmt_num(tefi, 3, txt("common", "not_computable")))
            )

            for (i in seq_along(summary_rows))
                .el_add_row(self$results$summary, i,
                            list(element = summary_rows[[i]][[1]], value = summary_rows[[i]][[2]]))

            # -----------------------------------------------------------------
            # Item membership.
            # ES: Pertenencia de los ítems.
            # -----------------------------------------------------------------
            for (i in seq_along(items)) {
                dim_value <- if (is.na(wc[[i]])) tr("Isolated (no edges)", "Aislado (sin aristas)") else as.character(wc[[i]])
                .el_add_row(self$results$membership, i, list(item = items[i], dimension = dim_value))
            }

            # -----------------------------------------------------------------
            # Network loadings (Category B on failure).
            # ES: Cargas de red (Categoría B si fallan).
            # -----------------------------------------------------------------
            low_loading_items <- character(0)

            if (isTRUE(self$options$showLoadings)) {

                self$results$loadingsGuide$setContent(
                    .el_html_block(NULL, .el_html_list(txt("ega", "guide_loadings")), raw = TRUE)
                )

                table <- self$results$loadings
                loads <- .el_capture(EGAnet::net.loads(A = ega$network, wc = wc))
                std <- if (!is.null(loads$value)) loads$value$std else NULL

                if (is.null(std) || all(is.na(std))) {
                    reason <- if (!is.null(loads$error)) sprintf(txt("ega", "loadings_failed"), loads$error)
                              else txt("ega", "loadings_all_singleton")
                    .el_add_row(table, 1, list(item = txt("common", "not_computable")))
                    table$addFootnote(rowNo = 1, col = "item", reason)
                } else {
                    dims <- colnames(std)
                    for (d in dims)
                        table$addColumn(name = paste0("d", d), title = paste(tr("Dimension", "Dimensión"), d),
                                        type = "number", format = "zto")
                    for (i in seq_len(nrow(std))) {
                        values <- list(item = rownames(std)[i])
                        for (d in dims)
                            values[[paste0("d", d)]] <- .el_clean_num(std[i, d])
                        .el_add_row(table, i, values)
                    }

                    # Dominant loading = the loading on the item's own
                    # dimension. Below 0.15 is "small" in Christensen &
                    # Golino's (2021) guidelines.
                    # ES: Carga dominante = la carga en la propia dimensión
                    # del ítem. Por debajo de 0.15 es "pequeña" según las
                    # guías de Christensen y Golino (2021).
                    for (item in rownames(std)) {
                        own <- wc[[item]]
                        if (!is.na(own) && as.character(own) %in% dims) {
                            value <- .el_clean_num(std[item, as.character(own)])
                            if (!is.na(value) && abs(value) < 0.15)
                                low_loading_items <- c(low_loading_items, item)
                        }
                    }
                }
            }

            # -----------------------------------------------------------------
            # Network scores: summary table and/or new dataset columns.
            # ES: Puntuaciones de red: tabla resumen y/o columnas nuevas en
            # el conjunto de datos.
            # -----------------------------------------------------------------
            score_warnings <- character(0)
            if (isTRUE(self$options$netScores) || isTRUE(self$results$netScoresOV$enabled))
                score_warnings <- private$.computeScores(prep, ega, wc, tr, txt)

            # -----------------------------------------------------------------
            # Interpretation and recommendations.
            # ES: Interpretación y recomendaciones.
            # -----------------------------------------------------------------
            paragraphs <- character(0)

            if (!is.na(n_dim) && n_dim == 1) {
                paragraphs <- c(paragraphs, sprintf(txt("ega", "interp_dims_one"), self$options$uniMethod))
            } else if (!is.na(n_dim)) {
                paragraphs <- c(paragraphs, sprintf(txt("ega", "interp_dims_many"), n_dim, n_dim, n_dim))
            }

            if (length(isolated) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("ega", "interp_isolated"),
                                                    length(isolated), paste(isolated, collapse = ", ")))

            if (!is.na(tefi))
                paragraphs <- c(paragraphs, sprintf(txt("ega", "interp_tefi"), .el_fmt_num(tefi, 3)))

            if (length(low_loading_items) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("ega", "interp_low_loadings"),
                                                    length(low_loading_items), paste(low_loading_items, collapse = ", ")))

            # The next step points to the bootstrap only while it has not
            # been requested; once it runs, its own interpretation follows.
            # ES: El siguiente paso remite al bootstrap solo mientras no se
            # haya pedido; cuando se ejecuta, sigue su propia interpretación.
            if (!isTRUE(self$options$runBoot))
                paragraphs <- c(paragraphs, txt("ega", "interp_next"))

            self$results$interpretation$setContent(.el_html_block(NULL, paragraphs))

            # -----------------------------------------------------------------
            # Stability (bootstrap), only when requested. It re-estimates
            # this same EGA in every sample, with the options above.
            # ES: Estabilidad (bootstrap), solo si se pide. Vuelve a estimar
            # este mismo EGA en cada muestra, con las opciones de arriba.
            # -----------------------------------------------------------------
            boot_warnings <- character(0)
            private$.bootUnstable <- character(0)
            if (isTRUE(self$options$runBoot))
                boot_warnings <- private$.runBootstrap(prep, tr, txt)

            # -----------------------------------------------------------------
            # Redundancy (UVA), only when requested. Runs after the bootstrap
            # so its interpretation can name items that are both redundant
            # and unstable.
            # ES: Redundancia (UVA), solo si se pide. Se ejecuta después del
            # bootstrap para que su interpretación pueda nombrar los ítems
            # que son a la vez redundantes e inestables.
            # -----------------------------------------------------------------
            uva_warnings <- character(0)
            if (isTRUE(self$options$runUVA))
                uva_warnings <- private$.runUVA(prep, wc, tr, txt)

            # -----------------------------------------------------------------
            # Confirmatory factor analysis, only when requested.
            # ES: Análisis factorial confirmatorio, solo si se pide.
            # -----------------------------------------------------------------
            cfa_warnings <- character(0)
            if (isTRUE(self$options$runCFA))
                cfa_warnings <- private$.runCFA(prep, ega, tr, txt)

            # -----------------------------------------------------------------
            # Notes: every EGAnet warning is shown, never suppressed.
            # ES: Notas: cada advertencia de EGAnet se muestra, nunca se
            # suprime.
            # -----------------------------------------------------------------
            warnings <- unique(c(fit$warnings, score_warnings, boot_warnings, uva_warnings, cfa_warnings))
            if (length(warnings) > 0) {
                self$results$notes$setContent(.el_html_block(
                    txt("common", "warnings_title"),
                    .el_html_list(warnings),
                    raw = TRUE
                ))
            } else {
                self$results$notes$setVisible(FALSE)
            }

            # -----------------------------------------------------------------
            # Plot state: only what plot.EGA() needs (network + memberships).
            # ES: Estado del gráfico: solo lo que plot.EGA() necesita (red +
            # pertenencias).
            # -----------------------------------------------------------------
            if (isTRUE(self$options$showNetworkPlot))
                self$results$networkPlot$setState(list(network = ega$network, wc = wc))
        },

        # ---------------------------------------------------------------------
        # Network scores with EGAnet::net.scores() on the network and
        # memberships above. Fills the summary table when it is shown and the
        # Output columns when the user asked to save them. A failure
        # (Category B) is reported in the table and leaves the rest intact.
        # Returns the EGAnet messages captured while it ran.
        # ES: Puntuaciones de red con EGAnet::net.scores() sobre la red y
        # las pertenencias de arriba. Llena la tabla resumen cuando se
        # muestra y las columnas Output cuando el usuario pidió guardarlas.
        # Un fallo (Categoría B) se informa en la tabla y deja intacto el
        # resto. Devuelve los mensajes de EGAnet capturados.
        # ---------------------------------------------------------------------
        .computeScores = function(prep, ega, wc, tr, txt) {

            show <- isTRUE(self$options$netScores)
            table <- self$results$scores
            if (show) {
                table$deleteRows()
                self$results$scoresGuide$setContent(
                    .el_html_block(NULL, .el_html_list(txt("scores", "guide")), raw = TRUE))
            }

            fit <- .el_capture(EGAnet::net.scores(data = prep$data, A = ega$network, wc = wc))
            sc <- if (!is.null(fit$value)) fit$value$scores$std.scores else NULL

            if (is.null(sc)) {
                if (show) {
                    .el_add_row(table, 1, list(dimension = txt("common", "not_computable")))
                    table$addFootnote(rowNo = 1, col = "dimension",
                                      sprintf(txt("scores", "failed"), fit$error))
                }
                return(fit$warnings)
            }

            sc <- as.matrix(sc)
            dims <- colnames(sc)
            if (is.null(dims))
                dims <- as.character(seq_len(ncol(sc)))
            membership <- as.character(wc)

            if (show) {
                for (j in seq_along(dims)) {
                    items <- names(wc)[!is.na(membership) & membership == dims[j]]
                    values <- as.numeric(sc[, j])
                    # Mean of the answered items, so dimensions with different
                    # numbers of items stay on the same scale.
                    # ES: Media de los ítems respondidos, para que dimensiones
                    # con distinto número de ítems queden en la misma escala.
                    r_mean <- if (length(items) > 0)
                        suppressWarnings(stats::cor(values, rowMeans(prep$data[, items, drop = FALSE], na.rm = TRUE),
                                                    use = "pairwise.complete.obs"))
                    else NA
                    .el_add_row(table, j, list(
                        dimension = dims[j],
                        items = length(items),
                        n = sum(!is.na(values)),
                        mean = .el_clean_num(mean(values, na.rm = TRUE)),
                        sd = .el_clean_num(stats::sd(values, na.rm = TRUE)),
                        rMean = .el_clean_num(r_mean)))
                }
            }

            output <- self$results$netScoresOV
            if (isTRUE(output$enabled) && output$isNotFilled()) {
                keys <- seq_along(dims)
                output$set(
                    keys = keys,
                    titles = sprintf(txt("scores", "saved_title"), dims),
                    descriptions = sprintf(txt("scores", "saved_desc"), dims),
                    measureTypes = rep("continuous", length(keys)))
                output$setRowNums(rownames(prep$data))
                for (j in keys)
                    output$setValues(index = j, as.numeric(sc[, j]))
            }

            fit$warnings
        },

        # ---------------------------------------------------------------------
        # Confirmatory factor analysis of the EGA structure (lavaan), with the
        # optional random split: EGA in part A, CFA of that structure in part
        # B, and the total sample and both parts reported side by side. The
        # split leaves the global random stream untouched. Failures are
        # Category B: reported in this section, EGA results intact.
        # Returns the messages captured from EGAnet and lavaan.
        # ES: Análisis factorial confirmatorio de la estructura de EGA
        # (lavaan), con la división aleatoria opcional: EGA en la parte A, CFA
        # de esa estructura en la parte B, y la muestra total y ambas partes
        # lado a lado. La división no altera el flujo aleatorio global. Los
        # fallos son Categoría B: se informan en esta sección y los
        # resultados de EGA quedan intactos.
        # ---------------------------------------------------------------------
        .runCFA = function(prep, ega, tr, txt) {

            split <- isTRUE(self$options$splitSample)
            estimator <- self$options$cfaEstimator
            warnings <- character(0)
            num <- function(x, d = 3) .el_fmt_num(x, d, "—")
            heading <- tr("Confirmatory factor analysis", "Análisis factorial confirmatorio")

            for (name in c("cfaCompare", "cfaMembership", "cfaLoadings"))
                self$results[[name]]$deleteRows()

            wc_total <- ega$wc
            items <- names(wc_total)
            data <- prep$data

            # Samples: total, and parts A and B when the split is on.
            # ES: Muestras: total, y partes A y B cuando hay división.
            samples <- list(total = list(data = data, ega = ega, wc = wc_total))
            fit_total <- .el_cfa_fit(data, wc_total, estimator)
            warnings <- c(warnings, fit_total$warnings)
            fits <- list(total = fit_total)

            if (split) {
                index_a <- .el_split_index(nrow(data), as.numeric(self$options$splitProp),
                                           self$options$splitSeed)
                part <- rep("B", nrow(data)); part[index_a] <- "A"

                for (p in c("A", "B")) {
                    d <- data[part == p, , drop = FALSE]
                    ega_p <- .el_capture(EGAnet::EGA(
                        data = d, corr = self$options$corr, na.data = self$options$naData,
                        model = self$options$model, algorithm = self$options$algorithm,
                        uni.method = self$options$uniMethod, plot.EGA = FALSE, verbose = FALSE))
                    warnings <- c(warnings, ega_p$warnings)
                    samples[[p]] <- list(
                        data = d, ega = ega_p$value, error = ega_p$error,
                        wc = if (!is.null(ega_p$value)) .el_align_wc(ega_p$value$wc, wc_total) else NULL)
                }

                # Part A: CFA of its own structure (in-sample, optimistic).
                # Part B: CFA of part A's structure (the cross-validated test).
                # ES: Parte A: CFA de su propia estructura (en la misma
                # muestra, optimista). Parte B: CFA de la estructura de la
                # parte A (la prueba con validación cruzada).
                wc_a <- samples$A$wc
                if (!is.null(wc_a)) {
                    fits$A <- .el_cfa_fit(samples$A$data, wc_a, estimator)
                    fits$B <- .el_cfa_fit(samples$B$data, wc_a, estimator)
                    warnings <- c(warnings, fits$A$warnings, fits$B$warnings)
                }

                output <- self$results$splitOV
                if (isTRUE(output$enabled) && output$isNotFilled()) {
                    output$setRowNums(rownames(data))
                    output$setValues(factor(part, levels = c("A", "B")))
                }
            }

            # Status: introduction, estimator, notes.
            # ES: Estado: introducción, estimador, notas.
            est_text <- if (identical(estimator, "auto")) {
                if (isTRUE(fit_total$ordinal)) txt("cfa", "estimator_auto_ordinal") else txt("cfa", "estimator_auto_cont")
            } else sprintf(txt("cfa", "estimator_fixed"), estimator)
            status <- c(txt("cfa", "intro"), est_text)
            if (!split)
                status <- c(status, txt("cfa", "no_split_note"))
            if (length(fit_total$dropped) > 0)
                status <- c(status, sprintf(txt("cfa", "dropped_factor"), paste(fit_total$dropped, collapse = ", ")))
            for (p in names(fits))
                if (!isTRUE(fits[[p]]$ok))
                    status <- c(status, sprintf(txt("cfa", "failed"),
                        if (p == "total") "" else paste0(" (", tr("part ", "parte "), p, ")"),
                        fits[[p]]$error))
            if (split) for (p in c("A", "B"))
                if (is.null(samples[[p]]$ega))
                    status <- c(status, sprintf(txt("common", "estimation_failed"), samples[[p]]$error))
            status <- c(status, txt("cfa", "fit_guide"))
            self$results$cfaStatus$setContent(.el_html_block(heading, status))

            # Side-by-side table.
            # ES: Tabla lado a lado.
            cell <- function(p, f) {
                if (is.null(fits[[p]]) || !isTRUE(fits[[p]]$ok)) return("—")
                f(fits[[p]]$fit)
            }
            ega_of <- function(p) samples[[p]]$ega
            n_dim_of <- function(p) { e <- ega_of(p); if (is.null(e)) "—" else as.character(.el_clean_num(e$n.dim)) }
            tefi_of <- function(p) { e <- ega_of(p); if (is.null(e)) "—" else num(.el_clean_num(e$TEFI)) }
            n_of <- function(p) as.character(nrow(samples[[p]]$data))
            cols <- if (split) c("total", "A", "B") else "total"
            key <- c(total = "total", A = "partA", B = "partB")
            rows <- list(
                list(txt("cfa", "row_n"), n_of),
                list(txt("cfa", "row_dims"), n_dim_of),
                list(txt("cfa", "row_tefi"), tefi_of),
                list(txt("cfa", "row_structure"), function(p)
                    if (p == "total") txt("cfa", "row_structure_total") else txt("cfa", "row_structure_A")),
                list(txt("cfa", "row_chisq"), function(p) cell(p, function(f)
                    paste0(num(f[["chisq"]], 2), " (", num(f[["df"]], 0), "), ", .el_fmt_p(f[["pvalue"]])))),
                list(txt("cfa", "row_cfi"), function(p) cell(p, function(f) num(f[["cfi"]]))),
                list(txt("cfa", "row_tli"), function(p) cell(p, function(f) num(f[["tli"]]))),
                list(txt("cfa", "row_rmsea"), function(p) cell(p, function(f)
                    paste0(num(f[["rmsea"]]), " [", num(f[["rmsea_low"]]), ", ", num(f[["rmsea_high"]]), "]"))),
                list(txt("cfa", "row_srmr"), function(p) cell(p, function(f) num(f[["srmr"]]))),
                list(txt("cfa", "row_converged"), function(p) cell(p, function(f)
                    if (isTRUE(f[["converged"]] == 1)) txt("cfa", "yes") else txt("cfa", "no")))
            )
            for (i in seq_along(rows)) {
                values <- list(element = rows[[i]][[1]])
                for (p in cols) values[[key[[p]]]] <- rows[[i]][[2]](p)
                .el_add_row(self$results$cfaCompare, i, values)
            }

            # Membership by sample (split only), labels aligned to the total.
            # ES: Pertenencia por muestra (solo con división), etiquetas
            # alineadas con la total.
            changes <- character(0)
            agree_share <- NA
            if (split && !is.null(samples$A$wc) && !is.null(samples$B$wc)) {
                label <- function(x) if (is.na(x)) tr("Isolated", "Aislado") else
                    if (startsWith(x, "new")) paste0(txt("cfa", "new_dim"), sub("^new", " ", x)) else x
                same <- logical(0)
                for (i in seq_along(items)) {
                    it <- items[i]
                    a <- samples$A$wc[[it]]; b <- samples$B$wc[[it]]
                    s <- !is.na(a) && !is.na(b) && a == b
                    same <- c(same, s)
                    if (!s) changes <- c(changes, it)
                    .el_add_row(self$results$cfaMembership, i, list(
                        item = it, total = label(as.character(wc_total[[it]])),
                        partA = label(a), partB = label(b),
                        agree = if (s) txt("cfa", "yes") else txt("cfa", "changed")))
                }
                agree_share <- mean(same)
            }

            # Loadings: from the validation fit when split, else the total.
            # ES: Cargas: del ajuste de validación con división, si no de la
            # muestra total.
            main <- if (split && !is.null(fits$B) && isTRUE(fits$B$ok)) fits$B else fit_total
            if (isTRUE(main$ok) && !is.null(main$loadings)) {
                ld <- main$loadings
                for (i in seq_len(nrow(ld)))
                    .el_add_row(self$results$cfaLoadings, i, list(
                        item = ld$item[i], factor = ld$factor[i],
                        loading = .el_clean_num(ld$loading[i]), se = .el_clean_num(ld$se[i])))
            }
            self$results$cfaLoadings$setTitle(if (split)
                tr("CFA standardized loadings (part B, validation)", "Cargas estandarizadas del CFA (parte B, validación)")
                else tr("CFA standardized loadings (total sample)", "Cargas estandarizadas del CFA (muestra total)"))

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            if (split) {
                paragraphs <- c(paragraphs, sprintf(txt("cfa", "interp_seed"),
                    sum(part == "A"), sum(part == "B"), as.integer(self$options$splitSeed)))
                d_all <- c(n_dim_of("total"), n_dim_of("A"), n_dim_of("B"))
                paragraphs <- c(paragraphs, sprintf(
                    txt("cfa", if (length(unique(d_all)) == 1) "interp_dims_same" else "interp_dims_diff"),
                    d_all[1], d_all[2], d_all[3]))
                if (!is.na(agree_share))
                    paragraphs <- c(paragraphs, sprintf(txt("cfa", "interp_agree"),
                        paste0(formatC(100 * agree_share, format = "f", digits = 0), "%")))
                if (length(changes) > 0)
                    paragraphs <- c(paragraphs, sprintf(txt("cfa", "interp_changes"), paste(changes, collapse = ", ")))
            }
            fit_line <- function(f, where) {
                lab <- .el_fit_label(f$fit)
                if (!isTRUE(f$ok) || is.na(lab)) return(character(0))
                sprintf(txt("cfa", "interp_fit"), where, num(f$fit[["cfi"]]), num(f$fit[["tli"]]),
                        num(f$fit[["rmsea"]]), num(f$fit[["srmr"]]), txt("cfa", paste0("fit_", lab)))
            }
            if (split && !is.null(fits$B))
                paragraphs <- c(paragraphs, fit_line(fits$B, txt("cfa", "sample_B")))
            paragraphs <- c(paragraphs, fit_line(fit_total, txt("cfa", "sample_total")))
            paragraphs <- c(paragraphs, txt("cfa", "interp_next"))
            self$results$cfaInterpretation$setContent(.el_html_block(NULL, paragraphs))

            unique(warnings)
        },

        # ---------------------------------------------------------------------
        # Redundancy with EGAnet::UVA() (Christensen, Garrido & Golino, 2023),
        # estimated with the same options as the EGA above. UVA is fast, so
        # it runs on every update without a cache. A failure (Category B)
        # leaves the EGA results intact and is explained in this section.
        # Returns the EGAnet messages captured while it ran.
        # ES: Redundancia con EGAnet::UVA() (Christensen, Garrido y Golino,
        # 2023), estimada con las mismas opciones del EGA de arriba. UVA es
        # rápido, así que se ejecuta en cada actualización sin caché. Un
        # fallo (Categoría B) deja intactos los resultados de EGA y se
        # explica en esta sección. Devuelve los mensajes de EGAnet capturados.
        # ---------------------------------------------------------------------
        .runUVA = function(prep, wc, tr, txt) {

            cut <- as.numeric(self$options$uvaCut)
            fmt <- function(x) .el_fmt_num(x, 2)
            heading <- tr("Redundancy (UVA)", "Redundancia (UVA)")
            intro <- txt("uva", "intro")

            for (name in c("uvaPairs", "uvaSets"))
                self$results[[name]]$deleteRows()

            fit <- .el_capture(EGAnet::UVA(
                data = prep$data,
                cut.off = cut,
                reduce = TRUE,
                reduce.method = "remove",
                corr = self$options$corr,
                na.data = self$options$naData,
                model = self$options$model,
                algorithm = self$options$algorithm,
                uni.method = self$options$uniMethod,
                verbose = FALSE
            ))

            if (is.null(fit$value)) {
                self$results$uvaStatus$setContent(.el_html_block(
                    heading, c(intro, sprintf(txt("uva", "failed"), fit$error))))
                for (name in c("uvaPairs", "uvaSets", "uvaInterpretation"))
                    self$results[[name]]$setVisible(FALSE)
                return(fit$warnings)
            }

            summary <- .el_uva_summary(fit$value, cut)

            self$results$uvaStatus$setContent(paste0(
                .el_html_block(heading, intro),
                .el_html_block(NULL, .el_html_list(txt("uva", "guide")), raw = TRUE)))

            # Pairs with wTO >= .20 (or the cutoff, if lower), as EGAnet's
            # own print() shows them.
            # ES: Pares con wTO >= .20 (o el punto de corte, si es menor),
            # como los muestra el print() de EGAnet.
            pairs <- summary$pairs
            dim_of <- function(item) { d <- wc[[item]]; if (is.null(d) || is.na(d)) NA else d }
            if (nrow(pairs) == 0) {
                .el_add_row(self$results$uvaPairs, 1, list(itemA = txt("uva", "no_pairs")))
            } else {
                for (i in seq_len(nrow(pairs))) {
                    w <- pairs$wto[i]
                    magnitude <- if (w > 0.30) txt("uva", "mag_large")
                                 else if (w > 0.25) txt("uva", "mag_moderate")
                                 else txt("uva", "mag_small")
                    da <- dim_of(pairs$node_i[i]); db <- dim_of(pairs$node_j[i])
                    same <- if (is.na(da) || is.na(db)) "" else if (da == db) txt("uva", "yes") else txt("uva", "no")
                    .el_add_row(self$results$uvaPairs, i, list(
                        itemA = pairs$node_i[i], itemB = pairs$node_j[i], wto = w,
                        magnitude = magnitude, sameDim = same))
                }
            }

            # Redundant sets and EGAnet's automatic keep/remove suggestion.
            # ES: Conjuntos redundantes y la sugerencia automática de EGAnet
            # de conservar/eliminar.
            sets <- summary$sets
            for (i in seq_along(sets))
                .el_add_row(self$results$uvaSets, i, list(
                    set = i,
                    items = paste(sets[[i]]$items, collapse = ", "),
                    keep = paste(sets[[i]]$keep, collapse = ", "),
                    remove = paste(sets[[i]]$remove, collapse = ", ")))
            if (length(sets) == 0)
                self$results$uvaSets$setVisible(FALSE)

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            above <- pairs[pairs$wto >= cut, , drop = FALSE]
            borderline <- pairs[pairs$wto < cut & pairs$wto >= 0.20, , drop = FALSE]

            if (length(sets) == 0) {
                paragraphs <- c(paragraphs, sprintf(txt("uva", "interp_none"), fmt(cut)))
            } else {
                set_text <- vapply(sets, function(s) paste0("(", paste(s$items, collapse = ", "), ")"), character(1))
                paragraphs <- c(paragraphs,
                    sprintf(txt("uva", "interp_sets"), length(sets), fmt(cut), paste(set_text, collapse = "; ")),
                    sprintf(txt("uva", "interp_suggest"),
                            paste(unique(unlist(lapply(sets, `[[`, "keep"))), collapse = ", "),
                            paste(unique(unlist(lapply(sets, `[[`, "remove"))), collapse = ", ")))
            }

            if (nrow(borderline) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("uva", "interp_borderline"), nrow(borderline), fmt(cut)))

            if (nrow(above) > 0) {
                split <- vapply(seq_len(nrow(above)), function(i) {
                    da <- dim_of(above$node_i[i]); db <- dim_of(above$node_j[i])
                    !is.na(da) && !is.na(db) && da != db
                }, logical(1))
                if (any(split))
                    paragraphs <- c(paragraphs, sprintf(txt("uva", "interp_split"),
                        paste(paste0(above$node_i[split], "-", above$node_j[split]), collapse = ", ")))
            }

            redundant_items <- unique(unlist(lapply(sets, `[[`, "items")))
            both <- intersect(redundant_items, private$.bootUnstable)
            if (length(both) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("uva", "interp_unstable"), paste(both, collapse = ", ")))

            # Unstable items whose only overlap is borderline (.20 to the
            # cutoff): not redundant by the rule, but worth naming together.
            # ES: Ítems inestables cuyo solapamiento es solo limítrofe (.20
            # hasta el punto de corte): no son redundantes según la regla,
            # pero conviene nombrarlos juntos.
            if (nrow(borderline) > 0 && length(private$.bootUnstable) > 0) {
                hits <- vapply(seq_len(nrow(borderline)), function(i)
                    any(c(borderline$node_i[i], borderline$node_j[i]) %in% private$.bootUnstable), logical(1))
                if (any(hits)) {
                    pairs_text <- paste0(borderline$node_i[hits], "-", borderline$node_j[hits],
                                         " (", .el_fmt_num(borderline$wto[hits], 3), ")")
                    paragraphs <- c(paragraphs, sprintf(txt("uva", "interp_unstable_borderline"),
                        paste(pairs_text, collapse = ", ")))
                }
            }

            paragraphs <- c(paragraphs, txt("uva", "interp_next"))
            self$results$uvaInterpretation$setContent(.el_html_block(NULL, paragraphs))

            fit$warnings
        },

        # ---------------------------------------------------------------------
        # Stability (bootstrap) with EGAnet::bootEGA().
        #
        # Computation time (ARCHITECTURE.md §16): nothing runs until "Run
        # bootstrap" is ticked; the compact summary of the bootstrap is cached
        # in the state of `bootStatus`, whose clearWith lists only the options
        # that change the computation. Language, stability cutoff and plot
        # options re-render from the cache without resampling again.
        # A failed bootstrap (Category B) leaves the EGA results above intact
        # and explains the failure in the status block.
        # Returns the EGAnet messages captured while resampling.
        #
        # ES: Estabilidad (bootstrap) con EGAnet::bootEGA().
        # Tiempo de cálculo (ARCHITECTURE.md §16): nada se ejecuta hasta
        # marcar "Run bootstrap"; el resumen compacto se guarda en el estado
        # de `bootStatus`, cuyo clearWith lista solo las opciones que cambian
        # el cálculo. El idioma, el punto de corte y las opciones de gráfico
        # se vuelven a mostrar desde la caché sin remuestrear.
        # Un bootstrap fallido (Categoría B) deja intactos los resultados de
        # EGA y explica el fallo en el bloque de estado.
        # Devuelve los mensajes de EGAnet capturados durante el remuestreo.
        # ---------------------------------------------------------------------
        .runBootstrap = function(prep, tr, txt) {

            iter <- as.integer(self$options$iter)
            seed <- as.integer(self$options$seed)
            intro <- txt("bootega", "intro")
            # jamovi does not print Html titles, so the section heading goes
            # inside the block to separate it from the EGA results above.
            # ES: jamovi no muestra los títulos de Html, así que el
            # encabezado de la sección va dentro del bloque para separarla de
            # los resultados de EGA de arriba.
            heading <- tr("Stability (bootstrap)", "Estabilidad (bootstrap)")
            cache <- self$results$bootStatus$state

            if (is.null(cache)) {
                fit <- .el_capture(EGAnet::bootEGA(
                    data = prep$data,
                    corr = self$options$corr,
                    na.data = self$options$naData,
                    model = self$options$model,
                    algorithm = self$options$algorithm,
                    uni.method = self$options$uniMethod,
                    iter = iter,
                    type = self$options$bootType,
                    ncores = 1,
                    # EGAnet's C seed generator reads the seed as a double;
                    # jamovi's Integer option arrives as an R integer.
                    # ES: El generador de semillas en C de EGAnet lee la
                    # semilla como double; la opción Integer de jamovi llega
                    # como entero de R.
                    seed = as.numeric(seed),
                    plot.itemStability = FALSE,
                    verbose = FALSE
                ))

                if (is.null(fit$value)) {
                    self$results$bootStatus$setContent(.el_html_block(
                        heading, c(intro, sprintf(txt("bootega", "failed"), fit$error))))
                    private$.hideBoot()
                    return(fit$warnings)
                }

                cache <- .el_boot_summary(fit$value, fit$warnings)
                cache$n_used <- if (identical(self$options$naData, "listwise")) prep$n_complete else prep$n_total
                cache$n_complete <- prep$n_complete
                self$results$bootStatus$setState(cache)
            }

            type_label <- if (identical(self$options$bootType, "parametric"))
                tr("parametric", "paramétrico") else tr("resampling", "remuestreo")
            self$results$bootStatus$setContent(.el_html_block(
                heading, c(intro, sprintf(txt("bootega", "done"), cache$iter, type_label, seed))))

            private$.fillBoot(cache, tr, txt, type_label, seed)
            cache$warnings
        },

        # ---------------------------------------------------------------------
        # Tables, interpretation and plot states from the cached summary.
        # ES: Tablas, interpretación y estados de gráficos desde la caché.
        # ---------------------------------------------------------------------
        .fillBoot = function(cache, tr, txt, type_label, seed) {

            cut <- as.numeric(self$options$stabilityCut)
            pct <- function(x) paste0(formatC(100 * x, format = "f", digits = 1), "%")
            num <- function(x) .el_fmt_num(x, 2, txt("common", "not_computable"))
            dim_label <- function(d) if (is.na(d) || identical(d, "NA")) txt("bootega", "isolated") else as.character(d)

            self$results$bootSummaryGuide$setContent(
                .el_html_block(NULL, .el_html_list(txt("bootega", "guide_summary")), raw = TRUE))

            # Tables are refilled on every run; rows restored from a previous
            # run (when an option outside their clearWith changed) are
            # dropped first so they are never duplicated.
            # ES: Las tablas se rellenan en cada ejecución; las filas
            # restauradas de una ejecución previa (cuando cambió una opción
            # fuera de su clearWith) se eliminan antes para no duplicarlas.
            for (name in c("bootSummary", "bootFrequency", "bootDimStability", "bootItemStability"))
                self$results[[name]]$deleteRows()

            # Summary.
            rows <- list(
                list(tr("Items", "Ítems"), as.character(length(cache$items))),
                list(tr("Cases used", "Casos usados"), paste0(
                    cache$n_used, " (", self$options$naData, "; ",
                    cache$n_complete, tr(" complete cases)", " casos completos)"))),
                list(tr("Bootstrap", "Bootstrap"), paste0(cache$iter, tr(" samples, ", " muestras, "), type_label)),
                list(tr("Seed", "Semilla"), as.character(seed)),
                list(tr("Dimensions in the original sample", "Dimensiones en la muestra original"),
                     if (is.na(cache$empirical_ndim)) txt("common", "not_computable") else as.character(cache$empirical_ndim)),
                list(tr("Median number of dimensions", "Mediana del número de dimensiones"), num(cache$median)),
                list(tr("95% interval (2.5th to 97.5th percentile)", "Intervalo del 95% (percentiles 2.5 a 97.5)"),
                     paste0(num(cache$q_low), tr(" to ", " a "), num(cache$q_high))),
                list(tr("Standard error", "Error estándar"), .el_fmt_num(cache$se, 3, txt("common", "not_computable")))
            )
            for (i in seq_along(rows))
                .el_add_row(self$results$bootSummary, i, list(element = rows[[i]][[1]], value = rows[[i]][[2]]))

            # Frequency.
            freq <- cache$frequency
            for (i in seq_len(nrow(freq)))
                .el_add_row(self$results$bootFrequency, i, list(
                    dims = freq$dims[i], count = freq$count[i], proportion = freq$proportion[i]))

            # Dimension stability.
            ds <- cache$dimensions
            for (i in seq_len(nrow(ds)))
                .el_add_row(self$results$bootDimStability, i, list(
                    dimension = dim_label(ds$dimension[i]), items = ds$items[i],
                    consistency = ds$consistency[i], meanItem = ds$mean_item[i]))

            # Item stability.
            it <- cache$item_table
            for (i in seq_len(nrow(it))) {
                flag <- if (is.na(it$stability[i])) txt("common", "not_computable")
                        else if (it$stability[i] < cut) txt("bootega", "unstable") else txt("bootega", "stable")
                .el_add_row(self$results$bootItemStability, i, list(
                    item = it$item[i], dimension = dim_label(it$dimension[i]),
                    stability = it$stability[i], flag = flag))
            }

            # Interpretation.
            paragraphs <- character(0)
            if (nrow(freq) > 0) {
                mode_row <- freq[which.max(freq$count), ]
                if (!is.na(cache$empirical_ndim) && mode_row$dims == cache$empirical_ndim) {
                    paragraphs <- c(paragraphs, sprintf(txt("bootega", "interp_mode_match"),
                        cache$iter, as.integer(mode_row$dims), pct(mode_row$proportion),
                        num(cache$median), num(cache$q_low), num(cache$q_high)))
                } else {
                    paragraphs <- c(paragraphs, sprintf(txt("bootega", "interp_mode_mismatch"),
                        cache$iter, as.integer(mode_row$dims), pct(mode_row$proportion),
                        as.integer(cache$empirical_ndim),
                        num(cache$median), num(cache$q_low), num(cache$q_high)))
                }
                if (mode_row$proportion < cut)
                    paragraphs <- c(paragraphs, sprintf(txt("bootega", "interp_mode_weak"),
                        pct(mode_row$proportion), pct(cut)))
            }

            low_dims <- ds$dimension[!is.na(ds$consistency) & ds$consistency < cut & ds$dimension != "NA"]
            paragraphs <- c(paragraphs, if (length(low_dims) > 0)
                sprintf(txt("bootega", "interp_dims_low"), pct(cut), paste(low_dims, collapse = ", "))
                else sprintf(txt("bootega", "interp_dims_ok"), pct(cut)))

            low_items <- it$item[!is.na(it$stability) & it$stability < cut]
            private$.bootUnstable <- low_items
            paragraphs <- c(paragraphs, if (length(low_items) > 0)
                sprintf(txt("bootega", "interp_items_low"), length(low_items), pct(cut), paste(low_items, collapse = ", "))
                else sprintf(txt("bootega", "interp_items_ok"), pct(cut)))

            paragraphs <- c(paragraphs, txt("bootega", "interp_next"))
            self$results$bootInterpretation$setContent(.el_html_block(NULL, paragraphs))

            # Plot states.
            # ES: Estados de los gráficos.
            if (isTRUE(self$options$showItemPlot))
                self$results$bootItemPlot$setState(list(
                    items = it, cut = cut,
                    labels = list(y = txt("bootega", "plot_stability"),
                                  dimension = tr("Dimension", "Dimensión"),
                                  isolated = txt("bootega", "isolated"))))

            if (isTRUE(self$options$showFrequencyPlot))
                self$results$bootFrequencyPlot$setState(list(
                    frequency = freq, empirical = cache$empirical_ndim,
                    labels = list(x = txt("bootega", "plot_dims"), y = txt("bootega", "plot_prop"),
                                  original = txt("bootega", "plot_original"),
                                  other = txt("bootega", "plot_other"))))
        },

        .hideBoot = function() {
            for (name in c("bootSummaryGuide", "bootSummary", "bootFrequency", "bootDimStability",
                           "bootItemStability", "bootInterpretation", "bootItemPlot", "bootFrequencyPlot"))
                self$results[[name]]$setVisible(FALSE)
        },

        # ---------------------------------------------------------------------
        # Result titles in the report language.
        # ES: Títulos de resultados en el idioma del informe.
        # ---------------------------------------------------------------------
        .setTitles = function(tr) {
            titles <- list(
                c("intro", "Introduction", "Introducción"),
                c("choicesGuide", "About your choices", "Acerca de sus elecciones"),
                c("summaryGuide", "Dimensional structure", "Estructura dimensional"),
                c("summary", "Dimensional structure", "Estructura dimensional"),
                c("membership", "Item membership", "Pertenencia de los ítems"),
                c("loadingsGuide", "Network loadings", "Cargas de red"),
                c("loadings", "Network loadings (standardized)", "Cargas de red (estandarizadas)"),
                c("interpretation", "Applied interpretation", "Interpretación aplicada"),
                c("networkPlot", "Estimated network", "Red estimada"),
                c("scoresGuide", "Network scores", "Puntuaciones de red"),
                c("scores", "Network scores", "Puntuaciones de red"),
                c("uvaStatus", "Redundancy (UVA)", "Redundancia (UVA)"),
                c("uvaPairs", "Item pairs by weighted topological overlap", "Pares de ítems por solapamiento topológico ponderado"),
                c("uvaSets", "Redundant sets", "Conjuntos redundantes"),
                c("uvaInterpretation", "Redundancy interpretation", "Interpretación de la redundancia"),
                c("bootStatus", "Stability (bootstrap)", "Estabilidad (bootstrap)"),
                c("cfaStatus", "Confirmatory factor analysis", "Análisis factorial confirmatorio"),
                c("cfaCompare", "Total sample and random parts", "Muestra total y partes aleatorias"),
                c("cfaMembership", "Item membership by sample", "Pertenencia de los ítems por muestra"),
                c("cfaInterpretation", "CFA interpretation", "Interpretación del CFA"),
                c("bootSummaryGuide", "Number of dimensions across samples", "Número de dimensiones entre muestras"),
                c("bootSummary", "Number of dimensions across samples", "Número de dimensiones entre muestras"),
                c("bootFrequency", "Frequency of the number of dimensions", "Frecuencia del número de dimensiones"),
                c("bootDimStability", "Dimension stability", "Estabilidad de las dimensiones"),
                c("bootItemStability", "Item stability", "Estabilidad de los ítems"),
                c("bootInterpretation", "Stability interpretation", "Interpretación de la estabilidad"),
                c("bootItemPlot", "Item stability", "Estabilidad de los ítems"),
                c("bootFrequencyPlot", "Frequency of the number of dimensions", "Frecuencia del número de dimensiones"),
                c("notes", "Notes", "Notas")
            )
            for (t in titles)
                tryCatch(self$results[[t[1]]]$setTitle(tr(t[2], t[3])), error = function(e) NULL)

            cols <- list(
                c("summary", "element", "Element", "Elemento"),
                c("summary", "value", "Value", "Valor"),
                c("membership", "item", "Item", "Ítem"),
                c("membership", "dimension", "Dimension", "Dimensión"),
                c("loadings", "item", "Item", "Ítem"),
                c("scores", "dimension", "Dimension", "Dimensión"),
                c("scores", "items", "Items", "Ítems"),
                c("scores", "mean", "Mean", "Media"),
                c("scores", "sd", "SD", "DE"),
                c("scores", "rMean", "r with mean score", "r con el promedio"),
                c("uvaPairs", "itemA", "Item", "Ítem"),
                c("uvaPairs", "itemB", "Item", "Ítem"),
                c("uvaPairs", "magnitude", "Redundancy", "Redundancia"),
                c("uvaPairs", "sameDim", "Same dimension", "Misma dimensión"),
                c("uvaSets", "set", "Set", "Conjunto"),
                c("uvaSets", "items", "Items", "Ítems"),
                c("uvaSets", "keep", "Suggested to keep", "Se sugiere conservar"),
                c("uvaSets", "remove", "Suggested to remove", "Se sugiere eliminar"),
                c("cfaCompare", "element", "Element", "Elemento"),
                c("cfaCompare", "total", "Total sample", "Muestra total"),
                c("cfaCompare", "partA", "Part A (derivation)", "Parte A (derivación)"),
                c("cfaCompare", "partB", "Part B (validation)", "Parte B (validación)"),
                c("cfaMembership", "item", "Item", "Ítem"),
                c("cfaMembership", "total", "Total sample", "Muestra total"),
                c("cfaMembership", "partA", "Part A", "Parte A"),
                c("cfaMembership", "partB", "Part B", "Parte B"),
                c("cfaMembership", "agree", "Same in A and B", "Igual en A y B"),
                c("cfaLoadings", "item", "Item", "Ítem"),
                c("cfaLoadings", "factor", "Factor", "Factor"),
                c("cfaLoadings", "loading", "Loading", "Carga"),
                c("cfaLoadings", "se", "SE", "EE"),
                c("bootSummary", "element", "Element", "Elemento"),
                c("bootSummary", "value", "Value", "Valor"),
                c("bootFrequency", "dims", "Dimensions", "Dimensiones"),
                c("bootFrequency", "count", "Samples", "Muestras"),
                c("bootFrequency", "proportion", "Proportion", "Proporción"),
                c("bootDimStability", "dimension", "Dimension", "Dimensión"),
                c("bootDimStability", "items", "Items", "Ítems"),
                c("bootDimStability", "consistency", "Structural consistency", "Consistencia estructural"),
                c("bootDimStability", "meanItem", "Mean item stability", "Estabilidad media de ítems"),
                c("bootItemStability", "item", "Item", "Ítem"),
                c("bootItemStability", "dimension", "Dimension", "Dimensión"),
                c("bootItemStability", "stability", "Stability", "Estabilidad"),
                c("bootItemStability", "flag", "Assessment", "Valoración")
            )
            for (col in cols)
                tryCatch(self$results[[col[1]]]$getColumn(col[2])$setTitle(tr(col[3], col[4])), error = function(e) NULL)
        },

        # ---------------------------------------------------------------------
        # Network plot. EGAnet draws its own ggplot (GGally::ggnet2) with a
        # manual color scale, so jamovi's ggtheme is not added on top: it
        # would draw axes and a panel background behind the network.
        # ES: Gráfico de red. EGAnet dibuja su propio ggplot (GGally::ggnet2)
        # con escala de color manual, así que el ggtheme de jamovi no se
        # agrega encima: dibujaría ejes y fondo de panel detrás de la red.
        # ---------------------------------------------------------------------
        .plotNetwork = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$network) || sum(state$network != 0) == 0)
                return(FALSE)

            plot <- .el_ega_plot(
                network = state$network,
                wc = state$wc,
                opts = self$options,
                palette = .el_plot_series_palette(self$options$plotPalette)
            )
            if (is.null(plot))
                return(FALSE)

            print(plot)
            TRUE
        },

        # ---------------------------------------------------------------------
        # Item stability: one point per item on a 0-1 scale, colored by its
        # original dimension, with the cutoff as a dashed line. Standard
        # ggplot, so jamovi's ggtheme applies (unlike the network plot).
        # ES: Estabilidad de ítems: un punto por ítem en escala 0-1, coloreado
        # por su dimensión original, con el punto de corte como línea
        # discontinua. ggplot estándar, así que se aplica el ggtheme de jamovi
        # (a diferencia del gráfico de red).
        # ---------------------------------------------------------------------
        .plotBootItems = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$items) || nrow(state$items) == 0)
                return(FALSE)

            df <- state$items
            df$dimension <- ifelse(is.na(df$dimension) | df$dimension == "NA",
                                   state$labels$isolated, as.character(df$dimension))
            order_index <- order(df$dimension, -df$stability)
            df$item <- factor(df$item, levels = rev(df$item[order_index]))
            df$dimension <- factor(df$dimension, levels = unique(df$dimension[order_index]))

            plot <- ggplot2::ggplot(df, ggplot2::aes(x = item, y = stability, color = dimension)) +
                ggplot2::geom_hline(yintercept = state$cut, linetype = "dashed", color = "grey50") +
                ggplot2::geom_segment(ggplot2::aes(xend = item, y = 0, yend = stability), linewidth = 0.8) +
                ggplot2::geom_point(size = 3) +
                ggplot2::coord_flip() +
                ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
                ggplot2::labs(x = NULL, y = state$labels$y, color = state$labels$dimension) +
                ggtheme

            palette <- .el_plot_series_palette(self$options$plotPalette)
            if (!is.null(palette))
                plot <- plot + ggplot2::scale_color_manual(
                    values = rep_len(palette, nlevels(df$dimension)))

            print(plot)
            TRUE
        },

        # ---------------------------------------------------------------------
        # Frequency of the number of dimensions, with the original sample's
        # value highlighted.
        # ES: Frecuencia del número de dimensiones, con el valor de la muestra
        # original resaltado.
        # ---------------------------------------------------------------------
        .plotBootFrequency = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$frequency) || nrow(state$frequency) == 0)
                return(FALSE)

            df <- state$frequency
            df$group <- factor(
                ifelse(!is.na(state$empirical) & df$dims == state$empirical,
                       state$labels$original, state$labels$other),
                levels = c(state$labels$original, state$labels$other))

            plot <- ggplot2::ggplot(df, ggplot2::aes(x = factor(dims), y = proportion, fill = group)) +
                ggplot2::geom_col(width = 0.65) +
                ggplot2::geom_text(ggplot2::aes(label = formatC(proportion, format = "f", digits = 2)),
                                   vjust = -0.4, size = 4) +
                ggplot2::scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.25)) +
                ggplot2::scale_fill_discrete(drop = FALSE) +
                ggplot2::labs(x = state$labels$x, y = state$labels$y, fill = NULL) +
                ggtheme

            palette <- .el_plot_series_palette(self$options$plotPalette)
            if (!is.null(palette))
                plot <- plot + ggplot2::scale_fill_manual(values = palette[1:2], drop = FALSE)

            print(plot)
            TRUE
        }
    )
)

# -----------------------------------------------------------------------------
# .el_boot_summary()
#
# Input: boot - an EGAnet::bootEGA() result (EGA.type = "EGA"); warnings -
#   messages captured while it ran.
# Output: a small list with everything the report needs, so the cached state
#   never holds the hundreds of bootstrap networks bootEGA() returns.
# ES: Salida: una lista pequeña con todo lo que el informe necesita, para que
#   el estado en caché nunca guarde los cientos de redes que devuelve
#   bootEGA().
# -----------------------------------------------------------------------------
.el_boot_summary <- function(boot, warnings = character(0)) {

    ndim <- boot$boot.ndim
    counts <- table(ndim[!is.na(ndim)])
    frequency <- data.frame(
        dims = as.integer(names(counts)),
        count = as.integer(counts),
        proportion = as.numeric(counts) / length(ndim),
        stringsAsFactors = FALSE
    )

    item_obj <- boot$stability$item.stability
    structure <- item_obj$membership$structure
    items <- names(item_obj$membership$empirical)
    if (is.null(items))
        items <- names(structure)
    stability <- as.numeric(item_obj$item.stability$empirical.dimensions)

    item_table <- data.frame(
        item = items,
        dimension = as.character(structure),
        stability = stability,
        stringsAsFactors = FALSE
    )

    dim_obj <- boot$stability$dimension.stability
    dims <- names(dim_obj$structural.consistency)
    dimensions <- data.frame(
        dimension = dims,
        items = vapply(dims, function(d) sum(as.character(structure) == d, na.rm = TRUE), integer(1)),
        consistency = as.numeric(dim_obj$structural.consistency),
        mean_item = as.numeric(dim_obj$average.item.stability[dims]),
        stringsAsFactors = FALSE,
        row.names = NULL
    )

    list(
        iter = as.integer(boot$iter),
        items = items,
        empirical_ndim = .el_clean_num(boot$EGA$n.dim),
        median = .el_clean_num(stats::median(ndim, na.rm = TRUE)),
        se = .el_clean_num(stats::sd(ndim, na.rm = TRUE)),
        q_low = .el_clean_num(stats::quantile(ndim, 0.025, na.rm = TRUE, names = FALSE)),
        q_high = .el_clean_num(stats::quantile(ndim, 0.975, na.rm = TRUE, names = FALSE)),
        frequency = frequency,
        dimensions = dimensions,
        item_table = item_table,
        warnings = unique(as.character(warnings))
    )
}

# -----------------------------------------------------------------------------
# .el_uva_summary()
#
# Input: uva - an EGAnet::UVA() result (reduce.method = "remove"); cut - the
#   wTO cutoff used.
# Output: list(pairs = data frame node_i, node_j, wto with every pair at or
#   above min(.20, cut), sorted from highest wTO; sets = one entry per
#   redundant set with $items, $keep and $remove).
# ES: Salida: list(pairs = data frame con todo par igual o mayor que
#   min(.20, cut), ordenado de mayor a menor wTO; sets = una entrada por
#   conjunto redundante con $items, $keep y $remove).
# -----------------------------------------------------------------------------
.el_uva_summary <- function(uva, cut) {

    pw <- uva$wto$pairwise
    floor_value <- min(0.20, cut)
    pairs <- if (is.null(pw) || nrow(pw) == 0)
        data.frame(node_i = character(0), node_j = character(0), wto = numeric(0))
    else
        data.frame(node_i = as.character(pw$node_i), node_j = as.character(pw$node_j),
                   wto = as.numeric(pw$wto), stringsAsFactors = FALSE)
    pairs <- pairs[!is.na(pairs$wto) & pairs$wto >= floor_value, , drop = FALSE]
    pairs <- pairs[order(-pairs$wto), , drop = FALSE]
    rownames(pairs) <- NULL

    sets <- list()
    redundant <- uva$redundant
    if (length(redundant) > 0) {
        removed <- if (!is.null(uva$keep_remove)) as.character(uva$keep_remove$remove) else character(0)
        for (target in names(redundant)) {
            items <- unique(c(target, as.character(redundant[[target]])))
            sets[[length(sets) + 1]] <- list(
                items = items,
                keep = setdiff(items, removed),
                remove = intersect(items, removed)
            )
        }
    }

    list(pairs = pairs, sets = sets)
}

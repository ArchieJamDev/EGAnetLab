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

        # Lines of the key findings summary of this run: findings,
        # uncertainties and warnings, each one sentence naming its section.
        # ES: Líneas del resumen de hallazgos de esta ejecución: hallazgos,
        # incertidumbres y advertencias, cada una de una oración que nombra
        # su sección.
        .key = NULL,
        .addKey = function(type, text) {
            if (!is.null(private$.key) && length(text) > 0)
                private$.key[[type]] <- c(private$.key[[type]], text)
        },

        # Hierarchical EGA structure of this run (lower-order and
        # higher-order labels of each item), read by the CFA section to fit
        # the hierarchical models.
        # ES: Estructura del EGA jerárquico de esta ejecución (etiquetas de
        # orden inferior y superior de cada ítem), leída por la sección CFA
        # para ajustar los modelos jerárquicos.
        .hierStructure = NULL,

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
            private$.key <- list(findings = character(0), uncertain = character(0), warnings = character(0))

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
                if (isTRUE(self$options$runBootnet))
                    extra <- c(extra, sprintf(txt("choices", "bn_iter_seed"),
                                              as.integer(self$options$bnIter), as.integer(self$options$bnCaseIter),
                                              as.integer(self$options$bnSeed)))
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
            # Negatively worded items. When they are as answered, every
            # analysis uses them reversed; prep$raw keeps them in their
            # original direction for riEGA.
            # ES: Ítems redactados en negativo. Si están tal como se
            # respondieron, todos los análisis los usan invertidos; prep$raw
            # los conserva en su dirección original para riEGA.
            # -----------------------------------------------------------------
            prep$neg <- intersect(as.character(unlist(self$options$negItems)), names(prep$data))
            if (identical(self$options$negCoding, "raw")) {
                prep$raw <- prep$data
                prep$data <- .el_reverse_items(prep$data, prep$neg)
            } else {
                prep$raw <- .el_reverse_items(prep$data, prep$neg)
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
            if (length(prep$neg) > 0)
                summary_rows[[length(summary_rows) + 1]] <- list(
                    tr("Negatively worded items", "Ítems redactados en negativo"),
                    sprintf(if (identical(self$options$negCoding, "raw"))
                                tr("%s (reversed for the analysis)", "%s (invertidos para el análisis)")
                            else tr("%s (already reversed in the data)", "%s (ya invertidos en los datos)"),
                            paste(prep$neg, collapse = ", ")))

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
            # Network connections: every non-zero edge, strongest first, so
            # the weights can be read without labels crowding the plot.
            # ES: Conexiones de la red: cada arista distinta de cero, de la
            # más fuerte a la más débil, para leer los pesos sin que las
            # etiquetas saturen el gráfico.
            # -----------------------------------------------------------------
            if (isTRUE(self$options$showEdgeTable)) {
                edge_table <- self$results$edgeTable
                edges <- .el_edge_list(ega$network, wc)
                if (nrow(edges) == 0) {
                    edge_table$setNote("none", txt("ega", "edges_none"))
                } else {
                    for (i in seq_len(nrow(edges)))
                        .el_add_row(edge_table, i, list(
                            item1 = edges$a[i], item2 = edges$b[i], weight = edges$w[i],
                            relation = if (is.na(edges$same[i])) "—" else if (edges$same[i])
                                sprintf(tr("Within dimension %s", "Dentro de la dimensión %s"), edges$da[i]) else
                                sprintf(tr("Between %s and %s", "Entre %s y %s"), edges$da[i], edges$db[i])))
                    edge_table$setNote("weights", txt("ega", "edges_note"))
                }
            }

            # -----------------------------------------------------------------
            # Network scores: summary table and/or new dataset columns.
            # ES: Puntuaciones de red: tabla resumen y/o columnas nuevas en
            # el conjunto de datos.
            # -----------------------------------------------------------------
            score_warnings <- character(0)
            if (isTRUE(self$options$netScores) || isTRUE(self$results$netScoresOV$enabled) ||
                isTRUE(self$results$meanScoresOV$enabled))
                score_warnings <- private$.computeScores(prep, ega, wc, tr, txt)

            # -----------------------------------------------------------------
            # Compare structures with TEFI, only when requested.
            # ES: Comparar estructuras con TEFI, solo si se pide.
            # -----------------------------------------------------------------
            compare_warnings <- character(0)
            if (isTRUE(self$options$runCompare))
                compare_warnings <- private$.runCompare(prep, ega, tr, txt)

            # -----------------------------------------------------------------
            # Hierarchical EGA and random-intercept EGA, only when requested.
            # ES: EGA jerárquico y EGA con intercepto aleatorio, solo si se
            # piden.
            # -----------------------------------------------------------------
            hier_warnings <- character(0)
            if (isTRUE(self$options$runHier))
                hier_warnings <- private$.runHier(prep, ega, tr, txt)
            ri_warnings <- character(0)
            if (isTRUE(self$options$runRI))
                ri_warnings <- private$.runRI(prep, ega, tr, txt)

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

            # Key findings: structure, isolated items and small loadings.
            # ES: Hallazgos clave: estructura, ítems aislados y cargas
            # pequeñas.
            # The structure goes first among the findings, ahead of the
            # sections that ran before this point.
            # ES: La estructura va primero entre los hallazgos, antes que las
            # secciones que se ejecutaron antes de este punto.
            if (is.na(n_dim)) {
                private$.addKey("warnings", txt("key", "dims_none"))
            } else {
                sizes <- table(stats::na.omit(wc))
                line <- if (n_dim == 1) txt("key", "dims_one") else sprintf(txt("key", "dims_many"), as.integer(n_dim),
                    paste(sprintf(txt("key", "dim_part"), names(sizes), as.integer(sizes)), collapse = "; "))
                private$.key$findings <- c(line, private$.key$findings)
            }
            if (length(isolated) > 0)
                private$.addKey("warnings", sprintf(txt("key", "isolated"), paste(isolated, collapse = ", ")))
            if (length(low_loading_items) > 0)
                private$.addKey("warnings", sprintf(txt("key", "low_loadings"), paste(low_loading_items, collapse = ", ")))
            if (!isTRUE(self$options$runBoot))
                private$.addKey("uncertain", txt("key", "no_boot"))

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
            # Group comparison (metric invariance and NCT), only when
            # requested.
            # ES: Comparación entre grupos (invarianza métrica y NCT), solo si
            # se pide.
            # -----------------------------------------------------------------
            # -----------------------------------------------------------------
            # Centrality and network stability, only when requested.
            # ES: Centralidad y estabilidad de la red, solo si se piden.
            # -----------------------------------------------------------------
            cen_warnings <- character(0)
            if (isTRUE(self$options$runCentrality))
                cen_warnings <- private$.runCentrality(prep, ega, wc, tr, txt)
            bn_warnings <- character(0)
            if (isTRUE(self$options$runBootnet))
                bn_warnings <- private$.runBootnet(prep, ega, tr, txt)

            group_warnings <- character(0)
            if (isTRUE(self$options$runInvariance) || isTRUE(self$options$runNCT))
                group_warnings <- private$.runGroups(prep, ega, tr, txt)

            # -----------------------------------------------------------------
            # Notes: every EGAnet warning is shown, never suppressed.
            # ES: Notas: cada advertencia de EGAnet se muestra, nunca se
            # suprime.
            # -----------------------------------------------------------------
            warnings <- unique(c(fit$warnings, score_warnings, compare_warnings, hier_warnings, ri_warnings, boot_warnings, uva_warnings, cfa_warnings, cen_warnings, bn_warnings, group_warnings))
            # Purely informative package notices are left out (Archie's
            # request): the report already states what they say.
            # ES: Se omiten los avisos puramente informativos de los
            # paquetes (pedido de Archie): el informe ya dice lo que indican.
            warnings <- .el_translate_notices(.el_drop_notices(warnings), lang)
            if (length(warnings) > 0)
                private$.addKey("warnings", sprintf(txt("key", "notes"), length(warnings)))
            self$results$keySummary$setTitle(txt("key", "title"))
            if (isTRUE(self$options$showKeySummary))
                self$results$keySummary$setContent(.el_key_summary(lang, private$.key))
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
            # With the hierarchical EGA, nodes are colored by lower-order
            # dimension and the legend groups them under their higher-order
            # dimension ("Higher 1 · 2"), as plot.hierEGA() does in EGAnet.
            # ES: Con el EGA jerárquico, los nodos se colorean por dimensión
            # de orden inferior y la leyenda los agrupa bajo su dimensión de
            # orden superior ("Superior 1 · 2"), como hace plot.hierEGA() en
            # EGAnet.
            plot_wc <- wc
            hs <- private$.hierStructure
            hier_plot <- isTRUE(self$options$runHier) && !is.null(hs) && isTRUE(hs$hierarchical)
            if (hier_plot) {
                plot_wc <- ifelse(is.na(hs$aligned[items]) | is.na(hs$higher[items]), NA_character_,
                                  sprintf(tr("Higher %s \u00b7 %s", "Superior %s \u00b7 %s"),
                                          hs$higher[items], hs$aligned[items]))
                names(plot_wc) <- items
            }
            self$results$networkPlot$setTitle(if (hier_plot)
                tr("Estimated network (hierarchical: higher · lower order)",
                   "Red estimada (jerárquica: orden superior · inferior)")
                else tr("Estimated network", "Red estimada"))
            if (isTRUE(self$options$showNetworkPlot))
                self$results$networkPlot$setState(list(network = ega$network, wc = plot_wc))
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

            # Item means per dimension, on the original response scale: the
            # mean of the items each person answered in that dimension. They
            # need no network estimate, so they are saved even if net.scores()
            # fails.
            # ES: Promedios de los ítems por dimensión, en la escala original
            # de respuesta: la media de los ítems que cada persona respondió
            # en esa dimensión. No necesitan la red, así que se guardan aunque
            # net.scores() falle.
            means_out <- self$results$meanScoresOV
            if (isTRUE(means_out$enabled) && means_out$isNotFilled()) {
                labels <- sort(unique(as.character(stats::na.omit(wc))))
                if (length(labels) > 0) {
                    keys <- seq_along(labels)
                    means_out$set(
                        keys = keys,
                        titles = sprintf(txt("scores", "mean_title"), labels),
                        descriptions = sprintf(txt("scores", "mean_desc"), labels),
                        measureTypes = rep("continuous", length(keys)))
                    means_out$setRowNums(rownames(prep$data))
                    for (j in keys) {
                        own <- names(wc)[!is.na(wc) & as.character(wc) == labels[j]]
                        values <- rowMeans(as.matrix(prep$data[, own, drop = FALSE]), na.rm = TRUE)
                        values[is.nan(values)] <- NA
                        means_out$setValues(index = j, as.numeric(values))
                    }
                }
            }

            if (!show && !isTRUE(self$results$netScoresOV$enabled))
                return(character(0))

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

            # EGAnet computes scale(data) %*% loadings with every other
            # dimension's loadings set to zero, so one missing answer
            # anywhere leaves the person without any score (NA * 0 is NA).
            # The same product restricted to each dimension's own items gives
            # identical scores for complete cases and keeps the scores of the
            # dimensions a person did answer.
            # ES: EGAnet calcula scale(data) %*% cargas con las cargas de las
            # demás dimensiones en cero, así que una sola respuesta perdida
            # deja a la persona sin ninguna puntuación (NA * 0 es NA). El
            # mismo producto restringido a los ítems de cada dimensión da
            # puntuaciones idénticas en casos completos y conserva las de las
            # dimensiones que la persona sí respondió.
            std <- fit$value$loadings$std
            if (anyNA(prep$data) && !is.null(std) && all(dims %in% colnames(std))) {
                z <- scale(as.matrix(prep$data))
                for (j in seq_along(dims)) {
                    own <- names(wc)[!is.na(membership) & membership == dims[j]]
                    own <- intersect(own, rownames(std))
                    if (length(own) > 0)
                        sc[, j] <- as.numeric(z[, own, drop = FALSE] %*% std[own, dims[j]])
                }
            }

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
                        # Standardized scores have mean 0; drop rounding
                        # residue such as -9.6e-17.
                        # ES: Las puntuaciones estandarizadas tienen media 0;
                        # se elimina el residuo de redondeo como -9.6e-17.
                        mean = .el_clean_num(round(mean(values, na.rm = TRUE), 10)),
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
                    output$set(
                        keys = 1,
                        titles = tr("Subsample", "SubMuestra"),
                        descriptions = sprintf(tr("Random subsample (A = exploration, B = confirmation; seed %d)",
                                                  "Submuestra aleatoria (A = exploración, B = confirmación; semilla %d)"),
                                               as.integer(self$options$splitSeed)),
                        measureTypes = "nominal")
                    output$setRowNums(rownames(data))
                    output$setValues(index = 1, factor(part, levels = c("A", "B")))
                }
            }

            # Status: introduction, estimator, notes.
            # ES: Estado: introducción, estimador, notas.
            est_text <- if (identical(estimator, "auto")) {
                if (isTRUE(fit_total$ordinal)) txt("cfa", "estimator_auto_ordinal") else txt("cfa", "estimator_auto_cont")
            } else sprintf(txt("cfa", "estimator_fixed"), estimator)
            status <- c(txt("cfa", "intro"), est_text)
            # EGA read some items as ordinal (7 or fewer categories) while
            # the CFA used maximum likelihood (6 or more): say why.
            # ES: EGA trató algunos ítems como ordinales (7 categorías o
            # menos) mientras el CFA usó máxima verosimilitud (6 o más):
            # explicar por qué.
            if (identical(estimator, "auto") && identical(self$options$corr, "auto") &&
                isTRUE(prep$ordinal_like) && !isTRUE(fit_total$ordinal))
                status <- c(status, txt("cfa", "estimator_rule"))
            if (!split)
                status <- c(status, txt("cfa", "no_split_note"))
            if (length(fit_total$dropped) > 0)
                status <- c(status, sprintf(txt("cfa", "dropped_factor"), paste(fit_total$dropped, collapse = ", ")))
            for (p in names(fits))
                if (!isTRUE(fits[[p]]$ok))
                    status <- c(status, sprintf(txt("cfa", "failed"),
                        if (p == "total") "" else paste0(" (", tr("subsample ", "SubMuestra "), p, ")"),
                        fits[[p]]$error))
            if (split) for (p in c("A", "B"))
                if (is.null(samples[[p]]$ega))
                    status <- c(status, sprintf(txt("common", "estimation_failed"), samples[[p]]$error))
            status <- c(status, txt("cfa", "fit_guide"), txt("cfa", "fit_guide_more"))
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
                list(txt("cfa", "row_chisq_df"), function(p) cell(p, function(f)
                    if (is.na(f[["df"]]) || f[["df"]] <= 0) "—" else num(f[["chisq"]] / f[["df"]], 2))),
                list("GFI", function(p) cell(p, function(f) num(f[["gfi"]]))),
                list("AGFI", function(p) cell(p, function(f) num(f[["agfi"]]))),
                list("NFI", function(p) cell(p, function(f) num(f[["nfi"]]))),
                list("IFI", function(p) cell(p, function(f) num(f[["ifi"]]))),
                list("AIC", function(p) cell(p, function(f) num(f[["aic"]], 1))),
                list("BIC", function(p) cell(p, function(f) num(f[["bic"]], 1))),
                list(txt("cfa", "row_converged"), function(p) cell(p, function(f)
                    if (isTRUE(f[["converged"]] == 1)) txt("cfa", "yes") else txt("cfa", "no"))),
                list(txt("cfa", "row_admissible"), function(p) {
                    if (is.null(fits[[p]]) || !isTRUE(fits[[p]]$ok)) return("—")
                    if (length(fits[[p]]$problems) == 0) txt("cfa", "yes") else txt("cfa", "no")
                })
            )
            for (i in seq_along(rows)) {
                values <- list(element = rows[[i]][[1]])
                for (p in cols) values[[key[[p]]]] <- rows[[i]][[2]](p)
                .el_add_row(self$results$cfaCompare, i, values)
            }
            # Name the exact problem of each inadmissible solution.
            # ES: Nombrar el problema exacto de cada solución inadmisible.
            sample_name <- c(total = tr("Total sample", "Muestra total"), A = "SubMuestra A", B = "SubMuestra B")
            for (p in cols)
                if (!is.null(fits[[p]]) && isTRUE(fits[[p]]$ok) && length(fits[[p]]$problems) > 0)
                    self$results$cfaCompare$setNote(paste0("adm_", p), paste0(sample_name[[p]], ": ",
                        sprintf(txt("cfa_hier", "inadmissible_note"),
                                .el_describe_problems(fits[[p]]$problems, self$options$reportLang))))

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
                tr("CFA standardized loadings (subsample B, confirmation)", "Cargas estandarizadas del CFA (SubMuestra B, confirmación)")
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

            # Key findings: the confirmation sample when the sample was split.
            # ES: Hallazgos clave: la muestra de confirmación si se dividió.
            key_fit <- if (split && !is.null(fits$B)) fits$B else fit_total
            key_where <- txt("cfa", if (split && !is.null(fits$B)) "sample_B" else "sample_total")
            if (isTRUE(key_fit$ok) && length(key_fit$problems) > 0) {
                private$.addKey("warnings", sprintf(txt("key", "cfa_inadmissible"), key_where,
                    .el_describe_problems(key_fit$problems, self$options$reportLang)))
            } else if (isTRUE(key_fit$ok)) {
                lab <- .el_fit_label(key_fit$fit)
                if (!is.na(lab))
                    private$.addKey(if (lab == "poor") "uncertain" else "findings",
                        sprintf(txt("key", "cfa_fit"), txt("cfa", paste0("fit_", lab)), key_where,
                                num(key_fit$fit[["cfi"]]), num(key_fit$fit[["rmsea"]])))
            }

            # Hierarchical models, when the hierarchical EGA was requested.
            # ES: Modelos jerárquicos, cuando se pidió el EGA jerárquico.
            if (isTRUE(self$options$runHier))
                warnings <- c(warnings, private$.runCFAHier(prep, ega, estimator, tr, txt))

            unique(warnings)
        },

        # ---------------------------------------------------------------------
        # Models with and without hierarchy, all on the total sample and the
        # same items: one factor, correlated factors (EGA and, when it
        # differs, the hierEGA lower order), higher-order factors (from the
        # hierEGA higher order) and bifactor (a general factor plus the
        # lower-order dimensions as specific factors). A model that fails is
        # reported in its row; the others are kept. Returns lavaan messages.
        # ES: Modelos con y sin jerarquía, todos en la muestra total y con los
        # mismos ítems: un factor, factores correlacionados (EGA y, si
        # difiere, el orden inferior de hierEGA), factores de orden superior
        # (del orden superior de hierEGA) y bifactor (un factor general más
        # las dimensiones de orden inferior como factores específicos). Un
        # modelo que falla se informa en su fila; los demás se conservan.
        # Devuelve los mensajes de lavaan.
        # ---------------------------------------------------------------------
        .runCFAHier = function(prep, ega, estimator, tr, txt) {

            table <- self$results$cfaHierModels
            table$deleteRows()
            num <- function(x, d = 3) .el_fmt_num(x, d, "—")
            hs <- private$.hierStructure
            if (is.null(hs)) {
                table$setVisible(FALSE)
                self$results$cfaHierInterpretation$setContent(
                    .el_html_block(NULL, txt("cfa_hier", "unavailable")))
                for (name in c("cfaBifactorGuide", "cfaBifactorLoadings", "cfaBifactorInterpretation"))
                    self$results[[name]]$setVisible(FALSE)
                return(character(0))
            }

            items <- names(ega$wc)
            ega_wc <- as.character(ega$wc); names(ega_wc) <- items
            lower <- hs$lower[items]
            common <- items[!is.na(ega_wc) & !is.na(lower)]
            data <- prep$data
            agree <- .el_agreement(lower[common], ega_wc[common])
            same_lower <- length(agree$moved) == 0 &&
                length(unique(lower[common])) == length(unique(ega_wc[common]))

            models <- list(list(key = "one", label = txt("cfa_hier", "m_one"),
                                fit = .el_cfa_fit(data, stats::setNames(rep("1", length(common)), common), estimator)))
            models[[2]] <- list(key = "ega",
                                label = txt("cfa_hier", if (same_lower) "m_ega_same" else "m_ega"),
                                fit = .el_cfa_fit(data, ega_wc[common], estimator))
            if (!same_lower)
                models[[length(models) + 1]] <- list(key = "lower", label = txt("cfa_hier", "m_lower"),
                                                     fit = .el_cfa_fit(data, lower[common], estimator))
            if (isTRUE(hs$hierarchical))
                models[[length(models) + 1]] <- list(
                    key = "higher", label = sprintf(txt("cfa_hier", "m_higher"), hs$n_higher),
                    fit = .el_cfa_fit(data, lower[common], estimator, type = "higher", higher = hs$higher))
            models[[length(models) + 1]] <- list(key = "bifactor", label = txt("cfa_hier", "m_bifactor"),
                                                 fit = .el_cfa_fit(data, lower[common], estimator, type = "bifactor"))

            warnings <- character(0)
            for (i in seq_along(models)) {
                f <- models[[i]]$fit
                ok <- isTRUE(f$ok)
                v <- if (ok) f$fit else NULL
                .el_add_row(table, i, list(
                    model = models[[i]]$label,
                    items = as.integer(f$n_items),
                    chisq = if (ok) paste0(num(v[["chisq"]], 2), " (", num(v[["df"]], 0), ")") else "—",
                    cfi = if (ok) num(v[["cfi"]]) else "—",
                    tli = if (ok) num(v[["tli"]]) else "—",
                    rmsea = if (ok) num(v[["rmsea"]]) else "—",
                    srmr = if (ok) num(v[["srmr"]]) else "—",
                    aic = if (ok) num(v[["aic"]], 1) else "—",
                    bic = if (ok) num(v[["bic"]], 1) else "—"))
                if (!ok)
                    table$addFootnote(rowNo = i, col = "model",
                                      sprintf(txt("cfa_hier", "failed"), if (is.null(f$error)) "—" else f$error))
                else if (!isTRUE(v[["converged"]] == 1))
                    table$addFootnote(rowNo = i, col = "model", txt("cfa_hier", "not_converged"))
                else if (length(f$problems) > 0)
                    # An inadmissible solution names its exact problem and is
                    # left out of the choice of the best model.
                    # ES: Una solución inadmisible nombra su problema exacto y
                    # queda fuera de la elección del mejor modelo.
                    table$addFootnote(rowNo = i, col = "model", sprintf(txt("cfa_hier", "inadmissible_note"),
                        .el_describe_problems(f$problems, self$options$reportLang)))
                else if (length(f$warnings) > 0)
                    table$addFootnote(rowNo = i, col = "model", sprintf(txt("cfa_hier", "warning_note"),
                        .el_describe_warnings(f$warnings, self$options$reportLang)))
            }

            # Interpretation.
            # ES: Interpretación.
            private$.fillBifactor(models, tr, txt)

            paragraphs <- c(txt("cfa_hier", "intro"))
            ok <- vapply(models, function(m) isTRUE(m$fit$ok) && isTRUE(m$fit$fit[["converged"]] == 1), logical(1))
            admissible <- vapply(models, function(m) length(m$fit$problems) == 0, logical(1))
            for (m in models[ok & !admissible])
                paragraphs <- c(paragraphs, sprintf(txt("cfa_hier", "interp_excluded"), m$label,
                                                    .el_describe_problems(m$fit$problems, self$options$reportLang)))
            fitted <- models[ok & admissible]
            if (length(fitted) == 0) {
                paragraphs <- c(paragraphs, txt("cfa_hier", "interp_none"))
            } else {
                value <- function(m, k) as.numeric(m$fit$fit[[k]])
                best_of <- function(k, lowest) {
                    x <- vapply(fitted, value, numeric(1), k = k)
                    if (all(is.na(x))) return(NULL)
                    fitted[[if (lowest) which.min(x) else which.max(x)]]
                }
                b_cfi <- best_of("cfi", FALSE)
                if (!is.null(b_cfi))
                    paragraphs <- c(paragraphs, sprintf(txt("cfa_hier", "interp_best_cfi"),
                                                        b_cfi$label, num(value(b_cfi, "cfi"))))
                b_bic <- best_of("bic", TRUE)
                if (!is.null(b_bic)) {
                    bics <- sort(stats::na.omit(vapply(fitted, value, numeric(1), k = "bic")))
                    gap <- if (length(bics) > 1) bics[2] - bics[1] else NA_real_
                    paragraphs <- c(paragraphs, sprintf(txt("cfa_hier", "interp_best_bic"),
                                                        b_bic$label, num(value(b_bic, "bic"), 1)))
                    if (!is.na(gap))
                        paragraphs <- c(paragraphs, sprintf(
                            txt("cfa_hier", if (gap >= 10) "interp_bic_gap_strong" else "interp_bic_gap_weak"),
                            num(gap, 1)))
                }
                else
                    paragraphs <- c(paragraphs, txt("cfa_hier", "interp_no_ic"))
                keys <- vapply(fitted, function(m) m$key, character(1))
                base <- if ("lower" %in% keys) fitted[[match("lower", keys)]] else
                    if ("ega" %in% keys && same_lower) fitted[[match("ega", keys)]] else NULL
                if ("higher" %in% keys && !is.null(base)) {
                    hi <- fitted[[match("higher", keys)]]
                    equal <- isTRUE(abs(value(hi, "chisq") - value(base, "chisq")) < 1e-3 &&
                                    value(hi, "df") == value(base, "df"))
                    drop <- value(base, "cfi") - value(hi, "cfi")
                    paragraphs <- c(paragraphs, if (equal) txt("cfa_hier", "interp_equivalent") else
                        sprintf(txt("cfa_hier", if (isTRUE(drop <= 0.01)) "interp_higher_close" else "interp_higher_worse"),
                                num(value(hi, "cfi")), num(value(base, "cfi"))))
                }
                if (!isTRUE(hs$hierarchical))
                    paragraphs <- c(paragraphs, txt("cfa_hier", "interp_no_higher"))
                if ("bifactor" %in% keys)
                    paragraphs <- c(paragraphs, txt("cfa_hier", "interp_bifactor"))
            }
            paragraphs <- c(paragraphs, txt("cfa_hier", "interp_optimistic"))
            self$results$cfaHierInterpretation$setContent(.el_html_block(
                tr("Models with and without hierarchy", "Modelos con y sin jerarquía"), paragraphs))

            unique(warnings)
        },

        # ---------------------------------------------------------------------
        # Group comparison. Independent groups come from the grouping
        # variable; the same people measured twice come from the second set
        # of items (paired, NCT only). Metric invariance (Jamison et al.,
        # 2024) tests whether each item's network loading on its dimension
        # differs between groups; the Network Comparison Test (van Borkulo
        # et al., 2023) tests whether the networks differ in structure
        # (largest edge difference), global strength and, if asked, each edge
        # and each node's strength and expected influence. A failure is
        # explained in its section and leaves the rest intact.
        # ES: Comparación entre grupos. Los grupos independientes vienen de
        # la variable de agrupación; las mismas personas medidas dos veces,
        # del segundo conjunto de ítems (pareado, solo NCT). La invarianza
        # métrica (Jamison et al., 2024) prueba si la carga de red de cada
        # ítem en su dimensión difiere entre grupos; el Network Comparison
        # Test (van Borkulo et al., 2023) prueba si las redes difieren en
        # estructura (mayor diferencia de aristas), fuerza global y, si se
        # pide, en cada arista y en la fuerza e influencia esperada de cada
        # nodo. Un fallo se explica en su sección y deja intacto el resto.
        # ---------------------------------------------------------------------
        .runGroups = function(prep, ega, tr, txt) {

            o <- self$options
            heading <- tr("Group comparison", "Comparación entre grupos")
            sizes <- self$results$groupSizes
            sizes$deleteRows()
            warnings <- character(0)
            items <- names(ega$wc)
            seed <- as.integer(o$groupSeed)

            group_var <- o$group
            has_group <- !is.null(group_var) && length(group_var) == 1 && nzchar(group_var)
            paired_vars <- as.character(unlist(o$pairedVars))
            has_paired <- length(paired_vars) > 0

            intro <- txt("groups", "intro")
            notes <- character(0)

            # Independent groups.
            # ES: Grupos independientes.
            g <- NULL
            if (has_group) {
                g <- .el_group_vector(self$data, rownames(prep$data), group_var)
                # Groups in order of appearance, as the invariance test lists them.
                # ES: Grupos en orden de aparición, como los lista la prueba de
                # invarianza.
                group_order <- function(x) table(factor(x[!is.na(x)], levels = unique(x[!is.na(x)])))
                counts <- group_order(g)
                small <- names(counts)[counts < 10]
                if (length(small) > 0) {
                    notes <- c(notes, sprintf(txt("groups", "small_dropped"), paste(small, collapse = ", ")))
                    g[g %in% small] <- NA
                }
                if (sum(is.na(g)) > 0)
                    notes <- c(notes, sprintf(txt("groups", "missing_group"), sum(is.na(g))))
                counts <- group_order(g)
                for (i in seq_along(counts))
                    .el_add_row(sizes, i, list(group = names(counts)[i], n = as.integer(counts[[i]])))
                if (length(counts) < 2) {
                    notes <- c(notes, txt("groups", "need_two"))
                    g <- NULL
                } else if (length(counts) > 2) {
                    notes <- c(notes, sprintf(txt("groups", "pairwise"), length(counts)))
                }
            }

            # Same people measured twice.
            # ES: Las mismas personas medidas dos veces.
            d2 <- NULL
            if (has_paired) {
                if (length(paired_vars) != length(items)) {
                    notes <- c(notes, sprintf(txt("groups", "paired_count"), length(paired_vars), length(items)))
                } else {
                    index <- match(rownames(prep$data), rownames(self$data))
                    d2 <- as.data.frame(lapply(paired_vars, function(v) jmvcore::toNumeric(self$data[[v]][index])))
                    names(d2) <- items
                    rownames(d2) <- rownames(prep$data)
                    # The second measurement gets the same reversal as the first.
                    # ES: La segunda medición recibe la misma inversión que la
                    # primera.
                    if (identical(o$negCoding, "raw") && length(prep$neg) > 0)
                        d2 <- .el_reverse_items(d2, prep$neg)
                    if (!is.null(g) || !has_group) {
                        both <- stats::complete.cases(prep$data[, items, drop = FALSE]) & stats::complete.cases(d2)
                        .el_add_row(sizes, sizes$rowCount + 1, list(
                            group = tr("Same people, both measurements", "Mismas personas, ambas mediciones"),
                            n = as.integer(sum(both))))
                    }
                }
            }

            if (is.null(g) && is.null(d2))
                notes <- c(notes, txt("groups", "nothing"))

            self$results$groupStatus$setContent(.el_html_block(heading, c(intro, notes)))

            if (isTRUE(o$runInvariance))
                warnings <- c(warnings, private$.runInvariance(prep, ega, g, seed, tr, txt))
            if (isTRUE(o$runNCT))
                warnings <- c(warnings, private$.runNCT(prep, ega, g, d2, seed, tr, txt))

            unique(warnings)
        },

        .runInvariance = function(prep, ega, g, seed, tr, txt) {

            o <- self$options
            heading <- tr("Metric invariance", "Invarianza métrica")
            table <- self$results$invTable
            table$deleteRows()
            hide <- function() for (name in c("invTable", "invPlot", "invInterpretation"))
                self$results[[name]]$setVisible(FALSE)

            if (is.null(g)) {
                self$results$invStatus$setContent(.el_html_block(heading, c(txt("inv", "intro"), txt("inv", "no_groups"))))
                hide()
                return(character(0))
            }

            wc <- ega$wc
            keep <- names(wc)[!is.na(wc)]
            rows <- !is.na(g)
            d <- prep$data[rows, keep, drop = FALSE]
            groups <- g[rows]
            configural <- identical(o$invStructure, "configural")

            # The permutations are slow, so a compact copy of the result is
            # kept in the state of invStatus, which is cleared only when an
            # option that changes the computation changes (not with the
            # report language or the plot).
            # ES: Las permutaciones son lentas, así que una copia compacta del
            # resultado se guarda en el estado de invStatus, que solo se
            # borra cuando cambia una opción que altera el cálculo (no con el
            # idioma del informe ni con el gráfico).
            fit <- self$results$invStatus$state
            if (is.null(fit)) {
                fit <- .el_capture(suppressMessages(EGAnet::invariance(
                    data = d, groups = groups,
                    structure = if (configural) NULL else as.numeric(wc[keep]),
                    iter = as.integer(o$invIter),
                    configural.threshold = as.numeric(o$invConfigCut),
                    configural.type = "parametric",
                    corr = if (identical(o$corr, "cosine")) "auto" else o$corr,
                    na.data = o$naData, model = o$model, algorithm = o$algorithm,
                    uni.method = o$uniMethod, ncores = 1, seed = as.numeric(seed), verbose = FALSE)))
                if (!is.null(fit$value))
                    fit$value <- list(
                        results = fit$value$results, data = fit$value$data,
                        configural.results = list(data = fit$value$configural.results$data),
                        groups = list(unique_groups = fit$value$groups$unique_groups,
                                      loadings = fit$value$groups$loadings),
                        memberships = fit$value$memberships)
                self$results$invStatus$setState(fit)
            }

            status <- c(txt("inv", "intro"),
                        txt("inv", if (configural) "structure_configural" else "structure_ega"),
                        sprintf(txt("inv", "iter_seed"), as.integer(o$invIter), seed))
            if (length(keep) < length(wc))
                status <- c(status, sprintf(txt("inv", "isolated"), paste(setdiff(names(wc), keep), collapse = ", ")))

            if (is.null(fit$value)) {
                self$results$invStatus$setContent(.el_html_block(heading, c(status,
                    sprintf(txt("inv", "failed"), if (is.null(fit$error)) "—" else fit$error))))
                hide()
                return(fit$warnings)
            }
            r <- fit$value
            if (is.null(r$results)) {
                stable <- if (!is.null(r$data)) colnames(r$data) else character(0)
                self$results$invStatus$setContent(.el_html_block(heading, c(status,
                    sprintf(txt("inv", "configural_failed"), as.numeric(o$invConfigCut)))))
                hide()
                return(fit$warnings)
            }

            removed <- character(0)
            if (configural && !is.null(r$configural.results$data))
                removed <- setdiff(keep, colnames(r$configural.results$data))
            if (configural)
                status <- c(status, if (length(removed) == 0) txt("inv", "configural_ok") else
                    sprintf(txt("inv", "configural_partial"), length(removed), paste(removed, collapse = ", ")))
            self$results$invStatus$setContent(paste0(
                .el_html_block(heading, status),
                .el_html_block(NULL, .el_html_list(txt("inv", "guide")), raw = TRUE)))

            # Results by pair of groups.
            # ES: Resultados por par de grupos.
            group_names <- as.character(r$groups$unique_groups)
            loads <- r$groups$loadings
            pairs <- utils::combn(seq_along(group_names), 2, simplify = FALSE)
            memb <- r$memberships
            k <- 0
            sig_items <- character(0); sig_fdr <- character(0); directions <- character(0)
            plot_rows <- list()
            for (i in seq_along(r$results)) {
                df <- r$results[[i]]
                pair <- pairs[[i]]
                label <- paste(group_names[pair[1]], tr("vs.", "vs."), group_names[pair[2]])
                for (it in rownames(df)) {
                    dim <- as.character(df[it, "Membership"])
                    l1 <- tryCatch(as.numeric(loads[[pair[1]]][it, dim]), error = function(e) NA_real_)
                    l2 <- tryCatch(as.numeric(loads[[pair[2]]][it, dim]), error = function(e) NA_real_)
                    p <- as.numeric(df[it, "p"]); padj <- as.numeric(df[it, "p_BH"])
                    direction <- if (!is.na(p) && p <= 0.05) paste(
                        if (isTRUE(df[it, "Difference"] > 0)) group_names[pair[1]] else group_names[pair[2]],
                        ">", if (isTRUE(df[it, "Difference"] > 0)) group_names[pair[2]] else group_names[pair[1]]) else ""
                    k <- k + 1
                    .el_add_row(table, k, list(pair = label, item = it, dimension = dim,
                        load1 = .el_clean_num(l1), load2 = .el_clean_num(l2),
                        diff = .el_clean_num(as.numeric(df[it, "Difference"])),
                        p = .el_clean_num(p), padj = .el_clean_num(padj), direction = direction))
                    if (!is.na(p) && p <= 0.05) { sig_items <- c(sig_items, it); directions <- c(directions, paste0(it, " (", direction, ")")) }
                    if (!is.na(padj) && padj <= 0.05) sig_fdr <- c(sig_fdr, it)
                }
            }
            table$getColumn("load1")$setTitle(tr("Loading, first group", "Carga, primer grupo"))
            table$getColumn("load2")$setTitle(tr("Loading, second group", "Carga, segundo grupo"))
            if (length(group_names) == 2) {
                table$getColumn("load1")$setTitle(sprintf(tr("Loading, %s", "Carga, %s"), group_names[1]))
                table$getColumn("load2")$setTitle(sprintf(tr("Loading, %s", "Carga, %s"), group_names[2]))
                table$getColumn("pair")$setVisible(FALSE)
            }

            # Plot state: assigned loading of each item in each group.
            # ES: Estado del gráfico: carga asignada de cada ítem en cada
            # grupo.
            for (j in seq_along(group_names))
                for (it in names(memb)) {
                    dim <- as.character(memb[[it]])
                    v <- tryCatch(as.numeric(loads[[j]][it, dim]), error = function(e) NA_real_)
                    plot_rows[[length(plot_rows) + 1]] <- data.frame(item = it, dimension = dim, group = group_names[j],
                        loading = v, sig = it %in% sig_items, stringsAsFactors = FALSE)
                }
            if (isTRUE(o$showInvPlot) && length(plot_rows) > 0)
                self$results$invPlot$setState(list(
                    data = do.call(rbind, plot_rows),
                    labels = list(x = tr("Network loading on its dimension", "Carga de red en su dimensión"),
                                  group = tr("Group", "Grupo"),
                                  dimension = tr("Dimension", "Dimensión"),
                                  note = tr("* p ≤ .05 (uncorrected)", "* p ≤ .05 (sin corregir)"))))

            # Interpretation.
            # ES: Interpretación.
            sig_items <- unique(sig_items); sig_fdr <- unique(sig_fdr)
            paragraphs <- character(0)
            if (length(sig_items) == 0) {
                paragraphs <- c(paragraphs, txt("inv", "interp_invariant"))
            } else {
                paragraphs <- c(paragraphs, sprintf(txt("inv", "interp_noninvariant"),
                    length(sig_items), length(names(memb)), paste(unique(directions), collapse = "; ")))
                paragraphs <- c(paragraphs, if (length(sig_fdr) == 0) txt("inv", "interp_fdr_none") else
                    sprintf(txt("inv", "interp_fdr_some"), paste(sig_fdr, collapse = ", ")))
            }
            if (configural && length(removed) > 0)
                paragraphs <- c(paragraphs, txt("inv", "interp_partial"))
            paragraphs <- c(paragraphs, txt("inv", "interp_next"))
            private$.addKey("findings", if (length(sig_items) == 0) txt("key", "inv_ok")
                            else sprintf(txt("key", "inv_diff"), length(sig_items)))
            self$results$invInterpretation$setContent(.el_html_block(NULL, paragraphs))

            fit$warnings
        },

        .runNCT = function(prep, ega, g, d2, seed, tr, txt) {

            o <- self$options
            heading <- tr("Network Comparison Test", "Network Comparison Test")
            global <- self$results$nctGlobal
            edge_table <- self$results$nctEdgeTable
            cen_table <- self$results$nctCentralityTable
            for (t in list(global, edge_table, cen_table)) t$deleteRows()
            hide <- function() for (name in c("nctGlobal", "nctEdgeTable", "nctCentralityTable", "nctInterpretation"))
                self$results[[name]]$setVisible(FALSE)
            items <- names(ega$wc)
            ordinal <- identical(o$nctCorr, "ega") && identical(o$corr, "auto") && isTRUE(prep$ordinal_like)

            status <- c(txt("nct", "intro"),
                        txt("nct", if (ordinal) "estimator_ordinal" else if (isTRUE(prep$ordinal_like))
                            "estimator_pearson_ordinal" else "estimator_pearson"),
                        sprintf(txt("nct", "iter_seed"), as.integer(o$nctIter), seed))
            if (!identical(o$model, "glasso"))
                status <- c(status, sprintf(txt("nct", "model_note"), o$model))

            # Comparisons: every pair of independent groups, and the paired
            # comparison when a second measurement is given.
            # ES: Comparaciones: cada par de grupos independientes, y la
            # comparación pareada cuando hay una segunda medición.
            comps <- list()
            if (!is.null(g)) {
                levels <- unique(g[!is.na(g)])
                for (pr in utils::combn(levels, 2, simplify = FALSE)) {
                    d1 <- prep$data[!is.na(g) & g == pr[1], items, drop = FALSE]
                    dd <- prep$data[!is.na(g) & g == pr[2], items, drop = FALSE]
                    comps[[length(comps) + 1]] <- list(label = paste(pr[1], "vs.", pr[2]), names = pr,
                        d1 = d1[stats::complete.cases(d1), , drop = FALSE],
                        d2 = dd[stats::complete.cases(dd), , drop = FALSE], paired = FALSE)
                }
            }
            if (!is.null(d2)) {
                d1 <- prep$data[, items, drop = FALSE]
                both <- stats::complete.cases(d1) & stats::complete.cases(d2)
                comps[[length(comps) + 1]] <- list(label = tr("Measurement 1 vs. 2", "Medición 1 vs. 2"),
                    names = c(tr("Measurement 1", "Medición 1"), tr("Measurement 2", "Medición 2")),
                    d1 = d1[both, , drop = FALSE], d2 = d2[both, , drop = FALSE], paired = TRUE)
            }
            if (length(comps) == 0) {
                self$results$nctStatus$setContent(.el_html_block(heading, c(status, txt("nct", "nothing"))))
                hide()
                return(character(0))
            }
            if (any(vapply(comps, function(cmp) nrow(cmp$d1) < nrow(prep$data[, items, drop = FALSE]) && !cmp$paired && anyNA(prep$data), logical(1))))
                status <- c(status, txt("nct", "complete_cases"))
            self$results$nctStatus$setContent(paste0(
                .el_html_block(heading, status),
                .el_html_block(NULL, .el_html_list(txt("nct", "guide")), raw = TRUE)))

            warnings <- character(0)
            k <- 0; ke <- 0; kc <- 0
            paragraphs <- character(0)
            # Each comparison is cached in the state of nctStatus (cleared
            # only by options that change the computation), so changing the
            # report language or another section does not repeat the
            # permutations.
            # ES: Cada comparación se guarda en el estado de nctStatus (que
            # solo borran las opciones que cambian el cálculo), así que
            # cambiar el idioma del informe u otra sección no repite las
            # permutaciones.
            cache <- self$results$nctStatus$state
            if (is.null(cache)) cache <- list()
            for (ci in seq_along(comps)) {
                cmp <- comps[[ci]]
                key <- paste0("c", ci)
                fit <- cache[[key]]
                if (is.null(fit)) {
                    private$.checkpoint()
                    fit <- .el_nct(cmp$d1, cmp$d2, paired = cmp$paired, iter = o$nctIter,
                                   edges = isTRUE(o$nctEdges), centrality = isTRUE(o$nctCentrality),
                                   adjust = o$nctAdjust, ordinal = ordinal, seed = seed)
                    cache[[key]] <- fit
                    self$results$nctStatus$setState(cache)
                }
                warnings <- c(warnings, fit$warnings)
                if (is.null(fit$value)) {
                    paragraphs <- c(paragraphs, sprintf(txt("nct", "failed"), cmp$label,
                                                        if (is.null(fit$error)) "—" else fit$error))
                    next
                }
                v <- fit$value
                k <- k + 1
                .el_add_row(global, k, list(pair = cmp$label, test = txt("nct", "row_M"),
                    value1 = "", value2 = "", stat = .el_clean_num(v$M), p = .el_clean_num(v$M_p)))
                k <- k + 1
                .el_add_row(global, k, list(pair = cmp$label, test = txt("nct", "row_S"),
                    value1 = .el_clean_num(v$strength[1]), value2 = .el_clean_num(v$strength[2]),
                    stat = .el_clean_num(v$S), p = .el_clean_num(v$S_p)))

                n_edges <- 0
                if (!is.null(v$edges)) {
                    e <- v$edges[!is.na(v$edges$p) & v$edges$p <= 0.05, , drop = FALSE]
                    n_edges <- nrow(e)
                    for (i in seq_len(nrow(e))) {
                        ke <- ke + 1
                        .el_add_row(edge_table, ke, list(pair = cmp$label, edge = paste(e$a[i], "—", e$b[i]),
                            w1 = .el_clean_num(e$w1[i]), w2 = .el_clean_num(e$w2[i]),
                            diff = .el_clean_num(e$w1[i] - e$w2[i]), p = .el_clean_num(e$p[i])))
                    }
                }
                n_cen <- 0
                if (!is.null(v$centrality)) {
                    cen <- v$centrality
                    n_cen <- sum(!is.na(cen$p) & cen$p <= 0.05)
                    for (i in seq_len(nrow(cen))) {
                        kc <- kc + 1
                        .el_add_row(cen_table, kc, list(pair = cmp$label, item = cen$item[i],
                            measure = if (cen$measure[i] == "strength") tr("Strength", "Fuerza") else
                                tr("Expected influence", "Influencia esperada"),
                            diff = .el_clean_num(cen$diff[i]), p = .el_clean_num(cen$p[i])))
                    }
                }

                # Interpretation of this comparison.
                # ES: Interpretación de esta comparación.
                paragraphs <- c(paragraphs, sprintf(txt("nct", "interp_n"), cmp$label,
                    cmp$names[1], nrow(cmp$d1), cmp$names[2], nrow(cmp$d2),
                    if (cmp$paired) txt("nct", "paired_word") else ""))
                paragraphs <- c(paragraphs, sprintf(
                    txt("nct", if (isTRUE(v$M_p <= 0.05)) "interp_M_sig" else "interp_M_ns"),
                    .el_fmt_num(v$M, 3), .el_fmt_p(v$M_p)))
                paragraphs <- c(paragraphs, sprintf(
                    txt("nct", if (isTRUE(v$S_p <= 0.05)) "interp_S_sig" else "interp_S_ns"),
                    .el_fmt_num(v$strength[1], 2), cmp$names[1], .el_fmt_num(v$strength[2], 2), cmp$names[2],
                    .el_fmt_p(v$S_p)))
                m_sig <- isTRUE(v$M_p <= 0.05)
                s_sig <- isTRUE(v$S_p <= 0.05)
                pair_label <- paste(cmp$names, collapse = " / ")
                private$.addKey("findings", if (!m_sig && !s_sig) sprintf(txt("key", "nct_same"), pair_label)
                    else sprintf(txt("key", "nct_diff"), pair_label,
                                 txt("key", if (m_sig && s_sig) "nct_both" else if (m_sig) "nct_structure" else "nct_strength")))
                if (isTRUE(o$nctEdges))
                    paragraphs <- c(paragraphs, if (n_edges == 0) txt("nct", "interp_edges_none") else
                        sprintf(txt("nct", "interp_edges_some"), n_edges))
                if (isTRUE(o$nctCentrality))
                    paragraphs <- c(paragraphs, if (n_cen == 0) txt("nct", "interp_cen_none") else
                        sprintf(txt("nct", "interp_cen_some"), n_cen))
            }
            if (isTRUE(o$nctEdges) && ke == 0)
                .el_add_row(edge_table, 1, list(edge = txt("nct", "no_edges_note"),
                                                 w1 = "", w2 = "", diff = "", p = ""))
            if (length(comps) == 1) {
                global$getColumn("pair")$setVisible(FALSE)
                edge_table$getColumn("pair")$setVisible(FALSE)
                cen_table$getColumn("pair")$setVisible(FALSE)
                global$getColumn("value1")$setTitle(comps[[1]]$names[1])
                global$getColumn("value2")$setTitle(comps[[1]]$names[2])
                edge_table$getColumn("w1")$setTitle(sprintf(tr("Weight, %s", "Peso, %s"), comps[[1]]$names[1]))
                edge_table$getColumn("w2")$setTitle(sprintf(tr("Weight, %s", "Peso, %s"), comps[[1]]$names[2]))
            }
            global$setNote("M", txt("nct", "note_table"))
            paragraphs <- c(paragraphs, txt("nct", "interp_next"))
            self$results$nctInterpretation$setContent(.el_html_block(NULL, paragraphs))

            unique(warnings)
        },

        # ---------------------------------------------------------------------
        # Bifactor loadings: general and specific loading of each item, its
        # residual variance, the explained common variance (ECV) and the
        # specific factors that collapse into the general one. It shows why
        # a bifactor solution is inadmissible or over-extracted (Rodriguez,
        # Reise & Haviland, 2016).
        # ES: Cargas del bifactor: carga general y específica de cada ítem,
        # su varianza residual, la varianza común explicada (ECV) y los
        # factores específicos que colapsan en el general. Muestra por qué
        # una solución bifactor es inadmisible o está sobreextraída.
        # ---------------------------------------------------------------------
        .fillBifactor = function(models, tr, txt) {

            table <- self$results$cfaBifactorLoadings
            table$deleteRows()
            hide <- function() for (name in c("cfaBifactorGuide", "cfaBifactorLoadings", "cfaBifactorInterpretation"))
                self$results[[name]]$setVisible(FALSE)
            keys <- vapply(models, function(m) m$key, character(1))
            if (!"bifactor" %in% keys) return(hide())
            f <- models[[match("bifactor", keys)]]$fit
            if (!isTRUE(f$ok) || is.null(f$loadings) || nrow(f$loadings) == 0) return(hide())

            L <- f$loadings
            items <- unique(L$item)
            gen <- L[L$factor == "G", , drop = FALSE]
            spe <- L[L$factor != "G", , drop = FALSE]
            g_of <- stats::setNames(gen$loading, gen$item)
            s_of <- stats::setNames(spe$loading, spe$item)
            f_of <- stats::setNames(spe$factor, spe$item)
            resid <- if (is.null(f$resid)) stats::setNames(rep(NA_real_, length(items)), items) else f$resid

            heywood <- character(0); above <- character(0); weak <- character(0)
            for (i in seq_along(items)) {
                it <- items[i]
                g <- .el_clean_num(g_of[it]); sp <- .el_clean_num(s_of[it]); r <- .el_clean_num(resid[it])
                flags <- character(0)
                if (!is.na(r) && r < 0) { flags <- c(flags, txt("bifactor", "flag_heywood")); heywood <- c(heywood, it) }
                if ((!is.na(g) && abs(g) > 1) || (!is.na(sp) && abs(sp) > 1)) {
                    flags <- c(flags, txt("bifactor", "flag_above")); above <- c(above, it) }
                if (!is.na(sp) && abs(sp) < 0.20) { flags <- c(flags, txt("bifactor", "flag_weak")); weak <- c(weak, it) }
                if (!is.na(g) && abs(g) < 0.20) flags <- c(flags, txt("bifactor", "flag_weak_general"))
                .el_add_row(table, i, list(item = it, specific = if (is.na(f_of[it])) "—" else unname(f_of[it]),
                    general = g, spec = sp, resid = r, flag = paste(flags, collapse = "; ")))
            }

            # Explained common variance and collapsing specific factors.
            # ES: Varianza común explicada y factores específicos que
            # colapsan.
            ecv <- sum(gen$loading^2, na.rm = TRUE) / (sum(gen$loading^2, na.rm = TRUE) + sum(spe$loading^2, na.rm = TRUE))
            paragraphs <- sprintf(txt("bifactor", if (isTRUE(ecv >= 0.70)) "interp_ecv_high" else "interp_ecv_low"),
                                  paste0(round(100 * ecv), "%"), .el_fmt_num(ecv, 2))
            few <- character(0)
            for (fac in unique(spe$factor)) {
                own <- spe[spe$factor == fac, , drop = FALSE]
                mean_abs <- mean(abs(own$loading), na.rm = TRUE)
                if (isTRUE(mean_abs < 0.20) || isTRUE(mean(abs(own$loading) < 0.20, na.rm = TRUE) > 0.5))
                    paragraphs <- c(paragraphs, sprintf(txt("bifactor", "interp_collapse"), fac,
                                                        .el_fmt_num(mean_abs, 2)))
                if (nrow(own) <= 3)
                    few <- c(few, paste0(fac, " (", nrow(own), ")"))
            }
            if (length(few) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("bifactor", "interp_few_items"), paste(few, collapse = ", ")))
            weak_general <- items[vapply(items, function(it) isTRUE(abs(.el_clean_num(g_of[it])) < 0.20), logical(1))]
            if (length(weak_general) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("bifactor", "interp_weak_general"), paste(weak_general, collapse = ", ")))
            if (length(heywood) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("bifactor", "interp_heywood"), paste(heywood, collapse = ", ")))
            if (length(above) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("bifactor", "interp_above"), paste(above, collapse = ", ")))
            if (length(heywood) + length(above) == 0 && length(f$problems) == 0)
                paragraphs <- c(paragraphs, txt("bifactor", "interp_admissible"))
            paragraphs <- c(paragraphs, txt("bifactor", "interp_next"))

            self$results$cfaBifactorGuide$setContent(paste0(
                .el_html_block(tr("Bifactor model loadings", "Cargas del modelo bifactor"), txt("bifactor", "intro")),
                .el_html_block(NULL, .el_html_list(txt("bifactor", "guide")), raw = TRUE)))
            self$results$cfaBifactorInterpretation$setContent(.el_html_block(NULL, paragraphs))
        },

        # ---------------------------------------------------------------------
        # Structure comparison with TEFI (Golino et al., 2021). Every
        # structure is scored with EGAnet::tefi() on the correlation matrix
        # of the EGA above, so the values are comparable: the EGA solution,
        # the solutions of the other community algorithms (same network
        # options, seed 2026 for Louvain and Leiden) and the theoretical
        # structure the user wrote. Optionally, a CFA of each structure.
        # A failure in one structure is reported in its row and leaves the
        # rest intact. Returns the EGAnet and lavaan messages captured.
        # ES: Comparación de estructuras con TEFI (Golino et al., 2021).
        # Cada estructura se evalúa con EGAnet::tefi() sobre la matriz de
        # correlaciones del EGA de arriba, así que los valores son
        # comparables: la solución de EGA, las de los otros algoritmos de
        # comunidades (mismas opciones de red, semilla 2026 para Louvain y
        # Leiden) y la estructura teórica escrita por el usuario. Opcional:
        # un CFA de cada estructura. Un fallo en una estructura se informa
        # en su fila y deja intacto el resto. Devuelve los mensajes de
        # EGAnet y lavaan capturados.
        # ---------------------------------------------------------------------
        .runCompare = function(prep, ega, tr, txt) {

            heading <- tr("Compare structures (TEFI)", "Comparar estructuras (TEFI)")
            table <- self$results$compareTable
            members <- self$results$compareMembership
            table$deleteRows()
            members$deleteRows()
            warnings <- character(0)
            fmt <- function(x) .el_fmt_num(x, 3, "—")
            use_cfa <- isTRUE(self$options$compareCFA)
            algo_names <- c(walktrap = "Walktrap", louvain = "Louvain", leiden = "Leiden")

            ref <- as.character(ega$wc)
            names(ref) <- names(ega$wc)
            items <- names(ref)

            # Structures to compare.
            # ES: Estructuras a comparar.
            structures <- list(list(
                key = "ega", kind = "ega", wc = ref, error = NULL,
                label = sprintf(txt("compare", "ega_label"), algo_names[[self$options$algorithm]])))

            if (isTRUE(self$options$compareAlgorithms)) {
                for (alg in setdiff(names(algo_names), self$options$algorithm)) {
                    alt <- .el_capture(.el_with_seed(2026, EGAnet::EGA(
                        data = prep$data,
                        corr = self$options$corr,
                        na.data = self$options$naData,
                        model = self$options$model,
                        algorithm = alg,
                        uni.method = self$options$uniMethod,
                        plot.EGA = FALSE,
                        verbose = FALSE)))
                    warnings <- c(warnings, alt$warnings)
                    wc <- NULL
                    if (!is.null(alt$value)) {
                        wc <- as.character(alt$value$wc[items])
                        names(wc) <- items
                    }
                    structures[[length(structures) + 1]] <- list(
                        key = alg, kind = "algorithm", wc = wc, error = alt$error,
                        label = sprintf(txt("compare", "alt_label"), algo_names[[alg]]))
                }
            }

            parsed <- .el_factors_structure(self$options$theoryFactors, items)
            theory_errors <- character(0)
            if (!parsed$empty) {
                if (length(parsed$unknown) > 0)
                    theory_errors <- c(theory_errors, sprintf(txt("compare", "theory_unknown"),
                                                              paste(parsed$unknown, collapse = ", ")))
                if (length(parsed$duplicated) > 0)
                    theory_errors <- c(theory_errors, sprintf(txt("compare", "theory_duplicated"),
                                                              paste(parsed$duplicated, collapse = ", ")))
                if (length(parsed$duplicated_dims) > 0)
                    theory_errors <- c(theory_errors, sprintf(txt("compare", "theory_dup_dims"),
                                                              paste(parsed$duplicated_dims, collapse = ", ")))
                if (all(is.na(parsed$wc)))
                    theory_errors <- c(theory_errors, txt("compare", "theory_none"))
                if (length(theory_errors) == 0)
                    structures[[length(structures) + 1]] <- list(
                        key = "theory", kind = "theory", wc = parsed$wc, error = NULL,
                        label = txt("compare", "theory_label"))
            }

            # Section heading, guide and any problem with the theoretical
            # structure.
            # ES: Encabezado, guía y cualquier problema con la estructura
            # teórica.
            guide <- txt("compare", "guide")
            if (use_cfa)
                guide <- c(guide, txt("compare", "cfa_guide"))
            status <- paste0(
                .el_html_block(heading, txt("compare", "intro")),
                .el_html_block(NULL, .el_html_list(guide), raw = TRUE))
            if (length(theory_errors) > 0)
                status <- paste0(status, .el_html_block(NULL, theory_errors))
            self$results$compareStatus$setContent(status)

            # Scores for every structure.
            # ES: Valores de cada estructura.
            ega_items <- items[!is.na(ref)]
            for (k in seq_along(structures)) {
                st <- structures[[k]]
                st$dims <- NA_integer_
                st$tefi <- NA_real_
                st$single <- FALSE
                st$comparable <- FALSE
                st$agree <- NULL
                st$cfa <- NULL
                if (!is.null(st$wc)) {
                    st$dims <- length(unique(stats::na.omit(st$wc)))
                    st$single <- st$dims == 1
                    st$unassigned <- items[is.na(st$wc)]
                    if (st$dims >= 2)
                        st$tefi <- .el_tefi(ega, st$wc)
                    st$comparable <- !is.na(st$tefi) && setequal(items[!is.na(st$wc)], ega_items)
                    st$agree <- .el_agreement(st$wc, ref)
                    if (use_cfa) {
                        st$cfa <- .el_cfa_fit(prep$data, st$wc, "auto")
                        warnings <- c(warnings, st$cfa$warnings)
                    }
                }
                structures[[k]] <- st
            }

            tefis <- vapply(structures, function(st) if (st$comparable) st$tefi else NA_real_, numeric(1))
            lowest <- if (any(!is.na(tefis))) min(tefis, na.rm = TRUE) else NA_real_

            # Comparison table.
            # ES: Tabla de comparación.
            for (k in seq_along(structures)) {
                st <- structures[[k]]
                values <- list(structure = st$label)
                if (!is.null(st$wc)) {
                    values$dims <- st$dims
                    values$tefi <- .el_clean_num(st$tefi)
                    values$delta <- if (st$comparable) .el_clean_num(st$tefi - lowest) else NA_real_
                    a <- st$agree
                    values$agree <- if (a$total > 0)
                        sprintf(txt("compare", "agree"), a$same, a$total, round(100 * a$same / a$total))
                    else "—"
                    if (use_cfa && isTRUE(st$cfa$ok)) {
                        values$cfi <- .el_clean_num(st$cfa$fit[["cfi"]])
                        values$rmsea <- .el_clean_num(st$cfa$fit[["rmsea"]])
                        values$srmr <- .el_clean_num(st$cfa$fit[["srmr"]])
                    }
                }
                .el_add_row(table, k, values)
                if (!is.null(st$error) && is.null(st$wc))
                    table$addFootnote(rowNo = k, col = "structure", sprintf(txt("compare", "alt_failed"), st$error))
                if (isTRUE(st$single))
                    table$addFootnote(rowNo = k, col = "tefi", txt("compare", "single"))
                else if (!is.null(st$wc) && length(st$unassigned) > 0)
                    table$addFootnote(rowNo = k, col = "tefi", sprintf(txt("compare", "unassigned"),
                                                                        paste(st$unassigned, collapse = ", ")))
                if (use_cfa && !is.null(st$cfa) && !isTRUE(st$cfa$ok))
                    table$addFootnote(rowNo = k, col = "cfi", sprintf(txt("compare", "cfa_failed"), st$cfa$error))
            }

            # Item membership by structure: algorithm solutions are
            # relabelled to the EGA numbers; the theoretical structure keeps
            # the names the user wrote.
            # ES: Pertenencia de los ítems por estructura: las soluciones de
            # los algoritmos se reetiquetan con los números de EGA; la
            # estructura teórica conserva los nombres que escribió el
            # usuario.
            shown <- Filter(function(st) st$kind != "ega" && !is.null(st$wc), structures)
            for (st in shown)
                members$addColumn(name = st$key, title = st$label, type = "text")
            for (i in seq_along(items)) {
                item <- items[i]
                values <- list(item = item, ega = if (is.na(ref[[item]])) "—" else ref[[item]])
                for (st in shown) {
                    label <- if (st$kind == "theory") st$wc[[item]] else st$agree$aligned[[item]]
                    values[[st$key]] <- if (is.na(label)) "—" else label
                }
                .el_add_row(members, i, values)
            }

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            ega_st <- structures[[1]]
            if (!is.na(lowest)) {
                best <- structures[[which(tefis == lowest)[1]]]
                if (isTRUE(ega_st$comparable) && isTRUE(all.equal(ega_st$tefi, lowest)))
                    paragraphs <- c(paragraphs, sprintf(txt("compare", "interp_best_ega"), fmt(lowest)))
                else if (isTRUE(ega_st$comparable))
                    paragraphs <- c(paragraphs, sprintf(txt("compare", "interp_best_other"),
                                                        best$label, fmt(lowest),
                                                        fmt(ega_st$tefi - lowest), fmt(ega_st$tefi)))
            }

            for (st in structures[-1]) {
                if (is.null(st$wc))
                    next
                if (isTRUE(st$single)) {
                    paragraphs <- c(paragraphs, sprintf(txt("compare", "interp_single"), st$label))
                    next
                }
                a <- st$agree
                if (st$kind == "theory") {
                    if (length(a$moved) == 0 && a$total == length(ega_items) && st$dims == length(unique(stats::na.omit(ref))))
                        paragraphs <- c(paragraphs, txt("compare", "interp_theory_match"))
                    else
                        paragraphs <- c(paragraphs, sprintf(txt("compare", "interp_theory_vs_ega"),
                                                            a$same, a$total,
                                                            if (length(a$moved) > 0) paste(a$moved, collapse = ", ") else "—"))
                } else if (length(a$moved) == 0 && st$dims == length(unique(stats::na.omit(ref)))) {
                    paragraphs <- c(paragraphs, sprintf(txt("compare", "interp_same"), st$label))
                } else {
                    paragraphs <- c(paragraphs, sprintf(txt("compare", "interp_differs"),
                                                        st$label, a$same, a$total, fmt(st$tefi),
                                                        if (st$comparable) fmt(st$tefi - lowest) else "—",
                                                        if (length(a$moved) > 0) paste(a$moved, collapse = ", ") else "—"))
                }
            }

            if (parsed$empty)
                paragraphs <- c(paragraphs, txt("compare", "interp_no_theory"))
            if (use_cfa)
                paragraphs <- c(paragraphs, txt("compare", "interp_cfa"))
            paragraphs <- c(paragraphs, txt("compare", "interp_no_cutoff"))
            if (!is.na(lowest) && isTRUE(ega_st$comparable)) {
                if (isTRUE(all.equal(ega_st$tefi, lowest)))
                    private$.addKey("findings", txt("key", "compare_best_ega"))
                else
                    private$.addKey("uncertain", sprintf(txt("key", "compare_best_other"),
                        structures[[which(tefis == lowest)[1]]]$label))
            }

            self$results$compareInterpretation$setContent(.el_html_block(NULL, paragraphs))

            warnings
        },

        # ---------------------------------------------------------------------
        # Hierarchical EGA with EGAnet::hierEGA() (Jiménez et al., 2023):
        # lower-order dimensions from the lower level of Louvain, network
        # scores of those dimensions, and EGA on the scores for the
        # higher-order dimensions. Louvain uses seed 2026. A failure is
        # explained in the section and leaves the rest intact. Returns the
        # EGAnet messages captured.
        # ES: EGA jerárquico con EGAnet::hierEGA() (Jiménez et al., 2023):
        # dimensiones de orden inferior del nivel inferior de Louvain,
        # puntuaciones de red de esas dimensiones y EGA sobre ellas para las
        # dimensiones de orden superior. Louvain usa la semilla 2026. Un
        # fallo se explica en la sección y deja intacto el resto. Devuelve
        # los mensajes de EGAnet capturados.
        # ---------------------------------------------------------------------
        .runHier = function(prep, ega, tr, txt) {

            private$.hierStructure <- NULL

            heading <- tr("Hierarchical EGA", "EGA jerárquico")
            summary <- self$results$hierSummary
            members <- self$results$hierMembership
            summary$deleteRows()
            members$deleteRows()
            fmt <- function(x) .el_fmt_num(x, 3, "—")
            intro <- c(txt("hier", "intro"))

            corr <- if (identical(self$options$corr, "cosine")) "auto" else self$options$corr
            fit <- .el_capture(suppressMessages(.el_with_seed(2026, EGAnet::hierEGA(
                data = prep$data,
                corr = corr,
                na.data = self$options$naData,
                model = self$options$model,
                uni.method = self$options$uniMethod,
                plot.EGA = FALSE,
                verbose = FALSE))))

            if (is.null(fit$value) || is.null(fit$value$lower_order)) {
                self$results$hierStatus$setContent(.el_html_block(
                    heading, c(intro, sprintf(txt("hier", "failed"), if (is.null(fit$error)) "—" else fit$error))))
                for (name in c("hierSummary", "hierMembership", "hierPlot", "hierInterpretation"))
                    self$results[[name]]$setVisible(FALSE)
                return(fit$warnings)
            }

            status <- paste0(.el_html_block(heading, intro),
                             .el_html_block(NULL, .el_html_list(txt("hier", "guide")), raw = TRUE))
            if (identical(self$options$corr, "cosine"))
                status <- paste0(status, .el_html_block(NULL, txt("hier", "cosine_note")))
            self$results$hierStatus$setContent(status)

            h <- fit$value
            lower <- h$lower_order
            items <- names(ega$wc)
            lower_wc <- as.character(lower$wc[items]); names(lower_wc) <- items
            n_lower <- .el_clean_num(lower$n.dim)
            has_higher <- !is.null(h$dim.variables) && !is.na(n_lower) && n_lower > 1
            higher_wc <- stats::setNames(rep(NA_character_, length(items)), items)
            n_higher <- NA_real_
            if (has_higher) {
                dv <- h$dim.variables
                higher_wc[as.character(dv$items)] <- as.character(dv$higher)
                n_higher <- length(unique(stats::na.omit(higher_wc)))
            }
            ref <- as.character(ega$wc); names(ref) <- items
            aligned <- .el_number_new(.el_align_wc(lower_wc, ref), ref)
            agree <- .el_agreement(lower_wc, ref)

            tefi_lower <- .el_clean_num(lower$TEFI)
            tefi_higher <- if (has_higher) .el_clean_num(h$higher_order$TEFI) else NA_real_
            tefi_general <- .el_clean_num(h$TEFI)
            hierarchical <- has_higher && !is.na(n_higher) && n_higher < n_lower
            better <- if (hierarchical && !is.na(tefi_lower) && !is.na(tefi_higher)) {
                if (tefi_lower < tefi_higher) txt("hier", "better_lower") else txt("hier", "better_higher")
            } else "—"

            rows <- list(
                list(tr("Items", "Ítems"), as.character(length(items))),
                list(txt("hier", "row_lower"), if (is.na(n_lower)) "—" else as.character(n_lower)),
                list(txt("hier", "row_higher"), if (is.na(n_higher)) "—" else as.character(n_higher)),
                list(txt("hier", "row_tefi_lower"), fmt(tefi_lower)),
                list(txt("hier", "row_tefi_higher"), fmt(tefi_higher)),
                list(txt("hier", "row_tefi_general"), fmt(tefi_general)),
                list(txt("hier", "row_better"), better))
            for (i in seq_along(rows))
                .el_add_row(summary, i, list(element = rows[[i]][[1]], value = rows[[i]][[2]]))

            dash <- function(x) if (is.na(x)) "—" else x
            labels <- sort(unique(stats::na.omit(as.character(aligned))))
            if (length(labels) > 0 && !identical(labels, as.character(seq_along(labels))))
                members$setNote("labels", txt("ri", "labels_note"))
            for (i in seq_along(items))
                .el_add_row(members, i, list(
                    item = items[i], ega = dash(ref[[items[i]]]),
                    lower = dash(aligned[[items[i]]]), higher = dash(higher_wc[[items[i]]])))

            private$.hierStructure <- list(lower = lower_wc, higher = higher_wc, aligned = aligned,
                                           hierarchical = hierarchical, n_higher = n_higher)

            # Plot state: items at the bottom, lower-order dimensions in the
            # middle, higher-order dimensions on top; edge width follows the
            # network loadings when they are available.
            # ES: Estado del gráfico: ítems abajo, dimensiones de orden
            # inferior en el medio y de orden superior arriba; el grosor de
            # las aristas sigue las cargas de red cuando están disponibles.
            self$results$hierPlot$setState(.el_hier_plot_state(
                items = items, lower = lower_wc, aligned = aligned, higher = higher_wc,
                lower_loadings = h$parameters$lower_loadings,
                higher_loadings = if (hierarchical) tryCatch(
                    EGAnet::net.loads(h$higher_order)$std, error = function(e) NULL) else NULL,
                labels = list(items = tr("Items", "Ítems"), lower = txt("hier", "plot_lower"),
                              higher = txt("hier", "plot_higher"),
                              isolated = tr("Isolated", "Aislado"))))

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            if (!is.na(n_lower) && n_lower <= 1) {
                paragraphs <- c(paragraphs, txt("hier", "interp_one_lower"))
            } else {
                paragraphs <- c(paragraphs, sprintf(txt("hier", "interp_dims"), n_lower, dash(as.character(n_higher))))
                if (length(agree$moved) == 0 && n_lower == length(unique(stats::na.omit(ref))))
                    paragraphs <- c(paragraphs, txt("hier", "interp_lower_same"))
                else
                    paragraphs <- c(paragraphs, sprintf(txt("hier", "interp_lower_diff"), n_lower,
                        length(unique(stats::na.omit(ref))), agree$same, agree$total,
                        if (length(agree$moved) > 0) paste(agree$moved, collapse = ", ") else "—"))
                if (!hierarchical)
                    paragraphs <- c(paragraphs, txt("hier", "interp_no_higher"))
                else if (n_higher == 1)
                    paragraphs <- c(paragraphs, txt("hier", "interp_general"))
                else
                    paragraphs <- c(paragraphs, sprintf(txt("hier", "interp_several"), n_higher))
                if (hierarchical && !is.na(tefi_lower) && !is.na(tefi_higher))
                    paragraphs <- c(paragraphs, if (tefi_lower < tefi_higher)
                        sprintf(txt("hier", "interp_tefi_lower"), fmt(tefi_lower), fmt(tefi_higher))
                        else sprintf(txt("hier", "interp_tefi_higher"), fmt(tefi_higher), fmt(tefi_lower)))
                if (n_lower < 4)
                    paragraphs <- c(paragraphs, sprintf(txt("hier", "interp_few"), n_lower))
            }
            if (hierarchical || (!is.na(n_lower) && n_lower > 1))
                paragraphs <- c(paragraphs, txt("hier", if (isTRUE(self$options$runCFA)) "interp_cfa_below" else "interp_cfa_hint"))
            paragraphs <- c(paragraphs, txt("hier", "interp_experimental"))
            if (!is.na(n_lower) && n_lower > 1)
                private$.addKey("findings", if (!hierarchical) txt("key", "hier_none")
                    else if (n_higher == 1) sprintf(txt("key", "hier_general"), as.integer(n_lower))
                    else sprintf(txt("key", "hier_several"), as.integer(n_higher), as.integer(n_lower)))
            self$results$hierInterpretation$setContent(.el_html_block(NULL, paragraphs))

            fit$warnings
        },

        # ---------------------------------------------------------------------
        # Random-intercept EGA with EGAnet::riEGA(): a random-intercept factor
        # with equal loadings for every item (the wording or acquiescence
        # factor) is removed, and EGA is estimated on the residual
        # correlations. Valid only with negatively worded items in their
        # original (unrecoded) direction. A failure is explained in the
        # section. Returns the EGAnet messages captured.
        # ES: EGA con intercepto aleatorio con EGAnet::riEGA(): se quita un
        # factor de intercepto aleatorio con cargas iguales para todos los
        # ítems (el factor de redacción o aquiescencia) y se estima EGA sobre
        # las correlaciones residuales. Solo es válido con los ítems
        # redactados en negativo en su dirección original (sin recodificar).
        # Un fallo se explica en la sección. Devuelve los mensajes de EGAnet
        # capturados.
        # ---------------------------------------------------------------------
        .runRI = function(prep, ega, tr, txt) {

            heading <- tr("Wording effects (random-intercept EGA)", "Efectos de redacción (EGA con intercepto aleatorio)")
            summary <- self$results$riSummary
            members <- self$results$riMembership
            summary$deleteRows()
            members$deleteRows()
            fmt <- function(x) .el_fmt_num(x, 3, "—")
            # The validity warning goes first and in bold, before anything
            # else in the section (Archie's request).
            # ES: La advertencia de validez va primero y en negrita, antes
            # de todo lo demás de la sección (pedido de Archie).
            warning_html <- paste0("<p style=\"margin: 0.15em 0 0.65em 0; line-height: 1.40;\"><strong>",
                                   .el_html_escape(txt("ri", "warning")), "</strong></p>")
            intro <- txt("ri", "intro")

            # lavaan needs syntactic names, so items are renamed v1..vk and
            # mapped back afterwards.
            # ES: lavaan necesita nombres sintácticos, así que los ítems se
            # renombran v1..vk y se devuelven a su nombre después.
            items <- names(ega$wc)
            safe <- paste0("v", seq_along(items))
            # riEGA always works on the items in their original direction:
            # prep$raw undoes any reversal of the negatively worded items.
            # ES: riEGA siempre trabaja con los ítems en su dirección
            # original: prep$raw deshace toda inversión de los ítems
            # redactados en negativo.
            raw <- if (is.null(prep$raw)) prep$data else prep$raw
            d <- raw[, items, drop = FALSE]
            names(d) <- safe
            neg <- if (is.null(prep$neg)) character(0) else prep$neg
            neg_note <- if (length(neg) == 0) txt("ri", "neg_none") else
                sprintf(txt("ri", if (identical(self$options$negCoding, "raw")) "neg_raw" else "neg_recoded"),
                        paste(neg, collapse = ", "))

            fit <- if (identical(self$options$model, "BGGM")) {
                list(value = NULL, error = txt("ri", "bggm"), warnings = character(0))
            } else {
                .el_capture(suppressMessages(.el_with_seed(2026, EGAnet::riEGA(
                    data = d,
                    corr = self$options$corr,
                    na.data = self$options$naData,
                    model = self$options$model,
                    algorithm = self$options$algorithm,
                    uni.method = self$options$uniMethod,
                    plot.EGA = FALSE,
                    verbose = FALSE))))
            }

            if (is.null(fit$value) || is.null(fit$value$EGA)) {
                self$results$riStatus$setContent(paste0(
                    .el_html_block(heading, warning_html, raw = TRUE),
                    .el_html_block(NULL, c(intro, neg_note, sprintf(txt("ri", "failed"), if (is.null(fit$error)) "—" else fit$error)))))
                for (name in c("riSummary", "riMembership", "riInterpretation"))
                    self$results[[name]]$setVisible(FALSE)
                return(fit$warnings)
            }

            self$results$riStatus$setContent(paste0(
                .el_html_block(heading, warning_html, raw = TRUE),
                .el_html_block(NULL, c(intro, neg_note)),
                .el_html_block(NULL, .el_html_list(txt("ri", "guide")), raw = TRUE)))

            r <- fit$value
            ri_wc <- as.character(r$EGA$wc[safe]); names(ri_wc) <- items
            ref <- as.character(ega$wc); names(ref) <- items
            aligned <- .el_number_new(.el_align_wc(ri_wc, ref), ref)
            agree <- .el_agreement(ri_wc, ref)
            converged <- !is.null(r$RI$loadings)
            loads <- stats::setNames(rep(NA_real_, length(items)), items)
            if (converged) {
                L <- as.matrix(r$RI$loadings)
                nm <- rownames(L)
                if (!is.null(nm)) {
                    hit <- intersect(safe, nm)
                    loads[items[match(hit, safe)]] <- as.numeric(L[hit, 1])
                } else if (nrow(L) == length(items)) {
                    loads[] <- as.numeric(L[, 1])
                }
            }
            n_ega <- length(unique(stats::na.omit(ref)))
            n_ri <- .el_clean_num(r$EGA$n.dim)
            range_text <- if (converged && any(!is.na(loads)))
                paste0(fmt(min(loads, na.rm = TRUE)), tr(" to ", " a "), fmt(max(loads, na.rm = TRUE)))
            else "—"

            rows <- list(
                list(txt("ri", "row_model"), if (converged) txt("ri", "converged") else txt("ri", "not_converged")),
                list(txt("ri", "row_dims_ega"), as.character(n_ega)),
                list(txt("ri", "row_dims_ri"), if (is.na(n_ri)) "—" else as.character(n_ri)),
                list(txt("ri", "row_loadings"), range_text),
                list(txt("ri", "row_tefi"), fmt(r$TEFI)))
            for (i in seq_along(rows))
                .el_add_row(summary, i, list(element = rows[[i]][[1]], value = rows[[i]][[2]]))

            dash <- function(x) if (is.na(x)) "—" else x
            labels <- sort(unique(stats::na.omit(as.character(aligned))))
            if (length(labels) > 0 && !identical(labels, as.character(seq_along(labels))))
                members$setNote("labels", txt("ri", "labels_note"))
            for (i in seq_along(items))
                .el_add_row(members, i, list(
                    item = items[i], ega = dash(ref[[items[i]]]), riega = dash(aligned[[items[i]]]),
                    loading = .el_clean_num(loads[[items[i]]]),
                    negative = if (items[i] %in% neg) txt("cfa", "yes") else ""))

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            if (!converged)
                private$.addKey("warnings", txt("key", "ri_not_converged"))
            else if (!is.na(n_ri) && n_ri != n_ega)
                private$.addKey("findings", sprintf(txt("key", "ri_changed"), as.integer(n_ri), as.integer(n_ega)))
            else if (!is.na(n_ri))
                private$.addKey("findings", txt("key", "ri_same"))
            if (!converged) {
                paragraphs <- c(paragraphs, txt("ri", "interp_not_converged"))
            } else {
                paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_converged"), range_text))
                if (length(neg) == 0)
                    paragraphs <- c(paragraphs, txt("ri", "interp_no_neg"))
                if (!is.na(n_ri) && n_ri == n_ega && length(agree$moved) == 0)
                    paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_same"), n_ega))
                else if (!is.na(n_ri) && n_ri < n_ega)
                    paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_fewer"), n_ri, n_ega))
                else if (!is.na(n_ri) && n_ri > n_ega)
                    paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_more"), n_ri, n_ega))
                if (length(agree$moved) > 0)
                    paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_moved"), paste(agree$moved, collapse = ", ")))
            }
            # A dimension of EGA made only of negatively worded items is the
            # classic sign of a wording factor.
            # ES: Una dimensión de EGA formada solo por ítems redactados en
            # negativo es la señal clásica de un factor de redacción.
            if (length(neg) > 0) {
                for (g in unique(stats::na.omit(ref))) {
                    own <- items[!is.na(ref) & ref == g]
                    if (length(own) >= 2 && all(own %in% neg))
                        paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_neg_dim"), g, paste(own, collapse = ", ")))
                }
                moved_neg <- intersect(agree$moved, neg)
                if (length(moved_neg) > 0)
                    paragraphs <- c(paragraphs, sprintf(txt("ri", "interp_neg_moved"),
                                                        length(moved_neg), length(agree$moved)))
            }
            paragraphs <- c(paragraphs, txt("ri", "interp_validity"), txt("ri", "interp_tefi"))
            self$results$riInterpretation$setContent(.el_html_block(NULL, paragraphs))

            fit$warnings
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
            if (length(sets) > 0)
                private$.addKey("warnings", sprintf(txt("key", "uva_sets"), paste(vapply(sets, function(st)
                    paste0("(", paste(st$items, collapse = ", "), ")"), character(1)), collapse = "; ")))

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

            # Key findings.
            # ES: Hallazgos clave.
            if (nrow(freq) > 0) {
                if (!is.na(cache$empirical_ndim) && mode_row$dims == cache$empirical_ndim) {
                    private$.addKey(if (mode_row$proportion >= cut) "findings" else "uncertain",
                                    sprintf(txt("key", "boot_match"), pct(mode_row$proportion)))
                } else {
                    private$.addKey("uncertain", sprintf(txt("key", "boot_mismatch"), as.integer(mode_row$dims),
                        pct(mode_row$proportion), as.integer(cache$empirical_ndim)))
                }
                if (mode_row$proportion < cut)
                    private$.addKey("uncertain", sprintf(txt("key", "boot_weak"), pct(mode_row$proportion), pct(cut)))
            }
            if (length(low_dims) > 0)
                private$.addKey("uncertain", sprintf(txt("key", "boot_dims_low"), pct(cut), paste(low_dims, collapse = ", ")))
            if (length(low_items) > 0)
                private$.addKey("uncertain", sprintf(txt("key", "boot_items_low"), pct(cut), paste(low_items, collapse = ", ")))

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
        # ---------------------------------------------------------------------
        # Centrality of each item on the EGA network (qgraph). Fills the
        # table, the plot state and the interpretation.
        # ES: Centralidad de cada ítem en la red de EGA (qgraph). Llena la
        # tabla, el estado del gráfico y la interpretación.
        # ---------------------------------------------------------------------
        .runCentrality = function(prep, ega, wc, tr, txt) {

            heading <- tr("Centrality", "Centralidad")
            intro <- txt("cen", "intro")
            network <- as.matrix(ega$network)
            if (sum(network[upper.tri(network)] != 0) == 0) {
                self$results$cenStatus$setContent(.el_html_block(heading, c(intro, txt("cen", "empty"))))
                self$results$cenTable$setVisible(FALSE)
                self$results$cenPlot$setVisible(FALSE)
                self$results$cenInterpretation$setVisible(FALSE)
                return(character(0))
            }

            z <- isTRUE(self$options$cenStandardize)
            cb <- isTRUE(self$options$cenClosBetw)
            fit <- .el_capture(.el_centrality(network, closbetw = cb, standardize = z))
            if (is.null(fit$value)) {
                self$results$cenStatus$setContent(.el_html_block(
                    heading, c(intro, sprintf(txt("cen", "failed"), fit$error))))
                self$results$cenTable$setVisible(FALSE)
                self$results$cenPlot$setVisible(FALSE)
                self$results$cenInterpretation$setVisible(FALSE)
                return(fit$warnings)
            }
            cen <- fit$value
            raw <- attr(cen, "raw")

            guide <- c(txt("cen", "guide"), txt("cen", if (z) "guide_z" else "guide_raw"))
            self$results$cenStatus$setContent(paste0(
                .el_html_block(heading, intro),
                .el_html_block(NULL, .el_html_list(guide), raw = TRUE)))

            isolated_label <- tr("Isolated", "Aislado")
            dim_of <- function(item) {
                d <- wc[[item]]
                if (is.null(d) || is.na(d)) isolated_label else as.character(d)
            }

            table <- self$results$cenTable
            for (i in seq_len(nrow(cen))) {
                values <- list(item = cen$item[i], dimension = dim_of(cen$item[i]),
                               strength = .el_clean_num(cen$strength[i]),
                               ei = .el_clean_num(cen$ei[i]))
                if (cb) {
                    values$closeness <- .el_clean_num(cen$closeness[i])
                    values$betweenness <- .el_clean_num(cen$betweenness[i])
                }
                .el_add_row(table, i, values)
            }
            table$setNote("values", if (z)
                tr("Values standardized across items (z): mean 0, SD 1.",
                   "Valores estandarizados entre ítems (z): media 0, DE 1.")
                else tr("Raw values: strength and expected influence are sums of partial correlations.",
                        "Valores sin estandarizar: la fuerza y la influencia esperada son sumas de correlaciones parciales."))

            # Plot state: one row per item and measure.
            # ES: Estado del gráfico: una fila por ítem y medida.
            measure_labels <- c(strength = tr("Strength", "Fuerza"),
                                ei = tr("Expected influence", "Influencia esperada"),
                                closeness = tr("Closeness", "Cercanía"),
                                betweenness = tr("Betweenness", "Intermediación"))
            measures <- if (cb) names(measure_labels) else c("strength", "ei")
            long <- do.call(rbind, lapply(measures, function(m) data.frame(
                item = cen$item, dimension = vapply(cen$item, dim_of, ""),
                measure = measure_labels[[m]], value = cen[[m]], stringsAsFactors = FALSE)))
            if (isTRUE(self$options$showCenPlot)) {
                self$results$cenPlot$setSize(if (cb) 760 else 600, max(300, 22 * nrow(cen) + 90))
                self$results$cenPlot$setState(list(
                    data = long, measures = unname(measure_labels[measures]),
                    labels = list(x = if (z) tr("z value", "Valor z") else tr("Value", "Valor"),
                                  dimension = tr("Dimension", "Dimensión"))))
            }

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            ord <- order(-raw$strength)
            top_n <- min(3, nrow(raw))
            top <- raw$item[ord][seq_len(top_n)]
            paragraphs <- c(paragraphs, sprintf(txt("cen", "interp_top"), paste(top, collapse = ", ")))
            private$.addKey("findings", sprintf(txt("key", "cen_top"), paste(top, collapse = ", ")))
            low <- raw$item[rev(ord)][seq_len(min(2, nrow(raw) - top_n))]
            if (length(low) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("cen", "interp_low"), paste(low, collapse = ", ")))
            neg <- raw$item[raw$ei < raw$strength - 1e-10]
            paragraphs <- c(paragraphs, if (length(neg) == 0) txt("cen", "interp_ei_same")
                            else sprintf(txt("cen", "interp_ei_diff"), length(neg), paste(neg, collapse = ", ")))
            n_dims <- length(unique(stats::na.omit(wc)))
            if (n_dims > 1)
                paragraphs <- c(paragraphs, txt("cen", "interp_dims"))
            if (cb)
                paragraphs <- c(paragraphs, txt("cen", "interp_closbetw"))
            paragraphs <- c(paragraphs, if (isTRUE(self$options$runBootnet))
                txt("cen", "interp_with_bn") else txt("cen", "interp_next"))
            self$results$cenInterpretation$setContent(.el_html_block(NULL, paragraphs))

            fit$warnings
        },

        # ---------------------------------------------------------------------
        # Network stability with bootnet: edge intervals (resampling cases)
        # and centrality stability (dropping cases). Cached in bnStatus.
        # ES: Estabilidad de la red con bootnet: intervalos de las aristas
        # (remuestreo de casos) y estabilidad de la centralidad (eliminación
        # de casos). En caché en bnStatus.
        # ---------------------------------------------------------------------
        .runBootnet = function(prep, ega, tr, txt) {

            heading <- tr("Network stability", "Estabilidad de la red")
            intro <- txt("bn", "intro")
            iter <- as.integer(self$options$bnIter)
            case_iter <- as.integer(self$options$bnCaseIter)
            seed <- as.integer(self$options$bnSeed)
            hide <- function() {
                for (r in c("bnCS", "bnEdges", "bnEdgePlot", "bnCasePlot", "bnInterpretation"))
                    self$results[[r]]$setVisible(FALSE)
            }

            network <- as.matrix(ega$network)
            if (sum(network[upper.tri(network)] != 0) == 0) {
                self$results$bnStatus$setContent(.el_html_block(heading, c(intro, txt("bn", "empty"))))
                hide()
                return(character(0))
            }

            cache <- self$results$bnStatus$state
            if (is.null(cache)) {
                private$.checkpoint()
                fit <- .el_capture(.el_bootnet(
                    prep$data, corr = self$options$corr, na_data = self$options$naData,
                    model = self$options$model, iter = iter, case_iter = case_iter,
                    seed = seed, closbetw = isTRUE(self$options$cenClosBetw)))
                if (is.null(fit$value)) {
                    self$results$bnStatus$setContent(.el_html_block(
                        heading, c(intro, sprintf(txt("bn", "failed"), fit$error))))
                    hide()
                    return(fit$warnings)
                }
                cache <- fit$value
                cache$network <- NULL
                cache$warnings <- fit$warnings
                self$results$bnStatus$setState(cache)
            }

            self$results$bnStatus$setContent(paste0(
                .el_html_block(heading, c(intro, sprintf(txt("bn", "done"), cache$iter, cache$case_iter, cache$seed))),
                .el_html_block(NULL, .el_html_list(txt("bn", "guide")), raw = TRUE)))

            measure_labels <- c(strength = tr("Strength", "Fuerza"),
                                expectedInfluence = tr("Expected influence", "Influencia esperada"),
                                closeness = tr("Closeness", "Cercanía"),
                                betweenness = tr("Betweenness", "Intermediación"))
            pct <- function(x) paste0(round(100 * x), "%")

            # CS coefficients.
            # ES: Coeficientes CS.
            cs_table <- self$results$bnCS
            paragraphs <- character(0)
            for (i in seq_along(cache$cs)) {
                m <- names(cache$cs)[i]
                value <- .el_clean_num(cache$cs[[i]])
                reading <- if (is.na(value)) txt("common", "not_computable")
                           else if (value >= 0.5) txt("bn", "cs_good")
                           else if (value >= 0.25) txt("bn", "cs_mid") else txt("bn", "cs_bad")
                .el_add_row(cs_table, i, list(measure = measure_labels[[m]], cs = value, reading = reading))
                if (!is.na(value))
                    private$.addKey(if (value >= 0.5) "findings" else "uncertain",
                        sprintf(txt("key", if (value >= 0.5) "cs_good" else "cs_low"),
                                tolower(measure_labels[[m]]), .el_fmt_num(value, 2)))
                if (!is.na(value)) {
                    key <- if (value >= 0.5) "interp_cs_good" else if (value >= 0.25) "interp_cs_mid" else "interp_cs_bad"
                    args <- list(txt("bn", key), tolower(measure_labels[[m]]), .el_fmt_num(value, 2))
                    if (key == "interp_cs_good") args <- c(args, pct(value))
                    paragraphs <- c(paragraphs, do.call(sprintf, args))
                }
            }
            cs_table$setNote("cs", txt("bn", "cs_note"))

            # Edge intervals.
            # ES: Intervalos de las aristas.
            edges <- cache$edges
            edge_table <- self$results$bnEdges
            for (i in seq_len(nrow(edges)))
                .el_add_row(edge_table, i, list(
                    edge = paste0(edges$a[i], " – ", edges$b[i]),
                    weight = .el_clean_num(edges$weight[i]),
                    low = .el_clean_num(edges$low[i]), high = .el_clean_num(edges$high[i]),
                    nonzero = .el_clean_num(edges$nonzero[i])))
            edge_table$setNote("edges", txt("bn", "edges_note"))

            if (nrow(edges) > 0) {
                stable <- sum(edges$nonzero >= 0.9, na.rm = TRUE)
                zero <- sum(edges$low <= 0 & edges$high >= 0, na.rm = TRUE)
                paragraphs <- c(paragraphs,
                    sprintf(txt("bn", "interp_edges"), stable, nrow(edges), zero),
                    sprintf(txt("bn", "interp_width"),
                            .el_fmt_num(mean(edges$high - edges$low, na.rm = TRUE), 2)))
            }
            paragraphs <- c(paragraphs, txt("bn", "interp_next"))
            self$results$bnInterpretation$setContent(.el_html_block(NULL, paragraphs))

            # Plot states.
            # ES: Estados de los gráficos.
            if (isTRUE(self$options$showEdgeCIPlot) && nrow(edges) > 0) {
                self$results$bnEdgePlot$setSize(600, max(300, 16 * nrow(edges) + 110))
                self$results$bnEdgePlot$setState(list(
                    edges = edges,
                    labels = list(x = tr("Edge weight (95% bootstrap interval)",
                                         "Peso de la arista (intervalo bootstrap del 95%)"))))
            }
            if (isTRUE(self$options$showCasePlot)) {
                cases <- cache$cases
                cases$measure <- unname(measure_labels[cases$measure])
                self$results$bnCasePlot$setSize(600, if (length(unique(cases$measure)) > 2) 560 else 320)
                self$results$bnCasePlot$setState(list(
                    cases = cases,
                    labels = list(x = tr("Cases dropped", "Casos eliminados"),
                                  y = tr("Correlation with the original order",
                                         "Correlación con el orden original"),
                                  measure = tr("Measure", "Medida"),
                                  note = tr("Line: mean correlation. Band: 95% of the samples. Dashed line: .70.",
                                            "Línea: correlación media. Banda: 95% de las muestras. Línea discontinua: .70."))))
            }

            cache$warnings
        },

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
                c("compareStatus", "Compare structures (TEFI)", "Comparar estructuras (TEFI)"),
                c("compareTable", "Structures compared", "Estructuras comparadas"),
                c("compareMembership", "Item membership by structure", "Pertenencia de los ítems por estructura"),
                c("compareInterpretation", "Structure comparison interpretation", "Interpretación de la comparación de estructuras"),
                c("hierStatus", "Hierarchical EGA", "EGA jerárquico"),
                c("hierSummary", "Hierarchical structure", "Estructura jerárquica"),
                c("hierMembership", "Item membership by level", "Pertenencia de los ítems por nivel"),
                c("hierInterpretation", "Hierarchical EGA interpretation", "Interpretación del EGA jerárquico"),
                c("hierPlot", "Hierarchical structure plot", "Gráfico de la estructura jerárquica"),
                c("cenStatus", "Centrality", "Centralidad"),
                c("cenTable", "Centrality of each item", "Centralidad de cada ítem"),
                c("cenPlot", "Centrality of each item", "Centralidad de cada ítem"),
                c("cenInterpretation", "Centrality interpretation", "Interpretación de la centralidad"),
                c("bnStatus", "Network stability", "Estabilidad de la red"),
                c("bnCS", "Centrality stability (CS coefficient)", "Estabilidad de la centralidad (coeficiente CS)"),
                c("bnEdges", "Edge weights with bootstrap intervals", "Pesos de las aristas con intervalos bootstrap"),
                c("bnEdgePlot", "Edge weights with bootstrap intervals", "Pesos de las aristas con intervalos bootstrap"),
                c("bnCasePlot", "Centrality stability when dropping cases", "Estabilidad de la centralidad al eliminar casos"),
                c("bnInterpretation", "Network stability interpretation", "Interpretación de la estabilidad de la red"),
                c("groupStatus", "Group comparison", "Comparación entre grupos"),
                c("groupSizes", "Groups compared", "Grupos comparados"),
                c("invStatus", "Metric invariance", "Invarianza métrica"),
                c("invTable", "Network loadings by group", "Cargas de red por grupo"),
                c("invPlot", "Network loadings by group", "Cargas de red por grupo"),
                c("invInterpretation", "Metric invariance interpretation", "Interpretación de la invarianza métrica"),
                c("nctStatus", "Network Comparison Test", "Network Comparison Test"),
                c("nctGlobal", "Global network comparison", "Comparación global de las redes"),
                c("nctEdgeTable", "Edges that differ", "Aristas que difieren"),
                c("nctCentralityTable", "Node strength and expected influence", "Fuerza e influencia esperada de los nodos"),
                c("nctInterpretation", "Network Comparison Test interpretation", "Interpretación del Network Comparison Test"),
                c("cfaHierModels", "Models with and without hierarchy (total sample)", "Modelos con y sin jerarquía (muestra total)"),
                c("cfaBifactorLoadings", "Bifactor model loadings (standardized, total sample)", "Cargas del modelo bifactor (estandarizadas, muestra total)"),
                c("cfaHierInterpretation", "Hierarchical models interpretation", "Interpretación de los modelos jerárquicos"),
                c("riStatus", "Wording effects (random-intercept EGA)", "Efectos de redacción (EGA con intercepto aleatorio)"),
                c("riSummary", "Random-intercept EGA", "EGA con intercepto aleatorio"),
                c("riMembership", "Item membership with and without wording control", "Pertenencia de los ítems con y sin control de la redacción"),
                c("riInterpretation", "Wording effects interpretation", "Interpretación de los efectos de redacción"),
                c("cfaStatus", "Confirmatory factor analysis", "Análisis factorial confirmatorio"),
                c("cfaCompare", "Total sample and random subsamples", "Muestra total y submuestras aleatorias"),
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
                c("compareTable", "structure", "Structure", "Estructura"),
                c("compareTable", "dims", "Dimensions", "Dimensiones"),
                c("compareTable", "delta", "Difference from lowest", "Diferencia con el más bajo"),
                c("compareTable", "agree", "Items placed as in EGA", "Ítems ubicados como en EGA"),
                c("compareMembership", "item", "Item", "Ítem"),
                c("hierSummary", "element", "Element", "Elemento"),
                c("hierSummary", "value", "Value", "Valor"),
                c("hierMembership", "item", "Item", "Ítem"),
                c("hierMembership", "lower", "Lower order", "Orden inferior"),
                c("hierMembership", "higher", "Higher order", "Orden superior"),
                c("riSummary", "element", "Element", "Elemento"),
                c("riSummary", "value", "Value", "Valor"),
                c("riMembership", "item", "Item", "Ítem"),
                c("riMembership", "loading", "Random-intercept loading", "Carga del intercepto aleatorio"),
                c("riMembership", "negative", "Negatively worded", "Redactado en negativo"),
                c("cenTable", "item", "Item", "Ítem"),
                c("cenTable", "dimension", "Dimension", "Dimensión"),
                c("cenTable", "strength", "Strength", "Fuerza"),
                c("cenTable", "ei", "Expected influence", "Influencia esperada"),
                c("cenTable", "closeness", "Closeness", "Cercanía"),
                c("cenTable", "betweenness", "Betweenness", "Intermediación"),
                c("bnCS", "measure", "Measure", "Medida"),
                c("bnCS", "reading", "Reading", "Lectura"),
                c("bnEdges", "edge", "Edge", "Arista"),
                c("bnEdges", "weight", "Weight", "Peso"),
                c("bnEdges", "low", "Lower", "Inferior"),
                c("bnEdges", "high", "Upper", "Superior"),
                c("bnEdges", "nonzero", "Samples with the edge", "Muestras con la arista"),
                c("groupSizes", "group", "Group", "Grupo"),
                c("invTable", "pair", "Comparison", "Comparación"),
                c("invTable", "item", "Item", "Ítem"),
                c("invTable", "dimension", "Dimension", "Dimensión"),
                c("invTable", "diff", "Difference", "Diferencia"),
                c("invTable", "padj", "p (BH)", "p (BH)"),
                c("invTable", "direction", "Direction", "Dirección"),
                c("nctGlobal", "pair", "Comparison", "Comparación"),
                c("nctGlobal", "test", "Test", "Prueba"),
                c("nctGlobal", "value1", "First", "Primero"),
                c("nctGlobal", "value2", "Second", "Segundo"),
                c("nctGlobal", "stat", "Statistic", "Estadístico"),
                c("nctEdgeTable", "pair", "Comparison", "Comparación"),
                c("nctEdgeTable", "edge", "Edge", "Arista"),
                c("nctEdgeTable", "w1", "Weight, first", "Peso, primero"),
                c("nctEdgeTable", "w2", "Weight, second", "Peso, segundo"),
                c("nctEdgeTable", "diff", "Difference", "Diferencia"),
                c("nctEdgeTable", "p", "p (adjusted)", "p (ajustado)"),
                c("nctCentralityTable", "pair", "Comparison", "Comparación"),
                c("nctCentralityTable", "item", "Item", "Ítem"),
                c("nctCentralityTable", "measure", "Measure", "Medida"),
                c("nctCentralityTable", "diff", "Difference", "Diferencia"),
                c("nctCentralityTable", "p", "p (adjusted)", "p (ajustado)"),
                c("cfaBifactorLoadings", "item", "Item", "Ítem"),
                c("cfaBifactorLoadings", "specific", "Specific factor", "Factor específico"),
                c("cfaBifactorLoadings", "general", "General", "General"),
                c("cfaBifactorLoadings", "spec", "Specific", "Específica"),
                c("cfaBifactorLoadings", "resid", "Residual variance", "Varianza residual"),
                c("cfaBifactorLoadings", "flag", "Check", "Revisar"),
                c("cfaHierModels", "model", "Model", "Modelo"),
                c("cfaHierModels", "items", "Items", "Ítems"),
                c("cfaHierModels", "chisq", "χ² (df)", "χ² (gl)"),
                c("cfaCompare", "element", "Element", "Elemento"),
                c("cfaCompare", "total", "Total sample", "Muestra total"),
                c("cfaCompare", "partA", "Subsample A (exploration)", "SubMuestra A (exploración)"),
                c("cfaCompare", "partB", "Subsample B (confirmation)", "SubMuestra B (confirmación)"),
                c("cfaMembership", "item", "Item", "Ítem"),
                c("cfaMembership", "total", "Total sample", "Muestra total"),
                c("cfaMembership", "partA", "Subsample A", "SubMuestra A"),
                c("cfaMembership", "partB", "Subsample B", "SubMuestra B"),
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
            for (col in c("low", "high"))
                tryCatch(self$results$bnEdges$getColumn(col)$setSuperTitle(
                    tr("95% bootstrap interval", "Intervalo bootstrap del 95%")), error = function(e) NULL)
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
        # Network loading of each item on its dimension in each group, one
        # row per item (grouped by dimension), items that differ marked *.
        # ES: Carga de red de cada ítem en su dimensión en cada grupo, una
        # fila por ítem (agrupados por dimensión), con * en los que difieren.
        # ---------------------------------------------------------------------
        .plotInvariance = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$data) || nrow(state$data) == 0)
                return(FALSE)

            df <- state$data
            item_order <- unique(df$item)
            df <- df[order(as.numeric(df$dimension), match(df$item, item_order)), , drop = FALSE]
            dim_prefix <- if (is.null(state$labels$dimension)) "" else paste0(state$labels$dimension, " ")
            df$dimension <- factor(paste0(dim_prefix, df$dimension),
                                   levels = unique(paste0(dim_prefix, df$dimension)))
            items <- unique(df$item)
            df$label <- ifelse(df$sig, paste0(df$item, " *"), df$item)
            labels <- unique(df$label[match(items, df$item)])
            df$label <- factor(df$label, levels = rev(labels))
            df$group <- factor(df$group, levels = unique(state$data$group))

            plot <- ggplot2::ggplot(df, ggplot2::aes(x = loading, y = label, colour = group)) +
                ggplot2::geom_line(ggplot2::aes(group = label), colour = "grey70", linewidth = 0.8) +
                ggplot2::geom_point(size = 3) +
                ggplot2::facet_grid(dimension ~ ., scales = "free_y", space = "free_y") +
                ggplot2::labs(x = state$labels$x, y = NULL, colour = state$labels$group,
                              caption = state$labels$note) +
                ggtheme

            palette <- .el_plot_series_palette(self$options$plotPalette)
            if (!is.null(palette))
                plot <- plot + ggplot2::scale_colour_manual(values = rep_len(palette, nlevels(df$group)))

            print(plot)
            TRUE
        },

        # ---------------------------------------------------------------------
        # Hierarchical structure: items at the bottom, lower-order dimensions
        # in the middle and higher-order dimensions on top, joined by edges
        # whose width follows the network loadings. Standard ggplot, so
        # jamovi's ggtheme applies.
        # ES: Estructura jerárquica: ítems abajo, dimensiones de orden
        # inferior en el medio y de orden superior arriba, unidos por
        # aristas cuyo grosor sigue las cargas de red. ggplot estándar, así
        # que se aplica el ggtheme de jamovi.
        # ---------------------------------------------------------------------
        .plotHier = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$nodes) || nrow(state$nodes) == 0)
                return(FALSE)

            o <- self$options
            num <- function(x, default) { v <- suppressWarnings(as.numeric(x)); if (length(v) == 0 || is.na(v)) default else v }
            item_size <- num(o$hierItemSize, 4)
            dim_size <- num(o$hierDimSize, 11)
            label_size <- num(o$hierItemLabelSize, 3.3)
            width <- num(o$hierEdgeWidth, 1)
            edge_color <- if (is.null(o$hierEdgeColor)) "grey55" else o$hierEdgeColor
            show_items <- !isFALSE(o$hierItemLabels)
            show_levels <- !isFALSE(o$hierShowLevels)

            nodes <- state$nodes
            edges <- state$edges
            if (nrow(edges) > 0) {
                if (all(is.na(edges$weight))) edges$weight <- 0.5
                else edges$weight[is.na(edges$weight)] <- min(edges$weight, na.rm = TRUE)
            }
            item_nodes <- nodes[nodes$level == 0, , drop = FALSE]
            dim_nodes <- nodes[nodes$level == 1, , drop = FALSE]
            top_nodes <- nodes[nodes$level == 2, , drop = FALSE]
            top <- if (nrow(top_nodes) > 0) 2 else 1
            groups <- unique(c(dim_nodes$group, item_nodes$group))

            plot <- ggplot2::ggplot()
            if (nrow(edges) > 0)
                plot <- plot +
                    ggplot2::geom_segment(data = edges, ggplot2::aes(x = x, y = y, xend = xend, yend = yend,
                                                                     linewidth = weight),
                                          colour = edge_color, lineend = "round") +
                    ggplot2::scale_linewidth_continuous(range = c(0.3, 2.2) * width, guide = "none")
            plot <- plot +
                ggplot2::geom_point(data = item_nodes, ggplot2::aes(x = x, y = level, fill = group),
                                    shape = 21, size = item_size, colour = "grey25")
            if (show_items)
                plot <- plot +
                    ggplot2::geom_text(data = item_nodes, ggplot2::aes(x = x, y = level - 0.08, label = label),
                                       angle = 90, hjust = 1, size = label_size)
            plot <- plot +
                ggplot2::geom_point(data = dim_nodes, ggplot2::aes(x = x, y = level, fill = group),
                                    shape = 21, size = dim_size, colour = "grey25") +
                ggplot2::geom_text(data = dim_nodes, ggplot2::aes(x = x, y = level, label = label),
                                   size = dim_size * 0.36, fontface = "bold")
            if (nrow(top_nodes) > 0)
                plot <- plot +
                    ggplot2::geom_point(data = top_nodes, ggplot2::aes(x = x, y = level),
                                        shape = 22, size = dim_size * 1.1, fill = "grey88", colour = "grey25") +
                    ggplot2::geom_text(data = top_nodes, ggplot2::aes(x = x, y = level, label = label),
                                       size = dim_size * 0.36, fontface = "bold")

            # No axes: the level names are drawn as text on the left.
            # ES: Sin ejes: los nombres de los niveles se dibujan como texto
            # a la izquierda.
            levels_df <- data.frame(
                y = 0:top,
                label = c(state$labels$items, state$labels$lower, state$labels$higher)[seq_len(top + 1)])
            if (show_levels)
                plot <- plot +
                    ggplot2::geom_text(data = levels_df, ggplot2::aes(x = 0, y = y, label = label),
                                       hjust = 1, size = 3.6, colour = "grey30")
            bottom <- if (show_items) -(0.2 + 0.045 * (label_size / 3.3) * max(nchar(item_nodes$label), 4)) else -0.2
            left <- if (show_levels) -0.25 * max(nchar(levels_df$label)) / 2 else 0.5
            plot <- plot +
                ggplot2::scale_y_continuous(limits = c(bottom, top + 0.25)) +
                ggplot2::scale_x_continuous(limits = c(left, NA),
                                            expand = ggplot2::expansion(add = c(0.4, 0.8))) +
                ggplot2::labs(x = NULL, y = NULL) +
                ggtheme +
                ggplot2::theme_void() +
                ggplot2::theme(legend.position = "none")

            title <- trimws(as.character(if (is.null(o$hierPlotTitle)) "" else o$hierPlotTitle))
            if (nzchar(title))
                plot <- plot + ggplot2::ggtitle(title) +
                    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"))

            palette <- .el_plot_series_palette(o$plotPalette)
            if (!is.null(palette))
                plot <- plot + ggplot2::scale_fill_manual(
                    values = stats::setNames(rep_len(palette, length(groups)), groups))

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
        },

        # ---------------------------------------------------------------------
        # Centrality: one panel per measure, items grouped by dimension in
        # their original order, a line joining the items as in bootnet's
        # centrality plot. Standard ggplot, so jamovi's ggtheme applies.
        # ES: Centralidad: un panel por medida, ítems agrupados por dimensión
        # en su orden original, con una línea que une los ítems como en el
        # gráfico de centralidad de bootnet. ggplot estándar, así que se
        # aplica el ggtheme de jamovi.
        # ---------------------------------------------------------------------
        .plotCentrality = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$data) || nrow(state$data) == 0)
                return(FALSE)

            df <- state$data
            df <- df[!is.na(df$value), , drop = FALSE]
            if (nrow(df) == 0)
                return(FALSE)
            items <- unique(state$data$item)
            dims <- unique(state$data$dimension[match(items, state$data$item)])
            dim_order <- dims[order(suppressWarnings(as.numeric(dims)), dims, na.last = TRUE)]
            item_order <- items[order(match(state$data$dimension[match(items, state$data$item)], dim_order),
                                      seq_along(items))]
            df$item <- factor(df$item, levels = rev(item_order))
            df$dimension <- factor(df$dimension, levels = dim_order)
            df$measure <- factor(df$measure, levels = state$measures)

            plot <- ggplot2::ggplot(df, ggplot2::aes(x = value, y = item)) +
                ggplot2::geom_path(ggplot2::aes(group = measure), colour = "grey65", linewidth = 0.6) +
                ggplot2::geom_point(ggplot2::aes(colour = dimension), size = 3) +
                ggplot2::facet_grid(. ~ measure, scales = "free_x") +
                ggplot2::labs(x = state$labels$x, y = NULL, colour = state$labels$dimension) +
                ggtheme

            palette <- .el_plot_series_palette(self$options$plotPalette)
            if (!is.null(palette))
                plot <- plot + ggplot2::scale_colour_manual(values = rep_len(palette, nlevels(df$dimension)))

            print(plot)
            TRUE
        },

        # ---------------------------------------------------------------------
        # Edge weights of the estimated network with their 95% bootstrap
        # intervals, strongest at the top, and a reference line at zero.
        # ES: Pesos de las aristas de la red estimada con sus intervalos
        # bootstrap del 95%, la más fuerte arriba, y una línea de referencia
        # en cero.
        # ---------------------------------------------------------------------
        .plotEdgeCI = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$edges) || nrow(state$edges) == 0)
                return(FALSE)

            df <- state$edges
            df$edge <- paste0(df$a, " – ", df$b)
            df$edge <- factor(df$edge, levels = rev(df$edge[order(-df$weight)]))

            palette <- .el_plot_series_palette(self$options$plotPalette)
            colour <- if (!is.null(palette)) palette[1] else "#1f77b4"

            plot <- ggplot2::ggplot(df, ggplot2::aes(x = weight, y = edge)) +
                ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
                ggplot2::geom_errorbarh(ggplot2::aes(xmin = low, xmax = high), height = 0.3,
                                        colour = "grey55") +
                ggplot2::geom_point(size = 2.5, colour = colour) +
                ggplot2::labs(x = state$labels$x, y = NULL) +
                ggtheme

            print(plot)
            TRUE
        },

        # ---------------------------------------------------------------------
        # Case-dropping bootstrap: mean correlation of each centrality order
        # with the original, by proportion of cases dropped, with the band
        # covering 95% of the samples and the .70 reference line.
        # ES: Bootstrap de eliminación de casos: correlación media de cada
        # orden de centralidad con el original según la proporción de casos
        # eliminados, con la banda que cubre el 95% de las muestras y la
        # línea de referencia de .70.
        # ---------------------------------------------------------------------
        .plotCaseDrop = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$cases) || nrow(state$cases) == 0)
                return(FALSE)

            df <- state$cases
            df$measure <- factor(df$measure, levels = unique(df$measure))

            # One panel per measure: the bands of several measures overlap
            # and hide each other in a single panel (Archie's report).
            # ES: Un panel por medida: las bandas de varias medidas se
            # solapan y se ocultan entre sí en un solo panel (informe de
            # Archie).
            plot <- ggplot2::ggplot(df, ggplot2::aes(x = drop, y = mean, colour = measure, fill = measure)) +
                ggplot2::geom_hline(yintercept = 0.7, linetype = "dashed", colour = "grey50") +
                ggplot2::geom_ribbon(ggplot2::aes(ymin = low, ymax = high), alpha = 0.20, colour = NA) +
                ggplot2::geom_line(linewidth = 0.9) +
                ggplot2::geom_point(size = 2) +
                ggplot2::facet_wrap(~ measure, ncol = 2) +
                ggplot2::scale_x_continuous(labels = function(x) paste0(round(100 * x), "%")) +
                ggplot2::coord_cartesian(ylim = c(min(0, min(df$low, na.rm = TRUE)), 1)) +
                ggplot2::labs(x = state$labels$x, y = state$labels$y, caption = state$labels$note) +
                ggtheme +
                ggplot2::theme(legend.position = "none")

            palette <- .el_plot_series_palette(self$options$plotPalette)
            if (!is.null(palette))
                plot <- plot +
                    ggplot2::scale_colour_manual(values = rep_len(palette, nlevels(df$measure))) +
                    ggplot2::scale_fill_manual(values = rep_len(palette, nlevels(df$measure)))

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

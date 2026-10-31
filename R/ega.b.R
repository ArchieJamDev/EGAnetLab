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
            if (isTRUE(self$options$runBoot))
                boot_warnings <- private$.runBootstrap(prep, tr, txt)

            # -----------------------------------------------------------------
            # Notes: every EGAnet warning is shown, never suppressed.
            # ES: Notas: cada advertencia de EGAnet se muestra, nunca se
            # suprime.
            # -----------------------------------------------------------------
            warnings <- unique(c(fit$warnings, boot_warnings))
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
                        NULL, c(intro, sprintf(txt("bootega", "failed"), fit$error))))
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
                NULL, c(intro, sprintf(txt("bootega", "done"), cache$iter, type_label, seed))))

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
                c("bootStatus", "Stability (bootstrap)", "Estabilidad (bootstrap)"),
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

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
#     footnote naming the reason.
#
# ES: Política de errores (CODE_STYLE.md §19.1):
#   Categoría A - menos de tres ítems, sin datos, ítems vacíos o constantes,
#     o EGA() sin poder estimar la red -> jmvcore::reject().
#   Categoría B - cargas de red que fallan con una estructura por lo demás
#     válida -> la tabla de cargas se muestra igual, con una fila "No
#     computable" y una nota al pie con la razón.
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
            if (isTRUE(self$options$showChoicesGuide))
                self$results$choicesGuide$setContent(
                    .el_choices_guide(lang, self$options, .el_estimation_choice_labels(tr)))

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

            paragraphs <- c(paragraphs, txt("ega", "interp_next"))

            self$results$interpretation$setContent(.el_html_block(NULL, paragraphs))

            # -----------------------------------------------------------------
            # Notes: every EGAnet warning is shown, never suppressed.
            # ES: Notas: cada advertencia de EGAnet se muestra, nunca se
            # suprime.
            # -----------------------------------------------------------------
            if (length(fit$warnings) > 0) {
                self$results$notes$setContent(.el_html_block(
                    txt("common", "warnings_title"),
                    .el_html_list(fit$warnings),
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
                c("notes", "Notes", "Notas")
            )
            for (t in titles)
                tryCatch(self$results[[t[1]]]$setTitle(tr(t[2], t[3])), error = function(e) NULL)

            cols <- list(
                c("summary", "element", "Element", "Elemento"),
                c("summary", "value", "Value", "Valor"),
                c("membership", "item", "Item", "Ítem"),
                c("membership", "dimension", "Dimension", "Dimensión"),
                c("loadings", "item", "Item", "Ítem")
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
        }
    )
)

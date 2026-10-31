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
# Bootstrap Exploratory Graph Analysis.
# ES: Análisis Exploratorio de Grafos con bootstrap.
#
# Runs EGAnet::bootEGA() on the selected items and reports the distribution of
# the number of dimensions, the structural consistency of each dimension and
# the stability of each item (EGAnet's dimensionStability()/itemStability(),
# which bootEGA() computes on its own result).
#
# Computation time (ARCHITECTURE.md §16): nothing runs until "Run bootstrap"
# is ticked; the compact summary of the bootstrap is cached in the state of
# the `status` result, whose clearWith lists only the options that change the
# computation. Language, stability cutoff and plot options re-render from the
# cache without resampling again.
#
# ES: Tiempo de cálculo (ARCHITECTURE.md §16): nada se ejecuta hasta marcar
# "Run bootstrap"; el resumen compacto del bootstrap se guarda en el estado
# del resultado `status`, cuyo clearWith lista solo las opciones que cambian
# el cálculo. El idioma, el punto de corte de estabilidad y las opciones de
# gráfico se vuelven a mostrar desde la caché sin volver a remuestrear.
#
# Error policy (CODE_STYLE.md §19.1): invalid items or a failed bootstrap ->
# jmvcore::reject() (Category A).
# ES: Política de errores (CODE_STYLE.md §19.1): ítems inválidos o bootstrap
# fallido -> jmvcore::reject() (Categoría A).
# -----------------------------------------------------------------------------

bootegaClass <- if (requireNamespace("jmvcore", quietly = TRUE)) R6::R6Class(
    "bootegaClass",
    inherit = bootegaBase,
    private = list(

        .run = function() {

            lang <- .el_normalize_lang(self$options$reportLang)
            tr <- function(en, es) .el_tr(lang, en, es)
            txt <- function(section, key) .el_text(lang, section, key)

            private$.setTitles(tr)
            self$results$intro$setContent(.el_html_block(NULL, txt("bootega", "intro")))

            if (length(self$options$vars) == 0) {
                private$.hideResults()
                return()
            }

            # -----------------------------------------------------------------
            # About your choices.
            # ES: Acerca de sus elecciones.
            # -----------------------------------------------------------------
            iter <- as.integer(self$options$iter)
            seed <- as.integer(self$options$seed)

            if (isTRUE(self$options$showChoicesGuide)) {
                labels <- .el_estimation_choice_labels(tr)
                labels$bootType <- list(
                    parametric = tr("Parametric", "Paramétrico"),
                    resampling = tr("Resampling (cases)", "Remuestreo (casos)"))
                self$results$choicesGuide$setContent(.el_choices_guide(
                    lang, self$options, labels,
                    extra = sprintf(txt("choices", "iter_seed"), iter, seed)))
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

            if (!isTRUE(self$options$runBoot)) {
                self$results$status$setContent(.el_html_block(NULL, sprintf(txt("bootega", "not_run"), iter)))
                private$.hideResults()
                return()
            }

            # -----------------------------------------------------------------
            # Bootstrap (cached).
            # ES: Bootstrap (en caché).
            # -----------------------------------------------------------------
            cache <- self$results$status$state

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
                    seed = seed,
                    plot.itemStability = FALSE,
                    verbose = FALSE
                ))

                if (is.null(fit$value))
                    jmvcore::reject(sprintf(txt("bootega", "failed"), fit$error))

                cache <- .el_boot_summary(fit$value, fit$warnings)
                cache$n_used <- if (identical(self$options$naData, "listwise")) prep$n_complete else prep$n_total
                cache$n_complete <- prep$n_complete
                self$results$status$setState(cache)
            }

            type_label <- if (identical(self$options$bootType, "parametric"))
                tr("parametric", "paramétrico") else tr("resampling", "remuestreo")
            self$results$status$setContent(.el_html_block(
                NULL, sprintf(txt("bootega", "done"), cache$iter, type_label, seed)))

            private$.fillResults(cache, lang, tr, txt, type_label, seed)
        },

        # ---------------------------------------------------------------------
        # Tables, interpretation and plot states from the cached summary.
        # ES: Tablas, interpretación y estados de gráficos desde la caché.
        # ---------------------------------------------------------------------
        .fillResults = function(cache, lang, tr, txt, type_label, seed) {

            cut <- as.numeric(self$options$stabilityCut)
            pct <- function(x) paste0(formatC(100 * x, format = "f", digits = 1), "%")
            num <- function(x) .el_fmt_num(x, 2, txt("common", "not_computable"))
            dim_label <- function(d) if (is.na(d) || identical(d, "NA")) txt("bootega", "isolated") else as.character(d)

            self$results$summaryGuide$setContent(
                .el_html_block(NULL, .el_html_list(txt("bootega", "guide_summary")), raw = TRUE))

            # Tables are refilled on every run; rows restored from a previous
            # run (when an option outside their clearWith changed) are
            # dropped first so they are never duplicated.
            # ES: Las tablas se rellenan en cada ejecución; las filas
            # restauradas de una ejecución previa (cuando cambió una opción
            # fuera de su clearWith) se eliminan antes para no duplicarlas.
            for (name in c("summary", "frequency", "dimStability", "itemStability"))
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
                .el_add_row(self$results$summary, i, list(element = rows[[i]][[1]], value = rows[[i]][[2]]))

            # Frequency.
            freq <- cache$frequency
            for (i in seq_len(nrow(freq)))
                .el_add_row(self$results$frequency, i, list(
                    dims = freq$dims[i], count = freq$count[i], proportion = freq$proportion[i]))

            # Dimension stability.
            ds <- cache$dimensions
            for (i in seq_len(nrow(ds)))
                .el_add_row(self$results$dimStability, i, list(
                    dimension = dim_label(ds$dimension[i]), items = ds$items[i],
                    consistency = ds$consistency[i], meanItem = ds$mean_item[i]))

            # Item stability.
            it <- cache$item_table
            for (i in seq_len(nrow(it))) {
                flag <- if (is.na(it$stability[i])) txt("common", "not_computable")
                        else if (it$stability[i] < cut) txt("bootega", "unstable") else txt("bootega", "stable")
                .el_add_row(self$results$itemStability, i, list(
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
            self$results$interpretation$setContent(.el_html_block(NULL, paragraphs))

            # Notes: EGAnet's messages are shown, never suppressed.
            # ES: Notas: los mensajes de EGAnet se muestran, nunca se suprimen.
            if (length(cache$warnings) > 0) {
                self$results$notes$setContent(.el_html_block(
                    txt("common", "warnings_title"), .el_html_list(cache$warnings), raw = TRUE))
            } else {
                self$results$notes$setVisible(FALSE)
            }

            # Plot states.
            # ES: Estados de los gráficos.
            if (isTRUE(self$options$showItemPlot))
                self$results$itemPlot$setState(list(
                    items = it, cut = cut,
                    labels = list(y = txt("bootega", "plot_stability"),
                                  dimension = tr("Dimension", "Dimensión"),
                                  isolated = txt("bootega", "isolated"))))

            if (isTRUE(self$options$showFrequencyPlot))
                self$results$frequencyPlot$setState(list(
                    frequency = freq, empirical = cache$empirical_ndim,
                    labels = list(x = txt("bootega", "plot_dims"), y = txt("bootega", "plot_prop"),
                                  original = txt("bootega", "plot_original"),
                                  other = txt("bootega", "plot_other"))))
        },

        .hideResults = function() {
            for (name in c("summaryGuide", "summary", "frequency", "dimStability", "itemStability",
                           "interpretation", "itemPlot", "frequencyPlot", "notes"))
                self$results[[name]]$setVisible(FALSE)
        },

        .setTitles = function(tr) {
            titles <- list(
                c("intro", "Introduction", "Introducción"),
                c("choicesGuide", "About your choices", "Acerca de sus elecciones"),
                c("status", "Bootstrap status", "Estado del bootstrap"),
                c("summaryGuide", "Number of dimensions across samples", "Número de dimensiones entre muestras"),
                c("summary", "Number of dimensions across samples", "Número de dimensiones entre muestras"),
                c("frequency", "Frequency of the number of dimensions", "Frecuencia del número de dimensiones"),
                c("dimStability", "Dimension stability", "Estabilidad de las dimensiones"),
                c("itemStability", "Item stability", "Estabilidad de los ítems"),
                c("interpretation", "Applied interpretation", "Interpretación aplicada"),
                c("itemPlot", "Item stability", "Estabilidad de los ítems"),
                c("frequencyPlot", "Frequency of the number of dimensions", "Frecuencia del número de dimensiones"),
                c("notes", "Notes", "Notas")
            )
            for (t in titles)
                tryCatch(self$results[[t[1]]]$setTitle(tr(t[2], t[3])), error = function(e) NULL)

            cols <- list(
                c("summary", "element", "Element", "Elemento"),
                c("summary", "value", "Value", "Valor"),
                c("frequency", "dims", "Dimensions", "Dimensiones"),
                c("frequency", "count", "Samples", "Muestras"),
                c("frequency", "proportion", "Proportion", "Proporción"),
                c("dimStability", "dimension", "Dimension", "Dimensión"),
                c("dimStability", "items", "Items", "Ítems"),
                c("dimStability", "consistency", "Structural consistency", "Consistencia estructural"),
                c("dimStability", "meanItem", "Mean item stability", "Estabilidad media de ítems"),
                c("itemStability", "item", "Item", "Ítem"),
                c("itemStability", "dimension", "Dimension", "Dimensión"),
                c("itemStability", "stability", "Stability", "Estabilidad"),
                c("itemStability", "flag", "Assessment", "Valoración")
            )
            for (col in cols)
                tryCatch(self$results[[col[1]]]$getColumn(col[2])$setTitle(tr(col[3], col[4])), error = function(e) NULL)
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
        .plotItems = function(image, ggtheme, theme, ...) {
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
        .plotFrequency = function(image, ggtheme, theme, ...) {
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

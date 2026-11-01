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
# Dynamic EGA (phase 7): EGAnet::dynEGA() on intensive longitudinal data in
# long format, at the population, group and individual levels. A separate
# analysis because its data (many rows per person) would mislead the
# cross-sectional analyses of the EGA analysis (Archie's decision,
# 2026-11-01).
# ES: EGA dinámico (fase 7): EGAnet::dynEGA() sobre datos longitudinales
# intensivos en formato largo, en los niveles de población, grupo e
# individuo. Es un análisis aparte porque sus datos (muchas filas por
# persona) confundirían los análisis transversales del análisis EGA
# (decisión de Archie, 2026-11-01).
# -----------------------------------------------------------------------------

dynegaClass <- if (requireNamespace("jmvcore", quietly = TRUE)) R6::R6Class(
    "dynegaClass",
    inherit = dynegaBase,
    private = list(

        .run = function() {

            lang <- .el_normalize_lang(self$options$reportLang)
            tr <- function(en, es) .el_tr(lang, en, es)
            txt <- function(section, key) .el_text(lang, section, key)
            o <- self$options

            private$.setTitles(tr)
            self$results$intro$setContent(.el_html_block(NULL, txt("dyn", "intro")))

            if (length(o$vars) == 0 || is.null(o$id) || length(o$id) == 0) {
                self$results$status$setContent(.el_html_block(NULL, txt("dyn", "choose_id")))
                self$results$notes$setVisible(FALSE)
                return()
            }
            if (length(o$vars) < 3)
                jmvcore::reject(txt("common", "too_few_items"))

            n_embed <- as.integer(o$nEmbed)
            deriv <- as.integer(o$derivative)
            deriv_label <- txt("dyn", paste0("deriv_", deriv))
            fmt_delta <- .el_fmt_num(as.numeric(o$delta), 3)
            fmt_delta <- sub("\\.?0+$", "", fmt_delta)

            # About your choices.
            # ES: Acerca de sus elecciones.
            if (isTRUE(o$showChoicesGuide)) {
                labels <- .el_estimation_choice_labels(tr)
                labels$naData <- NULL
                labels$corr$cosine <- NULL
                labels$derivative <- list(`0` = tr("Level (0)", "Nivel (0)"),
                                          `1` = tr("Rate of change (1)", "Velocidad de cambio (1)"),
                                          `2` = tr("Acceleration (2)", "Aceleración (2)"))
                embed <- sprintf(txt("dyn", "embed_text"), n_embed, n_embed, as.integer(o$tau), fmt_delta)
                self$results$choicesGuide$setContent(
                    .el_choices_guide(lang, o, labels, extra = embed))
            }

            # Preparation (Category A).
            # ES: Preparación (Categoría A).
            group_var <- if (!is.null(o$group) && length(o$group) > 0) o$group else NULL
            time_var <- if (!is.null(o$time) && length(o$time) > 0) o$time else NULL
            min_points <- n_embed + 2L
            prep <- .el_dyn_prepare(self$data, o$vars, o$id, time = time_var, group = group_var,
                                    min_points = min_points)
            if (!isTRUE(prep$ok)) {
                if (identical(prep$reason, "constant_item"))
                    jmvcore::reject(sprintf(txt("dyn", "constant_item"), paste(prep$constant, collapse = ", ")))
                jmvcore::reject(sprintf(txt("dyn", "too_few_persons"), min_points))
            }

            levels <- "population"
            use_groups <- !is.null(group_var) && isTRUE(o$levelGroup) && length(unique(prep$data$Group)) > 1
            if (use_groups) levels <- c(levels, "group")
            if (isTRUE(o$levelIndividual)) levels <- c(levels, "individual")

            # Estimation, cached in the status state.
            # ES: Estimación, en caché en el estado de status.
            cache <- self$results$status$state
            warnings <- character(0)
            if (is.null(cache)) {
                private$.checkpoint()
                run_dyn <- function(data, lv) .el_capture(EGAnet::dynEGA(
                    data = data,
                    id = "ID",
                    group = if (use_groups) "Group" else NULL,
                    n.embed = n_embed,
                    tau = as.integer(o$tau),
                    delta = as.numeric(o$delta),
                    use.derivatives = deriv,
                    level = lv,
                    corr = o$corr,
                    model = o$model,
                    algorithm = o$algorithm,
                    uni.method = o$uniMethod,
                    ncores = 1,
                    seed = as.numeric(o$seed),
                    verbose = FALSE
                ))

                # Each person's own structure is estimated separately: a
                # person whose network cannot be estimated (an item that never
                # changes, or too many missing answers) would otherwise stop
                # EGAnet for everyone. Those persons stay in the population
                # and group levels, and only their own structure is reported
                # as not estimable.
                # ES: La estructura propia de cada persona se estima por
                # separado: una persona cuya red no puede estimarse (un ítem
                # que nunca cambia o demasiadas respuestas faltantes) detendría
                # EGAnet para todos. Esas personas siguen en los niveles de
                # población y grupo, y solo su estructura propia se informa
                # como no estimable.
                fit <- run_dyn(prep$data, setdiff(levels, "individual"))
                if (is.null(fit$value))
                    jmvcore::reject(sprintf(txt("dyn", "failed"), fit$error))
                if ("individual" %in% levels) {
                    ind <- list()
                    for (pid in names(prep$points)) {
                        private$.checkpoint()
                        one <- run_dyn(prep$data[prep$data$ID == pid, , drop = FALSE], "individual")
                        if (!is.null(one$value) && length(one$value$dynEGA$individual) > 0)
                            ind[[pid]] <- one$value$dynEGA$individual[[1]]
                    }
                    fit$value$dynEGA$individual <- ind
                }

                person_group <- if (use_groups)
                    tapply(prep$data$Group, factor(prep$data$ID, levels = names(prep$points)), `[`, 1) else NULL
                cache <- .el_dyn_summary(fit$value, o$vars, prep$points, person_group)
                cache$warnings <- fit$warnings
                self$results$status$setState(cache)
            }
            warnings <- c(warnings, cache$warnings)

            self$results$status$setContent(.el_html_block(NULL, sprintf(
                txt("dyn", "done"),
                if (use_groups) txt("dyn", "done_groups") else "",
                if (isTRUE(o$levelIndividual)) txt("dyn", "done_individual") else "",
                deriv_label, n_embed, as.integer(o$seed))))

            # Data and estimation summary.
            # ES: Resumen de datos y estimación.
            pop <- cache$population
            pts <- prep$points
            rows <- list(
                list(txt("dyn", "summary_persons"), as.character(length(pts))),
                list(txt("dyn", "summary_points"), sprintf("%d / %s / %d", min(pts),
                                                           .el_fmt_num(stats::median(pts), 1), max(pts))),
                list(txt("dyn", "summary_rows"), as.character(nrow(prep$data))),
                list(txt("dyn", "summary_glla"), sprintf(txt("dyn", "summary_glla_value"), n_embed,
                                                         as.integer(o$tau), fmt_delta, deriv_label)),
                list(tr("Correlation", "Correlación"), switch(o$corr,
                    auto = tr("Automatic (Pearson, because the derivatives are continuous)",
                              "Automática (Pearson, porque las derivadas son continuas)"),
                    pearson = "Pearson", spearman = "Spearman")),
                list(tr("Network model", "Modelo de red"), o$model),
                list(tr("Community detection", "Detección de comunidades"), o$algorithm),
                list(txt("dyn", "summary_ndim"), if (is.na(pop$n_dim)) txt("common", "not_computable")
                                                 else as.character(pop$n_dim))
            )
            for (i in seq_along(rows))
                .el_add_row(self$results$summary, i, list(element = rows[[i]][[1]], value = rows[[i]][[2]]))

            notes <- character(0)
            if (length(prep$dropped) > 0)
                notes <- c(notes, sprintf(txt("dyn", "dropped"), length(prep$dropped), min_points,
                                          paste(utils::head(prep$dropped, 20), collapse = ", ")))
            if (prep$group_varies > 0)
                notes <- c(notes, sprintf(txt("dyn", "group_varies"), prep$group_varies))

            # Item membership: population and each group.
            # ES: Pertenencia de los ítems: población y cada grupo.
            isolated_label <- tr("Isolated (no edges)", "Aislado (sin aristas)")
            dim_label <- function(d) if (is.na(d)) isolated_label else as.character(d)
            table <- self$results$membership
            groups <- cache$groups
            if (use_groups)
                for (g in names(groups))
                    table$addColumn(name = paste0("g_", g), title = g, type = "text",
                                    superTitle = tr("Groups", "Grupos"))
            for (i in seq_along(o$vars)) {
                item <- o$vars[i]
                values <- list(item = item, population = dim_label(pop$wc[[item]]))
                if (use_groups)
                    for (g in names(groups))
                        values[[paste0("g_", g)]] <- dim_label(groups[[g]]$wc[[item]])
                .el_add_row(table, i, values)
            }

            if (use_groups) {
                gt <- self$results$groupTable
                for (i in seq_along(groups)) {
                    g <- groups[[i]]
                    same <- !is.na(g$n_dim) && !is.na(pop$n_dim) && .el_ari(g$wc, pop$wc) == 1
                    .el_add_row(gt, i, list(group = names(groups)[i], persons = g$persons,
                                            dims = if (is.na(g$n_dim)) txt("common", "not_computable") else as.character(g$n_dim),
                                            same = if (same) tr("Yes", "Sí") else tr("No", "No")))
                }
                gt$setNote("same", tr("Same as population: identical item membership.",
                                      "Igual que la población: pertenencia de los ítems idéntica."))
            } else {
                self$results$groupTable$setVisible(FALSE)
            }

            # Interpretation.
            # ES: Interpretación.
            paragraphs <- character(0)
            if (!is.na(pop$n_dim) && pop$n_dim == 1)
                paragraphs <- c(paragraphs, sprintf(txt("dyn", "interp_dims_one"), deriv_label))
            else if (!is.na(pop$n_dim))
                paragraphs <- c(paragraphs, sprintf(txt("dyn", "interp_dims_many"), pop$n_dim, deriv_label))
            isolated <- o$vars[is.na(pop$wc[o$vars])]
            if (length(isolated) > 0)
                paragraphs <- c(paragraphs, sprintf(txt("dyn", "interp_isolated"), length(isolated),
                                                    paste(isolated, collapse = ", ")))
            paragraphs <- c(paragraphs, txt("dyn", paste0("interp_deriv_", deriv)))
            if (use_groups) {
                dims_word <- function(n) if (is.na(n)) txt("common", "not_computable")
                                         else if (n == 1) txt("dyn", "dims_word_1")
                                         else sprintf(txt("dyn", "dims_word_n"), n)
                detail <- paste(vapply(names(groups), function(g)
                    sprintf(txt("dyn", "group_word"), g, dims_word(groups[[g]]$n_dim)), ""), collapse = "; ")
                paragraphs <- c(paragraphs, sprintf(txt("dyn", "interp_groups_detail"), detail))
                matches <- vapply(groups, function(g) isTRUE(.el_ari(g$wc, pop$wc) == 1), logical(1))
                same_n <- all(vapply(groups, function(g) isTRUE(g$n_dim == pop$n_dim), logical(1)))
                paragraphs <- c(paragraphs,
                    if (!any(matches) && !is.na(pop$n_dim)) sprintf(txt("dyn", "interp_pooled"), pop$n_dim)
                    else txt("dyn", if (same_n) "interp_groups_same" else "interp_groups_diff"))
            }
            if (!isTRUE(o$levelIndividual))
                paragraphs <- c(paragraphs, txt("dyn", "interp_next"))
            self$results$interpretation$setContent(.el_html_block(NULL, paragraphs))

            if (isTRUE(o$showNetworkPlot))
                self$results$networkPlot$setState(list(network = pop$network, wc = pop$wc))

            # Individual structures.
            # ES: Estructuras individuales.
            if (isTRUE(o$levelIndividual) && !is.null(cache$individual))
                private$.fillIndividual(cache, pop, tr, txt)

            warnings <- .el_translate_notices(.el_drop_notices(unique(warnings)), lang)
            notes <- c(notes, warnings)
            if (length(notes) > 0)
                self$results$notes$setContent(.el_html_block(
                    txt("common", "warnings_title"), .el_html_list(notes), raw = TRUE))
            else
                self$results$notes$setVisible(FALSE)
        },

        .fillIndividual = function(cache, pop, tr, txt) {

            ind <- cache$individual
            n_items <- length(self$options$vars)
            few <- sum(ind$points - as.integer(self$options$nEmbed) + 1 < n_items)
            est <- ind[!is.na(ind$dims), , drop = FALSE]
            pct <- function(x) paste0(formatC(100 * x, format = "f", digits = 1), "%")
            self$results$indStatus$setContent(.el_html_block(NULL, c(
                txt("dyn", "ind_intro"),
                if (few > 0) sprintf(txt("dyn", "ind_few_points"), few, n_items),
                if (length(cache$failed) > 0)
                    sprintf(txt("dyn", "ind_failed"), length(cache$failed),
                            paste(utils::head(cache$failed, 20), collapse = ", ")))))

            if (nrow(est) == 0) {
                for (r in c("indFreq", "indAgree", "indTable", "indPlot", "indInterpretation"))
                    self$results[[r]]$setVisible(FALSE)
                return(invisible(NULL))
            }

            counts <- table(est$dims)
            freq <- data.frame(dims = as.numeric(names(counts)), count = as.integer(counts))
            freq$proportion <- freq$count / sum(freq$count)
            for (i in seq_len(nrow(freq)))
                .el_add_row(self$results$indFreq, i, list(dims = as.character(freq$dims[i]),
                                                          count = freq$count[i],
                                                          proportion = freq$proportion[i]))

            same_n <- mean(est$dims == pop$n_dim)
            identical_wc <- mean(est$ari >= 1 - 1e-12, na.rm = TRUE)
            median_ari <- stats::median(est$ari, na.rm = TRUE)
            agree <- self$results$indAgree
            rows <- list(
                list(txt("dyn", "agree_persons"), sprintf("%d / %d", nrow(est), nrow(ind))),
                list(txt("dyn", "agree_same_n"), pct(same_n)),
                list(txt("dyn", "agree_identical"), pct(identical_wc)),
                list(txt("dyn", "agree_median"), .el_fmt_num(median_ari, 2)))
            has_group <- "ari_group" %in% names(est) && any(!is.na(est$ari_group))
            if (has_group) {
                group_identical <- mean(est$ari_group >= 1 - 1e-12, na.rm = TRUE)
                group_median <- stats::median(est$ari_group, na.rm = TRUE)
                rows <- c(rows, list(
                    list(txt("dyn", "agree_group_identical"), pct(group_identical)),
                    list(txt("dyn", "agree_group_median"), .el_fmt_num(group_median, 2))))
            }
            for (i in seq_along(rows))
                .el_add_row(agree, i, list(element = rows[[i]][[1]], value = rows[[i]][[2]]))
            agree$setNote("ari", txt("dyn", "agree_note"))

            if (isTRUE(self$options$showIndTable) && has_group) {
                self$results$indTable$addColumn(name = "group", title = tr("Group", "Grupo"),
                                                type = "text", index = 2)
                self$results$indTable$addColumn(name = "ariGroup",
                                                title = tr("Agreement with own group (ARI)", "Acuerdo con su grupo (ARI)"),
                                                type = "number", format = "zto")
            }
            if (isTRUE(self$options$showIndTable))
                for (i in seq_len(nrow(ind)))
                    .el_add_row(self$results$indTable, i, list(
                        id = ind$id[i], points = ind$points[i],
                        dims = if (is.na(ind$dims[i])) txt("common", "not_computable") else as.character(ind$dims[i]),
                        ari = .el_clean_num(ind$ari[i]),
                        group = if (has_group) ind$group[i] else NULL,
                        ariGroup = if (has_group) .el_clean_num(ind$ari_group[i]) else NULL))

            if (isTRUE(self$options$showIndPlot))
                self$results$indPlot$setState(list(
                    frequency = freq, empirical = pop$n_dim,
                    labels = list(x = txt("dyn", "plot_x"), y = txt("dyn", "plot_y"),
                                  original = sprintf(txt("dyn", "plot_population"), as.character(pop$n_dim)), other = txt("dyn", "plot_other"))))

            dims_word <- function(n) if (n == 1) txt("dyn", "dims_word_1") else sprintf(txt("dyn", "dims_word_n"), n)
            distribution <- paste(sprintf("%s (%s)", vapply(freq$dims, dims_word, ""), pct(freq$proportion)),
                                  collapse = ", ")
            paragraphs <- sprintf(txt("dyn", "interp_ind_modal"), distribution, pct(same_n),
                                  as.character(pop$n_dim))
            if (has_group && group_median >= 0.80) {
                # The groups explain the differences between persons: say
                # so first, then why agreement with the population is lower.
                # ES: Los grupos explican las diferencias entre personas:
                # se dice primero y luego por qué el acuerdo con la
                # población es menor.
                paragraphs <- c(paragraphs,
                    sprintf(txt("dyn", "interp_ind_group_high"), pct(group_identical), .el_fmt_num(group_median, 2)))
                if (median_ari < 0.80)
                    paragraphs <- c(paragraphs, sprintf(txt("dyn", "interp_ind_pop_group"), .el_fmt_num(median_ari, 2)))
            } else {
                key <- if (median_ari >= 0.80 && same_n >= 0.5) "interp_ind_high"
                       else if (median_ari >= 0.50) "interp_ind_mid" else "interp_ind_low"
                paragraphs <- c(paragraphs, sprintf(txt("dyn", key), .el_fmt_num(median_ari, 2)))
                if (has_group)
                    paragraphs <- c(paragraphs, sprintf(txt("dyn", "interp_ind_group_low"), .el_fmt_num(group_median, 2)))
            }
            paragraphs <- c(paragraphs, txt("dyn", "interp_ind_next"))
            self$results$indInterpretation$setContent(.el_html_block(NULL, paragraphs))
            invisible(NULL)
        },

        .setTitles = function(tr) {
            titles <- list(
                c("intro", "Introduction", "Introducción"),
                c("choicesGuide", "About your choices", "Acerca de sus elecciones"),
                c("status", "Estimation", "Estimación"),
                c("summary", "Data and estimation", "Datos y estimación"),
                c("membership", "Item membership", "Pertenencia de los ítems"),
                c("groupTable", "Structure of each group", "Estructura de cada grupo"),
                c("interpretation", "Applied interpretation", "Interpretación aplicada"),
                c("networkPlot", "Population network", "Red de la población"),
                c("indStatus", "Structure of each person", "Estructura de cada persona"),
                c("indFreq", "Number of dimensions across persons", "Número de dimensiones entre personas"),
                c("indAgree", "Agreement with the population structure", "Acuerdo con la estructura de la población"),
                c("indTable", "Every person", "Cada persona"),
                c("indPlot", "Number of dimensions across persons", "Número de dimensiones entre personas"),
                c("indInterpretation", "Individual structures interpretation", "Interpretación de las estructuras individuales"),
                c("notes", "Notes", "Notas")
            )
            for (t in titles)
                tryCatch(self$results[[t[1]]]$setTitle(tr(t[2], t[3])), error = function(e) NULL)
            cols <- list(
                c("summary", "element", "Element", "Elemento"),
                c("summary", "value", "Value", "Valor"),
                c("membership", "item", "Item", "Ítem"),
                c("membership", "population", "Population", "Población"),
                c("groupTable", "group", "Group", "Grupo"),
                c("groupTable", "persons", "Persons", "Personas"),
                c("groupTable", "dims", "Dimensions", "Dimensiones"),
                c("groupTable", "same", "Same as population", "Igual que la población"),
                c("indFreq", "dims", "Dimensions", "Dimensiones"),
                c("indFreq", "count", "Persons", "Personas"),
                c("indFreq", "proportion", "Proportion", "Proporción"),
                c("indAgree", "element", "Element", "Elemento"),
                c("indAgree", "value", "Value", "Valor"),
                c("indTable", "id", "Person", "Persona"),
                c("indTable", "points", "Time points", "Momentos"),
                c("indTable", "dims", "Dimensions", "Dimensiones"),
                c("indTable", "ari", "Agreement (ARI)", "Acuerdo (ARI)")
            )
            for (col in cols)
                tryCatch(self$results[[col[1]]]$getColumn(col[2])$setTitle(tr(col[3], col[4])), error = function(e) NULL)
        },

        # Population network: the same network plot as the EGA analysis.
        # ES: Red de la población: el mismo gráfico de red que el análisis EGA.
        .plotNetwork = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$network) || sum(state$network != 0) == 0)
                return(FALSE)
            plot <- .el_ega_plot(network = state$network, wc = state$wc, opts = self$options,
                                 palette = .el_plot_series_palette(self$options$plotPalette))
            if (is.null(plot))
                return(FALSE)
            print(plot)
            TRUE
        },

        # Proportion of persons with each number of dimensions; the
        # population's number is highlighted.
        # ES: Proporción de personas con cada número de dimensiones; se
        # resalta el número de la población.
        .plotIndDims = function(image, ggtheme, theme, ...) {
            state <- image$state
            if (is.null(state) || is.null(state$frequency) || nrow(state$frequency) == 0)
                return(FALSE)
            df <- state$frequency
            df$group <- factor(ifelse(!is.na(state$empirical) & df$dims == state$empirical,
                                      state$labels$original, state$labels$other),
                               levels = c(state$labels$original, state$labels$other))
            plot <- ggplot2::ggplot(df, ggplot2::aes(x = factor(dims), y = proportion, fill = group)) +
                ggplot2::geom_col(width = 0.65) +
                ggplot2::geom_text(ggplot2::aes(label = formatC(proportion, format = "f", digits = 2)),
                                   vjust = -0.4, size = 4) +
                ggplot2::scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.25)) +
                ggplot2::labs(x = state$labels$x, y = state$labels$y, fill = NULL) +
                ggtheme
            # Both legend keys are kept, so the population's number is named
            # even when no person has it.
            # ES: Se conservan ambas claves de la leyenda, para nombrar el
            # número de la población aunque ninguna persona lo tenga.
            palette <- .el_plot_series_palette(self$options$plotPalette)
            if (is.null(palette)) palette <- c("#E69F00", "#56B4E9")
            plot <- plot + ggplot2::scale_fill_manual(values = stats::setNames(palette[1:2], levels(df$group)),
                                                      limits = levels(df$group), drop = FALSE)
            print(plot)
            TRUE
        }
    )
)

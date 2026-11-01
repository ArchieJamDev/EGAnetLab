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
# Network plot customization tests.
# ES: Pruebas de personalización del gráfico de red.
#
# Every option combination must produce a plot that renders, and the two
# options EGAnetLab applies itself (edgeMin, edge labels) must behave as
# documented in R/plot-helpers.R.
# ES: Toda combinación de opciones debe producir un gráfico que se dibuje, y
# las dos opciones que aplica EGAnetLab (edgeMin, etiquetas de aristas) deben
# comportarse como se documenta en R/plot-helpers.R.
# -----------------------------------------------------------------------------

edgeEgaFit <- function() {
    data <- edgeStructureData()
    EGAnet::EGA(data, plot.EGA = FALSE, verbose = FALSE)
}

renders <- function(plot) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off())
    print(plot)
    TRUE
}

test_that("default options draw EGAnet's network plot", {

    fit <- edgeEgaFit()
    plot <- EGAnetLab:::.el_ega_plot(fit$network, fit$wc, opts = list())

    expect_s3_class(plot, "ggplot")
    expect_true(renders(plot))
})

test_that("every layout, shape and edge style renders", {

    fit <- edgeEgaFit()
    grid <- list(
        list(layout = "kamadakawai", nodeShape = "square", edgeNegLty = "dashed"),
        list(layout = "circle", nodeShape = "triangle", edgePosColor = "blue", edgeNegColor = "orange"),
        list(layout = "mds", nodeShape = "diamond", labelColor = "navy", edgeNegLty = "dotted"),
        list(layout = "eigen", nodeSize = 8, nodeAlpha = 0.9, labelSize = 3, edgeSize = 4,
             plotTitle = "Network", legendTitle = "Dimension", legendPosition = "bottom")
    )

    for (opts in grid) {
        plot <- EGAnetLab:::.el_ega_plot(fit$network, fit$wc, opts = opts,
                                         palette = EGAnetLab:::.el_plot_series_palette("colorblind"))
        expect_s3_class(plot, "ggplot")
        expect_true(renders(plot), info = opts$layout)
    }
})

test_that("edge-weight labels add one label per plotted edge", {

    fit <- edgeEgaFit()
    plot <- EGAnetLab:::.el_ega_plot(fit$network, fit$wc,
                                     opts = list(showEdgeLabels = TRUE, edgeLabelDigits = 2))

    labels <- plot$layers[[length(plot$layers)]]$data
    n_edges <- sum(fit$network[upper.tri(fit$network)] != 0)
    expect_equal(nrow(labels), n_edges)
    expect_true(all(grepl("^-?[0-9]+\\.[0-9]{2}$", labels$text)))
    expect_true(renders(plot))
})

test_that("edgeMin hides weak edges and returns NULL when none remain", {

    fit <- edgeEgaFit()
    weights <- abs(fit$network[upper.tri(fit$network)])
    cut <- stats::median(weights[weights > 0])

    plot <- EGAnetLab:::.el_ega_plot(fit$network, fit$wc,
                                     opts = list(edgeMin = cut, showEdgeLabels = TRUE))
    labels <- plot$layers[[length(plot$layers)]]$data
    expect_equal(nrow(labels), sum(weights >= cut))

    expect_null(EGAnetLab:::.el_ega_plot(fit$network, fit$wc, opts = list(edgeMin = 1)))
})

test_that("the legend can be hidden", {

    fit <- edgeEgaFit()
    plot <- EGAnetLab:::.el_ega_plot(fit$network, fit$wc, opts = list(showLegend = FALSE))
    expect_equal(plot$theme$legend.position, "none")
})

test_that("palettes longer than the number of dimensions are accepted", {

    fit <- edgeEgaFit()
    for (choice in c("colorblind", "viridis")) {
        plot <- EGAnetLab:::.el_ega_plot(fit$network, fit$wc, opts = list(),
                                         palette = EGAnetLab:::.el_plot_series_palette(choice))
        expect_true(renders(plot), info = choice)
    }
})

test_that("distance-based layouts work with negative edges", {

    data <- edgeStructureData()
    data$item1 <- -data$item1 + 0.6 * data$item5
    for (layout in c("kamadakawai", "mds", "circle")) {
        res <- EGAnetLab::ega(data = data, vars = names(data), layout = layout)
        state <- res$networkPlot$state
        expect_true(any(state$network < 0))
        plot <- EGAnetLab:::.el_ega_plot(state$network, state$wc, list(layout = layout))
        expect_s3_class(plot, "ggplot")
    }
})

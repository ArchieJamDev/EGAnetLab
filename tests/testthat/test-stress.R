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
# Stress tests: missing data, small samples, categorical items and the
# bundled datasets. Each analysis must either finish or stop with one of
# EGAnetLab's own messages (expectGraceful), never with a raw R error.
# ES: Pruebas de estrés: datos ausentes, muestras pequeñas, ítems categóricos
# y los conjuntos de datos incluidos. Cada análisis debe terminar o detenerse
# con un mensaje propio de EGAnetLab (expectGraceful), nunca con un error
# crudo de R.
# -----------------------------------------------------------------------------

stressDynData <- function(persons = 20) {
    utils::data("sim.dynEGA", package = "EGAnet", envir = environment())
    d <- sim.dynEGA[sim.dynEGA$ID %in% c(seq_len(persons / 2), 50 + seq_len(persons / 2)), ]
    d$Time <- stats::ave(seq_len(nrow(d)), d$ID, FUN = seq_along)
    d$ID <- paste0("P", d$ID)
    rownames(d) <- NULL
    d
}

casesUsed <- function(res) res$summary$asDF$value[res$summary$asDF$element == "Cases used"]

test_that("10% missing values are handled pairwise and listwise", {

    data <- edgeMissingData()
    complete <- sum(stats::complete.cases(data))

    pw <- EGAnetLab::ega(data = data, vars = names(data), naData = "pairwise",
                         showNetworkPlot = FALSE)
    expect_true(pw$summary$isFilled())
    expect_match(casesUsed(pw), paste0("^300 \\(pairwise; ", complete, " "))

    lw <- EGAnetLab::ega(data = data, vars = names(data), naData = "listwise",
                         showNetworkPlot = FALSE)
    expect_true(lw$summary$isFilled())
    expect_match(casesUsed(lw), paste0("^", complete, " \\(listwise"))
})

test_that("listwise deletion with no complete row says so", {

    data <- edgeNoCompleteRowData()
    expect_error(EGAnetLab::ega(data = data, vars = names(data), naData = "listwise"),
                 "complete cases remain", fixed = TRUE)

    res <- EGAnetLab::ega(data = data, vars = names(data), naData = "pairwise",
                          showNetworkPlot = FALSE)
    expect_true(res$summary$isFilled())
})

test_that("small samples finish or stop with an explanation", {

    for (n in c(50, 20, 8)) {
        data <- edgeStructureData(n = n)
        expectGraceful(EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE))
    }
})

test_that("a small sample with bootstrap, UVA and CFA finishes or explains", {

    data <- edgeStructureData(n = 40)
    expectGraceful(EGAnetLab::ega(data = data, vars = names(data), runBoot = TRUE, iter = 20,
                                  seed = 3, runUVA = TRUE, runCFA = TRUE,
                                  showNetworkPlot = FALSE))
})

test_that("Likert items are treated as ordinal", {

    data <- edgeLikertData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE)

    expect_true(res$summary$isFilled())
    corr <- res$summary$asDF$value[res$summary$asDF$element == "Correlation"]
    expect_match(corr, "treated as ordinal", fixed = TRUE)
})

test_that("dichotomous items are analysed", {

    data <- edgeBinaryData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE)
    expect_true(res$summary$isFilled())
    expect_equal(nrow(res$membership$asDF), 12)
})

test_that("bootstrap and CFA run on data with missing values", {

    data <- edgeMissingData(rate = 0.05)
    expectGraceful(EGAnetLab::ega(data = data, vars = names(data), runBoot = TRUE, iter = 20,
                                  seed = 5, runCFA = TRUE, showNetworkPlot = FALSE))
})

test_that("a grouping variable with missing values is handled", {

    data <- edgeMissingData(rate = 0.05)
    data$grp <- factor(rep(c("A", "B"), length.out = nrow(data)))
    data$grp[c(1, 50, 100)] <- NA
    expectGraceful(EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                                  runInvariance = TRUE, invIter = 100,
                                  showNetworkPlot = FALSE))
})

test_that("dynega handles missing values in the items", {

    d <- stressDynData()
    withr::local_seed(7)
    for (v in paste0("V", 1:24))
        d[[v]][stats::runif(nrow(d)) < 0.03] <- NA_real_
    expectGraceful(EGAnetLab::dynega(data = d, vars = paste0("V", 1:24), id = "ID", time = "Time"))
})

test_that("the bundled WMT-2 data run end to end", {

    wmt <- bundledData("eganetlab_wmt2.csv")
    skip_if(is.null(wmt), "data/ not available")

    res <- EGAnetLab::ega(data = wmt, vars = paste0("wmt", 1:18), showNetworkPlot = FALSE)
    expect_true(res$summary$isFilled())
    expect_equal(nrow(res$membership$asDF), 18)
})

test_that("the bundled Big Five data run with missing values and wording effects", {

    bfi <- bundledData("eganetlab_bfi.csv")
    skip_if(is.null(bfi), "data/ not available")
    # Items are written in the call itself: jmvcore reads a bare variable
    # name passed to an option as a column name.
    # ES: Los ítems se escriben en la propia llamada: jmvcore lee el nombre
    # de una variable suelta pasada a una opción como nombre de columna.
    res <- EGAnetLab::ega(data = bfi, vars = paste0(rep(c("A", "C", "E", "N", "O"), each = 5), 1:5), showNetworkPlot = FALSE)
    expect_true(res$summary$isFilled())
    expect_match(casesUsed(res), "^2800 \\(pairwise; 2436 ")

    ri <- EGAnetLab::ega(data = bfi, vars = paste0(rep(c("A", "C", "E", "N", "O"), each = 5), 1:5), runRI = TRUE,
                         negItems = c("A1", "C4", "C5", "E1", "E2", "O2", "O5"),
                         negCoding = "raw", showNetworkPlot = FALSE)
    expect_gt(ri$riSummary$rowCount, 0)
})

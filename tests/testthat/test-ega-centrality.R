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
# Centrality (qgraph) and network stability (bootnet) of the ega analysis.
# ES: Centralidad (qgraph) y estabilidad de la red (bootnet) del análisis ega.
# -----------------------------------------------------------------------------

test_that("ega shows no centrality or stability until asked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12))

    expect_false(res$cenTable$visible)
    expect_false(res$bnCS$visible)
})

test_that("centrality matches qgraph on the EGA network", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          runCentrality = TRUE, cenStandardize = FALSE)

    table <- res$cenTable$asDF
    expect_equal(nrow(table), 12)
    ega <- EGAnet::EGA(data, plot.EGA = FALSE, verbose = FALSE)
    net <- as.matrix(ega$network)
    expect_equal(table$strength, unname(colSums(abs(net))), tolerance = 1e-8)
    expect_equal(table$ei, unname(colSums(net)), tolerance = 1e-8)
    expect_match(res$cenInterpretation$content, "most central", fixed = TRUE)
    expect_match(res$cenInterpretation$content, "Next step", fixed = TRUE)
})

test_that("standardized centrality has mean 0 and SD 1", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          runCentrality = TRUE, cenClosBetw = TRUE)

    table <- res$cenTable$asDF
    for (col in c("strength", "ei", "closeness", "betweenness")) {
        expect_equal(mean(table[[col]]), 0, tolerance = 1e-8)
        expect_equal(stats::sd(table[[col]]), 1, tolerance = 1e-8)
    }
    expect_match(res$cenInterpretation$content, "Bringmann", fixed = TRUE)
})

test_that("negative edges separate expected influence from strength", {

    data <- edgeStructureData()
    data$item4 <- -data$item4
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          runCentrality = TRUE, cenStandardize = FALSE)

    table <- res$cenTable$asDF
    expect_lt(table$ei[table$item == "item4"], table$strength[table$item == "item4"])
    expect_match(res$cenInterpretation$content, "negative connections", fixed = TRUE)
})

test_that("centrality is reported in Spanish", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          runCentrality = TRUE, reportLang = "es")

    expect_match(res$cenStatus$content, "fuerza", fixed = TRUE)
    expect_match(res$cenInterpretation$content, "Siguiente paso", fixed = TRUE)
    expect_false(grepl("EGAnet(?!Lab)", res$cenStatus$content, perl = TRUE))
})

test_that("bootnet gives edge intervals and CS coefficients", {

    skip_if_not_installed("bootnet")
    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          runBootnet = TRUE, bnIter = 100, bnCaseIter = 100)

    cs <- res$bnCS$asDF
    expect_equal(nrow(cs), 2)
    expect_true(all(cs$cs >= 0 & cs$cs <= 0.75))
    edges <- res$bnEdges$asDF
    expect_gt(nrow(edges), 0)
    expect_true(all(edges$low <= edges$weight + 1e-8 | edges$high >= edges$weight - 1e-8))
    expect_true(all(edges$nonzero >= 0 & edges$nonzero <= 1))
    expect_match(res$bnStatus$content, "Epskamp", fixed = TRUE)
    expect_match(res$bnInterpretation$content, "CS =", fixed = TRUE)
})

test_that("bootnet re-estimates exactly the EGA network", {

    skip_if_not_installed("bootnet")
    data <- edgeStructureData()
    out <- EGAnetLab:::.el_bootnet(data, corr = "auto", na_data = "pairwise", model = "glasso",
                                   iter = 100, case_iter = 100, seed = 1)
    ega <- EGAnet::EGA(data, plot.EGA = FALSE, verbose = FALSE)
    expect_equal(unname(out$network), unname(as.matrix(ega$network)), tolerance = 1e-10)
})

test_that("bootnet is reproducible with the same seed", {

    skip_if_not_installed("bootnet")
    data <- edgeStructureData()
    run <- function() EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                                     runBootnet = TRUE, bnIter = 100, bnCaseIter = 100)
    a <- run()
    b <- run()
    expect_equal(a$bnCS$asDF, b$bnCS$asDF)
    expect_equal(a$bnEdges$asDF, b$bnEdges$asDF)
})

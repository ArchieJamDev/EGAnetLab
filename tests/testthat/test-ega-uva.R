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
# Redundancy (UVA) section of the ega analysis.
# ES: Sección Redundancia (UVA) del análisis ega.
# -----------------------------------------------------------------------------

# Twelve-item structure plus a near-duplicate of item1, which UVA must flag.
# ES: Estructura de doce ítems más un casi duplicado de item1, que UVA debe
# señalar.
redundantData <- function() {
    data <- edgeStructureData()
    withr::local_seed(7)
    data$item1b <- data$item1 + stats::rnorm(nrow(data), sd = 0.15)
    data
}

runUVA <- function(data, ...) {
    EGAnetLab::ega(data = data, vars = names(data), runUVA = TRUE, ...)
}

test_that("ega runs no redundancy analysis until it is ticked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data))

    expect_false(res$uvaStatus$visible)
    expect_equal(res$uvaPairs$rowCount, 0)
})

test_that("UVA flags a near-duplicate item and suggests one to remove", {

    res <- runUVA(redundantData())

    pairs <- res$uvaPairs$asDF
    top <- pairs[1, ]
    expect_setequal(c(top$itemA, top$itemB), c("item1", "item1b"))
    expect_true(top$wto >= 0.25)
    expect_true(all(diff(pairs$wto) <= 0))
    expect_equal(top$sameDim, "Yes")

    # Other moderately overlapping items may form sets too; check the one
    # that holds the duplicate.
    # ES: Otros ítems con solapamiento moderado también pueden formar
    # conjuntos; se revisa el que contiene el duplicado.
    sets <- res$uvaSets$asDF
    expect_true(nrow(sets) >= 1)
    members <- lapply(sets$items, function(x) strsplit(x, ", ")[[1]])
    hit <- which(vapply(members, function(m) "item1b" %in% m, logical(1)))
    expect_length(hit, 1)
    expect_true("item1" %in% members[[hit]])
    removed <- strsplit(sets$remove[hit], ", ")[[1]]
    expect_true(any(c("item1", "item1b") %in% removed))

    expect_match(res$uvaInterpretation$content, "redundant set", fixed = TRUE)
    expect_match(res$choicesGuide$content, "wTO", fixed = TRUE)
})

test_that("UVA reports no redundancy below the cutoff", {

    res <- runUVA(edgeStructureData(), uvaCut = 0.40)
    sets <- res$uvaSets$asDF

    expect_equal(nrow(sets), 0)
    expect_match(res$uvaInterpretation$content, "no evidence of redundancy", fixed = TRUE)
})

test_that("UVA renders in Spanish", {

    res <- runUVA(redundantData(), reportLang = "es")
    expect_match(res$uvaInterpretation$content, "conjunto(s) redundante(s)", fixed = TRUE)
    expect_equal(res$uvaPairs$asDF$sameDim[1], "Sí")
})

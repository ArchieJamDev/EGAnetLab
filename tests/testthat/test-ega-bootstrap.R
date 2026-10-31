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
# Stability (bootstrap) section of the ega analysis. Few bootstrap samples
# keep the suite fast; stability values are checked for range and
# reproducibility, not for exact numbers.
# ES: Sección Estabilidad (bootstrap) del análisis ega. Pocas muestras
# bootstrap mantienen la batería rápida; los valores de estabilidad se
# verifican por rango y reproducibilidad, no por números exactos.
# -----------------------------------------------------------------------------

runBoot <- function(data, ...) {
    EGAnetLab::ega(data = data, vars = names(data), runBoot = TRUE,
                   iter = 20, seed = 11, ...)
}

test_that("ega runs no bootstrap until Run bootstrap is ticked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data))

    expect_false(res$bootStatus$visible)
    expect_equal(res$bootSummary$rowCount, 0)
    expect_match(res$interpretation$content, "Run bootstrap", fixed = TRUE)
    expect_false(grepl("Bootstrap type", res$choicesGuide$content, fixed = TRUE))
})

test_that("the bootstrap resamples the same EGA shown above", {

    data <- edgeStructureData()
    res <- runBoot(data)

    ega_dims <- res$summary$asDF
    ega_dims <- ega_dims$value[ega_dims$element == "Number of dimensions"]
    boot <- res$bootSummary$asDF
    original <- boot$value[boot$element == "Dimensions in the original sample"]
    expect_equal(original, ega_dims)
    expect_equal(original, "3")

    freq <- res$bootFrequency$asDF
    expect_equal(sum(freq$count), 20)
    expect_equal(sum(freq$proportion), 1, tolerance = 1e-8)

    items <- res$bootItemStability$asDF
    expect_equal(nrow(items), 12)
    expect_true(all(items$stability >= 0 & items$stability <= 1))

    dims <- res$bootDimStability$asDF
    expect_true(nrow(dims) >= 1)
    expect_true(all(dims$consistency >= 0 & dims$consistency <= 1))

    expect_match(res$bootStatus$content, "seed 11", fixed = TRUE)
    expect_match(res$choicesGuide$content, "Bootstrap type: Parametric", fixed = TRUE)
    expect_false(grepl("tick Run bootstrap", res$interpretation$content, fixed = TRUE))
})

test_that("the bootstrap is reproducible with the same seed", {

    data <- edgeStructureData()
    first <- runBoot(data)$bootItemStability$asDF
    second <- runBoot(data)$bootItemStability$asDF
    expect_equal(first$stability, second$stability)
})

test_that("the bootstrap flags items below the stability cutoff", {

    data <- edgeStructureData()
    items <- runBoot(data, stabilityCut = 0.95)$bootItemStability$asDF

    expect_equal(items$flag == "Below cutoff", items$stability < 0.95)
})

test_that("the bootstrap renders in Spanish", {

    data <- edgeStructureData()
    res <- runBoot(data, reportLang = "es", bootType = "resampling")

    expect_true("Dimensiones en la muestra original" %in% res$bootSummary$asDF$element)
    expect_match(res$choicesGuide$content, "Tipo de bootstrap: Remuestreo (casos)", fixed = TRUE)
})

test_that("the bootstrap warns when the most frequent solution is weak", {

    data <- edgeStructureData()
    res <- runBoot(data, stabilityCut = 0.95)
    freq <- res$bootFrequency$asDF
    weak <- max(freq$proportion) < 0.95

    expect_equal(grepl("not firmly established", res$bootInterpretation$content, fixed = TRUE), weak)
})

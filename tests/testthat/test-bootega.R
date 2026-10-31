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
# bootega tests. Few bootstrap samples keep the suite fast; stability values
# are checked for range and reproducibility, not for exact numbers.
# ES: Pruebas de bootega. Pocas muestras bootstrap mantienen la batería
# rápida; los valores de estabilidad se verifican por rango y
# reproducibilidad, no por números exactos.
# -----------------------------------------------------------------------------

runBoot <- function(data, ...) {
    EGAnetLab::bootega(data = data, vars = names(data), runBoot = TRUE,
                       iter = 20, seed = 11, ...)
}

test_that("bootega waits for the Run bootstrap checkbox", {

    data <- edgeStructureData()
    res <- EGAnetLab::bootega(data = data, vars = names(data))

    expect_match(res$status$content, "Run bootstrap", fixed = TRUE)
    expect_equal(res$summary$rowCount, 0)
    expect_match(res$choicesGuide$content, "Bootstrap type: Parametric", fixed = TRUE)
})

test_that("bootega reports dimension and item stability", {

    data <- edgeStructureData()
    res <- runBoot(data)

    summary <- res$summary$asDF
    original <- summary$value[summary$element == "Dimensions in the original sample"]
    expect_equal(original, "3")

    freq <- res$frequency$asDF
    expect_equal(sum(freq$count), 20)
    expect_equal(sum(freq$proportion), 1, tolerance = 1e-8)

    items <- res$itemStability$asDF
    expect_equal(nrow(items), 12)
    expect_true(all(items$stability >= 0 & items$stability <= 1))

    dims <- res$dimStability$asDF
    expect_true(nrow(dims) >= 1)
    expect_true(all(dims$consistency >= 0 & dims$consistency <= 1))

    expect_match(res$status$content, "seed 11", fixed = TRUE)
})

test_that("bootega is reproducible with the same seed", {

    data <- edgeStructureData()
    first <- runBoot(data)$itemStability$asDF
    second <- runBoot(data)$itemStability$asDF
    expect_equal(first$stability, second$stability)
})

test_that("bootega flags items below the stability cutoff", {

    data <- edgeStructureData()
    items <- runBoot(data, stabilityCut = 0.95)$itemStability$asDF

    expect_equal(items$flag == "Below cutoff", items$stability < 0.95)
})

test_that("bootega renders the report in Spanish", {

    data <- edgeStructureData()
    res <- runBoot(data, reportLang = "es", bootType = "resampling")

    expect_true("Dimensiones en la muestra original" %in% res$summary$asDF$element)
    expect_match(res$choicesGuide$content, "Tipo de bootstrap: Remuestreo (casos)", fixed = TRUE)
})

test_that("bootega rejects fewer than three items", {

    data <- edgeStructureData()[, 1:2]
    expect_error(
        EGAnetLab::bootega(data = data, vars = names(data), runBoot = TRUE, iter = 20),
        "three"
    )
})

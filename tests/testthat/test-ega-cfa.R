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
# Confirmatory factor analysis and random split of the ega analysis.
# ES: Análisis factorial confirmatorio y división aleatoria del análisis ega.
# -----------------------------------------------------------------------------

runCFA <- function(...) {
    data <- edgeStructureData()
    EGAnetLab::ega(data = data, vars = names(data), runCFA = TRUE, ...)
}

test_that("CFA tests the EGA structure in the total sample", {

    res <- runCFA()
    compare <- res$cfaCompare$asDF

    expect_equal(nrow(compare), 17)
    expect_false(compare$total[compare$element == "GFI"] == "\u2014")
    expect_equal(compare$total[compare$element == "Cases"], "300")
    expect_equal(compare$total[compare$element == "Dimensions found by EGA"], "3")
    cfi <- as.numeric(compare$total[compare$element == "CFI"])
    expect_true(cfi > 0.9 && cfi <= 1)
    expect_equal(nrow(res$cfaLoadings$asDF), 12)
    expect_equal(res$cfaMembership$rowCount, 0)
    expect_match(res$cfaStatus$content, "optimistic", fixed = TRUE)
})

test_that("the random split reports total, part A and part B side by side", {

    res <- runCFA(splitSample = TRUE, splitSeed = 5)
    compare <- res$cfaCompare$asDF
    n <- as.numeric(compare[compare$element == "Cases", c("total", "partA", "partB")])

    expect_equal(n, c(300, 150, 150))
    expect_false(compare$partB[compare$element == "CFI"] == "\u2014")

    membership <- res$cfaMembership$asDF
    expect_equal(nrow(membership), 12)
    expect_true(all(membership$agree %in% c("Yes", "Changes")))
    expect_match(res$cfaInterpretation$content, "seed 5", fixed = TRUE)
    expect_match(res$cfaLoadings$title, "confirmation", fixed = TRUE)
})

test_that("the random split is reproducible and follows the proportion", {

    first <- runCFA(splitSample = TRUE, splitSeed = 9, splitProp = 0.6)$cfaCompare$asDF
    second <- runCFA(splitSample = TRUE, splitSeed = 9, splitProp = 0.6)$cfaCompare$asDF

    expect_equal(first, second)
    expect_equal(first$partA[first$element == "Cases"], "180")
})

test_that("CFA renders in Spanish", {

    res <- runCFA(splitSample = TRUE, reportLang = "es")
    expect_true("Casos" %in% res$cfaCompare$asDF$element)
    expect_match(res$cfaInterpretation$content, "semilla", fixed = TRUE)
})

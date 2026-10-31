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
# Structure comparison (TEFI) of the ega analysis.
# ES: Comparación de estructuras (TEFI) del análisis ega.
# -----------------------------------------------------------------------------

runCompare <- function(...) {
    data <- edgeStructureData()
    EGAnetLab::ega(data = data, vars = names(data), runCompare = TRUE, ...)
}

# Factors as jamovi's Theoretical structure list builds them.
# ES: Factores como los arma la lista Theoretical structure de jamovi.
factors <- function(...) {
    groups <- list(...)
    lapply(names(groups), function(label) list(label = label, vars = groups[[label]]))
}

theory3 <- factors(A = paste0("item", 1:4), B = paste0("item", 5:8), C = paste0("item", 9:12))

test_that("ega shows no structure comparison until asked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data))

    expect_false(res$compareTable$visible)
    expect_equal(res$compareTable$rowCount, 0)
})

test_that("the EGA solution is compared with the other algorithms", {

    res <- runCompare()
    table <- res$compareTable$asDF
    summary <- res$summary$asDF

    expect_equal(nrow(table), 3)
    expect_equal(table$dims, c(3, 3, 3))
    tefi_summary <- as.numeric(summary$value[summary$element == "TEFI"])
    expect_equal(round(table$tefi[1], 3), tefi_summary)
    expect_true(all(table$delta >= 0, na.rm = TRUE))
    expect_true(any(table$delta == 0))
    expect_equal(nrow(res$compareMembership$asDF), 12)
    expect_match(res$compareInterpretation$content, "Theoretical structure", fixed = TRUE)
})

test_that("algorithm solutions are reproducible", {

    first <- runCompare()$compareTable$asDF
    second <- runCompare()$compareTable$asDF
    expect_equal(first$tefi, second$tefi)
})

test_that("a theoretical structure that matches EGA is recognized", {

    res <- runCompare(compareAlgorithms = FALSE, theoryFactors = theory3)
    table <- res$compareTable$asDF

    expect_equal(nrow(table), 2)
    expect_equal(table$agree[2], "12 of 12 (100%)")
    expect_equal(table$tefi[1], table$tefi[2])
    expect_match(res$compareInterpretation$content, "group the items in the same way", fixed = TRUE)
    membership <- res$compareMembership$asDF
    expect_equal(membership$theory[membership$item == "item10"], "C")
})

test_that("a different theoretical structure has a higher TEFI and names the items that move", {

    res <- runCompare(compareAlgorithms = FALSE,
                      theoryFactors = factors(A = paste0("item", 1:6), B = paste0("item", 7:12)))
    table <- res$compareTable$asDF
    expect_equal(nrow(table), 2)
    expect_true(table$tefi[2] > table$tefi[1])
    expect_match(res$compareInterpretation$content, "lowest TEFI", fixed = TRUE)
    expect_match(res$compareInterpretation$content, "item5", fixed = TRUE)
})

test_that("a one-dimensional theoretical structure is not compared by TEFI", {

    res <- runCompare(compareAlgorithms = FALSE, theoryFactors = factors(G = paste0("item", 1:12)))
    table <- res$compareTable$asDF

    expect_equal(table$dims[2], 1)
    expect_true(is.na(table$tefi[2]))
    expect_match(res$compareInterpretation$content, "single dimension", fixed = TRUE)
})

test_that("theoretical structure errors are explained without stopping the analysis", {

    res <- runCompare(compareAlgorithms = FALSE,
                      theoryFactors = factors(A = c("item1", "item2"), B = c("item2", "item3")))
    expect_match(res$compareStatus$content, "more than one factor", fixed = TRUE)
    expect_equal(nrow(res$compareTable$asDF), 1)

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:11), runCompare = TRUE, compareAlgorithms = FALSE,
                          theoryFactors = factors(A = c("item1", "item2", "item12"), B = c("item5", "item6")))
    expect_match(res$compareStatus$content, "item12", fixed = TRUE)
    expect_equal(nrow(res$compareTable$asDF), 1)
})

test_that("CFA fit is added for each structure on request", {

    res <- runCompare(compareAlgorithms = FALSE, theoryFactors = theory3, compareCFA = TRUE)
    table <- res$compareTable$asDF

    expect_true(all(table$cfi > 0.9 & table$cfi <= 1))
    expect_true(all(table$rmsea >= 0))
    expect_match(res$compareInterpretation$content, "favor it", fixed = TRUE)
})

test_that("the structure comparison renders in Spanish", {

    res <- runCompare(theoryFactors = theory3, reportLang = "es")
    expect_match(res$compareStatus$content, "Índice de Ajuste de Entropía Total", fixed = TRUE)
    expect_equal(res$compareTable$asDF$agree[4], "12 de 12 (100%)")
})

test_that("an empty theoretical structure is not compared", {

    res <- runCompare(compareAlgorithms = FALSE)
    expect_equal(nrow(res$compareTable$asDF), 1)

    build <- EGAnetLab:::.el_factors_structure
    r <- build(list(list(label = "", vars = c("a", "b")), list(label = "Factor 2", vars = list())), c("a", "b", "c"))
    expect_false(r$empty)
    expect_equal(unname(r$wc), c("Factor 1", "Factor 1", NA))
    expect_equal(r$unassigned, "c")
    expect_true(build(list(list(label = "Factor 1", vars = list())), c("a", "b"))$empty)
})

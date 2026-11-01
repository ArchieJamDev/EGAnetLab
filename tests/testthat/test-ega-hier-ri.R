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
# Hierarchical EGA and random-intercept EGA of the ega analysis.
# ES: EGA jerárquico y EGA con intercepto aleatorio del análisis ega.
# -----------------------------------------------------------------------------

test_that("ega shows no hierarchical or random-intercept EGA until asked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data))

    expect_false(res$hierSummary$visible)
    expect_false(res$riSummary$visible)
    expect_equal(res$hierSummary$rowCount, 0)
    expect_equal(res$riSummary$rowCount, 0)
})

test_that("hierarchical EGA reports both levels and every item", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE)
    summary <- res$hierSummary$asDF

    expect_equal(nrow(summary), 7)
    expect_true(as.numeric(summary$value[summary$element == "Lower-order dimensions"]) >= 2)
    expect_equal(nrow(res$hierMembership$asDF), 12)
    expect_match(res$hierStatus$content, "Jiménez", fixed = TRUE)
    expect_match(res$hierInterpretation$content, "experimental", fixed = TRUE)
})

test_that("hierarchical EGA is reproducible", {

    data <- edgeStructureData()
    first <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE)$hierMembership$asDF
    second <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE)$hierMembership$asDF
    expect_equal(first, second)
})

test_that("random-intercept EGA compares dimensions with and without wording control", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runRI = TRUE)
    summary <- res$riSummary$asDF

    expect_equal(nrow(summary), 5)
    expect_equal(summary$value[summary$element == "Dimensions without wording control (EGA)"], "3")
    expect_equal(nrow(res$riMembership$asDF), 12)
    expect_match(res$riStatus$content, "<strong>Before reading this section", fixed = TRUE)
    expect_match(res$riInterpretation$content, "unrecoded", fixed = TRUE)
})

test_that("random-intercept EGA works with item names lavaan cannot read", {

    data <- edgeSpecialNameData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runRI = TRUE)
    expect_equal(nrow(res$riSummary$asDF), 5)
    expect_true("ítem 3 (inv.)" %in% res$riMembership$asDF$item)
})

test_that("hierarchical and random-intercept EGA render in Spanish", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE, runRI = TRUE, reportLang = "es")
    expect_match(res$hierStatus$content, "orden superior", fixed = TRUE)
    expect_match(res$riStatus$content, "aquiescencia", fixed = TRUE)
})

test_that("hierarchical EGA sends its structure to the plot", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE)
    state <- res$hierPlot$state

    expect_true(res$hierPlot$visible)
    expect_false(is.null(state))
    expect_equal(sum(state$nodes$level == 0), 12)
    expect_true(sum(state$nodes$level == 1) >= 2)
})

test_that("CFA compares models with and without hierarchy when both are asked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE, runCFA = TRUE)
    models <- res$cfaHierModels$asDF

    expect_true(res$cfaHierModels$visible)
    expect_true(nrow(models) >= 3)
    expect_true("One factor" %in% models$model)
    expect_true(any(startsWith(models$model, "Bifactor")))
    expect_match(res$cfaHierInterpretation$content, "optimistic", fixed = TRUE)

    plain <- EGAnetLab::ega(data = data, vars = names(data), runCFA = TRUE)
    expect_false(plain$cfaHierModels$visible)
})

test_that("negatively worded items are reversed only when they are as answered", {

    data <- edgeStructureData()
    neg <- names(data)[1:2]
    flipped <- data
    for (v in neg) flipped[[v]] <- min(data[[v]]) + max(data[[v]]) - data[[v]]

    original <- EGAnetLab::ega(data = data, vars = names(data))$membership$asDF
    raw <- EGAnetLab::ega(data = flipped, vars = names(data), negItems = neg, negCoding = "raw")
    expect_equal(raw$membership$asDF, original)
    expect_true(any(grepl("reversed for the analysis", raw$summary$asDF$value, fixed = TRUE)))

    recoded <- EGAnetLab::ega(data = data, vars = names(data), negItems = neg, negCoding = "recoded")
    expect_equal(recoded$membership$asDF, original)
})

test_that("random-intercept EGA marks the negatively worded items", {

    data <- edgeStructureData()
    neg <- names(data)[1:2]
    res <- EGAnetLab::ega(data = data, vars = names(data), runRI = TRUE, negItems = neg)
    members <- res$riMembership$asDF

    expect_equal(sum(members$negative == "Yes"), 2)
    expect_match(res$riStatus$content, "already reversed in the data", fixed = TRUE)

    none <- EGAnetLab::ega(data = data, vars = names(data), runRI = TRUE)
    expect_match(none$riStatus$content, "No item is marked", fixed = TRUE)
})

test_that("reversing items keeps the observed range", {

    data <- data.frame(a = c(1, 2, 5, NA), b = c(2, 3, 4, 4))
    out <- EGAnetLab:::.el_reverse_items(data, "a")
    expect_equal(out$a, c(5, 4, 1, NA))
    expect_equal(out$b, data$b)
})

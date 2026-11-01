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
# Group comparison of the ega analysis: metric invariance (independent
# groups) and the Network Comparison Test (independent and paired groups).
# ES: Comparación entre grupos del análisis ega: invarianza métrica (grupos
# independientes) y Network Comparison Test (grupos independientes y
# pareados).
# -----------------------------------------------------------------------------

groupData <- function(k = 2) {
    data <- edgeStructureData()
    data$grp <- factor(rep(LETTERS[seq_len(k)], length.out = nrow(data)))
    data
}

pairedData <- function() {
    data <- edgeStructureData()
    withr::local_seed(7)
    for (i in 1:12)
        data[[paste0("t2_", i)]] <- data[[paste0("item", i)]] + stats::rnorm(nrow(data), sd = 0.5)
    data
}

test_that("ega shows no group comparison until asked", {

    data <- groupData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp")

    expect_false(res$groupStatus$visible)
    expect_false(res$invTable$visible)
    expect_false(res$nctGlobal$visible)
})

test_that("invariance without a grouping variable explains what to add", {

    data <- groupData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), runInvariance = TRUE)

    expect_match(res$groupStatus$content, "grouping variable", fixed = TRUE)
    expect_match(res$invStatus$content, "grouping variable", fixed = TRUE)
    expect_equal(res$invTable$rowCount, 0)
})

test_that("metric invariance tests every item between two groups", {

    data <- groupData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                          runInvariance = TRUE, invIter = 100)

    sizes <- res$groupSizes$asDF
    expect_equal(sizes$n, c(150, 150))
    table <- res$invTable$asDF
    expect_equal(nrow(table), 12)
    expect_true(all(table$p >= 0 & table$p <= 1))
    expect_match(res$invStatus$content, "Jamison", fixed = TRUE)
    expect_match(res$invInterpretation$content, "Next step", fixed = TRUE)
})

test_that("metric invariance is reproducible with the same seed", {

    data <- groupData()
    run <- function() EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                                     runInvariance = TRUE, invIter = 100)$invTable$asDF
    expect_equal(run(), run())
})

test_that("more than two groups are compared pair by pair", {

    data <- groupData(3)
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                          runInvariance = TRUE, invIter = 100)

    expect_match(res$groupStatus$content, "3 groups", fixed = TRUE)
    expect_equal(nrow(res$invTable$asDF), 36)
})

test_that("small groups are left out with a note", {

    data <- groupData()
    data$grp <- as.character(data$grp)
    data$grp[1:5] <- "C"
    data$grp <- factor(data$grp)
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                          runInvariance = TRUE, invIter = 100)

    expect_match(res$groupStatus$content, "fewer than 10 cases", fixed = TRUE)
    expect_equal(nrow(res$groupSizes$asDF), 2)
})

test_that("NCT compares two independent groups", {

    skip_if_not_installed("NetworkComparisonTest")
    data <- groupData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                          runNCT = TRUE, nctIter = 100, nctEdges = TRUE, nctCentrality = TRUE)

    global <- res$nctGlobal$asDF
    expect_equal(nrow(global), 2)
    expect_true(all(global$p >= 0 & global$p <= 1))
    expect_equal(nrow(res$nctCentralityTable$asDF), 24)
    expect_match(res$nctStatus$content, "van Borkulo", fixed = TRUE)
    expect_match(res$nctInterpretation$content, "n = 150", fixed = TRUE)
})

test_that("NCT compares the same people measured twice", {

    skip_if_not_installed("NetworkComparisonTest")
    data <- pairedData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          pairedVars = c("t2_1", "t2_2", "t2_3", "t2_4", "t2_5", "t2_6",
                                         "t2_7", "t2_8", "t2_9", "t2_10", "t2_11", "t2_12"),
                          runNCT = TRUE, nctIter = 100)

    expect_equal(nrow(res$nctGlobal$asDF), 2)
    expect_match(res$nctInterpretation$content, "the same people measured twice", fixed = TRUE)
    expect_equal(res$groupSizes$asDF$n, 300)
})

test_that("a second measurement with the wrong number of variables is explained", {

    data <- pairedData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12),
                          pairedVars = c("t2_1", "t2_2"), runNCT = TRUE, nctIter = 100)

    expect_match(res$groupStatus$content, "same order as the items", fixed = TRUE)
    expect_equal(res$nctGlobal$rowCount, 0)
})

test_that("group comparison texts switch to Spanish", {

    data <- groupData()
    res <- EGAnetLab::ega(data = data, vars = paste0("item", 1:12), group = "grp",
                          runInvariance = TRUE, invIter = 100, reportLang = "es")

    expect_match(res$invStatus$content, "Invarianza métrica", fixed = TRUE)
    expect_match(res$invInterpretation$content, "Siguiente paso", fixed = TRUE)
})

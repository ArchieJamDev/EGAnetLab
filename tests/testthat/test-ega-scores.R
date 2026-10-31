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
# Network scores of the ega analysis.
# ES: Puntuaciones de red del análisis ega.
# -----------------------------------------------------------------------------

test_that("ega shows no network scores until asked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data))

    expect_false(res$scores$visible)
    expect_equal(res$scores$rowCount, 0)
})

test_that("network scores summarize one score per dimension", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), netScores = TRUE)
    scores <- res$scores$asDF

    expect_equal(nrow(scores), 3)
    expect_equal(sum(scores$items), 12)
    expect_true(all(scores$n == 300))
    expect_true(all(scores$sd > 0))
    expect_true(all(scores$rMean > 0.9))
})

test_that("network scores keep missing responses as missing", {

    data <- edgeStructureData()
    data$item1[1:5] <- NA
    res <- EGAnetLab::ega(data = data, vars = names(data), netScores = TRUE)
    scores <- res$scores$asDF

    expect_true(min(scores$n) < 300)
    expect_true(max(scores$n) == 300)
})

test_that("network scores render in Spanish", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), netScores = TRUE, reportLang = "es")
    expect_match(res$scoresGuide$content, "puntuaciones de red", fixed = TRUE)
})

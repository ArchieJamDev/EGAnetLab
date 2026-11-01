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
# Key findings summary (phase 8).
# ES: Resumen de hallazgos (fase 8).
# -----------------------------------------------------------------------------

test_that("the EGA report opens with the key findings", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE)
    html <- res$keySummary$content

    expect_match(html, "Main findings", fixed = TRUE)
    expect_match(html, "The items form 3 dimensions", fixed = TRUE)
    expect_match(html, "stability of the structure was not checked", fixed = TRUE)
    expect_match(html, "Warnings", fixed = TRUE)
})

test_that("the key findings follow the bootstrap and the report language", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE,
                          runBoot = TRUE, iter = 20, reportLang = "es")
    html <- res$keySummary$content

    expect_match(html, "Hallazgos principales", fixed = TRUE)
    expect_match(html, "(Estabilidad)", fixed = TRUE)
    expect_false(grepl("No se evaluó la estabilidad", html, fixed = TRUE))
})

test_that("the key findings can be turned off", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE,
                          showKeySummary = FALSE)
    expect_false(res$keySummary$visible)
})

test_that("Dynamic EGA opens with the key findings", {

    utils::data("sim.dynEGA", package = "EGAnet", envir = environment())
    d <- sim.dynEGA[sim.dynEGA$ID %in% c(1:10, 51:60), ]
    d$Time <- stats::ave(seq_len(nrow(d)), d$ID, FUN = seq_along)
    d$Beep <- (d$Time - 1) %% 4 + 1
    res <- EGAnetLab::dynega(data = d, vars = c("V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "Beep"),
                             id = "ID", time = "Time")
    html <- res$keySummary$content

    expect_match(html, "In the population, the items form", fixed = TRUE)
    expect_match(html, "schedule variables: Beep", fixed = TRUE)
    expect_match(html, "Individual structures were not estimated", fixed = TRUE)
})

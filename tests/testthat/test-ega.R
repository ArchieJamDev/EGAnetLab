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
# ega edge-case tests.
# ES: Pruebas de casos límite de ega.
#
# Category A conditions must reject with an explanation; a valid structure
# must fill every table. See CODE_STYLE.md §19.1.
# ES: Las condiciones de Categoría A deben rechazar con una explicación; una
# estructura válida debe llenar cada tabla. Ver CODE_STYLE.md §19.1.
# -----------------------------------------------------------------------------

test_that("ega recovers a clean three-dimensional structure", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE)

    expect_true(res$summary$isFilled())
    expect_true(res$membership$isFilled())
    expect_equal(nrow(res$membership$asDF), 12)

    dims <- res$summary$asDF$value[res$summary$asDF$element == "Number of dimensions"]
    expect_equal(dims, "3")
})

test_that("ega renders the report in Spanish when asked", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), reportLang = "es", showNetworkPlot = FALSE)

    expect_true("Número de dimensiones" %in% res$summary$asDF$element)
})

test_that("ega tolerates accented and symbol item names", {

    data <- edgeSpecialNameData()
    res <- EGAnetLab::ega(data = data, vars = names(data), showNetworkPlot = FALSE)

    expect_true("café ± más" %in% res$membership$asDF$item)
})

test_that("ega shows only the introduction when no items are selected", {

    data <- edgeStructureData()
    expect_no_error(EGAnetLab::ega(data = data, vars = character(0)))
})

test_that("ega rejects fewer than three items", {

    data <- edgeStructureData()
    expect_error(EGAnetLab::ega(data = data, vars = c("item1", "item2")), "three")
})

test_that("ega rejects a constant item and names it", {

    data <- edgeConstantItemData()
    expect_error(EGAnetLab::ega(data = data, vars = names(data)), "item1")
})

test_that("ega rejects an entirely missing item and names it", {

    data <- edgeEmptyItemData()
    expect_error(EGAnetLab::ega(data = data, vars = names(data)), "item1")
})

test_that("ega rejects a single-row data set", {

    data <- edgeSingleRowData()
    expect_error(EGAnetLab::ega(data = data, vars = names(data)))
})

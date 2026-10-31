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
# Shared edge-case data fixtures.
# ES: Datos compartidos para casos límite.
#
# Every EGAnetLab analysis is exercised on pathological input built here:
# a clean three-dimensional structure (the positive control), accented and
# symbol item names, a constant item, an entirely missing item, too few
# items, and a single-row data set. Tests assert graceful behavior (an
# explanatory jmvcore::reject() or a filled table), never a numeric result;
# numeric agreement with EGAnet itself lives in validation/.
#
# ES: Cada análisis de EGAnetLab se pone a prueba con entradas patológicas
# construidas aquí: una estructura limpia de tres dimensiones (el control
# positivo), nombres de ítems con acentos y símbolos, un ítem constante, un
# ítem completamente vacío, muy pocos ítems y un conjunto de una sola fila.
# Las pruebas verifican un comportamiento controlado (un jmvcore::reject()
# explicativo o una tabla llena), nunca un resultado numérico; la
# concordancia numérica con EGAnet vive en validation/.
# -----------------------------------------------------------------------------

# Three correlated dimensions with four items each (loadings 0.7), n = 300.
# ES: Tres dimensiones correlacionadas con cuatro ítems cada una (cargas
# 0.7), n = 300.
edgeStructureData <- function(n = 300, seed = 20261031) {

    withr::local_seed(seed)

    factors <- matrix(stats::rnorm(n * 3), ncol = 3)
    factors[, 2] <- 0.3 * factors[, 1] + sqrt(1 - 0.3^2) * factors[, 2]
    factors[, 3] <- 0.3 * factors[, 1] + sqrt(1 - 0.3^2) * factors[, 3]

    items <- lapply(1:12, function(j) {
        f <- factors[, (j - 1) %/% 4 + 1]
        0.7 * f + sqrt(1 - 0.7^2) * stats::rnorm(n)
    })

    data <- as.data.frame(items)
    names(data) <- paste0("item", 1:12)
    data
}

edgeSpecialNameData <- function() {
    data <- edgeStructureData()
    names(data)[1:3] <- c("niño_años", "café ± más", "ítem 3 (inv.)")
    data
}

edgeConstantItemData <- function() {
    data <- edgeStructureData()
    data$item1 <- 3
    data
}

edgeEmptyItemData <- function() {
    data <- edgeStructureData()
    data$item1 <- NA_real_
    data
}

edgeSingleRowData <- function() {
    edgeStructureData()[1, , drop = FALSE]
}

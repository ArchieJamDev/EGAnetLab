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
# Numerical equivalence: EGAnetLab::ega() vs. a direct EGAnet::EGA() call.
# ES: Equivalencia numérica: EGAnetLab::ega() frente a una llamada directa a
# EGAnet::EGA().
#
# EGAnetLab must never change what EGAnet computes (CODE_STYLE.md §21). This
# script runs both on the bundled WMT-2 items with every combination of
# network model and community detection algorithm, and checks that the
# number of dimensions, every item membership and TEFI agree exactly.
#
# ES: EGAnetLab nunca debe cambiar lo que calcula EGAnet (CODE_STYLE.md
# §21). Este script ejecuta ambos sobre los ítems WMT-2 incluidos, con cada
# combinación de modelo de red y algoritmo de detección de comunidades, y
# verifica que el número de dimensiones, cada pertenencia y el TEFI
# coincidan exactamente.
#
# Run from the repository root: Rscript validation/ega_equivalence.R
# -----------------------------------------------------------------------------

data <- utils::read.csv(file.path("data", "eganetlab_wmt2.csv"))
items <- paste0("wmt", 1:18)

grid <- expand.grid(
    model = c("glasso", "TMFG"),
    algorithm = c("walktrap", "louvain", "leiden"),
    stringsAsFactors = FALSE
)

results <- lapply(seq_len(nrow(grid)), function(i) {

    model <- grid$model[i]
    algorithm <- grid$algorithm[i]

    # Louvain and Leiden are stochastic; the same seed is set before each call.
    # ES: Louvain y Leiden son estocásticos; se fija la misma semilla antes de
    # cada llamada.
    set.seed(20261031)
    direct <- EGAnet::EGA(data[, items], model = model, algorithm = algorithm,
                          plot.EGA = FALSE, verbose = FALSE)

    set.seed(20261031)
    lab <- EGAnetLab::ega(data = data, vars = items, model = model, algorithm = algorithm,
                          showNetworkPlot = FALSE)

    summary <- lab$summary$asDF
    lab_dims <- summary$value[summary$element == "Number of dimensions"]
    lab_tefi <- summary$value[summary$element == "TEFI"]
    lab_wc <- lab$membership$asDF$dimension
    direct_wc <- ifelse(is.na(direct$wc), "Isolated (no edges)", as.character(direct$wc))

    data.frame(
        model = model,
        algorithm = algorithm,
        dims_direct = direct$n.dim,
        dims_lab = lab_dims,
        tefi_direct = formatC(direct$TEFI, format = "f", digits = 3),
        tefi_lab = lab_tefi,
        memberships_equal = identical(unname(direct_wc), lab_wc)
    )
})

results <- do.call(rbind, results)
results$agree <- as.character(results$dims_direct) == results$dims_lab &
    results$tefi_direct == results$tefi_lab & results$memberships_equal

print(results)
utils::write.csv(results, file.path("validation", "ega_equivalence_results.csv"), row.names = FALSE)

if (!all(results$agree))
    stop("EGAnetLab and EGAnet disagree in at least one configuration.")

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
# Build the bundled example dataset.
# ES: Construir el conjunto de datos de ejemplo incluido.
#
# Source: the `wmt2` data set shipped with EGAnet (AGPL-3): responses of
# 1,185 people to the 18 dichotomous items (0 = incorrect, 1 = correct) of
# the Wiener Matrizen-Test 2 (WMT-2), plus six demographic variables. It is
# the data set used throughout EGAnet's own documentation, so EGAnetLab's
# results can be checked against the package's published examples. The
# demographic columns (sex, age group) are kept because later analyses
# (Measurement Invariance, Network Comparison) need a grouping variable.
#
# ES: Fuente: el conjunto `wmt2` incluido en EGAnet (AGPL-3): respuestas de
# 1.185 personas a los 18 ítems dicotómicos (0 = incorrecto, 1 = correcto)
# del Wiener Matrizen-Test 2 (WMT-2), más seis variables demográficas. Es el
# conjunto que usa la documentación de EGAnet, así que los resultados de
# EGAnetLab pueden contrastarse con sus ejemplos publicados. Se conservan las
# columnas demográficas (sexo, grupo de edad) porque los análisis posteriores
# (Invarianza de medida, Comparación de redes) necesitan una variable de
# agrupación.
#
# Nothing is recoded, imputed or removed: the CSV is the package data
# written out as-is, with factor labels trimmed of surrounding spaces.
#
# ES: No se recodifica, imputa ni elimina nada: el CSV es el dato del
# paquete escrito tal cual, con las etiquetas de factor sin espacios
# sobrantes.
# -----------------------------------------------------------------------------

utils::data("wmt2", package = "EGAnet", envir = environment())

out <- wmt2
for (v in names(out))
    if (is.factor(out[[v]]))
        out[[v]] <- factor(trimws(as.character(out[[v]])))

utils::write.csv(out, file.path("data", "eganetlab_wmt2.csv"), row.names = FALSE, na = "")

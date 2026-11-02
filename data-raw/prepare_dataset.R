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

# -----------------------------------------------------------------------------
# Intensive longitudinal example for Dynamic EGA: EGAnet's sim.dynEGA (100
# simulated persons, 50 time points each, 24 items, two groups), with a
# time column added and values rounded to 4 decimals.
# ES: Ejemplo longitudinal intensivo para el EGA dinámico: sim.dynEGA de
# EGAnet (100 personas simuladas, 50 momentos cada una, 24 ítems, dos
# grupos), con una columna de tiempo y valores redondeados a 4 decimales.
# -----------------------------------------------------------------------------
utils::data("sim.dynEGA", package = "EGAnet", envir = environment())

dyn <- sim.dynEGA
items <- grep("^V[0-9]+$", names(dyn), value = TRUE)
dyn[items] <- lapply(dyn[items], round, 4)
dyn$Time <- stats::ave(seq_len(nrow(dyn)), dyn$ID, FUN = seq_along)
dyn$Group <- factor(dyn$Group)
dyn <- dyn[c("ID", "Group", "Time", items)]

utils::write.csv(dyn, file.path("data", "eganetlab_dynamic_sim.csv"), row.names = FALSE, na = "")

# -----------------------------------------------------------------------------
# Big Five personality items (bfi).
# ES: Ítems de personalidad de los Cinco Grandes (bfi).
#
# Source: the `bfi` data set of the psychTools R package (GPL >= 2;
# Revelle, 2024): 2,800 people from the SAPA web project answering 25
# public-domain IPIP items on a 6-point scale (1 = very inaccurate,
# 6 = very accurate), five per Big Five domain, plus gender, education
# and age. It complements wmt2 with what wmt2 lacks: polytomous items,
# real missing data (364 people with at least one missing item), negatively
# worded items (A1, C4, C5, E1, E2, O2, O5) for riEGA, and a grouping
# variable for group comparisons. Item responses are kept as published;
# only gender and education get their labels.
#
# ES: Fuente: el conjunto `bfi` del paquete de R psychTools (GPL >= 2;
# Revelle, 2024): 2.800 personas del proyecto web SAPA que respondieron 25
# ítems de dominio público del IPIP en una escala de 6 puntos (1 = muy
# inexacto, 6 = muy exacto), cinco por dominio de los Cinco Grandes, más
# género, educación y edad. Complementa a wmt2 con lo que a este le falta:
# ítems politómicos, datos ausentes reales (364 personas con al menos un
# ítem sin responder), ítems redactados en negativo (A1, C4, C5, E1, E2, O2,
# O5) para riEGA y una variable de agrupación para comparar grupos. Las
# respuestas se conservan tal cual; solo género y educación reciben sus
# etiquetas.
# -----------------------------------------------------------------------------
utils::data("bfi", package = "psychTools", envir = environment())

big5 <- bfi
big5$gender <- factor(big5$gender, levels = 1:2, labels = c("Male", "Female"))
big5$education <- factor(big5$education, levels = 1:5,
                         labels = c("Some high school", "High school", "Some college",
                                    "College graduate", "Graduate degree"))

utils::write.csv(big5, file.path("data", "eganetlab_bfi.csv"), row.names = FALSE, na = "")

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
# Consistency between computation, tables and narrative: cautious wording,
# inadmissible solutions, numbering notes and the table of connections.
# ES: Consistencia entre cálculo, tablas y narrativa: redacción cauta,
# soluciones inadmisibles, notas de numeración y tabla de conexiones.
# -----------------------------------------------------------------------------

test_that("the table of network connections lists every edge, strongest first", {

    data <- edgeStructureData()
    plain <- EGAnetLab::ega(data = data, vars = names(data))
    expect_false(plain$edgeTable$visible)

    res <- EGAnetLab::ega(data = data, vars = names(data), showEdgeTable = TRUE)
    edges <- res$edgeTable$asDF
    expect_true(nrow(edges) > 0)
    expect_equal(order(-abs(edges$weight)), seq_len(nrow(edges)))
    expect_true(all(edges$item1 != edges$item2))
})

test_that("the edge list helper reads within and between dimensions", {

    m <- matrix(0, 3, 3, dimnames = list(c("a", "b", "c"), c("a", "b", "c")))
    m["a", "b"] <- m["b", "a"] <- 0.1
    m["a", "c"] <- m["c", "a"] <- -0.4
    out <- EGAnetLab:::.el_edge_list(m, c(a = 1, b = 1, c = 2))
    expect_equal(out$b, c("c", "b"))
    expect_equal(out$same, c(FALSE, TRUE))
})

test_that("riEGA does not read the random intercept as wording without negative items", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runRI = TRUE)
    text <- res$riInterpretation$content
    expect_false(grepl("could be separated from the content", text, fixed = TRUE))
    if (grepl("was estimated", text, fixed = TRUE))
        expect_match(text, "nothing in this analysis supports", fixed = TRUE)
    else
        expect_match(text, "cannot be interpreted", fixed = TRUE)
})

test_that("a solution with a negative variance is flagged as inadmissible", {

    data <- edgeStructureData()
    names(data) <- paste0("v", 1:12)
    model <- "F1 =~ v1 + v2 + v3 + v4\nv1 ~~ -0.2*v1"
    fit <- suppressWarnings(lavaan::cfa(model, data = data[, 1:4], std.lv = TRUE))
    problems <- EGAnetLab:::.el_cfa_problems(fit, c(v1 = "item1", v2 = "item2", v3 = "item3", v4 = "item4"))
    expect_equal(problems$neg_resid, "item1")
    expect_match(EGAnetLab:::.el_describe_problems(problems, "en"), "Heywood case) (item1)", fixed = TRUE)
    expect_match(EGAnetLab:::.el_describe_problems(problems, "es"), "caso Heywood", fixed = TRUE)
})

test_that("an admissible model reports no problems", {

    data <- edgeStructureData()
    fit <- EGAnetLab:::.el_cfa_fit(data, stats::setNames(rep(c("1", "2", "3"), each = 4), names(data)))
    expect_true(fit$ok)
    expect_length(fit$problems, 0)
})

test_that("the hierarchical CFA reads a small CFI loss cautiously", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE, runCFA = TRUE)
    text <- res$cfaHierInterpretation$content
    expect_false(grepl("the data support the hierarchy", text, fixed = TRUE))
})

test_that("UVA does not suggest comparing TEFI across different item sets", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runUVA = TRUE)
    expect_match(res$uvaInterpretation$content, "only comparable between structures of the same items", fixed = TRUE)
})

test_that("the CFA explains why its ordinal rule differs from EGA's", {

    data <- edgeStructureData()
    data[] <- lapply(data, function(x) as.integer(cut(x, 7)))
    res <- EGAnetLab::ega(data = data, vars = names(data), runCFA = TRUE)
    expect_match(res$cfaStatus$content, "Rhemtulla", fixed = TRUE)
})

test_that("the bifactor loadings table opens up the bifactor model", {

    data <- edgeStructureData()
    res <- EGAnetLab::ega(data = data, vars = names(data), runHier = TRUE, runCFA = TRUE)
    if (res$cfaBifactorLoadings$visible) {
        loads <- res$cfaBifactorLoadings$asDF
        expect_equal(nrow(loads), 12)
        expect_true(all(c("general", "spec", "resid") %in% names(loads)))
        expect_match(res$cfaBifactorInterpretation$content, "ECV", fixed = TRUE)
    }
    plain <- EGAnetLab::ega(data = data, vars = names(data), runCFA = TRUE)
    expect_false(plain$cfaBifactorLoadings$visible)
})

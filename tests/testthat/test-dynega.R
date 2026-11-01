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
# Dynamic EGA analysis (phase 7).
# ES: Análisis de EGA dinámico (fase 7).
# -----------------------------------------------------------------------------

dynData <- function(persons = 30) {
    utils::data("sim.dynEGA", package = "EGAnet", envir = environment())
    d <- sim.dynEGA[sim.dynEGA$ID %in% c(seq_len(persons / 2), 50 + seq_len(persons / 2)), ]
    d$Time <- stats::ave(seq_len(nrow(d)), d$ID, FUN = seq_along)
    d$Group <- factor(d$Group)
    d$ID <- paste0("P", d$ID)
    rownames(d) <- NULL
    d
}

items <- paste0("V", 1:24)

test_that("dynega waits for the items and the person ID", {

    res <- EGAnetLab::dynega(data = dynData(), vars = paste0("V", 1:24))
    expect_match(res$status$content, "long format", fixed = TRUE)
    expect_equal(res$summary$rowCount, 0)
})

test_that("dynega matches EGAnet::dynEGA at the population level", {

    d <- dynData()
    res <- EGAnetLab::dynega(data = d, vars = paste0("V", 1:24), id = "ID", time = "Time")

    fit <- EGAnet::dynEGA(d[c(items, "ID")], id = "ID", level = "population", model = "glasso",
                          algorithm = "walktrap", uni.method = "louvain", ncores = 1,
                          seed = 2026, verbose = FALSE)
    wc <- fit$dynEGA$population$wc
    membership <- res$membership$asDF
    expect_equal(nrow(membership), 24)
    expect_equal(as.numeric(membership$population), unname(as.numeric(wc)))
    expect_match(res$interpretation$content, "derivative analysed", fixed = TRUE)
    expect_match(res$interpretation$content, "Next step", fixed = TRUE)
})

test_that("rows are ordered by the time variable within each person", {

    d <- dynData()
    shuffled <- d[sample(nrow(d)), ]
    a <- EGAnetLab::dynega(data = d, vars = paste0("V", 1:24), id = "ID", time = "Time")$membership$asDF
    b <- EGAnetLab::dynega(data = shuffled, vars = paste0("V", 1:24), id = "ID", time = "Time")$membership$asDF
    expect_equal(a, b)
})

test_that("groups and individuals are summarized", {

    d <- dynData()
    res <- EGAnetLab::dynega(data = d, vars = paste0("V", 1:24), id = "ID", time = "Time", group = "Group",
                             levelIndividual = TRUE, showIndTable = TRUE)

    expect_equal(nrow(res$groupTable$asDF), 2)
    expect_equal(sum(res$groupTable$asDF$persons), 30)
    expect_true(all(c("g_1", "g_2") %in% names(res$membership$asDF)))
    freq <- res$indFreq$asDF
    expect_equal(sum(freq$count), 30)
    expect_equal(nrow(res$indTable$asDF), 30)
    ari <- res$indTable$asDF$ari
    expect_true(all(ari >= -1 & ari <= 1))
    expect_match(res$indInterpretation$content, "ARI", fixed = TRUE)

    # Each person is also compared with the structure of their own group.
    # ES: Cada persona también se compara con la estructura de su propio grupo.
    ind <- res$indTable$asDF
    expect_true(all(c("group", "ariGroup") %in% names(ind)))
    expect_true(all(ind$ariGroup >= -1 & ind$ariGroup <= 1, na.rm = TRUE))
    expect_equal(nrow(res$indAgree$asDF), 6)
    expect_match(res$indInterpretation$content, "own group", fixed = TRUE)
})

test_that("persons with too few time points are left out with a note", {

    d <- dynData()
    d <- d[!(d$ID == "P1" & d$Time > 4), ]
    res <- EGAnetLab::dynega(data = d, vars = paste0("V", 1:24), id = "ID", time = "Time")

    expect_match(res$notes$content, "P1", fixed = TRUE)
    expect_match(res$summary$asDF$value[1], "29", fixed = TRUE)
})

test_that("the adjusted Rand index matches its definition", {

    expect_equal(EGAnetLab:::.el_ari(c(1, 1, 2, 2), c(2, 2, 1, 1)), 1)
    expect_equal(EGAnetLab:::.el_ari(c(1, 1, 1, 2, 2, 3, 3, 3), c(1, 1, 2, 2, 2, 3, 3, 1)),
                 0.2380952, tolerance = 1e-6)
    expect_equal(EGAnetLab:::.el_ari(c(1, 1, 1, 1), c(1, 1, 2, 2)), 0)
})

test_that("dynega is reported in Spanish", {

    res <- EGAnetLab::dynega(data = dynData(), vars = paste0("V", 1:24), id = "ID", time = "Time",
                             reportLang = "es")
    expect_match(res$intro$content, "longitudinales intensivos", fixed = TRUE)
    expect_match(res$interpretation$content, "Siguiente paso", fixed = TRUE)
    expect_false(grepl("EGAnet(?!Lab)", res$interpretation$content, perl = TRUE))
})

test_that("memberships are matched to the items even without names", {

    fit <- list(dynEGA = list(population = list(wc = c(1, 1, 2), n.dim = 2, network = diag(3))))
    out <- EGAnetLab:::.el_dyn_summary(fit, c("a", "b", "c"), c(P1 = 10))
    expect_equal(unname(out$population$wc), c(1, 1, 2))
    expect_equal(names(out$population$wc), c("a", "b", "c"))
    expect_true(is.na(EGAnetLab:::.el_ari(c(NA, NA), c(NA, NA))))
})

test_that("items read as text factors are converted to numbers", {

    f <- factor(c("3", "1", "2", NA), levels = c("1", "2", "3"))
    expect_equal(EGAnetLab:::.el_dyn_numeric(f), c(3, 1, 2, NA))
    g <- factor(c("high", "low"), levels = c("low", "high"))
    expect_equal(EGAnetLab:::.el_dyn_numeric(g), c(2, 1))
    expect_equal(EGAnetLab:::.el_dyn_numeric(c(1L, 2L)), c(1, 2))
})

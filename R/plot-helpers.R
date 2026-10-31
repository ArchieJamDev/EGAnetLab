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
# .el_ega_plot()
#
# Input: network - the estimated network (EGA()$network); wc - the item
#   memberships (EGA()$wc); opts - the analysis options (self$options or a
#   plain list with the same names); palette - NULL (EGAnet's default) or a
#   character vector of colors from .el_plot_series_palette().
# Output: a ggplot object, or NULL when no edge survives the edgeMin filter.
#
# Draws the network with EGAnet's own plot method (GGally::ggnet2 + sna
# layouts) and forwards the user's customization as ggnet2 arguments, whose
# defaults in the options equal EGAnet's. Two options are applied by
# EGAnetLab itself because plot.EGA() has no argument for them: edgeMin
# (edges below it are dropped from the plotted copy of the network only) and
# the edge-weight labels (drawn at each edge's midpoint from the node
# coordinates ggnet2 stores in plot$data).
#
# ES: Dibuja la red con el método de gráfico de EGAnet (GGally::ggnet2 +
# disposiciones de sna) y reenvía la personalización del usuario como
# argumentos de ggnet2, cuyos valores por defecto en las opciones son los de
# EGAnet. Dos opciones las aplica EGAnetLab porque plot.EGA() no tiene
# argumento para ellas: edgeMin (las aristas menores se quitan solo de la
# copia de la red que se grafica) y las etiquetas de peso (dibujadas en el
# punto medio de cada arista a partir de las coordenadas de nodos que ggnet2
# guarda en plot$data).
# -----------------------------------------------------------------------------
.el_ega_plot <- function(network, wc, opts, palette = NULL) {

    opt <- function(name, default) {
        value <- opts[[name]]
        if (is.null(value) || length(value) == 0 || (is.atomic(value) && is.na(value[1])))
            default else value
    }

    network <- as.matrix(network)
    edge_min <- suppressWarnings(as.numeric(opt("edgeMin", 0)))
    if (!is.na(edge_min) && edge_min > 0)
        network[abs(network) < edge_min] <- 0

    if (sum(network != 0) == 0)
        return(NULL)

    shapes <- c(circle = 19, square = 15, triangle = 17, diamond = 18)
    colors <- c(blue = "#0072B2", orange = "#D55E00")
    color_of <- function(x) if (x %in% names(colors)) colors[[x]] else x

    args <- list(
        x = structure(list(network = network, wc = wc), class = "EGA"),
        layout = opt("layout", "qgraph"),
        node.size = as.numeric(opt("nodeSize", 12)),
        node.shape = shapes[[opt("nodeShape", "circle")]],
        node.alpha = as.numeric(opt("nodeAlpha", 0.5)),
        label.size = as.numeric(opt("labelSize", 5)),
        label.color = opt("labelColor", "black"),
        edge.size = as.numeric(opt("edgeSize", 8)),
        edge.color = c(color_of(opt("edgePosColor", "darkgreen")),
                       color_of(opt("edgeNegColor", "red"))),
        edge.lty = c("solid", opt("edgeNegLty", "solid"))
    )
    if (!is.null(palette))
        args$color.palette <- palette

    title <- trimws(as.character(opt("plotTitle", "")))
    if (nzchar(title))
        args$title <- title

    legend_title <- trimws(as.character(opt("legendTitle", "")))
    if (nzchar(legend_title))
        args$legend.title <- legend_title

    # plot.EGA() is an S3 method registered by EGAnet; make sure the
    # namespace is loaded before dispatching on class "EGA".
    # ES: plot.EGA() es un método S3 que registra EGAnet; se asegura que el
    # espacio de nombres esté cargado antes de despachar por la clase "EGA".
    requireNamespace("EGAnet", quietly = TRUE)
    plot <- do.call(graphics::plot, args)

    if (isTRUE(opt("showEdgeLabels", FALSE)))
        plot <- .el_add_edge_labels(plot, network,
                                    size = as.numeric(opt("edgeLabelSize", 3)),
                                    digits = as.integer(opt("edgeLabelDigits", 2)))

    if (isTRUE(opt("showLegend", TRUE))) {
        plot <- plot + ggplot2::theme(legend.position = opt("legendPosition", "right"))
    } else {
        plot <- plot + ggplot2::theme(legend.position = "none")
    }

    plot
}

# -----------------------------------------------------------------------------
# .el_add_edge_labels()
#
# Input: plot - a ggnet2-based ggplot whose $data holds one row per node
#   with columns label, x and y; network - the plotted weight matrix (with
#   dimnames); size, digits - label size and decimals.
# Output: the plot with one label per non-zero edge at the edge's midpoint.
#
# Nodes are matched by name, so the row order EGAnet uses internally (it
# sorts nodes by community) does not matter.
# ES: Los nodos se emparejan por nombre, así que el orden interno de filas
# que usa EGAnet (ordena los nodos por comunidad) no importa.
# -----------------------------------------------------------------------------
.el_add_edge_labels <- function(plot, network, size = 3, digits = 2) {

    nodes <- plot$data
    if (is.null(nodes) || !all(c("label", "x", "y") %in% names(nodes)))
        return(plot)

    names <- colnames(network)
    if (is.null(names))
        return(plot)

    upper <- which(upper.tri(network) & network != 0, arr.ind = TRUE)
    if (nrow(upper) == 0)
        return(plot)

    from <- match(names[upper[, 1]], nodes$label)
    to <- match(names[upper[, 2]], nodes$label)
    keep <- !is.na(from) & !is.na(to)
    if (!any(keep))
        return(plot)

    edges <- data.frame(
        x = (nodes$x[from[keep]] + nodes$x[to[keep]]) / 2,
        y = (nodes$y[from[keep]] + nodes$y[to[keep]]) / 2,
        text = formatC(network[upper[keep, , drop = FALSE]], format = "f", digits = digits)
    )

    plot + ggplot2::geom_label(
        data = edges,
        mapping = ggplot2::aes(x = x, y = y, label = text),
        inherit.aes = FALSE,
        size = size,
        fill = "white",
        label.size = 0,
        label.padding = ggplot2::unit(0.08, "lines")
    )
}

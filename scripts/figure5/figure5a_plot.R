#!/usr/bin/env Rscript

library(RColorBrewer)
library(igraph)
library(ggraph)
library(tidygraph)
library(ggpubr)

get_edgecolor <- function(x) {
  sapply(x, function(y) if(y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if(y > 0) "solid" else "dashed")
}


plot_network <- function(network_file, combined_layout, interaction_threshold, title, edgecolor) {
  graph_raw <- as_tbl_graph(read_graph(network_file, format="gml"))
  graph <- graph_raw %>%
    activate(edges) %>%
    filter(abs(weight) > interaction_threshold) %>%
    mutate(color=get_edgecolor(weight)) %>%
    activate(nodes) %>%
    mutate(isolated=node_is_isolated()) %>%
    filter(isolated==FALSE)
  temp_layout <- create_layout(graph=graph, layout="linear", circular=TRUE)
  match_inds <- match(temp_layout$name, combined_layout$name)
  graph_layout <- data.frame(temp_layout)
  graph_layout$x <- combined_layout[match_inds,]$x
  graph_layout$y <- combined_layout[match_inds,]$y
  graph_plot <- ggraph(graph=graph, layout="manual", node.positions=graph_layout, circular=TRUE) +
    geom_edge_arc(aes(color=color, edge_linetype=color, edge_alpha=color)) +
    # geom_node_point(aes(color=factor(colorkey))) +
    geom_node_point() +
    scale_edge_color_manual(values = c(negative="#d95f02", positive="#1b9e77")) +
    scale_edge_linetype_manual(values = c(negative="dashed", positive="solid")) +
    scale_edge_alpha_manual(values = c(negative=0.6, positive=0.3)) +
    labs(title=title) +
    coord_fixed() +
    theme_bw() +
    theme(
        # legend.position="none",
        plot.title=element_text(hjust=0.5),
        axis.title=element_blank(),
        axis.text=element_blank(),
        axis.line=element_blank(),
        axis.ticks=element_blank(),
        panel.background=element_blank(),
        panel.border=element_blank(),
        panel.grid=element_blank()
    )
}

combined_graph <- read_graph("combined.gml", format="gml")
combined_layout <- create_layout(graph=combined_graph, layout="linear", circular=TRUE)

palette <- brewer.pal(n=6, name="Dark2")
magma_plot <- plot_network("magma.gml", combined_layout, 0.01, "magma", palette[[1]])
mldm_plot <- plot_network("mldm.gml", combined_layout, 0.01, "mldm", palette[[2]])
spieceasi_plot <- plot_network("spieceasi.gml", combined_layout, 0.01, "spieceasi", palette[[3]])
sparcc_plot <- plot_network("sparcc.gml", combined_layout, 0.3, "sparcc", palette[[4]])
spearman_plot <- plot_network("spearman.gml", combined_layout, 0.3, "spearman",  palette[[5]])
pearson_plot <- plot_network("pearson.gml", combined_layout, 0.3, "pearson", palette[[6]])

combined_plot <- ggarrange(magma_plot, mldm_plot, spieceasi_plot, sparcc_plot, spearman_plot, pearson_plot, ncol=3, nrow=2, common.legend=TRUE, legend="bottom")
annotate_figure(combined_plot, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)

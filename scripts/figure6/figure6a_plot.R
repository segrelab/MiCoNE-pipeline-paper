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


plot_network <- function(network_file, combined_layout, interaction_threshold, title, palette, ind) {
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
    geom_edge_arc(aes(color=factor(layer), edge_linetype=factor(color), edge_alpha=factor(layer))) +
    # geom_node_point(aes(color=factor(colorkey))) +
    geom_node_point() +
    #scale_edge_color_manual(values = c(background=palette[[1]], foreground=palette[[ind]], common="black")) +
    scale_edge_color_manual(values = c(foreground="#7570B3", background="#c1c1c1", common="black")) +
    scale_edge_linetype_manual(values = c(negative="dashed", positive="solid")) +
    scale_edge_alpha_manual(values = c(foreground=0.4, background=0.4, common=0.7)) +
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
        panel.grid=element_blank(),
    )
}

combined_graph <- read_graph("combined.gml", format="gml")
combined_layout <- create_layout(graph=combined_graph, layout="linear", circular=TRUE)

palette <- brewer.pal(n=6, name="Pastel1")
default_plot <- plot_network("default.gml", combined_layout, 0.3, "default", palette, 1)
database_plot <- plot_network("gg.gml", combined_layout, 0.3, "TA=Greengenes", palette, 2)
clustering_plot <- plot_network("open_ref.gml", combined_layout, 0.3, "DC=open_ref", palette, 3)
otu_filtering_plot <- plot_network("otu_filtering.gml", combined_layout, 0.3, "OP=off", palette, 4)
network_inference_plot <- plot_network("spieceasi_direct.gml", combined_layout, 0.3, "NI=spieceasi",  palette, 5)

combined_plot <- ggarrange(default_plot, database_plot, clustering_plot, otu_filtering_plot, network_inference_plot, ncol=3, nrow=2, common.legend=TRUE, legend="bottom")
final_plot <- annotate_figure(combined_plot, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(final_plot, file="figure6a.pdf")


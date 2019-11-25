#!/usr/bin/env Rscript

library(RColorBrewer)
library(igraph)
library(ggraph)
library(tidygraph)
library(ggpubr)

# library(dplyr)
# library(pracma)

get_edgecolor <- function(x) {
  sapply(x, function(y) if(y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if(y > 0) "solid" else "dashed")
}


plot_network <- function(network_file, combined_layout, interaction_threshold, pvalue_threshold, title, edgecolor) {
  graph_raw <- as_tbl_graph(read_graph(network_file, format="gml"))
  graph <- graph_raw %>%
    activate(edges) %>%
    filter(pvalue < pvalue_threshold) %>%
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
  lo <- data.matrix(graph_layout[, c("x", "y")])
  angle <- as_tibble(cart2pol(lo)) %>% mutate(degree=phi*180/phi)
  graph_plot <- ggraph(graph=graph, layout="manual", node.positions=graph_layout, circular=TRUE) +
    geom_edge_arc(aes(color=color, edge_linetype=color, edge_alpha=color)) +
    # geom_node_point(aes(color=factor(colorkey))) +
    geom_node_point() +
    geom_node_text(aes(label = name), size=2, repel=TRUE, angle=0) +
      # geom_node_text(aes(label = name), 
      #                size = 2, 
      #                hjust = ifelse(lo[,1] > 0, -0.2, 1.2),
      #                angle = case_when(lo[,2] > 0 & lo[,1] > 0 ~ angle$degree, 
      #                                  lo[,2] < 0 & lo[,1] > 0 ~ angle$degree,
      #                                  lo[,1] == 1 ~angle$degree,
      #                                  TRUE ~ angle$degree - 180)) +
    scale_edge_color_manual(values = c(negative="#d95f02", positive="#1b9e77")) +
    scale_edge_linetype_manual(values = c(negative="solid", positive="solid")) +
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
combined_graph_hp <- read_graph("combined_hp.gml", format="gml")
combined_layout_hp <- create_layout(graph=combined_graph_hp, layout="linear", circular=TRUE)
combined_graph_stool <- read_graph("combined_stool.gml", format="gml")
combined_layout_stool <- create_layout(graph=combined_graph_stool, layout="linear", circular=TRUE)

palette <- brewer.pal(n=6, name="Dark2")
hp_plot <- plot_network("HP_genus_network.gml", combined_layout_hp, 0.3, 0.05, "Hard Palate", palette[[1]])
stool_plot <- plot_network("Stool_genus_network.gml", combined_layout_stool, 0.3, 0.75, "Stool", palette[[2]])

combined_plot <- ggarrange(hp_plot, stool_plot, ncol=2, nrow=1, common.legend=TRUE, labels=c("A", "B"), legend="bottom")
# final_plot <- annotate_figure(combined_plot, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(combined_plot, file="figure7.pdf")

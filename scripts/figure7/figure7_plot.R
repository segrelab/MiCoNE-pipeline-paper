#!/usr/bin/env Rscript

library(RColorBrewer)
library(dplyr)
library(pracma)
library(igraph)
library(ggraph)
library(tidygraph)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure7/output/moving_pictures/"
    dataset1 <- "moving_pictures"
    dataset2 <- "moving_pictures"
    output_folder <- "../../figures/"
} else if (length(args) == 4) {
    data_folder <- args[1]
    dataset1 <- args[2]
    dataset2 <- args[3]
    output_folder <- args[4]
} else {
    stop("Required number of arguments must equal 4")
}
data_folder1 <- paste0(data_folder, dataset1, "/")
data_folder2 <- paste0(data_folder, dataset2, "/")
combined_gml <- paste0(data_folder1, "combined.gml")
default_gml <- paste0(data_folder1, "default.gml")
clustering_gml <- paste0(data_folder1, "DC_closed_reference(gg_97).gml")
chimera_checking_gml <- paste0(data_folder1, "CC_uchime.gml")
database_gml <- paste0(data_folder1, "TA_blast(ncbi).gml")
otu_filtering_gml <- paste0(data_folder1, "OP_normalize_filter(off).gml")
network_inference_gml <- paste0(data_folder1, "NI_sparcc.gml")
l1_distance_csv <- paste0(data_folder1, "l1_distance_to_ref.csv")
combined_gml_2 <- paste0(data_folder2, "combined.gml")
default_gml_2 <- paste0(data_folder2, "default.gml")
output_file <- paste0(output_folder, "figure7.pdf")
output_file_a <- paste0(output_folder, "figure7a.pdf")
output_file_b <- paste0(output_folder, "figure7b.pdf")

#########################################
# a
#########################################
get_edgecolor <- function(x) {
    sapply(x, function(y) if (y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if (y > 0) "solid" else "dashed")
}


plot_network <- function(network_file, combined_layout, interaction_threshold, title, palette, ind) {
    graph_raw <- as_tbl_graph(read_graph(network_file, format = "gml"))
    if (title == "default") {
        foreground <- "#c1c1c1"
    } else {
        foreground <- "#7570B3"
    }
    graph <- graph_raw %>%
        activate(edges) %>%
        filter(abs(weight) > interaction_threshold) %>%
        mutate(color = get_edgecolor(weight)) %>%
        activate(nodes) %>%
        mutate(isolated = node_is_isolated()) %>%
        filter(isolated == FALSE)
    temp_layout <- create_layout(graph = graph, layout = "linear", circular = TRUE)
    match_inds <- match(temp_layout$name, combined_layout$name)
    graph_layout <- data.frame(temp_layout)
    graph_layout$x <- combined_layout[match_inds, ]$x
    graph_layout$y <- combined_layout[match_inds, ]$y
    graph_plot <- ggraph(graph = graph, layout = "manual", x = graph_layout$x, y = graph_layout$y, circular = TRUE) +
        geom_edge_arc(aes(color = factor(layer), edge_linetype = factor(color), edge_alpha = factor(layer))) +
        # geom_node_point(aes(color=factor(colorkey))) +
        geom_node_point() +
        # scale_edge_color_manual(values = c(background=palette[[1]], foreground=palette[[ind]], common="black")) +
        scale_edge_color_manual(values = c(foreground = foreground, background = "#c1c1c1", common = "black")) +
        scale_edge_linetype_manual(values = c(negative = "dashed", positive = "solid")) +
        scale_edge_alpha_manual(values = c(foreground = 0.4, background = 0.4, common = 0.7)) +
        labs(title = title) +
        coord_fixed() +
        theme_bw() +
        theme(
            legend.position = "none",
            plot.title = element_text(hjust = 0.5),
            axis.title = element_blank(),
            axis.text = element_blank(),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            panel.background = element_blank(),
            panel.border = element_blank(),
            panel.grid = element_blank(),
        )
}

combined_graph <- read_graph(combined_gml, format = "gml")
combined_layout <- create_layout(graph = combined_graph, layout = "linear", circular = TRUE)

palette <- brewer.pal(n = 6, name = "Pastel1")
default_plot <- plot_network(default_gml, combined_layout, 0.3, "default", palette, 1)
clustering_plot <- plot_network(clustering_gml, combined_layout, 0.3, "DC=closed_reference(gg_97)", palette, 3)
chimera_checking_plot <- plot_network(chimera_checking_gml, combined_layout, 0.3, "CC=uchime", palette, 4)
database_plot <- plot_network(database_gml, combined_layout, 0.3, "TA=blast(NCBI)", palette, 2)
otu_filtering_plot <- plot_network(otu_filtering_gml, combined_layout, 0.3, "OP=off", palette, 4)
network_inference_plot <- plot_network(network_inference_gml, combined_layout, 0.3, "NI=SparCC", palette, 5)

legend_grob <- get_legend(database_plot)

combined_plot <- ggarrange(
    default_plot, database_plot, chimera_checking_plot, clustering_plot, otu_filtering_plot, network_inference_plot,
    ncol = 3, nrow = 2, common.legend = FALSE, legend = "right"
)
a_plot <- annotate_figure(combined_plot, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(output_file_a, width = 11, height = 5.5)



#########################################
# b
#########################################
l1_data <- read.csv(l1_distance_csv, header = TRUE, sep = ",")

box_plot <- ggboxplot(
    l1_data,
    x = "step", y = "l1_distance", label = "process", repel = TRUE, order = c("DC", "CC", "TA", "NI"), color = "step", add = "jitter", palette = "Set2", ylab = "L1 distance", xlab = "Pipeline step"
)

b_plot <- annotate_figure(box_plot, fig.lab = "B", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(output_file_b, width = 11, height = 5)


#########################################
# c
#########################################
plot_network_c <- function(network_file, combined_layout, interaction_threshold, pvalue_threshold, title, edgecolor) {
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
  graph_plot <- ggraph(graph = graph, layout = "manual", x = graph_layout$x, y = graph_layout$y, circular = TRUE) +
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

combined_graph_1 <- read_graph(combined_gml, format = "gml")
combined_layout_1 <- create_layout(graph = combined_graph_1, layout = "linear", circular = TRUE)
combined_graph_2 <- read_graph(combined_gml_2, format = "gml")
combined_layout_2 <- create_layout(graph = combined_graph_2, layout = "linear", circular = TRUE)

palette <- brewer.pal(n = 6, name = "Pastel1")
default_plot_1 <- plot_network_c(default_gml, combined_layout_1, 0.3, 0.05, "Control", palette[[1]])
default_plot_2 <- plot_network_c(default_gml_2, combined_layout_2, 0.3, 0.05, "Autism", palette[[2]])
c_plot <- ggarrange(default_plot_1, default_plot_2, ncol=2, nrow=1, common.legend=TRUE, legend="bottom")
annotate_figure(c_plot, fig.lab="C", fig.lab.pos="top.left", fig.lab.size=20)


final_plot <- ggarrange(a_plot, b_plot, c_plot, ncol = 1)
ggsave(output_file, final_plot, width = 11, height = 12)


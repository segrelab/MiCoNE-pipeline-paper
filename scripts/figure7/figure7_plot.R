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
combined_gml_2 <- paste0(data_folder2, "combined.gml")
default_gml_2 <- paste0(data_folder2, "default.gml")
output_file <- paste0(output_folder, "figure7.pdf")

get_edgecolor <- function(x) {
    sapply(x, function(y) if (y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if (y > 0) "solid" else "dashed")
}

plot_network <- function(graph_raw, interaction_threshold) {
    graph <- graph_raw %>%
        activate(edges) %>%
        filter(abs(weight) > interaction_threshold) %>%
        mutate(interaction = get_edgecolor(weight)) %>%
        mutate(weight = abs(weight)) %>%
        activate(nodes) %>%
        filter(!node_is_isolated())
    graph_plot <- ggraph(graph = graph, layout = "nicely") +
        geom_edge_link(aes(color = interaction)) +
        geom_node_point() +
        facet_edges(~dataset, drop = FALSE) +
        geom_node_text(aes(label = name), size = 2, repel = TRUE, angle = 0) +
        scale_edge_color_manual(values = c(negative = "#d95f02", positive = "#1b9e77")) +
        coord_fixed() +
        theme_bw() +
        theme(
            legend.position = "right",
            plot.title = element_text(hjust = 0.5),
            axis.title = element_blank(),
            axis.text = element_blank(),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            text = element_text(size = 15),
        )
}

default_graph_1 <- as_tbl_graph(read_graph(default_gml, format = "gml"))
default_graph_2 <- as_tbl_graph(read_graph(default_gml_2, format = "gml"))
combined_graph_z <- default_graph_1 %>% graph_join(default_graph_2, by = c("name", "label", "taxlevel"))

final_plot <- plot_network(combined_graph_z, 0.1)

ggsave(output_file, width = 11, height = 5)

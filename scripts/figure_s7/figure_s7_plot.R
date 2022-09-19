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
clustering_gml <- paste0(data_folder1, "DC_de_novo.gml")
chimera_checking_gml <- paste0(data_folder1, "CC_uchime.gml")
database_gml <- paste0(data_folder1, "TA_blast(ncbi).gml")
otu_filtering_gml <- paste0(data_folder1, "OP_normalize_filter(off).gml")
# network_inference_gml <- paste0(data_folder1, "NI_sparcc.gml")
distance_csv <- paste0(data_folder1, "distance_to_ref.csv")
combined_gml_2 <- paste0(data_folder2, "combined.gml")
default_gml_2 <- paste0(data_folder2, "default.gml")
output_file <- paste0(output_folder, "figure_s7.pdf")

#########################################
# a
#########################################
get_edgecolor <- function(x) {
    sapply(x, function(y) if (y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if (y > 0) "solid" else "dashed")
}

plot_facet_network <- function(network_file, interaction_threshold) {
    graph_raw <- as_tbl_graph(read_graph(network_file, format = "gml"))
    graph <- graph_raw %>%
        activate(edges) %>%
        filter(abs(weight) > interaction_threshold) %>%
        mutate(interaction = get_edgecolor(weight)) %>%
        mutate(edge_step = factor(title, levels = c("default", "DC=de_novo", "CC=uchime", "TA=blast(ncbi)", "OP=normalize_filter(off)"))) %>%
        mutate(weight = abs(weight)) %>%
        activate(nodes) %>%
        filter(!node_is_isolated()) %>%
        mutate(node_step = factor(title, levels = c("default", "DC=de_novo", "CC=uchime", "TA=blast(ncbi)", "OP=normalize_filter(off)")))
    graph_plot <- ggraph(graph = graph, layout = "nicely") +
        geom_edge_link(aes(color = interaction)) +
        geom_node_point() +
        facet_edges(~edge_step, drop = FALSE) +
        scale_edge_color_manual(values = c(negative = "#d95f02", positive = "#1b9e77")) +
        # coord_fixed() +
        theme_bw() +
        labs(x = "", y = "") +
        theme(
            legend.position = "bottom",
            axis.text = element_blank(),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            text = element_text(size = 15),
        )
}

a_plot <- plot_facet_network(combined_gml, 0.1)

#########################################
# b
#########################################
distance_data <- read.csv(distance_csv, header = TRUE, sep = ",")
distance_data[distance_data == "open_reference(gg_97)"] <- "OR"
distance_data[distance_data == "closed_reference(gg_97)"] <- "CR"
distance_data[distance_data == "de_novo"] <- "DN"
distance_data[distance_data == "dada2"] <- "D2"
distance_data[distance_data == "deblur"] <- "DB"
distance_data[distance_data == "naive_bayes(silva_138_99)"] <- "NaiveBayes(SILVA)"
distance_data[distance_data == "blast(ncbi)"] <- "BLAST(NCBI)"
distance_data[distance_data == "normalize_filter(on)"] <- "Filter(on)"
distance_data[distance_data == "normalize_filter(off)"] <- "Filter(off)"
names(distance_data)[names(distance_data) == "edge_fraction"] <- "Common edges"
names(distance_data)[names(distance_data) == "node_fraction"] <- "Common nodes"

b_plot <- ggdotplot(
    distance_data,
    x = "step", y = c("Common nodes", "Common edges"), combine = TRUE, label = "process", repel = TRUE, order = c("DC", "CC", "TA", "OP"), fill = "step", add = "jitter", palette = "Set2", ylab = "Fraction", xlab = "Pipeline step"
) +
    ylim(0.0, 1.0) +
    theme(
        text = element_text(size = 18),
        legend.position = "none",
    )


final_plot <- ggarrange(a_plot, b_plot, ncol = 1, labels = c("A", "B"))
ggsave(output_file, width = 11, height = 12)

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
l1_distance_csv <- paste0(data_folder1, "l1_distance_to_ref.csv")
edit_distance_csv <- paste0(data_folder1, "edit_distance_to_ref.csv")
combined_gml_2 <- paste0(data_folder2, "combined.gml")
default_gml_2 <- paste0(data_folder2, "default.gml")
output_file <- paste0(output_folder, "figure7.pdf")
output_file_a <- paste0(output_folder, "figure7a.pdf")
output_file_b <- paste0(output_folder, "figure7b.pdf")
output_file_c <- paste0(output_folder, "figure7c.pdf")

#########################################
# a
#########################################
get_edgecolor <- function(x) {
    sapply(x, function(y) if (y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if (y > 0) "solid" else "dashed")
}

get_layer <- function(x) {
    sapply(x, function(y) if (y == "default") "#c1c1c1" else "#7570B3")
}


plot_facet_network <- function(network_file, interaction_threshold) {
    graph_raw <- as_tbl_graph(read_graph(network_file, format = "gml"))
    graph <- graph_raw %>%
        activate(edges) %>%
        filter(abs(weight) > interaction_threshold) %>%
        mutate(color = get_edgecolor(weight)) %>%
        mutate(layer = get_layer(title)) %>%
        mutate(step = factor(title, levels = c("default", "DC=de_novo", "CC=uchime", "TA=blast(ncbi)", "OP=normalize_filter(off)"))) %>%
        mutate(weight = abs(weight)) %>%
        activate(nodes) %>%
        filter(!node_is_isolated())
    graph_plot <- ggraph(graph = graph, layout = "nicely") +
        geom_edge_link(aes(color = color)) +
        geom_node_point() +
        facet_edges(~step) +
        scale_edge_color_manual(values = c(negative = "#d95f02", positive = "#1b9e77")) +
        # coord_fixed() +
        theme_bw() +
        theme(
            legend.position = "bottom",
            plot.title = element_text(hjust = 0.5),
            axis.title = element_blank(),
            axis.text = element_blank(),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            text = element_text(size = 15),
        )
}

a_plot <- plot_facet_network(combined_gml, 0.1)

ggsave(output_file_a, width = 11, height = 5.5)


#########################################
# b
#########################################
edit_data <- read.csv(edit_distance_csv, header = TRUE, sep = ",")
edit_data[edit_data == "de_novo"] <- "OR"
edit_data[edit_data == "closed_reference(gg_97)"] <- "CR"
edit_data[edit_data == "de_novo"] <- "DN"
edit_data[edit_data == "dada2"] <- "D2"
edit_data[edit_data == "deblur"] <- "DB"
edit_data[edit_data == "naive_bayes(silva_138_99)"] <- "NaiveBayes(SILVA)"
edit_data[edit_data == "blast(ncbi)"] <- "BLAST(NCBI)"
edit_data[edit_data == "normalize_filter(on)"] <- "Filter(on)"
edit_data[edit_data == "normalize_filter(off)"] <- "Filter(off)"

box_plot <- ggdotplot(
    edit_data,
    x = "step", y = "edit_distance", label = "process", repel = TRUE, order = c("DC", "CC", "TA", "OP"), fill = "step", add = "jitter", palette = "Set2", ylab = "edit distance", xlab = "Pipeline step"
) +
    theme(
        text = element_text(size = 18),
    )

b_plot <- annotate_figure(box_plot, fig.lab = "B", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(output_file_b, width = 11, height = 5)


#########################################
# c
#########################################
plot_network_c <- function(network_file, combined_layout, interaction_threshold, title, edgecolor) {
    graph_raw <- as_tbl_graph(read_graph(network_file, format = "gml"))
    graph <- graph_raw %>%
        activate(edges) %>%
        filter(abs(weight) > interaction_threshold) %>%
        mutate(color = get_edgecolor(weight)) %>%
        mutate(weight = abs(weight)) %>%
        activate(nodes) %>%
        filter(!node_is_isolated())
    temp_layout <- create_layout(graph = graph, layout = "nicely")
    match_inds <- match(temp_layout$name, combined_layout$name)
    graph_layout <- data.frame(temp_layout)
    graph_layout$x <- combined_layout[match_inds, ]$x
    graph_layout$y <- combined_layout[match_inds, ]$y
    # lo <- data.matrix(graph_layout[, c("x", "y")])
    # angle <- as_tibble(cart2pol(lo)) %>% mutate(degree=phi*180/phi)
    graph_plot <- ggraph(graph = graph, layout = "manual", x = graph_layout$x, y = graph_layout$y) +
        geom_edge_link(aes(color = color)) +
        # geom_node_point(aes(color=factor(colorkey))) +
        geom_node_point() +
        geom_node_text(aes(label = name), size = 2, repel = TRUE, angle = 0) +
        # geom_node_text(aes(label = name),
        #                size = 2,
        #                hjust = ifelse(lo[,1] > 0, -0.2, 1.2),
        #                angle = case_when(lo[,2] > 0 & lo[,1] > 0 ~ angle$degree,
        #                                  lo[,2] < 0 & lo[,1] > 0 ~ angle$degree,
        #                                  lo[,1] == 1 ~angle$degree,
        #                                  TRUE ~ angle$degree - 180)) +
        scale_edge_color_manual(values = c(negative = "#d95f02", positive = "#1b9e77")) +
        labs(title = title) +
        coord_fixed() +
        theme_bw() +
        theme(
            # legend.position="none",
            plot.title = element_text(hjust = 0.5),
            axis.title = element_blank(),
            axis.text = element_blank(),
            axis.line = element_blank(),
            axis.ticks = element_blank(),
            panel.background = element_blank(),
            panel.border = element_blank(),
            panel.grid = element_blank(),
            text = element_text(size = 15),
        )
}

combined_graph_1 <- read_graph(default_gml, format = "gml")
# combined_layout_1 <- create_layout(graph = combined_graph_1, layout = "linear", circular = TRUE)
combined_graph_2 <- read_graph(default_gml_2, format = "gml")
# combined_layout_2 <- create_layout(graph = combined_graph_2, layout = "linear", circular = TRUE)
combined_graph_z <- union(combined_graph_1, combined_graph_2)
combined_layout_z <- create_layout(graph = combined_graph_z, layout = "nicely")

palette <- brewer.pal(n = 6, name = "Pastel1")
default_plot_1 <- plot_network_c(default_gml, combined_layout_z, 0.1, "Control", palette[[1]])
default_plot_2 <- plot_network_c(default_gml_2, combined_layout_z, 0.1, "Autism", palette[[2]])
c_plot <- ggarrange(default_plot_1, default_plot_2, ncol = 2, nrow = 1, common.legend = TRUE, legend = "bottom")

ggsave(output_file_c, width = 11, height = 5)

c_plot <- annotate_figure(c_plot, fig.lab = "C", fig.lab.pos = "top.left", fig.lab.size = 20)


final_plot <- ggarrange(a_plot, b_plot, c_plot, ncol = 1)
ggsave(output_file, width = 11, height = 14)

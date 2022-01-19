#!/usr/bin/env Rscript

library(RColorBrewer)
library(igraph)
library(ggraph)
library(tidygraph)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure6/output/moving_pictures/"
    output_folder <- "../../figures/"
} else if (length(args) == 2) {
    data_folder <- args[1]
    output_folder <- args[2]
} else {
    stop("Required number of arguments must equal 2")
}
combined_gml <- paste0(data_folder, "combined.gml")
default_gml <- paste0(data_folder, "default.gml")
clustering_gml <- paste0(data_folder, "DC_closed_reference(gg_97).gml")
chimera_checking_gml <- paste0(data_folder, "CC_uchime.gml")
database_gml <- paste0(data_folder, "TA_blast(ncbi).gml")
otu_filtering_gml <- paste0(data_folder, "OP_normalize_filter(off).gml")
network_inference_gml <- paste0(data_folder, "NI_sparcc.gml")
l1_distance_csv <- paste0(data_folder, "l1_distance_to_ref.csv")
output_file <- paste0(output_folder, "figure6.pdf")
output_file_a <- paste0(output_folder, "figure6a.pdf")
output_file_b <- paste0(output_folder, "figure6b.pdf")

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
    x = "step", y = "l1_distance", add = "jitter", label = "process", repel = TRUE, order = c("DC", "CC", "TA", "NI"), color = "step", add = "jitter", palette = "Set2", ylab = "L1 distance", xlab = "Pipeline step"
)

b_plot <- annotate_figure(box_plot, fig.lab = "B", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(output_file_b, width = 11, height = 5)


# TODO: Figure 6C
#########################################
# c
#########################################


final_plot <- ggarrange(a_plot, b_plot, ncol = 1)
ggsave(output_file, final_plot, width = 11, height = 12)


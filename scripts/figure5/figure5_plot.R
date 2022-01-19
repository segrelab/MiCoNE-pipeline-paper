#!/usr/bin/env Rscript

library(RColorBrewer)
library(igraph)
library(ggraph)
library(tidygraph)
library(UpSetR)
library(grid)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure5/output/moving_pictures/"
    output_folder <- "../../figures/"
} else if (length(args) == 2) {
    data_folder <- args[1]
    output_folder <- args[2]
} else {
    stop("Required number of arguments must equal 2")
}
combined_gml <- paste0(data_folder, "combined.gml")
sparcc_gml <- paste0(data_folder, "sparcc.gml")
propr_gml <- paste0(data_folder, "propr.gml")
pearson_gml <- paste0(data_folder, "pearson.gml")
spearman_gml <- paste0(data_folder, "spearman.gml")
spieceasi_gml <- paste0(data_folder, "spieceasi.gml")
mldm_gml <- paste0(data_folder, "mldm.gml")
flashweave_gml <- paste0(data_folder, "flashweave.gml")
cozine_gml <- paste0(data_folder, "cozine.gml")
harmonies_gml <- paste0(data_folder, "harmonies.gml")
spring_gml <- paste0(data_folder, "spring.gml")
nmatrix_csv <- paste0(data_folder, "nmatrix.csv")
ematrix_csv <- paste0(data_folder, "ematrix.csv")
output_file <- paste0(output_folder, "figure5.pdf")
output_file_a <- paste0(output_folder, "figure5a.pdf")
output_file_bc <- paste0(output_folder, "figure5bc.pdf")


#########################################
# a
#########################################

get_edgecolor <- function(x) {
    sapply(x, function(y) if (y > 0) "positive" else "negative")
}

get_edgestyle <- function(x) {
    sapply(x, function(y) if (y > 0) "solid" else "dashed")
}

plot_network <- function(network_file, combined_layout, interaction_threshold, title, edgecolor) {
    graph_raw <- as_tbl_graph(read_graph(network_file, format = "gml"))
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
        geom_edge_arc(aes(color = color, edge_linetype = color, edge_alpha = color)) +
        # geom_node_point(aes(color=factor(colorkey))) +
        geom_node_point() +
        scale_edge_color_manual(values = c(negative = "#d95f02", positive = "#1b9e77")) +
        scale_edge_linetype_manual(values = c(negative = "solid", positive = "solid")) +
        scale_edge_alpha_manual(values = c(negative = 0.6, positive = 0.3)) +
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
            panel.grid = element_blank()
        )
}

combined_graph <- read_graph(combined_gml, format = "gml")
combined_layout <- create_layout(graph = combined_graph, layout = "linear", circular = TRUE)

palette <- brewer.pal(n = 10, name = "Dark2")

flashweave_plot <- plot_network(flashweave_gml, combined_layout, 0.01, "flashweave", palette[[1]])
# mldm_plot <- plot_network(mldm_gml, combined_layout, 0.01, "mldm", palette[[2]])
spieceasi_plot <- plot_network(spieceasi_gml, combined_layout, 0.01, "spieceasi", palette[[3]])
cozine_plot <- plot_network(cozine_gml, combined_layout, 0.01, "cozine", palette[[3]])
harmonies_plot <- plot_network(harmonies_gml, combined_layout, 0.01, "harmonies", palette[[3]])
spring_plot <- plot_network(spring_gml, combined_layout, 0.01, "spring", palette[[3]])

# sparcc_plot <- plot_network(sparcc_gml, combined_layout, 0.3, "sparcc", palette[[4]])
spearman_plot <- plot_network(spearman_gml, combined_layout, 0.3, "spearman", palette[[5]])
pearson_plot <- plot_network(pearson_gml, combined_layout, 0.3, "pearson", palette[[6]])
propr_plot <- plot_network(propr_gml, combined_layout, 0.3, "propr", palette[[7]])

# NOTE: mldm did not work for moving_pictures
# combined_plot <- ggarrange(flashweave_plot, spieceasi_plot, cozine_plot, harmonies_plot, spring_plot, sparcc_plot, spearman_plot, pearson_plot, propr_plot, ncol = 3, nrow = 4, common.legend = TRUE, legend = "bottom")
combined_plot <- ggarrange(
    flashweave_plot, spieceasi_plot, cozine_plot, harmonies_plot, spring_plot, spearman_plot, pearson_plot, propr_plot,
    ncol = 3, nrow = 3, common.legend = TRUE, legend = "bottom"
)
a_plot <- annotate_figure(combined_plot, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)

ggsave(output_file_a, width = 11, height = 5.5)


#########################################
# cd
#########################################
plot_upset <- function(bmatrix, sets, kind) {
    upset(
        bmatrix,
        sets = sets,
        order.by = "freq",
        query.legend = "top",
        mainbar.y.label = paste0("Intersection of ", kind),
        sets.x.label = paste0("Number of ", kind),
        queries = list(list(query = intersects, params = sets, color = "red", active = TRUE, query.name = "Common to all")),
        text.scale = c(2, 1.3, 1.3, 1, 1.3, 1.3),
    )
}

# Node matrix
nmatrix <- read.csv(nmatrix_csv, header = TRUE, sep = ",")
nmatrix_bool <- data.frame(nmatrix)

# nmatrix_bool["sparcc"][nmatrix_bool["sparcc"] < 0.3] <- 0
nmatrix_bool["propr"][nmatrix_bool["propr"] < 0.3] <- 0
nmatrix_bool["spearman"][nmatrix_bool["spearman"] < 0.3] <- 0
nmatrix_bool["pearson"][nmatrix_bool["pearson"] < 0.3] <- 0
nmatrix_bool["flashweave"][nmatrix_bool["flashweave"] < 0.01] <- 0
nmatrix_bool["cozine"][nmatrix_bool["cozine"] < 0.01] <- 0
nmatrix_bool["harmonies"][nmatrix_bool["harmonies"] < 0.01] <- 0
nmatrix_bool["spring"][nmatrix_bool["spring"] < 0.01] <- 0
# nmatrix_bool["mldm"][nmatrix_bool["mldm"] < 0.01] = 0
nmatrix_bool["spieceasi"][nmatrix_bool["spieceasi"] < 0.01] <- 0
nmatrix_bool[nmatrix_bool > 0] <- 1

# nmatrix_plot <- plot_upset(nmatrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "sparcc", "propr"), "nodes")
nmatrix_plot <- plot_upset(nmatrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "propr"), "nodes")
nmatrix_plot
nmatrix_gg <- as_ggplot(grid.grab())


# Edge matrix
ematrix <- read.csv(ematrix_csv, header = TRUE, sep = ",")
ematrix_bool <- data.frame(ematrix)

# ematrix_bool["sparcc"][abs(ematrix_bool["sparcc"]) < 0.3] <- 0
ematrix_bool["propr"][abs(ematrix_bool["propr"]) < 0.3] <- 0
ematrix_bool["spearman"][abs(ematrix_bool["spearman"]) < 0.3] <- 0
ematrix_bool["pearson"][abs(ematrix_bool["pearson"]) < 0.3] <- 0
ematrix_bool["flashweave"][abs(ematrix_bool["flashweave"]) < 0.01] <- 0
ematrix_bool["cozine"][ematrix_bool["cozine"] < 0.01] <- 0
ematrix_bool["harmonies"][ematrix_bool["harmonies"] < 0.01] <- 0
ematrix_bool["spring"][ematrix_bool["spring"] < 0.01] <- 0
# ematrix_bool["mldm"][abs(ematrix_bool["mldm"]) < 0.01] = 0
ematrix_bool["spieceasi"][abs(ematrix_bool["spieceasi"]) < 0.01] <- 0
ematrix_bool[ematrix_bool > 0] <- 1

# ematrix_plot <- plot_upset(ematrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "sparcc", "propr"), "edges")
ematrix_plot <- plot_upset(ematrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "propr"), "edges")
ematrix_plot
ematrix_gg <- as_ggplot(grid.grab())


# Plotting
nmatrix_gg
ematrix_gg
bc_plot <- ggarrange(nmatrix_gg, ematrix_gg, labels = c("B", "C"))

ggsave(output_file_bc, width = 11, height = 5)


final_plot <- ggarrange(a_plot, bc_plot, ncol = 1, heights=c(1.3,1.0))
ggsave(output_file, final_plot, width = 11, height = 12)

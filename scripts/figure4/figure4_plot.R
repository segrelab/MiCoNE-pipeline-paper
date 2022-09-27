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
    data_folder <- "../../data/figure4/output/moving_pictures/"
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
output_file <- paste0(output_folder, "figure4.pdf")
output_file_a <- paste0(output_folder, "figure4a.pdf")
output_file_bc <- paste0(output_folder, "figure4bc.pdf")

corr_thres <- 0.3
direct_thres <- 0.01

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
        mutate(interaction = get_edgecolor(weight)) %>%
        mutate(abs_weight = abs(weight)) %>%
        activate(nodes) %>%
        mutate(isolated = node_is_isolated()) %>%
        filter(isolated == FALSE)
    temp_layout <- create_layout(graph = graph, layout = "linear", circular = TRUE)
    match_inds <- match(temp_layout$name, combined_layout$name)
    graph_layout <- data.frame(temp_layout)
    graph_layout$x <- combined_layout[match_inds, ]$x
    graph_layout$y <- combined_layout[match_inds, ]$y
    graph_plot <- ggraph(graph = graph, layout = "manual", x = graph_layout$x, y = graph_layout$y, circular = TRUE) +
        geom_edge_arc(aes(color = interaction, edge_linetype = interaction, edge_alpha = interaction)) +
        # geom_node_point(aes(color=factor(colorkey))) +
        geom_node_point() +
        scale_edge_color_manual(values = c(negative = "#d95f02", positive = "#1b9e77")) +
        scale_edge_linetype_manual(values = c(negative = "solid", positive = "solid")) +
        scale_edge_alpha_manual(values = c(negative = 0.5, positive = 0.5)) +
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

combined_graph <- read_graph(combined_gml, format = "gml")
combined_layout <- create_layout(graph = combined_graph, layout = "linear", circular = TRUE)

palette <- brewer.pal(n = 10, name = "Dark2")

flashweave_plot <- plot_network(flashweave_gml, combined_layout, direct_thres, "flashweave", palette[[1]])
# mldm_plot <- plot_network(mldm_gml, combined_layout, direct_thres, "mldm", palette[[2]])
spieceasi_plot <- plot_network(spieceasi_gml, combined_layout, direct_thres, "spieceasi", palette[[2]])
cozine_plot <- plot_network(cozine_gml, combined_layout, direct_thres, "cozine", palette[[3]])
harmonies_plot <- plot_network(harmonies_gml, combined_layout, direct_thres, "harmonies", palette[[4]])
spring_plot <- plot_network(spring_gml, combined_layout, direct_thres, "spring", palette[[5]])

sparcc_plot <- plot_network(sparcc_gml, combined_layout, corr_thres, "sparcc", palette[[6]])
spearman_plot <- plot_network(spearman_gml, combined_layout, corr_thres, "spearman", palette[[7]])
pearson_plot <- plot_network(pearson_gml, combined_layout, corr_thres, "pearson", palette[[8]])
propr_plot <- plot_network(propr_gml, combined_layout, corr_thres, "propr", palette[[9]])

combined_plot <- ggarrange(
    flashweave_plot, spieceasi_plot, cozine_plot, harmonies_plot, spring_plot, sparcc_plot, propr_plot, spearman_plot, pearson_plot,
    ncol = 3, nrow = 3, common.legend = TRUE, legend = "bottom"
)
a_plot <- annotate_figure(combined_plot, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)

# ggsave(output_file_a, width = 11, height = 5.5)


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
        text.scale = c(2.2, 1.5, 1.5, 1, 1.5, 1.5),
    )
}

# Node matrix
nmatrix <- read.csv(nmatrix_csv, header = TRUE, sep = ",")
nmatrix_bool <- data.frame(nmatrix)

nmatrix_bool["sparcc"][nmatrix_bool["sparcc"] < corr_thres] <- 0
nmatrix_bool["propr"][nmatrix_bool["propr"] < corr_thres] <- 0
nmatrix_bool["spearman"][nmatrix_bool["spearman"] < corr_thres] <- 0
nmatrix_bool["pearson"][nmatrix_bool["pearson"] < corr_thres] <- 0
nmatrix_bool["flashweave"][nmatrix_bool["flashweave"] < direct_thres] <- 0
nmatrix_bool["cozine"][nmatrix_bool["cozine"] < direct_thres] <- 0
nmatrix_bool["harmonies"][nmatrix_bool["harmonies"] < direct_thres] <- 0
nmatrix_bool["spring"][nmatrix_bool["spring"] < direct_thres] <- 0
# nmatrix_bool["mldm"][nmatrix_bool["mldm"] < direct_thres] = 0
nmatrix_bool["spieceasi"][nmatrix_bool["spieceasi"] < direct_thres] <- 0
nmatrix_bool[nmatrix_bool > 0] <- 1

# nmatrix_plot <- plot_upset(nmatrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "sparcc", "propr"), "nodes")
nmatrix_plot <- plot_upset(nmatrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "sparcc", "propr"), "nodes")
nmatrix_plot
nmatrix_gg <- as_ggplot(grid.grab())


# Edge matrix
ematrix <- read.csv(ematrix_csv, header = TRUE, sep = ",")
ematrix_bool <- data.frame(ematrix)

ematrix_bool["sparcc"][abs(ematrix_bool["sparcc"]) < corr_thres] <- 0
ematrix_bool["propr"][abs(ematrix_bool["propr"]) < corr_thres] <- 0
ematrix_bool["spearman"][abs(ematrix_bool["spearman"]) < corr_thres] <- 0
ematrix_bool["pearson"][abs(ematrix_bool["pearson"]) < corr_thres] <- 0
ematrix_bool["flashweave"][abs(ematrix_bool["flashweave"]) < direct_thres] <- 0
ematrix_bool["cozine"][ematrix_bool["cozine"] < direct_thres] <- 0
ematrix_bool["harmonies"][ematrix_bool["harmonies"] < direct_thres] <- 0
ematrix_bool["spring"][ematrix_bool["spring"] < direct_thres] <- 0
# ematrix_bool["mldm"][abs(ematrix_bool["mldm"]) < direct_thres] = 0
ematrix_bool["spieceasi"][abs(ematrix_bool["spieceasi"]) < direct_thres] <- 0
ematrix_bool[ematrix_bool > 0] <- 1

# ematrix_plot <- plot_upset(ematrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "sparcc", "propr"), "edges")
ematrix_plot <- plot_upset(ematrix_bool, c("flashweave", "spieceasi", "cozine", "harmonies", "spring", "sparcc", "propr"), "edges")
ematrix_plot
ematrix_gg <- as_ggplot(grid.grab())


# Plotting
nmatrix_gg
ematrix_gg
bc_plot <- ggarrange(nmatrix_gg, ematrix_gg, labels = c("B", "C"))

# ggsave(output_file_bc, width = 11, height = 5)


final_plot <- ggarrange(a_plot, bc_plot, ncol = 1, heights = c(1.3, 1.0))
ggsave(output_file, final_plot, width = 11, height = 15)

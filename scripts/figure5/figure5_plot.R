#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)
library(tidyverse)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure5/output/"
    output_folder <- "../../figures/"
} else if (length(args) == 2) {
    data_folder <- args[1]
    output_folder <- args[2]
} else {
    stop("Required number of arguments must equal 2")
}
norta_performance_csv <- paste0(data_folder, "norta/performance.csv")
seqtime_performance_csv <- paste0(data_folder, "seqtime/performance.csv")
output_file <- paste0(output_folder, "figure5.pdf")

plot_scatter <- function(data) {
    ggscatter(data,
        x = "precision", y = "sensitivity",
        color = "factor1", shape = "factor2"
    ) +
        theme_bw() +
        theme(
            text = element_text(size = 15),
        )
}

methods <- c("propr", "sparcc", "flashweave", "spieceasi", "SS[0.333]", "SS[0.667]", "SS[1.000]", "SV[0.333]", "SV[0.667]", "SV[1.000]")
norta <- read.csv(norta_performance_csv, sep = ",", header = TRUE)
norta <- subset(norta, title %in% methods)
norta$dataset <- "NorTA"
seqtime <- read.csv(seqtime_performance_csv, sep = ",", header = TRUE)
seqtime <- subset(seqtime, title %in% methods)
seqtime$dataset <- "Seqtime"
data <- rbind(norta, seqtime)
data[data["type"] == "SS", "type"] <- "SS (consensus)"
data[data["type"] == "SV", "type"] <- "SV (consensus)"

my_comparisons <- list(c("spieceasi", "SS[0.667]"), c("spieceasi", "SV[1.000]"))
precision_plot <- ggboxplot(data, x = "title", y = "precision", color = "type", add = "jitter") +
    facet_grid(dataset ~ type, scales = "free", space = "free") +
    stat_compare_means(comparisons = my_comparisons) +
    theme_pubr() +
    theme(
        axis.text.x = element_text(angle = 30, hjust = 1),
        text = element_text(size = 18),
    ) +
    xlab("Algorithm") +
    ylab("Precision")
# facet_precision <- gghistogram(data, x = "precision", bins = 20, facet.by = "dataset", palette = "Set2", add = "mean", rug = TRUE, color = "type", fill = "type")
# facet_sensitivity <- gghistogram(data, x = "sensitivity", bins = 20, facet.by = "dataset", palette = "Set2", add = "mean", rug = TRUE, color = "type", fill = "type")
# final_plot <- ggarrange(facet_precision, facet_sensitivity, ncol = 1, common.legend = TRUE, legend = "right")
ggsave(output_file, width = 14, height = 12)

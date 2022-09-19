#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)
library(tidyverse)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure_s6/output/seqtime/"
    output_folder <- "../../figures/"
} else if (length(args) == 2) {
    data_folder <- args[1]
    output_folder <- args[2]
} else {
    stop("Required number of arguments must equal 2")
}
performance_csv <- paste0(data_folder, "performance.csv")
output_file <- paste0(output_folder, "figure_s6.pdf")

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

seqtime <- read.csv(performance_csv, sep = ",", header = TRUE)
indv_algos <- c("cozine", "flashweave", "harmonies", "pearson", "propr", "sparcc", "spearman", "spieceasi", "spring")
seqtime_indv <- seqtime[seqtime$algorithm %in% indv_algos, ]
seqtime_sv <- seqtime[seqtime$algorithm == "simple", ]
seqtime_ss <- seqtime[seqtime$algorithm == "scaled", ]
# seqtime_pm <- seqtime[seqtime$algorithm == "pvalue",]

p_indv <- plot_scatter(seqtime_indv)
p_sv <- plot_scatter(seqtime_sv)
p_ss <- plot_scatter(seqtime_ss)
# p_pm <- plot_scatter(seqtime_pm)
facet_indv <- facet(p_indv, facet.by = "title", ncol = 4) + labs(title = "Individual algorithms")
facet_sv <- facet(p_sv, facet.by = "title", ncol = 4) + labs(title = "Simple voting consensus")
facet_ss <- facet(p_ss, facet.by = "title", ncol = 4) + labs(title = "Scaled sum consensus")
# facet_pm <- facet(p_pm, facet.by = "title", ncol = 1) + labs(title = "Pvalue merging consensus")

final_plot <- ggarrange(facet_indv, facet_sv, facet_ss, ncol = 1, common.legend = TRUE, legend = "right", heights = c(2.5, 1, 1))
ggsave(output_file, width = 14, height = 12)

#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure_s7/output/seqtime/"
    output_folder <- "../../figures/"
} else if (length(args) == 2) {
    data_folder <- args[1]
    output_folder <- args[2]
} else {
    stop("Required number of arguments must equal 2")
}
performance_csv <- paste0(data_folder, "performance.csv")
output_file <- paste0(output_folder, "figure_s7.pdf")

plot_scatter <- function(data) {
  ggscatter(data,
    x = "precision", y = "sensitivity",
    color = "factor1", shape = "factor2"
  ) +
    theme_pubr() #+
  # stat_stars(aes(color = "factor1"))
}

seqtime <- read.csv(performance_csv, sep = ",", header = TRUE)

p <- plot_scatter(seqtime)
final_plot <- facet(p, facet.by = "algorithm", ncol = 5)

ggsave(output_file, width = 14, height = 12)

#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)
library(ggpubr)
library(ggalluvial)
library(ggrepel)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure_s5/output/moving_pictures/"
    mock_folder <- "../../data/figure_s5/output/"
    output_folder <- "../../figures/"
} else if (length(args) == 3) {
    data_folder <- args[1]
    mock_folder <- args[2]
    output_folder <- args[3]
} else {
    stop("Required number of arguments must equal 3")
}
gg_silva_csv <- paste0(data_folder, "gg_silva.csv")
gg_ncbi_csv <- paste0(data_folder, "gg_ncbi.csv")
ncbi_silva_csv <- paste0(data_folder, "ncbi_silva.csv")
output_file <- paste0(output_folder, "figure_s5.pdf")


################################################################################
# Figure 4b
################################################################################
# Parameters
notu <- 50
levels <- c("Phylum", "Class", "Order", "Family", "Genus", "Species")

read_paired_data <- function(data_file) {
    raw_df <- read.csv(data_file, header = TRUE, sep = ",", na.strings = "")
    raw_df
}


make_bar_plot <- function(data, title) {
    ggbarplot(
        data,
        x = "tax_level",
        y = "value",
        fill = "assignment",
        color = "assignment",
        label = TRUE,
        lab.pos = "in",
        title = title,
        xlab = "Taxonomy level",
        ylab = "Number of Assignments",
        palette = c("#00AFBB", "#FC4E07"),
        # palette="Paired"
    ) +
        theme(
        plot.title = element_text(size=10),
        axis.text.x = element_text(angle = 30, hjust = 1)
    )
}

# Combinations
gg_silva <- read_paired_data(gg_silva_csv)
gg_ncbi <- read_paired_data(gg_ncbi_csv)
ncbi_silva <- read_paired_data(ncbi_silva_csv)

gg_silva_plot <- make_bar_plot(gg_silva, "NaiveBayes(GG) vs. NaiveBayes(SILVA)")
gg_ncbi_plot <- make_bar_plot(gg_ncbi, "NaiveBayes(GG) vs. BLAST(NCBI)")
ncbi_silva_plot <- make_bar_plot(ncbi_silva, "BLAST(NCBI) vs. NaiveBayes(SILVA)")

combined_plot_b <- ggarrange(
    gg_silva_plot, gg_ncbi_plot, ncbi_silva_plot,
    nrow = 1, ncol = 3, common.legend = TRUE, legend = "right"
)
# annotate_figure(combined_plot_b, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)
ggsave(output_file, width = 11, height = 4)

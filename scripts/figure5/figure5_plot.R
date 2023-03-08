#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(reshape2)

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

plot_boxplot <- function(data, title) {
    my_comparisons <- list(c("spieceasi", "SS[0.667]"), c("spieceasi", "SV[1.000]"))
    precision_plot <- ggboxplot(data, x = "title", y = "precision", facet.by = "type", color = "type", add = "jitter") +
        facet_grid(. ~ type, scales = "free", space = "free") +
        theme_pubr() +
        theme(
            axis.text.x = element_text(angle = 30, hjust = 1),
            text = element_text(size = 18),
        ) +
        xlab("Algorithm") +
        ylab("Precision") +
        labs(title = title, fill = "NI method")
}

plot_boxplot_precision <- function(data, title) {
    my_comparisons <- list(c("spieceasi", "SS[0.667]"), c("spieceasi", "SV[1.000]"))
    precision_plot <- ggboxplot(data, x = "title", y = "precision", facet.by = "type", color = "type", add = "jitter") +
        facet_grid(. ~ type, scales = "free", space = "free") +
        theme_pubr() +
        theme(
            axis.text.x = element_blank(),
            text = element_text(size = 18),
        ) +
        ylim(0, 1) +
        xlab("") +
        ylab("Precision") +
        labs(title = title, fill = "NI method")
}

plot_boxplot_sensitivity <- function(data, title) {
    my_comparisons <- list(c("spieceasi", "SS[0.667]"), c("spieceasi", "SV[1.000]"))
    sensitivity_plot <- ggboxplot(data, x = "title", y = "sensitivity", facet.by = "type", color = "type", add = "jitter") +
        facet_grid(. ~ type, scales = "free", space = "free") +
        theme_pubr() +
        theme(
            axis.text.x = element_text(angle = 30, hjust = 1),
            text = element_text(size = 18),
        ) +
        ylim(0, 1) +
        xlab("Algorithm") +
        ylab("Sensitivity") +
        labs(fill = "NI method")
}

plot_boxplot_all <- function(data, title) {
    data_subset <- data[, c("type", "title", "precision", "sensitivity")]
    data_melt <- melt(data_subset, id = c("type", "title"))
    colnames(data_melt)[colnames(data_melt) == "variable"] <- "Metric"
    my_comparisons <- list(c("spieceasi", "SS[0.667]"), c("spieceasi", "SV[1.000]"))
    sensitivity_plot <- ggboxplot(data_melt, x = "title", y = "value", facet.by = "type", color = "Metric", add = "jitter") +
        facet_grid(. ~ type, scales = "free", space = "free") +
        theme_pubr() +
        theme(
            axis.text.x = element_text(angle = 30, hjust = 1),
            text = element_text(size = 18),
        ) +
        ylim(0, 1) +
        xlab("Algorithm") +
        ylab("Precision/Sensitivity") +
        labs(title = title, fill = "NI method")
}

methods <- c("propr", "sparcc", "flashweave", "spieceasi", "SS[0.333]", "SS[0.667]", "SS[1.000]", "SV[0.333]", "SV[0.667]", "SV[1.000]")
norta <- read.csv(norta_performance_csv, sep = ",", header = TRUE)
norta <- subset(norta, title %in% methods)
norta$dataset <- "NorTA"
norta[norta["type"] == "IND", "type"] <- "Individual"
norta[norta["type"] == "SS", "type"] <- "SS (consensus)"
norta[norta["type"] == "SV", "type"] <- "SV (consensus)"
seqtime <- read.csv(seqtime_performance_csv, sep = ",", header = TRUE)
seqtime <- subset(seqtime, title %in% methods)
seqtime$dataset <- "Seqtime"
seqtime[seqtime["type"] == "IND", "type"] <- "Individual"
seqtime[seqtime["type"] == "SS", "type"] <- "SS (consensus)"
seqtime[seqtime["type"] == "SV", "type"] <- "SV (consensus)"

plot_norta_precision <- plot_boxplot_precision(norta, "NorTA")
plot_norta_sensitivity <- plot_boxplot_sensitivity(norta, "NorTA")
plot_seqtime_precision <- plot_boxplot_precision(seqtime, "Seqtime")
plot_seqtime_sensitivity <- plot_boxplot_sensitivity(seqtime, "Seqtime")

plot_norta <- plot_boxplot_all(norta, "NorTA")
plot_seqtime <- plot_boxplot_all(seqtime, "Seqtime")

final_plot <- ggarrange(plot_norta_precision, plot_norta_sensitivity, plot_seqtime_precision, plot_seqtime_sensitivity, ncol = 1, labels = c("A", "B", "C", "D"), common.legend = TRUE, legend = "right")
# final_plot <- ggarrange(plot_norta, plot_seqtime, ncol = 1, labels = c("A", "B"), common.legend = TRUE, legend = "right")
ggsave(output_file, width = 14, height = 12)

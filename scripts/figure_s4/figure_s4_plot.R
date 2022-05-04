#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure_s4/output/FMT/"
    output_folder <- "../../figures/FMT/"
} else if (length(args) == 3) {
    data_folder <- args[1]
    output_folder <- args[3]
} else {
    stop("Required number of arguments must equal 3")
}
unweighted_unifrac_csv <- paste0(data_folder, "unweighted_unifrac.csv")
weighted_unifrac_csv <- paste0(data_folder, "weighted_unifrac.csv")
output_file <- paste0(output_folder, "figure_s4.pdf")

#########################################
# ab
#########################################

tidy_up_data <- function(unifrac_data) {
    unifrac_data$method <- factor(unifrac_data$method)
    tidy_data <- unifrac_data %>%
        group_by(method) %>%
        select_at(c("method", "unifrac")) %>%
        summarize_all(.funs = mean) %>%
        distinct(method, .keep_all = TRUE)
}

plot_bar <- function(data, title) {
    ggbarplot(data, x = "method", y ="unifrac", fill="steelblue", label = TRUE, lab.pos = "out", lab.nb.digits = 3) +
        ylim(0, 1) +
        ggtitle(title) +
        theme_pubr() +
        theme(
            text = element_text(size = 15),
        )
}

unweighted <- read.csv(unweighted_unifrac_csv, sep = ",", header = TRUE)
unweighted_tidy <- tidy_up_data(unweighted)
weighted <- read.csv(weighted_unifrac_csv, sep = ",", header = TRUE)
weighted_tidy <- tidy_up_data(weighted)

weighted_plot <- plot_bar(weighted_tidy, "weighted unifrac")
unweighted_plot <- plot_bar(unweighted_tidy, "unweighted unifrac")

bar_plot <- ggarrange(
    weighted_plot, unweighted_plot,
    nrow = 1, ncol = 2, labels = c("A", "B"), common.legend = TRUE, legend = "right"
)
ggsave(output_file, bar_plot, width = 11, height = 5.5)

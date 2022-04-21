#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure_s4/output/moving_pictures/"
    mock_folder <- "../../data/figure_s4/output/"
    output_folder <- "../../figures/"
} else if (length(args) == 3) {
    data_folder <- args[1]
    mock_folder <- args[2]
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

tidy_up_data_ab <- function(unifrac_data) {
    unifrac_data$method1 <- factor(unifrac_data$method1)
    unifrac_data$method2 <- factor(unifrac_data$method2)
    tidy_data <- unifrac_data %>%
        group_by(method1, method2) %>%
        select_at(c("method1", "method2", "unifrac")) %>%
        summarize_all(.funs = mean) %>%
        rowwise() %>%
        mutate(pair = sort(c(method1, method2)) %>% paste(collapse = ",")) %>%
        group_by(pair) %>%
        distinct(pair, .keep_all = TRUE)
}

plot_heatmap <- function(data, title) {
    ggplot(data = data, aes(x = method1, y = method2, fill = unifrac)) +
        geom_tile(color = "white") +
        geom_text(aes(label = abbreviate(unifrac))) +
        scale_fill_distiller(
            palette = "Spectral",
            limits = c(0, 1),
            breaks = c(0, 0.25, 0.5, 0.75, 1),
            labels = c("Similar", 0.25, 0.5, 0.75, "Dissimilar")
        ) +
        ggtitle(title) +
        theme_pubr() +
        theme(
            plot.title = element_text(hjust = 0.5),
            axis.title = element_blank(),
            axis.text.x = element_text(angle = 30, hjust = 1),
            axis.text.y = element_text(angle = 30)
        ) +
        coord_fixed()
}

unweighted <- read.csv(unweighted_unifrac_csv, sep = ",", header = TRUE)
unweighted_tidy <- tidy_up_data_ab(unweighted)
weighted <- read.csv(weighted_unifrac_csv, sep = ",", header = TRUE)
weighted_tidy <- tidy_up_data_ab(weighted)

weighted_plot <- plot_heatmap(weighted_tidy, "weighted unifrac")
unweighted_plot <- plot_heatmap(unweighted_tidy, "unweighted unifrac")

heatmap_plot <- ggarrange(
    weighted_plot, unweighted_plot,
    nrow = 1, ncol = 2, labels = c("A", "B"), common.legend = TRUE, legend = "right"
)
ggsave(output_file, heatmap_plot, width = 11, height = 5.5)

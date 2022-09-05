#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure2/output/moving_pictures/"
    mock_folder <- "../../data/figure2/output/"
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
mock4_unweighted_csv <- paste0(mock_folder, "mock4/unweighted_unifrac.csv")
mock12_unweighted_csv <- paste0(mock_folder, "mock12/unweighted_unifrac.csv")
mock16_unweighted_csv <- paste0(mock_folder, "mock16/unweighted_unifrac.csv")
mock4_weighted_csv <- paste0(mock_folder, "mock4/weighted_unifrac.csv")
mock12_weighted_csv <- paste0(mock_folder, "mock12/weighted_unifrac.csv")
mock16_weighted_csv <- paste0(mock_folder, "mock16/weighted_unifrac.csv")
output_file <- paste0(output_folder, "figure2.pdf")
output_file_ab <- paste0(output_folder, "figure2ab.pdf")
output_file_cd <- paste0(output_folder, "figure2cd.pdf")

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
            axis.text.y = element_text(angle = 30),
            text = element_text(size = 15),
        ) +
        coord_fixed()
}

unweighted <- read.csv(unweighted_unifrac_csv, sep = ",", header = TRUE)
unweighted_tidy <- tidy_up_data_ab(unweighted)
weighted <- read.csv(weighted_unifrac_csv, sep = ",", header = TRUE)
weighted_tidy <- tidy_up_data_ab(weighted)

weighted_plot <- plot_heatmap(weighted_tidy, "Weighted UniFrac")
unweighted_plot <- plot_heatmap(unweighted_tidy, "UnWeighted UniFrac")

heatmap_plot <- ggarrange(
    weighted_plot, unweighted_plot,
    nrow = 1, ncol = 2, labels = c("A", "B"), common.legend = TRUE, legend = "right"
)
ggsave(output_file_ab, heatmap_plot, width = 11, height = 5.5)


#########################################
# cd
#########################################


tidy_up_data_cd <- function(unifrac_data, name) {
    unifrac_data$dataset <- rep(name, nrow(unifrac_data))
    unifrac_data$method1 <- factor(unifrac_data$method1)
    unifrac_data$method2 <- factor(unifrac_data$method2)
    tidy_data <- unifrac_data %>%
        filter(grepl("input", method2)) %>%
        filter(!grepl("input", method1)) %>%
        select_at(c("method1", "sample", "unifrac", "dataset"))
}

make_dot_plot <- function(unifrac_data, title) {
    dot_plot <- add_summary(
        ggstripchart(
            unifrac_data,
            x = "method1",
            y = "unifrac",
            color = "dataset",
            title = title,
            xlab = "Denoising/Clustering method",
            ylab = "UniFrac distance",
            ylim = c(0, 1),
            size = 3,
            add = "jitter",
        ) +
            theme_pubr() +
            theme(
                plot.title = element_text(hjust = 0.5),
                axis.text.x = element_text(angle = 30, hjust = 1),
                text = element_text(size = 15),
            ),
        fun = "mean_sd"
    )
}

# Weighted
mock4_weighted <- read.csv(mock4_weighted_csv, sep = ",", header = TRUE)
mock12_weighted <- read.csv(mock12_weighted_csv, sep = ",", header = TRUE)
mock16_weighted <- read.csv(mock16_weighted_csv, sep = ",", header = TRUE)

mock4_weighted_tidy <- tidy_up_data_cd(mock4_weighted, "mock4")
mock12_weighted_tidy <- tidy_up_data_cd(mock12_weighted, "mock12")
mock16_weighted_tidy <- tidy_up_data_cd(mock16_weighted, "mock16")

mock_weighted_tidy <- rbind(mock4_weighted_tidy, mock12_weighted_tidy, mock16_weighted_tidy)
mock_weighted_plot <- make_dot_plot(mock_weighted_tidy, "Weighted UniFrac")

# Unweighted
mock4_unweighted <- read.csv(mock4_unweighted_csv, sep = ",", header = TRUE)
mock12_unweighted <- read.csv(mock12_unweighted_csv, sep = ",", header = TRUE)
mock16_unweighted <- read.csv(mock16_unweighted_csv, sep = ",", header = TRUE)

mock4_unweighted_tidy <- tidy_up_data_cd(mock4_unweighted, "mock4")
mock12_unweighted_tidy <- tidy_up_data_cd(mock12_unweighted, "mock12")
mock16_unweighted_tidy <- tidy_up_data_cd(mock16_unweighted, "mock16")

mock_unweighted_tidy <- rbind(mock4_unweighted_tidy, mock12_unweighted_tidy, mock16_unweighted_tidy)
mock_unweighted_plot <- make_dot_plot(mock_unweighted_tidy, "UnWeighted UniFrac")


final_dot_plot <- ggarrange(
    mock_weighted_plot, mock_unweighted_plot,
    labels = c("C", "D"), nrow = 1, ncol = 2, common.legend = TRUE, legend = "right"
)
ggsave(output_file_cd, width = 11, height = 5)


############
# Final plot
final_plot <- ggarrange(heatmap_plot, final_dot_plot, nrow = 2, ncol = 1)
ggsave(output_file, width = 11, height = 12)

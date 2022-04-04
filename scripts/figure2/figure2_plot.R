#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)
library(ggrepel)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure2/output/moving_pictures/"
    output_folder <- "../../figures/"
} else if (length(args) == 2) {
    data_folder <- args[1]
    output_folder <- args[2]
} else {
    stop("Required number of arguments must equal 2")
}
x_csv <- paste0(data_folder, "x.csv")
y_reduced_csv <- paste0(data_folder, "y_reduced2.csv")
percentage_variance_csv <- paste0(data_folder, "percentage_variance.csv")
output_file <- paste0(output_folder, "figure2.pdf")

plot_scatter <- function(data, color_var) {
    ggscatter(data,
        x = "X0", y = "X1",
        color = color_var,
        # ellipse = TRUE
    ) +
    theme(
        text = element_text(size = 16),
    )
}

x <- read.csv(x_csv)
y_reduced <- read.csv(y_reduced_csv)
names(y_reduced)[names(y_reduced) == "X"] <- "hash"
percentage_variance <- read.csv(percentage_variance_csv)

percentage_variance <-
    percentage_variance %>%
    mutate(labels = scales::percent(mean_sq, scale = 1)) %>%
    arrange(desc(Workflow)) %>%
    mutate(text_y = cumsum(mean_sq) - mean_sq / 2)


df <- y_reduced %>%
    select("hash", "X0", "X1") %>%
    left_join(x, by = "hash")
scatter_ta <- plot_scatter(df, "TA")
scatter_ni <- plot_scatter(df, "NI")

pie_chart <- ggplot(data = percentage_variance, aes(x = "", y = mean_sq, fill = Workflow)) +
    geom_bar(stat = "identity") +
    geom_label_repel(aes(label = labels, y = text_y), nudge_x = 1.6) +
    coord_polar(theta = "y") +
    theme_pubr() +
    theme(
        axis.ticks = element_blank(),
        axis.line = element_blank(),
        axis.title = element_blank(),
        axis.text.y = element_blank(),
        axis.text.x = element_blank(),
        legend.position="right",
        legend.justification="right",
        text = element_text(size = 16),
    )

scatter_facet <- ggarrange(scatter_ta, scatter_ni, ncol = 2)
ggarrange(pie_chart, scatter_facet, labels = c("A", "B"), ncol = 1)
ggsave(output_file, width = 14, height = 12)

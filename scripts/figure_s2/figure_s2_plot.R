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
y_reduced_tsne_csv <- paste0(data_folder, "y_reduced_tsne.csv")
percentage_variance_csv <- paste0(data_folder, "percentage_variance.csv")
output_file <- paste0(output_folder, "figure_s2.pdf")

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
y_reduced_tsne <- read.csv(y_reduced_tsne_csv)
names(y_reduced_tsne)[names(y_reduced_tsne) == "X"] <- "hash"

df <- y_reduced_tsne %>%
    select("hash", "X0", "X1") %>%
    left_join(x, by = "hash")
df[df == "open_reference(gg_97)"] <- "OR"
df[df == "closed_reference(gg_97)"] <- "CR"
df[df == "de_novo"] <- "DN"
df[df == "dada2"] <- "D2"
df[df == "deblur"] <- "DB"
df[df == "normalize_filter(on)"] <- "Filter(on)"
df[df == "normalize_filter(off)"] <- "Filter(off)"

scatter_dc <- plot_scatter(df, "DC")
scatter_ta <- plot_scatter(df, "TA")
scatter_op <- plot_scatter(df, "OP")
scatter_ni <- plot_scatter(df, "NI")

ggarrange(scatter_dc, scatter_ta, scatter_op, scatter_ni, nrow=2, ncol = 2, labels = c("A", "B", "C", "D"))
ggsave(output_file, width = 14, height = 12)

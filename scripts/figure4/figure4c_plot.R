#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)
library(ggpubr)

levels <- c("Family", "Genus", "Species")

tidy_up_data <- function(data_file, name) {
    data <- read_csv(data_file)
    data$dataset <- rep(name, nrow(data))
    data$tax_level <- factor(data$tax_level, levels=levels)
    return(data)
}


make_dot_plot <- function(braycurtis_data) {
    add_summary(
         ggstripchart(
            braycurtis_data,
            x="database",
            y="braycurtis",
            color="dataset",
            xlab="database",
            ylab="Braycurtis dissimilarity",
            ylim=c(0, 1),
            size=3,
            add="jitter",
        ) +
        theme(
            plot.title=element_text(hjust=0.5),
        ),
        fun="mean_sd"
    )
}


mock4_data <- tidy_up_data("mock4_braycurtis.csv", "mock4")
mock12_data <- tidy_up_data("mock12_braycurtis.csv", "mock12")
mock16_data <- tidy_up_data("mock16_braycurtis.csv", "mock16")

mock_data <- rbind(mock4_data, mock12_data, mock16_data)
dot_plot <- make_dot_plot(mock_data)
dot_plot_facet <- facet(dot_plot, facet.by="tax_level")
final_plot <- annotate_figure(dot_plot_facet, fig.lab="C", fig.lab.pos="top.left", fig.lab.size=20)

ggsave("figure4c.pdf", width=11, height=5)

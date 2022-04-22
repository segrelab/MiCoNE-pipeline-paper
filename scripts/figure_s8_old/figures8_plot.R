#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

methods <- c("magma", "pearson", "mldm", "spearman", "spieceasi", "sparcc")

tidy_up_data <- function(similarity_data) {
    similarity_data$method1 <- factor(similarity_data$method1, levels=methods)
    similarity_data$method2 <- factor(similarity_data$method2, levels=methods)
    tidy_data <- similarity_data %>%
        group_by(method1, method2) %>%
        select_at(c("method1", "method2", "similarity")) %>%
        summarize_all(.funs=mean) %>%
        rowwise() %>%
        mutate(pair=sort(c(method1, method2)) %>% paste(collapse=",")) %>%
        group_by(pair) %>%
        distinct(pair, .keep_all=TRUE)
}

plot_heatmap <- function(data, title) {
    ggplot(data=data, aes(x=method1, y=method2, fill=similarity)) +
        geom_tile(color="white") +
        geom_text(aes(label=abbreviate(similarity))) +
        scale_fill_distiller(
            palette="Spectral",
            direction=1,
            limits=c(0, 1),
            breaks=c(0, 0.25, 0.5, 0.75, 1),
            labels=c("Dissimilar", 0.25, 0.5, 0.75, "Similar")
        ) +
        ggtitle(title) +
        theme_pubr() +
        theme(
            plot.title=element_text(hjust=0.5),
            axis.title=element_blank(),
            axis.text.x=element_text(angle=30, hjust=1),
            axis.text.y=element_text(angle=30)
        ) +
        coord_fixed()
}

fmt_similarity <- read.csv("fmt_similarity.csv", sep=",", header=TRUE)
fmt_similarity_tidy <- tidy_up_data(fmt_similarity)
hp_similarity <- read.csv("hp_similarity.csv", sep=",", header=TRUE)
hp_similarity_tidy <- tidy_up_data(hp_similarity)

fmt_similarity_plot <- plot_heatmap(fmt_similarity_tidy, "FMT similarity")
hp_similarity_plot <- plot_heatmap(hp_similarity_tidy, "HP similarity")

heatmap_plot <- ggarrange(fmt_similarity_plot, hp_similarity_plot, nrow=1, ncol=2, labels=c("A", "B"), common.legend=TRUE, legend="right")
ggsave("figures8.pdf", heatmap_plot, width=11, height=8.5)

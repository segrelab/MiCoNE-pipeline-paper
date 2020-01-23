#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

methods <- c("closed_reference", "de_novo", "open_reference", "deblur", "dada2")

tidy_up_data <- function(unifrac_data) {
    unifrac_data$method1 <- factor(unifrac_data$method1, levels=methods)
    unifrac_data$method2 <- factor(unifrac_data$method2, levels=methods)
    tidy_data <- unifrac_data %>%
        group_by(method1, method2) %>%
        select_at(c("method1", "method2", "unifrac")) %>%
        summarize_all(.funs=mean) %>%
        rowwise() %>%
        mutate(pair=sort(c(method1, method2)) %>% paste(collapse=",")) %>%
        group_by(pair) %>%
        distinct(pair, .keep_all=TRUE)
}

plot_heatmap <- function(data, title) {
    ggplot(data=data, aes(x=method1, y=method2, fill=unifrac)) +
        geom_tile(color="white") +
        geom_text(aes(label=abbreviate(unifrac))) +
        scale_fill_distiller(
            palette="Spectral",
            limits=c(0, 1),
            breaks=c(0, 0.25, 0.5, 0.75, 1),
            labels=c("Similar", 0.25, 0.5, 0.75, "Dissimilar")
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

unweighted <- read.csv("fmt_unweighted_unifrac.csv", sep=",", header=TRUE)
unweighted_tidy <- tidy_up_data(unweighted)
weighted <- read.csv("fmt_weighted_unifrac.csv", sep=",", header=TRUE)
weighted_tidy <- tidy_up_data(weighted)

weighted_plot <- plot_heatmap(weighted_tidy, "weighted unifrac")
unweighted_plot <- plot_heatmap(unweighted_tidy, "unweighted unifrac")

heatmap_plot <- ggarrange(weighted_plot, unweighted_plot, nrow=1, ncol=2, labels=c("A", "B"), common.legend=TRUE, legend="right")
ggsave("figure3ab.pdf", heatmap_plot, width=11, height=8.5)

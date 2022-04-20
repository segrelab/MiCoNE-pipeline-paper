#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

methods <- c("closed_reference", "de_novo", "open_reference", "deblur", "dada2")

tidy_up_data <- function(corr_data) {
    corr_data$method1 <- factor(corr_data$method1, levels=methods)
    corr_data$method2 <- factor(corr_data$method2, levels=methods)
    tidy_data <- corr_data %>%
        group_by(method1, method2) %>%
        select_at(c("method1", "method2", "corr")) %>%
        summarize_all(.funs=mean) %>%
        rowwise() %>%
        mutate(pair=sort(c(method1, method2)) %>% paste(collapse=",")) %>%
        group_by(pair) %>%
        distinct(pair, .keep_all=TRUE)
}

plot_heatmap <- function(data, title) {
    ggplot(data=data, aes(x=method1, y=method2, fill=corr)) +
        geom_tile(color="white") +
        geom_text(aes(label=abbreviate(corr))) +
        scale_fill_distiller(
            palette="Spectral",
            limits=c(0, 1),
            breaks=c(0, 0.25, 0.5, 0.75, 1),
            labels=c("Low", 0.25, 0.5, 0.75, "High")
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

corr <- read.csv("fmt_corr.csv", sep=",", header=TRUE)
corr_tidy <- tidy_up_data(corr)
# weighted <- read.csv("fmt_weighted_unifrac.csv", sep=",", header=TRUE)
# weighted_tidy <- tidy_up_data(weighted)

corr_plot <- plot_heatmap(corr_tidy, "correlation")
# unweighted_plot <- plot_heatmap(unweighted_tidy, "unweighted unifrac")

heatmap_plot <- ggarrange(corr_plot, nrow=1, ncol=1, labels=c("C"), common.legend=TRUE, legend="right")
ggsave("figure_s1c.pdf", heatmap_plot, width=11, height=8.5)

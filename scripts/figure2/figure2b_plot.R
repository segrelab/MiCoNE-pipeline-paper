#!/usr/bin/env Rscript

library(titdyverse)
library(ggplot2)
library(ggpubr)

plot_pca <- function(pca_data) {
    pca_plot <- ggscatter(pca_data,
        x="pc1",
        y="pc2",
        fill="TA",
        shape="DC",
        size="OP",
        xlab="PC1",
        ylab="PC2",
        legend="right",
    ) +
    scale_shape_manual(values=c(21, 22, 23, 24, 25)) +
    scale_size_manual(values=c("no"=5, "yes"=2.5)) +
    guides(fill=guide_legend(override.aes=list(shape=21)))
    ggarrange(pca_plot, labels=c("B"), nrow=1, ncol=1, common.legend=TRUE, legend="right")
}


pca_data <- read.table("pca_2comp.csv", sep=",", header=TRUE)
plot_pca(pca_data)

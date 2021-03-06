#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)

methods <- c("input", "closed_reference", "de_novo", "open_reference", "deblur", "dada2")

tidy_up_data <- function(unifrac_data, name) {
    unifrac_data$dataset <- rep(name, nrow(unifrac_data))
    unifrac_data$method1 <- factor(unifrac_data$method1, levels=methods)
    unifrac_data$method2 <- factor(unifrac_data$method2, levels=methods)
    tidy_data <- unifrac_data %>%
        filter(method2 == "input") %>%
        filter(method1 != "input") %>%
        select_at(c("method1", "sample", "unifrac", "dataset"))
}

make_dot_plot <- function(unifrac_data, title) {
    dot_plot <- add_summary(
        ggstripchart(
            unifrac_data,
            x="method1",
            y="unifrac",
            color="dataset",
            title=title,
            xlab="denoising/clustering method",
            ylab="unifrac distance",
            ylim=c(0, 1),
            size=3,
            add="jitter",
        ) +
        theme(
            plot.title=element_text(hjust=0.5),
            axis.text.x=element_text(angle=30, hjust=1),
        ),
        fun="mean_sd"
    )
}

# Weighted
mock4_weighted <- read.csv("mock4_weighted_unifrac.csv", sep=",", header=TRUE)
mock12_weighted <- read.csv("mock12_weighted_unifrac.csv", sep=",", header=TRUE)
mock16_weighted <- read.csv("mock16_weighted_unifrac.csv", sep=",", header=TRUE)

mock4_weighted_tidy <- tidy_up_data(mock4_weighted, "mock4")
mock12_weighted_tidy <- tidy_up_data(mock12_weighted, "mock12")
mock16_weighted_tidy <- tidy_up_data(mock16_weighted, "mock16")

mock_weighted_tidy <- rbind(mock4_weighted_tidy, mock12_weighted_tidy, mock16_weighted_tidy)
mock_weighted_plot <- make_dot_plot(mock_weighted_tidy, "weighted unifrac")

# Unweighted
mock4_unweighted <- read.csv("mock4_unweighted_unifrac.csv", sep=",", header=TRUE)
mock12_unweighted <- read.csv("mock12_unweighted_unifrac.csv", sep=",", header=TRUE)
mock16_unweighted <- read.csv("mock16_unweighted_unifrac.csv", sep=",", header=TRUE)

mock4_unweighted_tidy <- tidy_up_data(mock4_unweighted, "mock4")
mock12_unweighted_tidy <- tidy_up_data(mock12_unweighted, "mock12")
mock16_unweighted_tidy <- tidy_up_data(mock16_unweighted, "mock16")

mock_unweighted_tidy <- rbind(mock4_unweighted_tidy, mock12_unweighted_tidy, mock16_unweighted_tidy)
mock_unweighted_plot <- make_dot_plot(mock_unweighted_tidy, "unweighted unifrac")


final_plot <- ggarrange(mock_weighted_plot, mock_unweighted_plot, labels=c("C", "D"), nrow=1, ncol=2, common.legend=TRUE, legend="right")

ggsave("figure3cd.pdf", width=11, height=5)

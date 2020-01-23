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
    )
}

# Weighted
emp_soil_weighted <- read.csv("emp_soil_weighted_unifrac.csv", sep=",", header=TRUE)
emp_water_weighted <- read.csv("emp_water_weighted_unifrac.csv", sep=",", header=TRUE)

emp_soil_weighted_tidy <- tidy_up_data(emp_soil_weighted, "emp_soil")
emp_water_weighted_tidy <- tidy_up_data(emp_water_weighted, "emp_water")

weighted_tidy <- rbind(emp_soil_weighted_tidy, emp_water_weighted_tidy)
weighted_plot <- make_dot_plot(weighted_tidy, "weighted unifrac")

# Unweighted
emp_soil_unweighted <- read.csv("emp_soil_unweighted_unifrac.csv", sep=",", header=TRUE)
emp_water_unweighted <- read.csv("emp_water_unweighted_unifrac.csv", sep=",", header=TRUE)

emp_soil_unweighted_tidy <- tidy_up_data(emp_soil_unweighted, "emp_soil")
emp_water_unweighted_tidy <- tidy_up_data(emp_water_unweighted, "emp_water")

unweighted_tidy <- rbind(emp_soil_unweighted_tidy, emp_water_unweighted_tidy)
unweighted_plot <- make_dot_plot(unweighted_tidy, "unweighted unifrac")


final_plot <- ggarrange(weighted_plot, unweighted_plot, labels=c("A", "B"), nrow=1, ncol=2, common.legend=TRUE, legend="right")

ggsave("figure_s3.pdf", width=11, height=5)

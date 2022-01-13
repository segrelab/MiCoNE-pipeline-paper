#!/usr/bin/env Rscript

library(tidyverse)
library(ggpubr)


l1_data <- read.csv("../../data/figure6/output/moving_pictures/l1_distance_to_ref.csv", header=TRUE, sep=",")

ggboxplot(l1_data, x="step", y="l1_distance", add="jitter", label="process", repel=TRUE, order=c("DC", "CC", "TA", "NI"), color="step", add="jitter",palette="Set2", ylab="L1 distance", xlab="Pipeline step")

ggsave("figure6b.pdf", width=11, height=5)

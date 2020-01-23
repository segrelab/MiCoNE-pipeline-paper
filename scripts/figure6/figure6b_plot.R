#!/usr/bin/env Rscript

library(tidyverse)
library(ggpubr)


l1_data <- read.csv("distance_to_ref.csv", header=TRUE, sep=",")

ggboxplot(l1_data, x="step", y="distance", order=c("DC", "TA", "OP"), color="step", add="jitter",palette="Set2", ylab="L1 distance", xlab="Pipeline step")

ggsave("figure6b.pdf", width=11, height=5)

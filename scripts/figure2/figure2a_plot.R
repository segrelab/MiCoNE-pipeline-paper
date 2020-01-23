#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)
library(ggpubr)


group <- c("DC", "TA", "OP", "misc")
percentage <- c(17.97, 24.90, 5.16, 51.96)
labels <- paste0(group, " (", percentage, "%)")
df <- data.frame(group=group, percentage=percentage, labels=labels)

pie_chart <- ggpie(
                   df,
                   "percentage",
                   label="labels",
                   fill="group",
                   palette="Set2",
                   lab.pos="in",lab.font="black"
)
ggarrange(pie_chart, labels=c("A"), nrow=1, ncol=1, common.legend=TRUE, legend="right")

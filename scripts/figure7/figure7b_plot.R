#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)


header <- c("factor1", "factor2", "algorithm", "tp", "fp", "tn", "fn", "precision", "sensitivity")

plot_scatter <- function(data) {
  ggscatter(data,
    x = "precision", y = "sensitivity",
    color = "factor1", shape = "factor2"
  ) +
    theme_pubr() #+
  # stat_stars(aes(color = "factor1"))
}

norta <- read.csv("../../data/figure7/output/norta/performance.csv", sep = ",", header = TRUE)
## seqtime <- read.csv("../../data/figure7/output/seqtime/performance.csv", sep = ",", header = TRUE)

p <- plot_scatter(norta) #+ geom_text(data=norta, mapping=aes(x="precision", y="sensitivity", label="algorithm"))
final_plot <- facet(p, facet.by = "algorithm", ncol = 5)

ggarrange(final_plot, labels = c("B"))
ggsave("figure7b_plot.pdf", width = 14, height = 12)

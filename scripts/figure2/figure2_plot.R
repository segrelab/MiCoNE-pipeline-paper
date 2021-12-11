#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)
library(ggrepel)

plot_scatter <- function(data) {
  ggscatter(data,
    x = "X0", y = "X1",
    color = "NI", shape = "TA",
   #ylim=c(-1, 1),
   #xlim=c(-1, 1),
   #ellipse = TRUE
  )
}

x <- read.csv("../../data/figure2/output/moving_pictures/x.csv")
y_reduced <- read.csv("../../data/figure2/output/moving_pictures/y_reduced2.csv")
names(y_reduced)[names(y_reduced)=="X"] <- "hash"
percentage_variance <- read.csv("../../data/figure2/output/moving_pictures/percentage_variance.csv")
percentage_variance$labels <- paste0(percentage_variance$X, " (", formatC(percentage_variance$sum_sq, digits = 3, format = "f"), "%)")


# df <- y_reduced %>% select("hash", "X0", "X1") %>% filter((abs(X0) < 5) & (abs(X1) < 10)) %>% left_join(x, by="hash")
df <- y_reduced %>% select("hash", "X0", "X1") %>% left_join(x, by="hash")
scat <- plot_scatter(df)

# Maybe repel: https://stackoverflow.com/questions/69715282/how-to-adjust-ggrepel-label-on-pie-chart
pie_chart <- ggpie(
                   percentage_variance,
                   "sum_sq",
                   label="labels",
                   fill="X",
                   palette="Set2",
                   lab.pos="out",lab.font="black",
                   repel = TRUE,
)

ggarrange(pie_chart, scat, labels = c("A", "B"))
ggsave("figure2.pdf", width = 14, height = 12)

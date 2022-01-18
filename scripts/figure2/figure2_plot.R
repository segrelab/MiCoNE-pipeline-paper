#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(ggpubr)
library(ggrepel)

plot_scatter <- function(data, color_var) {
  ggscatter(data,
    x = "X0", y = "X1",
    color = color_var,
    #ellipse = TRUE
  )
}

x <- read.csv("../../data/figure2/output/moving_pictures/x.csv")
y_reduced <- read.csv("../../data/figure2/output/moving_pictures/y_reduced2.csv")
names(y_reduced)[names(y_reduced)=="X"] <- "hash"
percentage_variance <- read.csv("../../data/figure2/output/moving_pictures/percentage_variance.csv")

percentage_variance <-
  percentage_variance %>%
  mutate(labels = scales::percent(mean_sq, scale=1)) %>%
  arrange(desc(X)) %>%
  mutate(text_y = cumsum(mean_sq) - mean_sq / 2)


# df <- y_reduced %>% select("hash", "X0", "X1") %>% filter((abs(X0) < 5) & (abs(X1) < 10)) %>% left_join(x, by="hash")
df <- y_reduced %>% select("hash", "X0", "X1") %>% left_join(x, by="hash")
scatter_ta <- plot_scatter(df, "TA")
scatter_ni <- plot_scatter(df, "NI")

pie_chart <- ggplot(data = percentage_variance, aes(x = "", y = mean_sq, fill = X)) +
                       geom_bar(stat = "identity") + 
                       geom_label_repel(aes(label = labels, y = text_y), nudge_x = 1.6) +
                       coord_polar(theta = "y") +
                       theme_pubr() +
                       theme(axis.ticks = element_blank(),
                             axis.line = element_blank(),
                             axis.title = element_blank(),
                            axis.text.y = element_blank(),
                            axis.text.x = element_blank())

scatter_facet = ggarrange(scatter_ta, scatter_ni)
ggarrange(pie_chart, scatter_facet, labels = c("A", "B"), ncol = 1)
ggsave("figure2.pdf", width = 14, height = 12)

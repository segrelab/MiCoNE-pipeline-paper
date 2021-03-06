#!/usr/bin/env Rscript

library(UpSetR)
library(grid)
library(ggpubr)

plot_upset <- function(bmatrix, sets, kind) {
    upset(
      bmatrix,
      sets=sets,
      order.by="freq",
      query.legend="top",
      mainbar.y.label=paste0("Intersection of ", kind),
      sets.x.label=paste0("Number of ", kind),
      queries=list(list(query=intersects, params=sets, color="red", active=TRUE, query.name="Common to all")),
      text.scale = c(2, 1.3, 1.3, 1, 1.3, 1.3),
    )
}

# Node matrix
nmatrix <- read.csv("nmatrix.csv", header=TRUE, sep=",")
nmatrix_bool <- data.frame(nmatrix)

nmatrix_bool["sparcc"][nmatrix_bool["sparcc"] < 0.3] = 0
nmatrix_bool["spearman"][nmatrix_bool["spearman"] < 0.3] = 0
nmatrix_bool["pearson"][nmatrix_bool["pearson"] < 0.3] = 0
nmatrix_bool["magma"][nmatrix_bool["magma"] < 0.01] = 0
nmatrix_bool["mldm"][nmatrix_bool["mldm"] < 0.01] = 0
nmatrix_bool["spieceasi"][nmatrix_bool["spieceasi"] < 0.01] = 0
nmatrix_bool[nmatrix_bool > 0] = 1

nmatrix_plot <- plot_upset(nmatrix_bool, c("magma", "mldm", "spieceasi", "sparcc"), "nodes")
nmatrix_plot
nmatrix_gg <- as_ggplot(grid.grab())


# Edge matrix
ematrix <- read.csv("ematrix.csv", header=TRUE, sep=",")
ematrix_bool <- data.frame(ematrix)

ematrix_bool["sparcc"][abs(ematrix_bool["sparcc"]) < 0.3] = 0
ematrix_bool["spearman"][abs(ematrix_bool["spearman"]) < 0.3] = 0
ematrix_bool["pearson"][abs(ematrix_bool["pearson"]) < 0.3] = 0
ematrix_bool["magma"][abs(ematrix_bool["magma"]) < 0.01] = 0
ematrix_bool["mldm"][abs(ematrix_bool["mldm"]) < 0.01] = 0
ematrix_bool["spieceasi"][abs(ematrix_bool["spieceasi"]) < 0.01] = 0
ematrix_bool[ematrix_bool > 0] = 1

ematrix_plot <- plot_upset(ematrix_bool, c("magma", "mldm", "spieceasi", "sparcc"), "edges")
ematrix_plot
ematrix_gg <- as_ggplot(grid.grab())


# Plotting
nmatrix_gg
ematrix_gg
ggarrange(nmatrix_gg, ematrix_gg, labels=c("B", "C"))
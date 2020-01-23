#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)
library(ggpubr)


# Parameters
notu <- 50
levels <- c("Phylum", "Class", "Order", "Family", "Genus", "Species")


tidy_up_data <- function(db_file, notu) {
    db_data <- read_csv(db_file)[1:notu,]
    for (i in 1:length(levels)) {
        cols <- levels[1:i]
        db_data[levels[i]] = apply(db_data[,cols], 1, paste, collapse="-")
    }
    return(db_data)
}

combine_data <- function(db1, db2) {
    comb_tbl <- as_tibble(
        rbind(t(colSums(db1 == db2)), t(colSums(db1 != db2)))
    )
    comb_tbl$type = c("matches", "mismatches")
    final_tbl <- comb_tbl %>%
        gather(levels, key="tax_level", value="value") %>%
        select_at(.vars=c("tax_level", "value", "type"))
    final_tbl$value = final_tbl$value / nrow(db1) * 100
    return(final_tbl)
}


make_bar_plot <- function(data, title) {
    ggbarplot(
        data,
        x="tax_level",
        y="value",
        fill="type",
        color="type",
        label=TRUE,
        lab.pos="in",
        title=title,
        xlab="Taxonomy level",
        ylab="% of Mismatches",
        palette = c("#00AFBB", "#FC4E07"),
        #palette="Paired"
    ) +
    theme(axis.text.x=element_text(angle=30, hjust=1))
}

# Importing data
gg <- tidy_up_data("fmt_gg.csv", notu)
silva <- tidy_up_data("fmt_silva.csv", notu)
ncbi <- tidy_up_data("fmt_ncbi.csv", notu)

# Combinations
gg_silva <- combine_data(gg, silva)
gg_ncbi <- combine_data(gg, ncbi)
ncbi_silva <- combine_data(ncbi, silva)

gg_silva_plot <- make_bar_plot(gg_silva, "GreenGenes vs. SILVA")
gg_ncbi_plot <- make_bar_plot(gg_ncbi, "GreenGenes vs. NCBI")
ncbi_silva_plot <- make_bar_plot(ncbi_silva, "NCBI vs. SILVA")

combined_plot <- ggarrange(gg_silva_plot, gg_ncbi_plot, ncbi_silva_plot, nrow=1, ncol=3, common.legend=TRUE, legend="right")
annotate_figure(combined_plot, fig.lab="B", fig.lab.pos="top.left", fig.lab.size=20)

ggsave("figure4b.pdf", width=11, height=3.5)

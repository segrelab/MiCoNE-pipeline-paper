#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)
library(ggpubr)
library(ggalluvial)
library(ggrepel)

# inputs
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    data_folder <- "../../data/figure4/output/moving_pictures/"
    mock_folder <- "../../data/figure4/output/"
    output_folder <- "../../figures/"
} else if (length(args) == 3) {
    data_folder <- args[1]
    mock_folder <- args[2]
    output_folder <- args[3]
} else {
    stop("Required number of arguments must equal 3")
}
gg_csv <- paste0(data_folder, "naive_bayes(gg_13_8_99).csv")
silva_csv <- paste0(data_folder, "naive_bayes(silva_138_99).csv")
ncbi_csv <- paste0(data_folder, "blast(ncbi).csv")
mock4_braycurtis_csv <- paste0(mock_folder, "mock4/input_braycurtis.csv")
mock12_braycurtis_csv <- paste0(mock_folder, "mock12/input_braycurtis.csv")
mock16_braycurtis_csv <- paste0(mock_folder, "mock16/input_braycurtis.csv")
output_file <- paste0(output_folder, "figure4.pdf")
output_file_a <- paste0(output_folder, "figure4a.pdf")
output_file_b <- paste0(output_folder, "figure4b.pdf")
output_file_c <- paste0(output_folder, "figure4c.pdf")

################################################################################
# Figure 4a
################################################################################
# FIXME: Combine all the genus in all the files so that you get full legend
notu <- 50

# FIXME: This doesn't work all files get same values
read_data <- function(data_file, n) {
    raw_df <- read.csv(data_file, header = TRUE, sep = ",", na.strings = "")[1:n, ]
    # df <- aggregate(Abundance ~ Genus, raw_df, sum)
    # df
    raw_df
}

gg <- read_data(gg_csv, notu)
silva <- read_data(silva_csv, notu)
ncbi <- read_data(ncbi_csv, notu)

make_alluvial_plot <- function(db_data, title) {
    genus_factors <- levels(factor(db_data$Genus))
    n_genus <- length(genus_factors)
    palette <- get_palette(, n_genus)
    palette[n_genus] <- "#d3d3d3"
    alluvial_plot <- ggplot(data = db_data, aes(axis1 = OTU, axis2 = Genus, y = Abundance)) +
        scale_x_discrete(limits = c("OTU", "Genus"), expand = c(.1, .05)) +
        xlab("Tax") +
        geom_alluvium(aes(fill = Genus), width = 1 / 12) +
        geom_stratum(width = 1 / 4, aes(fill = Genus)) +
        scale_fill_manual(values = palette) +
        scale_linetype_manual(values = c("blank", "solid")) +
        # geom_text_repel(aes(label=Genus), stat="stratum", size=2, direction="y", nudge_x=0.5) +
        ggtitle(title) +
        theme_pubr() +
        theme(plot.title = element_text(hjust = 0.5), axis.line.x = element_blank(), axis.title.x = element_blank())
}


gg_plot <- make_alluvial_plot(gg, "GreenGenes")
silva_plot <- make_alluvial_plot(silva, "SILVA")
ncbi_plot <- make_alluvial_plot(ncbi, "NCBI")

gg$OTU <- gg$empty
gg_plot <- gg_plot #+
# geom_text_repel(stat="stratum", label.strata=TRUE, data=gg[,c("OTU", "Genus", "Abundance")], nudge_x=1)

silva$OTU <- silva$empty
silva_plot <- silva_plot #+
# geom_text_repel(stat="stratum", label.strata=TRUE, data=silva[,c("OTU", "Genus", "Abundance")], nudge_x=1)

ncbi$OTU <- ncbi$empty
ncbi_plot <- ncbi_plot #+
# geom_text_repel(stat="stratum", label.strata=TRUE, data=ncbi[,c("OTU", "Genus", "Abundance")], nudge_x=1)

final_plot_a <- ggarrange(
    gg_plot,
    silva_plot + rremove("y.axis") + rremove("y.text") + rremove("y.ticks") + rremove("y.title"),
    ncbi_plot + rremove("y.axis") + rremove("y.text") + rremove("y.ticks") + rremove("y.title"),
    nrow = 1,
    ncol = 3,
    common.legend = TRUE,
    legend = "right"
)
annotate_figure(final_plot_a, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)
ggsave(output_file_a, width = 11, height = 8.5)


################################################################################
# Figure 4b
################################################################################
# Parameters
notu <- 50
levels <- c("Phylum", "Class", "Order", "Family", "Genus", "Species")


tidy_up_data <- function(db_file, notu) {
    db_data <- read_csv(db_file)[1:notu, ]
    for (i in 1:length(levels)) {
        cols <- levels[1:i]
        db_data[levels[i]] <- apply(db_data[, cols], 1, paste, collapse = "-")
    }
    return(db_data)
}

combine_data <- function(db1, db2) {
    comb_tbl <- as_tibble(
        rbind(t(colSums(db1 == db2)), t(colSums(db1 != db2)))
    )
    comb_tbl$type <- c("matches", "mismatches")
    final_tbl <- comb_tbl %>%
        gather(levels, key = "tax_level", value = "value") %>%
        select_at(.vars = c("tax_level", "value", "type"))
    # final_tbl$value = final_tbl$value / nrow(db1) * 100
    # if we want to display the numbers instead
    final_tbl$value <- final_tbl$value
    return(final_tbl)
}


make_bar_plot <- function(data, title) {
    ggbarplot(
        data,
        x = "tax_level",
        y = "value",
        fill = "type",
        color = "type",
        label = TRUE,
        lab.pos = "in",
        title = title,
        xlab = "Taxonomy level",
        ylab = "% of Mismatches",
        palette = c("#00AFBB", "#FC4E07"),
        # palette="Paired"
    ) +
        theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# Combinations
gg_silva <- combine_data(gg, silva)
gg_ncbi <- combine_data(gg, ncbi)
ncbi_silva <- combine_data(ncbi, silva)

gg_silva_plot <- make_bar_plot(gg_silva, "GreenGenes vs. SILVA")
gg_ncbi_plot <- make_bar_plot(gg_ncbi, "GreenGenes vs. NCBI")
ncbi_silva_plot <- make_bar_plot(ncbi_silva, "NCBI vs. SILVA")

combined_plot_b <- ggarrange(
    gg_silva_plot, gg_ncbi_plot, ncbi_silva_plot,
    nrow = 1, ncol = 3, common.legend = TRUE, legend = "right"
)
annotate_figure(combined_plot_b, fig.lab = "B", fig.lab.pos = "top.left", fig.lab.size = 20)
ggsave(output_file_b, width = 11, height = 3.5)


################################################################################
# Figure 4c
################################################################################
levels <- c("Family", "Genus", "Species")

tidy_up_data <- function(data_file, name) {
    data <- read_csv(data_file)
    data$dataset <- rep(name, nrow(data))
    data$tax_level <- factor(data$tax_level, levels = levels)
    return(data)
}


make_dot_plot <- function(braycurtis_data) {
    add_summary(
        ggstripchart(
            braycurtis_data,
            x = "database",
            y = "braycurtis",
            color = "dataset",
            xlab = "database",
            ylab = "Braycurtis dissimilarity",
            ylim = c(0, 1),
            size = 3,
            add = "jitter",
        ) +
            theme(
                plot.title = element_text(hjust = 0.5),
            ),
        fun = "mean_sd"
    )
}


mock4_data <- tidy_up_data(mock4_braycurtis_csv, "mock4")
mock12_data <- tidy_up_data(mock12_braycurtis_csv, "mock12")
mock16_data <- tidy_up_data(mock16_braycurtis_csv, "mock16")

mock_data <- rbind(mock4_data, mock12_data, mock16_data)
dot_plot <- make_dot_plot(mock_data)
dot_plot_facet_c <- facet(dot_plot, facet.by = "tax_level")
annotate_figure(dot_plot_facet_c, fig.lab = "C", fig.lab.pos = "top.left", fig.lab.size = 20)
ggsave(output_file_c, width = 11, height = 5)



################################################################################
# Combine figures
ggarrange(final_plot_a, combined_plot_b, dot_plot_facet_c, nrow = 3, ncol = 1)
ggsave(output_file, width = 11, height = 16)

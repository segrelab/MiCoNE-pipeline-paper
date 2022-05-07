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
otu_csv <- paste0(data_folder, "otu.csv")
gg_csv <- paste0(data_folder, "naive_bayes(gg_13_8_99).csv")
silva_csv <- paste0(data_folder, "naive_bayes(silva_138_99).csv")
ncbi_csv <- paste0(data_folder, "blast(ncbi).csv")
gg_silva_csv <- paste0(data_folder, "gg_silva.csv")
gg_ncbi_csv <- paste0(data_folder, "gg_ncbi.csv")
ncbi_silva_csv <- paste0(data_folder, "ncbi_silva.csv")
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
notu <- 50

read_data <- function(data_file, n) {
    raw_df <- read.csv(data_file, header = TRUE, sep = ",", na.strings = "")[1:n, ]
    # df <- aggregate(Abundance ~ Genus, raw_df, sum)
    # df
    raw_df
}

# otu <- read_data(otu_csv, notu)
# otu$database <- "OTU"
gg <- read_data(gg_csv, notu)
gg$database <- "NaiveBayes(GG)"
silva <- read_data(silva_csv, notu)
silva$database <- "NaiveBayes(SILVA)"
ncbi <- read_data(ncbi_csv, notu)
ncbi$database <- "BLAST(NCBI)"
combined <- rbind(gg, silva, ncbi)
# combined <- rbind(otu, gg, silva, ncbi)

make_alluvial_plot2 <- function(db_data, title) {
    genus_factors <- levels(factor(db_data$Genus))
    n_genus <- length(genus_factors)
    palette <- get_palette(, n_genus)
    alluvial_plot <- ggplot(db_data, aes(x = database, y = Abundance, stratum = Genus, alluvium = OTU, fill = Genus)) +
        stat_alluvium(geom = "flow", lode.guidance = "forward") +
        stat_stratum() +
        scale_fill_manual(values = palette) +
        geom_text_repel(aes(label = Genus), stat = "stratum", size = 2, direction = "y", nudge_x = 0.5) +
        ggtitle(title) +
        theme_pubr() +
        theme(
            text = element_text(size = 15),
            legend.position = "none",
        )
}


gg_n_genus <- length(unique(gg$Genus))
silva_n_genus <- length(unique(silva$Genus))
ncbi_n_genus <- length(unique(ncbi$Genus))

combined_plot <- make_alluvial_plot2(combined, paste("NaiveBayes(GG)=", gg_n_genus, ", NaiveBayes(SILVA)=", silva_n_genus, ", BLAST(NCBI)=", ncbi_n_genus))

final_plot_a <- ggarrange(combined_plot, nrow = 1, ncol = 1, common.legend = FALSE)
annotate_figure(final_plot_a, fig.lab = "A", fig.lab.pos = "top.left", fig.lab.size = 20)
ggsave(output_file_a, width = 11, height = 10)


################################################################################
# Figure 4b
################################################################################
# Parameters
notu <- 50
levels <- c("Phylum", "Class", "Order", "Family", "Genus", "Species")

read_paired_data <- function(data_file) {
    raw_df <- read.csv(data_file, header = TRUE, sep = ",", na.strings = "")
    raw_df
}


make_bar_plot <- function(data, title) {
    ggbarplot(
        data,
        x = "tax_level",
        y = "value",
        fill = "assignment",
        color = "assignment",
        label = TRUE,
        lab.pos = "in",
        title = title,
        xlab = "Taxonomy level",
        ylab = "Number of Assignments",
        palette = c("#00AFBB", "#FC4E07"),
        # palette="Paired"
    ) +
        theme(
            text = element_text(size = 15),
            # plot.title = element_text(size = 10),
            axis.text.x = element_text(angle = 30, hjust = 1)
        )
}

# Combinations
gg_silva <- read_paired_data(gg_silva_csv)
gg_ncbi <- read_paired_data(gg_ncbi_csv)
ncbi_silva <- read_paired_data(ncbi_silva_csv)

gg_silva_plot <- make_bar_plot(gg_silva, "GG vs. SILVA")
gg_ncbi_plot <- make_bar_plot(gg_ncbi, "GG vs. NCBI")
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
                text = element_text(size = 15),
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
ggarrange(final_plot_a, combined_plot_b, dot_plot_facet_c, nrow = 3, ncol = 1, heights = c(2, 1, 1))
ggsave(output_file, width = 11, height = 16)

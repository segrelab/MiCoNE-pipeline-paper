#!/usr/bin/env Rscript

library(ggalluvial)
library(ggrepel)
library(ggplot2)
library(ggpubr)


# TODO: FIXME: Combine all the genus in all the files so that you get full legend
notu <- 50

# FIXME: This doesn't work all files get same values
read_data <- function(data_file, n) {
    raw_df <- read.csv(data_file, header=TRUE, sep=",", na.strings="")[1:n,]
    # df <- aggregate(Abundance ~ Genus, raw_df, sum)
    # df
    raw_df
}

gg <- read_data("../../data/figure4/output/moving_pictures/gg.csv", notu)
silva <- read_data("../../data/figure4/output/moving_pictures/silva.csv", notu)
ncbi <- read_data("../../data/figure4/output/moving_pictures/ncbi.csv", notu)

make_alluvial_plot <- function(db_data, title) {
    genus_factors <- levels(factor(db_data$Genus))
    n_genus <- length(genus_factors)
    palette <- get_palette(, n_genus)
    palette[n_genus] <- "#d3d3d3"
    alluvial_plot <- ggplot(data=db_data, aes(axis1=OTU, axis2=Genus,  y=Abundance)) +
        scale_x_discrete(limits=c("OTU", "Genus"), expand=c(.1, .05)) +
        xlab("Tax") +
        geom_alluvium(aes(fill=Genus), width=1/12) +
        geom_stratum(width=1/4, aes(fill=Genus)) +
        scale_fill_manual(values=palette) +
        scale_linetype_manual(values=c("blank", "solid")) +
        # geom_text_repel(aes(label=Genus), stat="stratum", size=2, direction="y", nudge_x=0.5) +
        ggtitle(title) +
        theme_pubr() +
        theme(plot.title=element_text(hjust=0.5), axis.line.x=element_blank(), axis.title.x=element_blank())
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

final_plot <- ggarrange(
    gg_plot,
    silva_plot + rremove("y.axis") + rremove("y.text") + rremove("y.ticks") + rremove("y.title"),
    ncbi_plot + rremove("y.axis") + rremove("y.text") + rremove("y.ticks") + rremove("y.title"),
    nrow=1,
    ncol=3,
    common.legend=TRUE,
    legend="right"
)
annotate_figure(final_plot, fig.lab="A", fig.lab.pos="top.left", fig.lab.size=20)

ggsave("figure4a.pdf", width=11, height=8.5)

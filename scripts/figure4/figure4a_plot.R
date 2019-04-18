#!/usr/bin/env Rscript

library(ggrepel)
library(ggplot2)
library(ggpubr)


gg <- read.csv("gg.csv", header=TRUE, sep=",", na.strings="")
silva <- read.csv("silva.csv", header=TRUE, sep=",", na.strings="")
ncbi <- read.csv("ncbi.csv", header=TRUE, sep=",", na.strings="")


gg_plot <- ggplot(data=gg, aes(axis1=OTU, axis2=Genus,  y=Abundance)) +
    scale_x_discrete(limits=c("OTU", "Genus"), expand=c(.1, .05)) +
    xlab("Tax") +
    geom_alluvium(aes(fill=Genus), width=1/12) +
    geom_stratum(width=1/4, aes(fill=Genus)) +
    scale_linetype_manual(values=c("blank", "solid")) +
    # geom_text_repel(aes(label=Genus), stat="stratum", size=2, direction="y", nudge_x=0.5) +
    ggtitle("GreenGenes") +
    theme_pubr() +
    theme(plot.title=element_text(hjust=0.5), axis.line.x=element_blank(), axis.title.x=element_blank())

silva_plot <- ggplot(data=silva, aes(axis1=OTU, axis2=Genus,  y=Abundance)) +
    scale_x_discrete(limits=c("OTU", "Genus"), expand=c(.1, .05)) +
    xlab("Tax") +
    geom_alluvium(aes(fill=Genus), width=1/12) +
    geom_stratum(width=1/4, aes(fill=Genus)) +
    scale_linetype_manual(values=c("blank", "solid")) +
    # geom_text_repel(aes(label=Genus), stat="stratum", size=2, direction="y", nudge_x=0.5) +
    ggtitle("SILVA") +
    theme_pubr() +
    theme(plot.title=element_text(hjust=0.5), axis.line.x=element_blank(), axis.title.x=element_blank())

ncbi_plot <- ggplot(data=ncbi, aes(axis1=OTU, axis2=Genus,  y=Abundance)) +
    scale_x_discrete(limits=c("OTU", "Genus"), expand=c(.1, .05)) +
    xlab("Tax") +
    geom_alluvium(aes(fill=Genus), width=1/12) +
    geom_stratum(width=1/4, aes(fill=Genus)) +
    scale_linetype_manual(values=c("blank", "solid")) +
    # geom_text_repel(aes(label=Genus), stat="stratum", size=2, direction="y", nudge_x=0.5) +
    ggtitle("NCBI") +
    theme_pubr() +
    theme(plot.title=element_text(hjust=0.5), axis.line.x=element_blank(), axis.title.x=element_blank())


gg$OTU <- gg$empty
gg_plot <- gg_plot +
    geom_text_repel(stat="stratum", label.strata=TRUE, data=gg[,c("OTU", "Genus", "Abundance")], nudge_x=1)

silva$OTU <- silva$empty
silva_plot <- silva_plot +
    geom_text_repel(stat="stratum", label.strata=TRUE, data=silva[,c("OTU", "Genus", "Abundance")], nudge_x=1)

ncbi$OTU <- ncbi$empty
ncbi_plot <- ncbi_plot +
    geom_text_repel(stat="stratum", label.strata=TRUE, data=ncbi[,c("OTU", "Genus", "Abundance")], nudge_x=1)

ggarrange(
    gg_plot,
    silva_plot + rremove("y.axis") + rremove("y.text") + rremove("y.ticks") + rremove("y.title"),
    ncbi_plot + rremove("y.axis") + rremove("y.text") + rremove("y.ticks") + rremove("y.title"),
    nrow=1,
    ncol=3,
    common.legend=TRUE,
    legend="bottom"
)

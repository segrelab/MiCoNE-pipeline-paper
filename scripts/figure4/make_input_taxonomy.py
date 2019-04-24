#!/usr/bin/env python

import click
from ete3 import NCBITaxa
import pandas as pd

from mindpipe import Lineage

NCBI = NCBITaxa()
TAX_LEVELS = Lineage._fields
TAX_MAP = {
    "Kingdom": "superkingdom",
    "Phylum": "phylum",
    "Class": "class",
    "Order": "order",
    "Family": "family",
    "Genus": "genus",
    "Species": "species",
}


def get_lineage(species_name):
    taxid = NCBI.get_name_translator([species_name])[species_name][0]
    lineage_taxids = NCBI.get_lineage(taxid)
    lineage_names = NCBI.get_taxid_translator(lineage_taxids)
    lineage_ranks = {v: k for k, v in NCBI.get_rank(lineage_taxids).items()}
    lineage_dict = dict()
    for tax_level in TAX_LEVELS:
        try:
            rank_taxid = lineage_ranks[TAX_MAP[tax_level]]
            rank_name = lineage_names[rank_taxid]
            lineage_dict[tax_level] = rank_name
        except KeyError:
            if tax_level == "Genus":
                lineage_dict["Genus"] = species_name.split(" ")[0]
            elif tax_level == "Species":
                lineage_dict["Species"] = species_name
            else:
                print(f"Warning unknown {tax_level} for {species_name}")
                lineage_dict[tax_level] = ""
    return Lineage(**lineage_dict)


@click.command()
@click.option("--expected_tax", help="Location of the input file")
@click.option("--output_file", help="Location of the output file")
def main(expected_tax: str, output_file: str):
    tax_table = pd.read_csv(expected_tax, index_col=0, sep="\t")
    species = [" ".join(t.split("_")[:2]) for t in tax_table.index]
    lineages = map(get_lineage, species)
    lineage_data = [lineage.to_dict(level="Species") for lineage in lineages]
    lineage_table = pd.DataFrame(data=lineage_data, index=tax_table.index)
    lineage_table = lineage_table[list(TAX_LEVELS)]
    final_table = pd.concat([lineage_table, tax_table], axis=1)
    final_table.to_csv(output_file, sep=",", index=False)


if __name__ == "__main__":
    main()

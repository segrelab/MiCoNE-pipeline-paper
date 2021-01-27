#!/usr/bin/env python3

from collections import defaultdict
import pathlib

from Bio import SeqIO
import pandas as pd


def main(files):
    counts_dict = {}
    for file in files:
        key = file.stem
        counts_dict[key] = defaultdict(int)
        for record in SeqIO.parse(file, "fastq"):
            tax = record.id.split('-', 1)[0]
            counts_dict[key][tax] += 1
    counts_df = pd.DataFrame(counts_dict)
    counts_df.fillna(value=0.0, inplace=True)
    counts_df.index.name = "tax"
    counts_df.to_csv("../real_composition/art/counts.csv")
    abund_df = counts_df / counts_df.sum(axis=0)
    abund_df.to_csv("../real_composition/art/abundances.csv")
    comp_df = abund_df * 100
    comp_df.to_csv("../real_composition/art/composition.csv")


if __name__ == "__main__":
    FILES = pathlib.Path("../seqs/art/original/").glob("*.fq")
    main(FILES)

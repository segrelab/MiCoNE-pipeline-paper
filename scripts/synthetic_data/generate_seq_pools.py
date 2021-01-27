#!/usr/bin/env python3

from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import pandas as pd
import random

ALPHABET = {'A', 'T', 'G', 'C'}


def mutate(record: SeqRecord, id_suffix: str, rate: float = 0.02) -> SeqRecord:
    new_id = f"{record.id}-{id_suffix}"
    sequence = record.seq
    change = lambda x: random.choice(list(ALPHABET - {x}))
    mutated_seq = ''.join([change(s) if random.random() <= rate else s for s in sequence])
    return SeqRecord(seq=Seq(mutated_seq), id=new_id, name='', description='')


def main(reference_file, abundance_file, read_depth, out_folder) -> None:
    abundances = pd.read_csv(abundance_file, index_col=0)
    counts = (abundances * read_depth / 100).astype(int)
    seq_dict = {}
    for record in SeqIO.parse(reference_file, "fasta"):
        seq_dict[record.id] = record
    for sample_name, sample_counts in counts.items():
        print(f"Processing {sample_name}")
        seq_list = []
        valid_counts = sample_counts[sample_counts > 0]
        for tax_name, count in valid_counts.items():
            tax_seq = seq_dict[tax_name]
            for i in range(count):
                seq_list.append(mutate(tax_seq, str(i)))
        fname = out_folder + sample_name + ".fasta"
        SeqIO.write(seq_list, fname, "fasta")


if __name__ == "__main__":
    REFERENCE = "../inputs/references.fasta"
    ABUNDANCE = "../inputs/abundance_file.txt"
    DEPTH = 5000
    OUT_FOLDER = "../outputs/seq_pools/"
    main(REFERENCE, ABUNDANCE, DEPTH, OUT_FOLDER)

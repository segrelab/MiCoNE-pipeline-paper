#!/usr/bin/env python3

# Use qiime2 env for this script

import pathlib
from itertools import chain, combinations
from subprocess import call

from biom import load_table
from Bio import SeqIO
import click


def parse_biom(biom_file, threshold=10):
    otu = load_table(str(biom_file))
    df = otu.to_dataframe(otu)
    otu_sums = df.sum(axis=1)
    return set(otu_sums[otu_sums > threshold].index)


def merge_seqs(file1, file2):
    filt_seqs1 = parse_biom(file1.parent / "otu_table.biom")
    filt_seqs2 = parse_biom(file2.parent / "otu_table.biom")
    filt_seqs = filt_seqs1.union(filt_seqs2)
    seqs1 = SeqIO.parse(str(file1), "fasta")
    seqs2 = SeqIO.parse(str(file2), "fasta")
    seqhash_set = set()
    seq_list = []
    for seq in chain(seqs1, seqs2):
        if seq.id not in seqhash_set:
            if seq.id not in filt_seqs:
                continue
            seq.name = ""
            seq.description = ""
            seq_list.append(seq)
            seqhash_set.add(seq.id)
    return seq_list


def get_artifact(fasta):
    artifact = fasta.parent / (fasta.stem + ".qza")
    print("Importing {}".format(fasta))
    cmd = """
    qiime tools import \
        --input-path '{fasta}' \
        --output-path '{artifact}' \
        --type 'FeatureData[Sequence]'
    """.format(
        fasta=fasta, artifact=artifact
    )
    call(cmd, shell=True)
    return artifact


def get_tree(artifact):
    parentDir = artifact.parent
    fname = artifact.stem
    print("Calculating tree for {}".format(artifact))
    cmd = """
    qiime phylogeny align-to-tree-mafft-fasttree \
      --i-sequences '{artifact}' \
      --o-alignment '{parent}/{fname}_aligned-sequences.qza' \
      --o-masked-alignment '{parent}/{fname}_masked-aligned-sequences.qza' \
      --o-tree '{parent}/{fname}_unrooted-tree.qza' \
      --o-rooted-tree '{parent}/{fname}_rooted-tree.qza' \
      --p-n-threads 4 \
      --quiet
    """.format(
        artifact=artifact, parent=parentDir, fname=fname
    )
    call(cmd, shell=True)
    return parentDir / (fname + "_rooted-tree.qza")


def export_tree(tree):
    folder = tree.parent / tree.stem
    print("Exporting tree {}".format(tree))
    cmd = "qiime tools export --input-path '{tree}' --output-path '{folder}'".format(
        tree=tree, folder=folder
    )
    call(cmd, shell=True)
    return folder


@click.command()
@click.option("--base_dir", help="Base directory of dataset", type=pathlib.Path)
@click.option(
    "--output_dir", help="Directory to store the resulting trees", type=pathlib.Path
)
def main(
    base_dir: pathlib.Path,
    output_dir: pathlib.Path,
):
    if not output_dir.exists():
        raise ValueError("{} does not exist".format(output_dir))
    files = []
    methods = [d for d in base_dir.iterdir() if d.is_dir()]
    for method in methods:
        met_files = method.glob("**/rep_seqs.fasta")
        files.extend(met_files)
    print(files)
    for file1, file2 in combinations(files, r=2):
        method1 = file1.parent.parent.name
        method2 = file2.parent.parent.name
        seqs = merge_seqs(file1, file2)
        tree_dir = output_dir / f"trees/{method1}-{method2}"
        print(f"Evaluating tree {tree_dir.name}")
        tree_dir.mkdir(parents=True, exist_ok=True)
        fname = tree_dir / "seqs.fasta"
        SeqIO.write(seqs, str(fname), "fasta")
        artifact = get_artifact(fname)
        tree = get_tree(artifact)
        export_tree(tree)


if __name__ == "__main__":
    main()

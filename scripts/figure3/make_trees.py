#!/usr/bin/env python3

# Use qiime2 env for this script

import pathlib
from itertools import chain, combinations
from subprocess import call
import sys

from Bio import SeqIO
import click


METHODS = ["de_novo", "closed_reference", "open_reference", "dada2", "deblur"]
CHIMERA_MAP = {
    "de_novo": "uchime.3",
    "closed_reference": "uchime.2",
    "open_reference": "uchime.1",
    "dada2": "uchime.4",
    "deblur": "uchime.5",
    "input": "input.1",
}


def merge_seqs(file1, file2):
    seqs1 = SeqIO.parse(str(file1), "fasta")
    seqs2 = SeqIO.parse(str(file2), "fasta")
    seqhash_set = set()
    seq_list = []
    for seq in chain(seqs1, seqs2):
        if seq.id not in seqhash_set:
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
        --input-path {fasta} \
        --output-path {artifact} \
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
      --i-sequences {artifact} \
      --o-alignment {parent}/{fname}_aligned-sequences.qza \
      --o-masked-alignment {parent}/{fname}_masked-aligned-sequences.qza \
      --o-tree {parent}/{fname}_unrooted-tree.qza \
      --o-rooted-tree {parent}/{fname}_rooted-tree.qza \
      --p-n-threads 0 \
      --quiet
    """.format(
        artifact=artifact, parent=parentDir, fname=fname
    )
    call(cmd, shell=True)
    return parentDir / (fname + "_rooted-tree.qza")


def export_tree(tree):
    folder = tree.parent / tree.stem
    print("Exporting tree {}".format(tree))
    cmd = "qiime tools export --input-path {tree} --output-path {folder}".format(
        tree=tree, folder=folder
    )
    call(cmd, shell=True)
    return folder


@click.command()
@click.option("--base_dir", help="Base directory of dataset")
@click.option("--use_input", default=False, type=bool, help="Flag to use input profile")
@click.option(
    "--remove_chimeric", default=False, type=bool, help="Flag to use non-chimeric data"
)
def main(base_dir, use_input=False, remove_chimeric=False):
    base_path = pathlib.Path(base_dir)
    tree_dir = base_path / "tree"
    if not tree_dir.exists():
        raise ValueError("{} does not exist".format(tree_dir))
    files = []
    if use_input:
        methods = METHODS + ["input"]
    else:
        methods = METHODS
    if remove_chimeric:
        methods_full = [CHIMERA_MAP[m] for m in methods]
    else:
        methods_full = ["{}.1".format(m) for m in methods]
    for method in methods_full:
        met_files = list((base_path / method).glob("**/rep_seqs.fasta"))
        files.extend(met_files)
    for file1, file2 in combinations(files, r=2):
        method1_full = file1.parent.parent.name
        method1 = methods[methods_full.index(method1_full)]
        method2_full = file2.parent.parent.name
        method2 = methods[methods_full.index(method2_full)]
        seqs = merge_seqs(file1, file2)
        if remove_chimeric:
            curr_dir = base_path / "tree/non_chimeric" / (method1 + "-" + method2)
        else:
            curr_dir = base_path / "tree/chimeric" / (method1 + "-" + method2)
        try:
            curr_dir.mkdir(parents=True)
            fname = curr_dir / "seqs.fasta"
            SeqIO.write(seqs, str(fname), "fasta")
            artifact = get_artifact(fname)
            tree = get_tree(artifact)
            export_tree(tree)
        except:
            pass


if __name__ == "__main__":
    main()

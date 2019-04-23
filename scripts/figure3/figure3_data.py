#!/usr/bin/env python3

import pathlib
from typing import List

from biom import load_table
import click
import numpy as np
import pandas as pd
from skbio.tree import TreeNode
from skbio.diversity.beta import weighted_unifrac, unweighted_unifrac


def get_files(path_glob: str) -> List[pathlib.Path]:
    base_dir, glob = path_glob.split("*", 1)
    glob = "*" + glob
    base_path = pathlib.Path(base_dir)
    return list(base_path.glob(glob))


def get_vectors(otu_1: pd.DataFrame, otu_2: pd.DataFrame, threshold: int):
    assert all([col in otu_2.columns for col in otu_1.columns])
    for col in otu_1.columns:
        otu_1_col, otu_2_col = otu_1[[col]], otu_2[[col]]
        otu_1_col = otu_1_col[otu_1_col[col] > threshold]
        otu_2_col = otu_2_col[otu_2_col[col] > threshold]
        otu_1_col.columns = ["1"]
        otu_2_col.columns = ["2"]
        joint_df = otu_1_col.join(otu_2_col, how="outer")
        joint_df.fillna(0.0, inplace=True)
        otu_ids = list(joint_df.index)
        u = list(joint_df["1"])
        v = list(joint_df["2"])
        yield u, v, otu_ids, col


def get_unifrac(
    otu_file_1: pathlib.Path,
    otu_file_2: pathlib.Path,
    tree_file: pathlib.Path,
    weighted: bool,
    threshold: int,
):
    otu_1 = load_table(str(otu_file_1)).to_dataframe(dense=True)
    otu_2 = load_table(str(otu_file_2)).to_dataframe(dense=True)
    tree = TreeNode.read(str(tree_file))
    unifrac_data = dict()
    for u, v, otu_ids, col in get_vectors(otu_1, otu_2, threshold):
        if weighted:
            unifrac_value = weighted_unifrac(
                u, v, otu_ids, tree, normalized=True, validate=True
            )
        else:
            unifrac_value = unweighted_unifrac(u, v, otu_ids, tree, validate=True)
        unifrac_data[col] = unifrac_value
    return pd.Series(unifrac_data)


@click.command()
@click.option("--trees", help="Path to the tree files (must contain glob)")
@click.option("--otus", help="Path to the OTU files (must contain glob)")
@click.option(
    "--weighted",
    default=True,
    type=bool,
    help="Flag to perform either weighted or unweighted unifrac",
)
@click.option("--threshold", default=3, type=int, help="Threshold for sequence count")
@click.option("--output", default=".", help="The path to the output directory")
def main(trees: str, otus: str, weighted: bool, threshold: int, output: str):
    output_path = pathlib.Path(output)
    assert output_path.exists()
    dataset_name = pathlib.Path(trees).parent.stem
    tree_files = get_files(trees)
    otu_files = get_files(otus)
    otu_files_map = {otu_file.stem: otu_file for otu_file in otu_files}
    data = []
    for tree_file in tree_files:
        method_1, method_2 = tree_file.stem.split("-")
        otu_file_1, otu_file_2 = otu_files_map[method_1], otu_files_map[method_2]
        unifrac_data = get_unifrac(
            otu_file_1, otu_file_2, tree_file, weighted=weighted, threshold=threshold
        )
        for col in unifrac_data.index:
            data.append(
                {
                    "method1": method_1,
                    "method2": method_2,
                    "unifrac": unifrac_data[col],
                    "sample": col,
                }
            )
            data.append(
                {
                    "method2": method_1,
                    "method1": method_2,
                    "unifrac": unifrac_data[col],
                    "sample": col,
                }
            )
            data.append(
                {
                    "method1": method_1,
                    "method2": method_1,
                    "unifrac": np.nan,
                    "sample": col,
                }
            )
            data.append(
                {
                    "method1": method_2,
                    "method2": method_2,
                    "unifrac": np.nan,
                    "sample": col,
                }
            )
    unifrac_df = pd.DataFrame(data)
    if weighted:
        unifrac_df.to_csv(
            output_path / f"{dataset_name}_weighted_unifrac.csv", index=False
        )
    else:
        unifrac_df.to_csv(
            output_path / f"{dataset_name}_unweighted_unifrac.csv", index=False
        )


if __name__ == "__main__":
    main()

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
    samples_1 = set(otu_1.columns)
    samples_2 = set(otu_2.columns)
    removed_samples = len(samples_1 - samples_2) + len(samples_2 - samples_1)
    print(f"Warning {removed_samples} samples have been removed")
    common_samples = samples_1 & samples_2
    for col in common_samples:
        otu_1_col, otu_2_col = otu_1[[col]], otu_2[[col]]
        otu_1_col.loc[otu_1_col[col] <= threshold, :] = 0
        otu_2_col.loc[otu_2_col[col] <= threshold, :] = 0
        otu_1_col.columns = ["1"]
        otu_2_col.columns = ["2"]
        joint_df = otu_1_col.join(otu_2_col, how="outer")
        joint_df.fillna(0, inplace=True)
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
    return pd.Series(unifrac_data), otu_1.shape[0], otu_2.shape[0]


def abbr_name(method: str) -> str:
    """Replace method name with abbreviation"""
    if method.startswith("closed_reference"):
        return "CR"
    if method.startswith("open_reference"):
        return "OR"
    if method.startswith("de_novo"):
        return "DN"
    if method.startswith("dada2"):
        return "D2"
    if method.startswith("deblur"):
        return "DB"


@click.command()
@click.option("--trees", help="Path to the tree files (must contain glob)")
@click.option("--otus", help="Path to the OTU files (must contain glob)")
@click.option(
    "--weighted",
    default=True,
    type=bool,
    help="Flag to perform either weighted or unweighted unifrac",
)
@click.option(
    "--asv", default=True, type=bool, help="To display ASV along with method name"
)
@click.option("--threshold", default=10, type=int, help="Threshold for sequence count")
@click.option("--output", default=".", help="The path to the output directory")
def main(trees: str, otus: str, weighted: bool, asv: bool, threshold: int, output: str):
    output_path = pathlib.Path(output)
    assert output_path.exists()
    tree_files = get_files(trees)
    otu_files = get_files(otus)
    otu_files_map = {otu_file.parent.parent.stem: otu_file for otu_file in otu_files}
    data = []
    for tree_file in tree_files:
        method_1, method_2 = tree_file.parent.parent.stem.split("-")
        otu_file_1, otu_file_2 = otu_files_map[method_1], otu_files_map[method_2]
        print(f"Generating unifrac for {method_1} and {method_2}")
        unifrac_data, otu_count_1, otu_count_2 = get_unifrac(
            otu_file_1, otu_file_2, tree_file, weighted=weighted, threshold=threshold
        )
        abbr_1, abbr_2 = abbr_name(method_1), abbr_name(method_2)
        for col in unifrac_data.index:
            if asv:
                label_1 = f"{abbr_1} ({otu_count_1})"
                label_2 = f"{abbr_2} ({otu_count_2})"
            else:
                label_1 = f"{abbr_1}"
                label_2 = f"{abbr_2}"
            data.append(
                {
                    "method1": label_1,
                    "method2": label_2,
                    "unifrac": unifrac_data[col],
                    "sample": col,
                }
            )
            data.append(
                {
                    "method2": label_1,
                    "method1": label_2,
                    "unifrac": unifrac_data[col],
                    "sample": col,
                }
            )
            data.append(
                {
                    "method1": label_1,
                    "method2": label_1,
                    "unifrac": np.nan,
                    "sample": col,
                }
            )
            data.append(
                {
                    "method1": label_2,
                    "method2": label_2,
                    "unifrac": np.nan,
                    "sample": col,
                }
            )
    unifrac_df = pd.DataFrame(data)
    if weighted:
        unifrac_df.to_csv(output_path / f"threshold_weighted_unifrac.csv", index=False)
    else:
        unifrac_df.to_csv(
            output_path / f"threshold_unweighted_unifrac.csv", index=False
        )


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

import pathlib

from typing import List


from biom import load_table
import click
import pandas as pd
from scipy.spatial.distance import braycurtis


def get_vectors(
    input_table: pd.DataFrame,
    db_table: pd.DataFrame,
    level: str,
    samples: List[str],
    threshold: int,
):
    db_grouped = db_table[samples + [level]].groupby(by=level).sum()
    input_grouped = (
        input_table[samples + [level]].groupby(by=level).sum() * db_grouped.sum()
    )
    assert all([col in input_grouped.columns for col in db_grouped.columns])
    for col in input_grouped.columns:
        input_col, db_col = input_grouped[[col]], db_grouped[[col]]
        input_col = input_col[input_col[col] > threshold]
        db_col = db_col[db_col[col] > threshold]
        input_col.columns = ["input"]
        db_col.columns = ["db"]
        joint_df = input_col.join(db_col, how="outer")
        joint_df.fillna(0.0, inplace=True)
        otu_ids = list(joint_df.index)
        u = list(joint_df["input"])
        v = list(joint_df["db"])
        yield u, v, otu_ids, col


def get_braycurtis(
    input_file: pathlib.Path,
    db_file: pathlib.Path,
    db_name: str,
    level_str: str,
    threshold: int,
):
    levels = level_str.split(",")
    input_table = pd.read_csv(input_file)
    db_data = load_table(str(db_file))
    db_df = db_data.to_dataframe(dense=True)
    samples = list(db_df.columns)
    obs_metadata = db_data.metadata_to_dataframe(axis="observation")
    db_table = pd.concat([obs_metadata, db_df], axis=1)
    data = []
    print(f"Calculating braycurtis dissimilarity for {db_name}")
    for level in levels:
        for u, v, otu_ids, col in get_vectors(
            input_table, db_table, level, samples, threshold
        ):
            value = braycurtis(u, v)
            data.append(
                {
                    "database": db_name,
                    "sample": col,
                    "tax_level": level,
                    "braycurtis": value,
                }
            )
    return data


@click.command()
@click.option("--input_dir", help="Location of the input files")
@click.option(
    "--levels",
    default="Family,Genus,Species",
    help="Levels to be used to calculate braycurtis",
)
@click.option("--threshold", default=3, type=int, help="Threshold for the OTU count")
@click.option(
    "--output_dir",
    default=".",
    help="Directory where the output files are to be created",
)
def main(input_dir: str, levels: str, threshold: int, output_dir: str):
    input_path = pathlib.Path(input_dir)
    dataset_name = input_path.parent.stem
    output_path = pathlib.Path(output_dir)
    assert output_path.exists()
    input_file = input_path / "expected_taxonomy.csv"
    gg_file = list(input_path.glob("gg/**/otu_table_wtax.biom"))[0]
    silva_file = list(input_path.glob("silva/**/otu_table_wtax.biom"))[0]
    ncbi_file = list(input_path.glob("ncbi/**/otu_table_wtax.biom"))[0]
    gg_data = get_braycurtis(input_file, gg_file, "GreenGenes", levels, threshold)
    silva_data = get_braycurtis(input_file, silva_file, "SILVA", levels, threshold)
    ncbi_data = get_braycurtis(input_file, ncbi_file, "NCBI", levels, threshold)
    data = gg_data + silva_data + ncbi_data
    combined_df = pd.DataFrame(data=data)
    combined_df.to_csv(
        output_path / f"{dataset_name}_braycurtis.csv", sep=",", index=False
    )


if __name__ == "__main__":
    main()

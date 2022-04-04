#!/usr/bin/env python3

import pathlib

from biom import load_table
import click
from micone import Lineage
import pandas as pd


LEVELS = ["Phylum", "Class", "Order", "Family", "Genus", "Species"]


def create_tables(file_paths, notus, output_path):
    tables = dict()
    for file in file_paths:
        db_name = file.parent.parent.parent.stem
        otu = load_table(str(file))
        otu_df = otu.to_dataframe(dense=True)
        obs_metadata = otu.metadata_to_dataframe(axis="observation")
        obs_metadata["Abundance"] = otu_df.sum(axis=1)
        if notus < 0:
            notus = obs_metadata.shape[0]
        final_df = obs_metadata.sort_values(by="Abundance", ascending=False).iloc[
            :notus
        ]
        final_df.replace("", "unknown", inplace=True)
        final_df.index = range(1, notus + 1)
        final_df.index.name = "OTU"
        final_df["empty"] = [""] * notus
        tables[db_name] = final_df
    return tables


# Table headers for combined dataframes:
# tax_level, value, assignment(match/mismatch)
def get_mismatches(db1: pd.DataFrame, db2: pd.DataFrame) -> pd.DataFrame:
    db1_lin_df = db1.drop(["empty", "Abundance"], axis=1)
    db1_lineages = [Lineage(**record) for record in db1_lin_df.to_dict("records")]
    db2_lin_df = db2.drop(["empty", "Abundance"], axis=1)
    db2_lineages = [Lineage(**record) for record in db2_lin_df.to_dict("records")]
    matches = dict()
    mismatches = dict()
    data = []
    for level in LEVELS:
        matches[level] = 0
        mismatches[level] = 0
        for db1_lineage, db2_lineage in zip(db1_lineages, db2_lineages):
            db1_linstr = db1_lineage.get_superset(level)
            db2_linstr = db2_lineage.get_superset(level)
            if db1_linstr == db2_linstr:
                matches[level] += 1
            else:
                mismatches[level] += 1
        data.append(
            {"tax_level": level, "assignment": "matches", "value": matches[level]}
        )
        data.append(
            {"tax_level": level, "assignment": "mismatches", "value": mismatches[level]}
        )
    return pd.DataFrame(data)


@click.command()
@click.option(
    "--files", help="The list of biom files with taxonomy assignments containing a glob"
)
@click.option(
    "--notus", default=100, type=int, help="The number of OTUs to restrict to"
)
@click.option("--output", default=".", help="The path to the output directory")
def main(files: str, notus: int, output: str):
    output_path = pathlib.Path(output)
    assert output_path.exists()
    base_dir, glob = files.split("*", 1)
    glob = "*" + glob
    base_path = pathlib.Path(base_dir)
    file_paths = list(base_path.glob(glob))
    tables = create_tables(file_paths, notus, output_path)
    for db_name, df in tables.items():
        output_file = output_path / f"{db_name}.csv"
        print(f"Writing file {output_file}")
        df.to_csv(output_file, sep=",", index=True)
    gg_silva = get_mismatches(
        tables["naive_bayes(gg_13_8_99)"], tables["naive_bayes(silva_138_99)"]
    )
    output_file = output_path / f"gg_silva.csv"
    print(f"Writing file {output_file}")
    gg_silva.to_csv(output_file, sep=",")
    gg_ncbi = get_mismatches(tables["naive_bayes(gg_13_8_99)"], tables["blast(ncbi)"])
    output_file = output_path / f"gg_ncbi.csv"
    print(f"Writing file {output_file}")
    gg_ncbi.to_csv(output_file, sep=",")
    ncbi_silva = get_mismatches(
        tables["blast(ncbi)"], tables["naive_bayes(silva_138_99)"]
    )
    output_file = output_path / f"ncbi_silva.csv"
    print(f"Writing file {output_file}")
    ncbi_silva.to_csv(output_file, sep=",")


if __name__ == "__main__":
    main()

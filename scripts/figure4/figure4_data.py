#!/usr/bin/env python3

import pathlib

from biom import load_table
import click


def write_tables(file_paths, notus, output_path):
    for file in file_paths:
        db_name = file.stem
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
        final_df.to_csv(output_path / f"{db_name}.csv", sep=",", index=True)


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
    write_tables(file_paths, notus, output_path)


if __name__ == "__main__":
    main()

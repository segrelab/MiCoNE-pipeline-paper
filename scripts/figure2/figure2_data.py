#!/usr/bin/env python

import pathlib

import click
import networkx as nx


@click.command()
@click.option("--base_dir", help="The base directory of the pipeline run")
@click.option(
    "--output", default=".", help="The directory where the output file is to be stored"
)
def main(base_dir: str, output: str):
    base_path = pathlib.Path(base_dir)
    process_tree = nx.read_gml(base_path / "DAG.gml")
    # Read locations of the networks
    # Parse the combination of methods used to contruct the network
    # Merge all the networks so that we get an edge-weight vector for every combination (column)
    # NOTE: Pearson and Spearman will just create a lot of correlations. How to handle?
    # Save the combination dataframe as a csv file
    # Save edge-weight dataframe as a csv file


if __name__ == "__main__":
    main()

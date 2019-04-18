#!/usr/bin/env python3

import pathlib

import click
import networkx as nx
import numpy as np
import pandas as pd

from mindpipe import NetworkGroup, Lineage


def write_networks(file_paths, multigraph, color_key_level, output_path):
    combined_graph = nx.Graph()
    for file in file_paths:
        network = NetworkGroup.load_json(file)
        network_name = file.stem
        graph = network.graph
        if multigraph:
            G = nx.MultiGraph()
        else:
            G = nx.Graph()
        id_name_map = dict()
        for node, node_data in graph.nodes(data=True):
            name = node_data["name"]
            id_name_map[node] = name
            taxlevel = node_data["taxlevel"]
            colorkey = (
                Lineage.from_str(node_data["lineage"])
                .get_superset(color_key_level)
                .name[-1]
            )
            G.add_node(name, name=name, taxlevel=taxlevel, colorkey=colorkey)
            combined_graph.add_node(
                name, name=name, taxlevel=taxlevel, colorkey=colorkey
            )
        for source, target, edge_data in graph.edges(data=True):
            source_name, target_name = id_name_map[source], id_name_map[target]
            weight = edge_data["weight"]
            pvalue = edge_data["pvalue"]
            G.add_edge(source_name, target_name, weight=weight, pvalue=pvalue)
            combined_graph.add_edge(
                source_name, target_name, weight=weight, pvalue=pvalue
            )
        nx.write_gml(G, str(output_path / f"{network_name}.gml"))
    nx.write_gml(combined_graph, str(output_path / "combined.gml"))
    return list(combined_graph.nodes), list(combined_graph.edges)


@click.command()
@click.option("--files", help="The path to the network files containing a glob pattern")
@click.option(
    "--color_key_level",
    default="Family",
    help="The taxonomy level to be used as color key",
)
@click.option(
    "--multigraph",
    default=True,
    type=bool,
    help="Flag to switch between multigraph and graph",
)
@click.option("--output", default=".", help="The path to the output directory")
def main(files: str, color_key_level: str, multigraph, output: str):
    output_path = pathlib.Path(output)
    assert output_path.exists()
    base_dir, glob = files.split("*", 1)
    glob = "*" + glob
    base_path = pathlib.Path(base_dir)
    file_paths = list(base_path.glob(glob))
    nodes, edges = write_networks(file_paths, multigraph, color_key_level, output_path)


if __name__ == "__main__":
    main()

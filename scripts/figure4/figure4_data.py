#!/usr/bin/env python3

import pathlib

import click
import networkx as nx
import numpy as np
import pandas as pd

from micone import Network, Lineage


def write_networks(file_paths, multigraph, color_key_level, output_path):
    combined_graph = nx.Graph()
    for file in file_paths:
        network = Network.load_json(file)
        network_name = file.parent.parent.parent.stem
        print(f"Writing network for {network_name}")
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
    print("Writing the combined graph")
    nx.write_gml(combined_graph, str(output_path / "combined.gml"))
    return list(combined_graph.nodes), list(combined_graph.edges)


def write_node_matrix(file_paths, nodes, output_path):
    node_set = set(nodes)
    rows = list(node_set)
    cols = [f.parent.parent.parent.stem for f in file_paths]
    node_df = pd.DataFrame(
        data=np.zeros((len(rows), len(cols))), index=rows, columns=cols
    )
    for file in file_paths:
        network = Network.load_json(file)
        network_name = file.parent.parent.parent.stem
        graph = network.graph
        for node, ndata in graph.nodes(data=True):
            name = ndata["name"]
            for source, target, edata in graph.edges(node, data=True):
                node_df.loc[name, network_name] += abs(edata["weight"])
    final_df = node_df.loc[(node_df != 0).any(axis=1)]
    final_df.index.name = "Nodes"
    print("Writing node matrix")
    final_df.to_csv(output_path / "nmatrix.csv", sep=",", index=True)


def write_edge_matrix(file_paths, edges, output_path):
    edge_set = set()
    rows = []
    for source, target in edges:
        edge = frozenset([source, target])
        if edge not in edge_set:
            edge_set.add(edge)
            rows.append(f"{source}-{target}-pos")
            rows.append(f"{source}-{target}-neg")
    cols = [f.parent.parent.parent.stem for f in file_paths]
    edge_df = pd.DataFrame(
        data=np.zeros((len(rows), len(cols))), index=rows, columns=cols
    )
    for file in file_paths:
        network = Network.load_json(file)
        network_name = file.parent.parent.parent.stem
        graph = network.graph
        id_name_map = dict()
        for node, ndata in graph.nodes(data=True):
            id_name_map[node] = ndata["name"]
        for source, target, edata in graph.edges(data=True):
            source_name = id_name_map[source]
            target_name = id_name_map[target]
            assert frozenset([source_name, target_name]) in edge_set
            if edata["weight"] > 0:
                suffix = "pos"
            else:
                suffix = "neg"
            ename = f"{source_name}-{target_name}-{suffix}"
            if ename not in rows:
                ename = f"{target_name}-{source_name}-{suffix}"
            edge_df.loc[ename, network_name] = abs(edata["weight"])
    final_df = edge_df.loc[(edge_df != 0).any(axis=1)]
    final_df.index.name = "Edges"
    print("Writing edge matrix")
    final_df.to_csv(output_path / "ematrix.csv", sep=",", index=True)


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
    write_node_matrix(file_paths, nodes, output_path)
    write_edge_matrix(file_paths, edges, output_path)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

import pathlib

import click
import networkx as nx

from micone import Network, NetworkGroup, Lineage


def write_networks(networks_dict, multigraph, color_key_level, output_path):
    combined_graph = nx.Graph()
    default_graph = networks_dict["default"].graph
    for network_name, network in networks_dict.items():
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
            G.add_node(
                name,
                name=name,
                taxlevel=taxlevel,
                colorkey=colorkey,
                layer="foreground",
            )
            combined_graph.add_node(
                name, name=name, taxlevel=taxlevel, colorkey=colorkey
            )
        for source, target, edge_data in graph.edges(data=True):
            source_name, target_name = id_name_map[source], id_name_map[target]
            weight = edge_data["weight"]
            pvalue = edge_data["pvalue"]
            G.add_edge(
                source_name,
                target_name,
                weight=weight,
                pvalue=pvalue,
                layer="foreground",
            )
            combined_graph.add_edge(
                source_name, target_name, weight=weight, pvalue=pvalue
            )
        id_name_map = dict()
        if network_name != "default":
            for node, node_data in default_graph.nodes(data=True):
                name = node_data["name"]
                id_name_map[node] = name
                taxlevel = node_data["taxlevel"]
                colorkey = (
                    Lineage.from_str(node_data["lineage"])
                    .get_superset(color_key_level)
                    .name[-1]
                )
                if name not in G.nodes:
                    G.add_node(
                        name,
                        name=name,
                        taxlevel=taxlevel,
                        colorkey=colorkey,
                        layer="background",
                    )
                else:
                    G.nodes[name]["layer"] = "common"
            for source, target, edge_data in default_graph.edges(data=True):
                source_name, target_name = id_name_map[source], id_name_map[target]
                weight = edge_data["weight"]
                pvalue = edge_data["pvalue"]
                if (source_name, target_name) not in G.edges:
                    G.add_edge(
                        source_name,
                        target_name,
                        weight=weight,
                        pvalue=pvalue,
                        layer="background",
                    )
                else:
                    G[source_name][target_name]["layer"] = "common"
                    G[source_name][target_name]["weight"] = edge_data["weight"]
        nx.write_gml(G, str(output_path / f"{network_name}.gml"))
    nx.write_gml(combined_graph, str(output_path / "combined.gml"))
    return list(combined_graph.nodes), list(combined_graph.edges)


@click.command()
@click.option(
    "--folder",
    help="The path to the folder containing the network files",
    type=pathlib.Path,
)
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
def main(
    folder: pathlib.Path,
    color_key_level: str,
    multigraph,
    output: str,
):
    if not folder.exists():
        raise ValueError(f"Folder {folder} must exist")
    networks_dict = dict()
    for sub_folder in folder.iterdir():
        # STEP1: Get all the `Network` for a particular folder (combination)
        name = sub_folder.stem
        network_files = sub_folder.glob("**/*.json")
        networks = [
            Network.load_json(str(network_file)) for network_file in network_files
        ]
        # STEP2: Convert all to `NetworkGroup` and perform `consensus`
        network_group = NetworkGroup(networks)
        cids = list(range(len(network_group.contexts)))
        consensus_network = network_group.get_consensus_network(
            cids, method="scaled_sum", parameter=0.5
        )
        # STEP3: Create a simple graph version of the consensus
        simple_consensus = consensus_network.to_network()
        networks_dict[name] = simple_consensus
    # STEP4: Then, feed the above to the previous function
    output_path = pathlib.Path(output)
    assert output_path.exists()
    nodes, edges = write_networks(
        networks_dict, multigraph, color_key_level, output_path
    )


if __name__ == "__main__":
    main()

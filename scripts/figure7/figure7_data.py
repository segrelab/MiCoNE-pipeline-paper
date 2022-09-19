#!/usr/bin/env python3

import pathlib

import click
import networkx as nx
import numpy as np
import pandas as pd
from tqdm import tqdm

from micone import Network, NetworkGroup, Lineage


def fix_title(title: str):
    try:
        step, tool = title.split("_", 1)
    except:
        return title
    return f"{step}={tool}"


def write_networks(networks_dict, multigraph, dataset, color_key_level, output_path):
    combined_graph = nx.MultiGraph()
    default_graph = networks_dict["default"].graph
    for network_name, network in tqdm(networks_dict.items()):
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
                dataset="Control" if dataset == "fmt-control" else "Autism",
            )
            combined_graph.add_node(
                name,
                name=name,
                taxlevel=taxlevel,
                colorkey=colorkey,
                title=f"{fix_title(network_name)}",
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
                dataset="Control" if dataset == "fmt-control" else "Autism",
            )
            combined_graph.add_edge(
                source_name,
                target_name,
                weight=weight,
                pvalue=pvalue,
                title=f"{fix_title(network_name)}",
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
                        dataset="Control" if dataset == "fmt-control" else "Autism",
                    )
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
                        dataset="Control" if dataset == "fmt-control" else "Autism",
                    )
                else:
                    G[source_name][target_name]["weight"] = edge_data["weight"]
        nx.write_gml(G, str(output_path / f"{network_name}.gml"))
    nx.write_gml(combined_graph, str(output_path / "combined.gml"))
    return list(combined_graph.nodes), list(combined_graph.edges)


def _get_adjmat(graph, combined_nodes) -> np.ndarray:
    n = len(combined_nodes)
    adjmat = pd.DataFrame(
        np.zeros((n, n)), index=combined_nodes, columns=combined_nodes
    )
    for source, target, data in graph.edges(data=True):
        weight = data.get("weight", 0.0)
        adjmat.loc[source, target] = 1 if weight > 0 else -1
    return adjmat.values


def calculate_l1_distance(default_graph: nx.Graph, process_graph: nx.Graph) -> float:
    combined_nodes = list(set(default_graph.nodes) | set(process_graph.nodes))
    default_adjmat = _get_adjmat(default_graph, combined_nodes)
    process_adjmat = _get_adjmat(process_graph, combined_nodes)
    l1 = np.abs(default_adjmat - process_adjmat).sum() / 2
    return l1


def calculate_edit_distance(default_graph: nx.Graph, process_graph: nx.Graph) -> float:
    approx_edits = nx.optimize_graph_edit_distance(default_graph, process_graph)
    edit_distance = next(approx_edits)
    return edit_distance


def _get_nodes_edges(graph: nx.Graph):
    graph.remove_nodes_from(list(nx.isolates(graph)))
    id_name_map = {id_: data["name"] for (id_, data) in graph.nodes(data=True)}
    edges = [frozenset([id_name_map[s], id_name_map[t]]) for s, t in graph.edges]
    return list(id_name_map.values()), edges


def calculate_fraction(
    default_graph: nx.Graph, process_graph: nx.Graph
) -> tuple[float, float]:
    default_nodes, default_edges = _get_nodes_edges(default_graph)
    process_nodes, process_edges = _get_nodes_edges(process_graph)
    common_nodes = set(default_nodes) & set(process_nodes)
    common_edges = set(default_edges) & set(process_edges)
    node_fraction = len(common_nodes) / len(process_graph.nodes)
    edge_fraction = len(common_edges) / len(process_graph.edges)
    return node_fraction, edge_fraction


def write_distances(networks_dict: dict, output_directory: pathlib.Path):
    data = []
    default_network = networks_dict["default"]["default"]
    default_graph = default_network.graph
    for step_name, step_network_dict in tqdm(networks_dict.items()):
        if step_name == "default":
            continue
        for process_name, process_network in step_network_dict.items():
            process_graph = process_network.graph
            l1_distance = calculate_l1_distance(default_graph, process_graph)
            edit_distance = calculate_edit_distance(default_graph, process_graph)
            node_fraction, edge_fraction = calculate_fraction(
                default_graph, process_graph
            )
            data.append(
                {
                    "step": step_name,
                    "process": process_name,
                    "l1_distance": l1_distance,
                    "edit_distance": edit_distance,
                    "node_fraction": node_fraction,
                    "edge_fraction": edge_fraction,
                }
            )
    df = pd.DataFrame(data)
    fname = output_directory / "distance_to_ref.csv"
    df.to_csv(fname, sep=",", index=False)


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
    default=False,
    type=bool,
    help="Flag to switch between multigraph and graph",
)
@click.option("--dc", help="The tool choice for DC step")
@click.option("--cc", help="The tool choice for CC step")
@click.option("--ta", help="The tool choice for TA step")
@click.option("--op", help="The tool choice for OP step")
@click.option("--ni", help="The tool choice for NI step")
@click.option("--dataset", help="The dataset (subset) for selection")
@click.option("--output", default=".", help="The path to the output directory")
def main(
    folder: pathlib.Path,
    color_key_level: str,
    multigraph: bool,
    dc: str,
    cc: str,
    ta: str,
    op: str,
    ni: str,
    dataset: str,
    output: str,
):
    if not folder.exists():
        raise ValueError(f"Folder {folder} must exist")
    networks_dict = {
        "default": dict(),
        "DC": dict(),
        "CC": dict(),
        "TA": dict(),
        "OP": dict(),
        # "NI": dict(),
    }
    for step_folder in tqdm(list(folder.iterdir())):
        step_name = step_folder.stem
        if step_name == "NI":
            continue
        assert step_name in networks_dict
        for process_folder in step_folder.iterdir():
            process_name = process_folder.stem
            # STEP1: Get all the `Network` for a particular folder (combination)
            network_files = list(process_folder.glob(f"**/{dataset}/*.json"))
            if not network_files:
                continue
            networks_for_consensus = [
                Network.load_json(str(network_file))
                for network_file in network_files
                if not network_file.parent.parent.name.endswith("pearson")
                and not network_file.parent.parent.name.endswith("spearman")
            ]
            # STEP2: Convert all to `NetworkGroup` and perform `consensus`
            if len(networks_for_consensus) == 0:
                networks = [
                    Network.load_json(str(network_file))
                    for network_file in network_files
                ]
                network_group = NetworkGroup(networks)
            else:
                network_group = NetworkGroup(networks_for_consensus)
            cids = list(range(len(network_group.contexts)))
            consensus_network = network_group.get_consensus_network(
                cids, method="scaled_sum", parameter=0.333
            )
            # STEP3: Create a simple graph version of the consensus
            simple_consensus = consensus_network.to_network()
            simple_consensus.interaction_threshold = 0.1
            networks_dict[step_name][process_name] = simple_consensus.filter(
                False, True
            )
    # STEP4: Then, feed the above to the previous function
    output_path = pathlib.Path(output) / dataset
    output_path.mkdir(parents=True, exist_ok=True)
    assert output_path.exists()
    networks_choice_dict = {
        f"DC_{dc}": networks_dict["DC"][dc],
        f"CC_{cc}": networks_dict["CC"][cc],
        f"TA_{ta}": networks_dict["TA"][ta],
        f"OP_{op}": networks_dict["OP"][op],
        # f"NI_{ni}": networks_dict["NI"][ni],
        "default": networks_dict["default"]["default"],
    }
    nodes, edges = write_networks(
        networks_choice_dict, multigraph, dataset, color_key_level, output_path
    )
    write_distances(networks_dict, output_directory=output_path)


if __name__ == "__main__":
    main()

#!/usr/bin/env python

import hashlib
import pathlib
import pickle
import multiprocessing as mp
from typing import Optional

import click
from micone import Network
import networkx as nx
import numpy as np
import pandas as pd
import networkx.algorithms.community as nx_comm
import tqdm
from tqdm_multiprocess import TqdmMultiProcessPool


import warnings

warnings.filterwarnings("ignore")


def get_metrics(graph: nx.Graph) -> dict:
    metrics = dict()
    # Average shortest path
    try:
        metrics["Average shortest path length"] = nx.average_shortest_path_length(graph)
    except nx.exception.NetworkXError:
        metrics["Average shortest path length"] = np.nan
    # Average clustering
    metrics["Average clustering"] = nx.average_clustering(graph)
    # Components
    metrics["No. of connected components"] = nx.number_connected_components(graph)
    # Modularity
    try:
        metrics["Modularity"] = nx_comm.modularity(
            graph, nx_comm.label_propagation_communities(graph)
        )
    except ZeroDivisionError:
        metrics["Modularity"] = np.nan
    # Connectivity
    metrics["Node connectivity"] = nx.node_connectivity(graph)
    metrics["Edge connectivity"] = nx.edge_connectivity(graph)
    # Assortativity
    metrics["Degree assortativity coefficient"] = nx.degree_assortativity_coefficient(
        graph
    )
    return metrics


def process_data(
    file_path: pathlib.Path,
    interaction_threshold: float,
    pvalue_threshold: float,
    tqdm_func,
    global_tqdm,
) -> dict:
    HEADER = ["DC", "CC", "TA", "OP", "TL", "NI"]
    process_string = file_path.parent.parent.stem
    hash = hashlib.md5(process_string.encode("utf-8")).hexdigest()
    processes = process_string.split("-")
    process_info = dict(zip(HEADER, processes))
    process_info["hash"] = hash
    network = Network.load_json(str(file_path))
    network.interaction_threshold = interaction_threshold
    network.pvalue_threshold = pvalue_threshold
    filtered_network = network.filter(pvalue_filter=True, interaction_filter=True)
    # Get the graph metrics
    graph = filtered_network.graph
    metrics = get_metrics(graph)
    data = {**process_info, **metrics}
    # tqdm_func.update()
    global_tqdm.update()
    return data


def error_callback(result):
    print("Error!")


def done_callback(result):
    pass


def summarize_metrics(df: pd.DataFrame) -> pd.DataFrame:
    HEADER = ["DC", "CC", "TA", "OP", "TL", "NI"]
    metrics = df.drop(HEADER, axis=1)
    data = []
    info_placeholder = dict(zip(HEADER, ["-"] * len(HEADER)))
    for step in HEADER:
        tools = set(df[step])
        for tool in tools:
            summarized_metrics_dict = metrics.loc[df[step] == tool, :].mean().to_dict()
            data_item = {**info_placeholder, step: tool, **summarized_metrics_dict}
            data.append(data_item)
    summarized_df = pd.DataFrame(data)
    return summarized_df


@click.command()
@click.option(
    "--files", help="The path to the network files containing the glob pattern"
)
@click.option(
    "--level", default="Genus", help="The taxonomy level to use for the data processing"
)
@click.option(
    "--interaction_threshold",
    default=0.1,
    type=float,
    help="The interaction threshold to apply",
)
@click.option(
    "--pvalue_threshold",
    default=0.05,
    type=float,
    help="The pvalue threshold to apply",
)
@click.option("--ncpus", default=4, type=int, help="The number of cpus to use")
@click.option("--output", default=".", help="The path to the output directory")
def main(
    files: str,
    level: str,
    interaction_threshold: float,
    pvalue_threshold: float,
    ncpus: int,
    output: str,
):
    output_path = pathlib.Path(output)
    assert output_path.exists()

    base_dir, glob = files.split("*", 1)
    glob = "*" + glob
    base_path = pathlib.Path(base_dir)
    file_paths = [
        f
        for f in base_path.glob(glob)
        if f"group({level})" in f.parent.parent.stem.split("-")
    ]

    # Multiprocessing setup
    pool = TqdmMultiProcessPool(ncpus)
    tasks = [
        (process_data, (file_path, interaction_threshold, pvalue_threshold))
        for file_path in file_paths
    ]
    task_count = len(tasks)

    print("Compiling the process info and graph metrics from networks")
    metrics_pickle = pathlib.Path("metrics.pkl")
    if metrics_pickle.exists():
        with open(metrics_pickle, "rb") as fid:
            df = pickle.load(fid)
    else:
        with tqdm.tqdm(total=task_count, dynamic_ncols=True) as global_progress:
            global_progress.set_description("global")
            results = pool.map(global_progress, tasks, error_callback, done_callback)
        df = pd.DataFrame(results).set_index("hash")
        df.TA.replace(
            {
                "blast(ncbi)": "BLAST(NCBI)",
                "naive_bayes(gg_13_8_99)": "NaiveBayes(GG)",
                "naive_bayes(silva_138_99)": "NaiveBayes(SILVA)",
            },
            inplace=True,
        )
        df.to_csv(output_path / "metrics.csv", index=True, sep=",")
        with open(metrics_pickle, "wb") as fid:
            pickle.dump(df, fid)

    print(df.head())
    df_summary = summarize_metrics(df)
    df_summary.to_csv(output_path / "metrics_summary.csv", sep=",", float_format="%.3f")
    print(df_summary.head())


if __name__ == "__main__":
    main()

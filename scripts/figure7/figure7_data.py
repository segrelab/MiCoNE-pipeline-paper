#!/usr/bin/env python3

import pathlib
from typing import Dict, Tuple, Union

import click
import numpy as np
import pandas as pd
from mlxtend.evaluate import confusion_matrix

from micone import Network, NetworkGroup


def read_predictions(
    prediction_file: pathlib.Path,
    interaction_threshold: float,
    pvalue_threshold: float,
) -> Network:
    network = Network.load_json(str(prediction_file))
    network.interaction_threshold = interaction_threshold
    network.pvalue_threshold = pvalue_threshold
    filtered_network = network.filter(pvalue_filter=True, interaction_filter=True)
    return filtered_network


def read_observations(
    observation_file: pathlib.Path, interaction_threshold: float, sign: bool
) -> pd.DataFrame:
    interactions: pd.DataFrame = pd.read_table(observation_file, index_col=0)
    np.fill_diagonal(interactions.values, 0.0)
    interactions[-interaction_threshold <= interactions <= interaction_threshold] = 0
    # NOTE: We don't need to apply threshold here again because we filter earlier
    if sign:
        interactions[interactions > 0] = 1
        interactions[interactions < 0] = -1
        interactions = interactions.astype(int)
    return interactions


def get_consensus(predictions_map: Dict[str, Dict[str, Network]]):
    corr_methods = ["sparcc", "propr", "spearman", "pearson"]
    direct_methods = [
        "spieceasi",
        "flashweave",
        "mldm",
        "cozine",
        "harmonies",
        "spring",
    ]
    consensus_methods = ["simple_voting", "scaled_sum"]
    consensus_parameters = np.linspace(
        0, 1, len(corr_methods) + len(direct_methods) + 1
    )
    pvalue_mergers_map: Dict[str, Dict[str, NetworkGroup]] = dict()
    consensus1_map: Dict[str, Dict[str, NetworkGroup]] = dict()
    consensus2_map: Dict[str, Dict[str, NetworkGroup]] = dict()
    for dataset_name in predictions_map:
        corr_networks = []
        direct_networks = []
        for algorithm_name in predictions_map[dataset_name]:
            if algorithm_name in corr_methods:
                corr_networks.append(predictions_map[dataset_name][algorithm_name])
            elif algorithm_name in direct_methods:
                direct_networks.append(predictions_map[dataset_name][algorithm_name])
        all_networks = corr_networks + direct_networks
        networkgroup_corr = NetworkGroup(corr_networks, id_field="id")
        networkgroup_direct = NetworkGroup(direct_networks, id_field="id")
        networkgroup_all = NetworkGroup(all_networks, id_field="id")
        # Step3a: Calculate merged pvalues network with different parameter values (unsure)
        cids = list(range(len(networkgroup_corr.contexts)))
        networkgroup_pvalue_merged = networkgroup_corr.combine_pvalues(cids)
        pvalue_mergers_map[dataset_name][
            "pvalue_merging_default"
        ] = networkgroup_pvalue_merged
        # Step3b: Calculate consensus network with different parameter values for all methods
        for method in consensus_methods:
            for parameter in consensus_parameters:
                cids = list(range(len(networkgroup_all.contexts)))
                networkgroup_consensus = networkgroup_all.get_consensus_network(
                    cids, method=method, parameter=parameter
                )
                if method == "simple_voting":
                    consensus1_map[dataset_name][
                        f"{method}_{parameter:.3f}"
                    ] = networkgroup_consensus
                elif method == "scaled_sum":
                    consensus2_map[dataset_name][
                        f"{method}_{parameter:.3f}"
                    ] = networkgroup_consensus
    return pvalue_mergers_map, consensus1_map, consensus2_map


def calculate_precision(confusion_matrix: dict) -> float:
    pre = confusion_matrix["tp"] / (confusion_matrix["tp"] + confusion_matrix["fp"])
    return pre


def calculate_sensitivity(confusion_matrix: dict) -> float:
    sen = confusion_matrix["tp"] / (confusion_matrix["fn"] + confusion_matrix["tp"])
    return sen


def calculate_performance(
    observations: pd.DataFrame, predictions: Union[Network, NetworkGroup], sign: bool
) -> Tuple[dict, float, float]:
    prediction_df = pd.DataFrame(
        np.zeros_like(observations.values),
        index=observations.index,
        columns=observations.columns,
    )
    if isinstance(predictions, Network):
        table = predictions.get_adjacency_table("weight")
        for row in table.index:
            for col in table.columns:
                prediction_df.loc[row, col] = table.loc[row, col]
    elif isinstance(predictions, NetworkGroup):
        vector_table = predictions.get_adjacency_vectors("weight")
        for row in vector_table.index:
            source, target = row.split("-")
            # FIXME: Is this the right thing to do?
            val = np.mean(vector_table.loc[row, :])
            prediction_df.loc[source, target] = val
            prediction_df.loc[target, source] = val
    else:
        raise ValueError("Unsupported predictions object")
    np.fill_diagonal(prediction_df.values, 0.0)
    if sign:
        prediction_df[prediction_df > 0] = 1
        prediction_df[prediction_df < 0] = -1
        prediction_df = prediction_df.astype(int)
    t_vec = observations.values.reshape(-1)
    p_vec = prediction_df.values.reshape(-1)
    cm = confusion_matrix(t_vec, p_vec, binary=True, positive_label=0)
    cm_fixed = [[cm[1, 1], cm[1, 0]], [cm[0, 1], cm[0, 0]]]
    cmatrix = {
        "tn": cm_fixed[0][0],
        "fp": cm_fixed[0][1],
        "fn": cm_fixed[1][0],
        "tp": cm_fixed[1][1],
    }
    precision = calculate_precision(cmatrix)
    sensitivity = calculate_sensitivity(cmatrix)
    return cmatrix, precision, sensitivity


def get_peformance_data(observations_map, predictions_map, sign) -> list:
    data = []
    for dataset_name in predictions_map:
        observations = observations_map[dataset_name]
        for algorithm_name in predictions_map[dataset_name]:
            predictions = predictions_map[dataset_name][algorithm_name]
            cmatrix, precision, sensitivity = calculate_performance(
                observations, predictions, sign
            )
            data.append(
                {
                    "factor1": dataset_name.split("_")[0],
                    "factor2": dataset_name.split("_")[1],
                    "algorithm": algorithm_name,
                    "tp": cmatrix["tp"],
                    "fp": cmatrix["fp"],
                    "tn": cmatrix["tn"],
                    "fn": cmatrix["fn"],
                    "precision": precision,
                    "sensitivity": sensitivity,
                }
            )
    return data


@click.command()
@click.option(
    "--files", help="The path to the network files containing the glob pattern"
)
@click.option(
    "--observations_directory", type=pathlib.Path, help="The path to the observations"
)
@click.option(
    "--interaction_threshold", default=0.1, help="Value to threshold interactions by"
)
@click.option("--pvalue_threshold", default=0.05, help="Value to threshold pvalues by")
@click.option(
    "--sign", default="False", help="Flag to convert matrices to sign matrices"
)
@click.option("--output", default=".", help="The path to the output directory")
def main(
    files: str,
    observations_directory: pathlib.Path,
    interaction_threshold: float,
    pvalue_threshold: float,
    sign: bool,
    output: str,
):
    output_path = pathlib.Path(output)
    assert output_path.exists()

    # Step1: Get observations
    observations_map: Dict[str, pd.DataFrame] = dict()
    for dataset in observations_directory.iterdir():
        dataset_name = dataset.stem
        observation_file = dataset / "interaction_matrix.tsv"
        observations_map[dataset_name] = read_observations(
            observation_file, interaction_threshold=interaction_threshold, sign=sign
        )

    # Step2: Get predictions
    base_dir, glob = files.split("*", 1)
    glob = "*" + glob
    base_path = pathlib.Path(base_dir)
    file_paths = list(base_path.glob(glob))
    predictions_map: Dict[str, Dict[str, Network]] = dict()
    for prediction_file in file_paths:
        dataset = prediction_file.parent
        algorithm_name = prediction_file.parent.parent.stem.split("-")[-1]
        dataset_name = dataset.stem
        predictions_map[dataset_name][algorithm_name] = read_predictions(
            prediction_file,
            interaction_threshold=interaction_threshold,
            pvalue_threshold=pvalue_threshold,
        )

    # Step3: Calculate consensus using predictions_map
    pvalue_mergers_map, consensus1_map, consensus2_map = get_consensus(predictions_map)

    # Step4: Calculate precision and sensitivity for all
    data = []
    data.extend(get_peformance_data(observations_map, predictions_map, sign))
    data.extend(get_peformance_data(observations_map, pvalue_mergers_map, sign))
    data.extend(get_peformance_data(observations_map, consensus1_map, sign))
    data.extend(get_peformance_data(observations_map, consensus2_map, sign))
    df = pd.DataFrame(data)
    df.to_csv(output_path / "performance.csv", index=False, sep=",")


if __name__ == "__main__":
    main()

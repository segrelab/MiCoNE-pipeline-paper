#!/usr/bin/env python3

from collections import defaultdict
import pathlib
import pickle
from typing import Dict, Tuple, Union

import click
import numpy as np
import pandas as pd
from mlxtend.evaluate import confusion_matrix
from tqdm import tqdm

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
    interactions[np.abs(interactions) <= interaction_threshold] = 0
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
        0, 1, (len(corr_methods) + len(direct_methods) + 1) // 2
    )
    pvalue_mergers_map: Dict[str, Dict[str, NetworkGroup]] = defaultdict(dict)
    consensus1_map: Dict[str, Dict[str, NetworkGroup]] = defaultdict(dict)
    consensus2_map: Dict[str, Dict[str, NetworkGroup]] = defaultdict(dict)
    for dataset_name in tqdm(predictions_map):
        corr_networks = []
        direct_networks = []
        for algorithm_name in predictions_map[dataset_name]:
            if algorithm_name in corr_methods:
                corr_networks.append(predictions_map[dataset_name][algorithm_name])
            elif algorithm_name in direct_methods:
                direct_networks.append(predictions_map[dataset_name][algorithm_name])
        all_networks = corr_networks + direct_networks
        networkgroup_corr = NetworkGroup(corr_networks, id_field="id")
        # networkgroup_direct = NetworkGroup(direct_networks, id_field="id")
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
    if len(predictions.links):
        if isinstance(predictions, Network):
            table = predictions.get_adjacency_table("weight")
            for row in table.index:
                for col in table.columns:
                    prediction_df.loc[row, col] = table.loc[row, col]
        elif isinstance(predictions, NetworkGroup):
            vector_table = predictions.get_adjacency_vectors("weight")
            for row in vector_table.index:
                if row not in predictions.linkid_revmap:
                    continue
                else:
                    source, target = predictions.linkid_revmap[row][0][-1].split("-")
                    # FIXME: Is this the right thing to do?
                    val = np.nanmean(vector_table.loc[row, :])
                    prediction_df.loc[source, target] = val
                    prediction_df.loc[target, source] = val
        else:
            raise ValueError("Unsupported predictions object")
        np.fill_diagonal(prediction_df.values, 0.0)
        prediction_df.fillna(0.0, inplace=True)
        if sign:
            prediction_df[prediction_df > 0] = 1
            prediction_df[prediction_df < 0] = -1
            prediction_df = prediction_df.astype(int)
        t_vec = observations.values.reshape(-1)
        p_vec = prediction_df.values.reshape(-1)
        cm = confusion_matrix(t_vec, p_vec, binary=True, positive_label=0)
        cm_fixed = [[cm[1, 1], cm[1, 0]], [cm[0, 1], cm[0, 0]]]
        cm_dict = {
            "tn": cm_fixed[0][0],
            "fp": cm_fixed[0][1],
            "fn": cm_fixed[1][0],
            "tp": cm_fixed[1][1],
        }
        precision = calculate_precision(cm_dict)
        sensitivity = calculate_sensitivity(cm_dict)
    else:
        cm_dict = {"tn": np.nan, "fp": np.nan, "fn": np.nan, "tp": np.nan}
        precision = np.nan
        sensitivity = np.nan
    return cm_dict, precision, sensitivity


def fix_name(name: str) -> str:
    if name.startswith("scaled_sum"):
        parameter_value = name.rsplit("_", 1)[-1]
        return f"SS({parameter_value})"
    elif name.startswith("simple_voting"):
        parameter_value = name.rsplit("_", 1)[-1]
        return f"SV({parameter_value})"
    elif name.startswith("pvalue_merging"):
        parameter_value = name.rsplit("_", 1)[-1]
        return "PM"
    else:
        return name


def get_peformance_data(observations_map, predictions_map, sign) -> list:
    data = []
    for dataset_name in tqdm(predictions_map):
        observations = observations_map[dataset_name]
        for algorithm_name in predictions_map[dataset_name]:
            predictions = predictions_map[dataset_name][algorithm_name]
            cm_dict, precision, sensitivity = calculate_performance(
                observations, predictions, sign
            )
            data.append(
                {
                    "factor1": dataset_name.split("_")[0],
                    "factor2": dataset_name.split("_")[1],
                    "algorithm": fix_name(algorithm_name),
                    "tp": cm_dict["tp"],
                    "fp": cm_dict["fp"],
                    "tn": cm_dict["tn"],
                    "fn": cm_dict["fn"],
                    "precision": precision,
                    "sensitivity": sensitivity,
                }
            )
    return data


def update_algo_name(df: pd.DataFrame) -> None:
    algos = set(df.algorithm)
    for algo in algos:
        avg_precision = np.nanmean(df.loc[df.algorithm == algo, "precision"])
        df.loc[df.algorithm == algo, "algorithm"] += f" P(avg)={avg_precision:.3f}"


@click.command()
@click.option(
    "--files", help="The path to the network files containing the glob pattern"
)
@click.option(
    "--interaction_threshold", default=0.1, help="Value to threshold interactions by"
)
@click.option("--pvalue_threshold", default=0.05, help="Value to threshold pvalues by")
@click.option(
    "--sign", default=True, type=bool, help="Flag to convert matrices to sign matrices"
)
@click.option("--output", default=".", help="The path to the output directory")
def main(
    files: str,
    interaction_threshold: float,
    pvalue_threshold: float,
    sign: bool,
    output: str,
):
    output_path = pathlib.Path(output)
    assert output_path.exists()

    # Step1 and 2: Get observations and predictions
    print("Step1 and 2: Get observations and predictions")
    step_1_2_pickle = pathlib.Path("step_1_2.pkl")
    if step_1_2_pickle.exists():
        with open(step_1_2_pickle, "rb") as fid:
            predictions_map = pickle.load(fid)
            observations_map = pickle.load(fid)
    else:
        base_dir, glob = files.split("*", 1)
        glob = "*" + glob
        base_path = pathlib.Path(base_dir)
        file_paths = list(base_path.glob(glob))
        predictions_map: Dict[str, Dict[str, Network]] = defaultdict(dict)
        observations_map: Dict[str, pd.DataFrame] = dict()
        for prediction_file in tqdm(file_paths):
            dataset = prediction_file.parent
            algorithm_name = prediction_file.parent.parent.stem.split("-")[-1]
            dataset_name = dataset.stem
            observation_file = dataset / "interaction_matrix.tsv"
            observations_map[dataset_name] = read_observations(
                observation_file, interaction_threshold=interaction_threshold, sign=sign
            )
            predictions_map[dataset_name][algorithm_name] = read_predictions(
                prediction_file,
                interaction_threshold=interaction_threshold,
                pvalue_threshold=pvalue_threshold,
            )
        with open(step_1_2_pickle, "wb") as fid:
            pickle.dump(predictions_map, fid)
            pickle.dump(observations_map, fid)

    # Step3: Calculate consensus using predictions_map
    print("Step3: Calculate consensus using predictions_map")
    step_3_pickle = pathlib.Path("step_3.pkl")
    if step_3_pickle.exists():
        with open(step_3_pickle, "rb") as fid:
            pvalue_mergers_map = pickle.load(fid)
            consensus1_map = pickle.load(fid)
            consensus2_map = pickle.load(fid)
    else:
        pvalue_mergers_map, consensus1_map, consensus2_map = get_consensus(
            predictions_map
        )
        with open(step_3_pickle, "wb") as fid:
            pickle.dump(pvalue_mergers_map, fid)
            pickle.dump(consensus1_map, fid)
            pickle.dump(consensus2_map, fid)

    # Step4: Calculate precision and sensitivity for all
    print("Step4: Calculate precision and sensitivity for all")
    step_4_pickle = pathlib.Path("step_4.pkl")
    if step_4_pickle.exists():
        with open(step_4_pickle, "rb") as fid:
            df = pickle.load(fid)
    else:
        data = []
        data.extend(get_peformance_data(observations_map, predictions_map, sign))
        data.extend(get_peformance_data(observations_map, pvalue_mergers_map, sign))
        data.extend(get_peformance_data(observations_map, consensus1_map, sign))
        data.extend(get_peformance_data(observations_map, consensus2_map, sign))
        df = pd.DataFrame(data)
        update_algo_name(df)
        with open(step_4_pickle, "wb") as fid:
            pickle.dump(df, fid)
    df.to_csv(output_path / "performance.csv", index=False, sep=",")


if __name__ == "__main__":
    main()
